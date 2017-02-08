***DRAFT***

***


## Goals

1. Define a representation of information about IdP configuration retrieved by remote client
2. Define a representation of information about IdP change request sent by remote client


## Data format for exchanging messages
Proposed format is json 

- Nearly every object withing document should have following keynames:
    -  **@type** : The special keyname is used to set the data type of a node or typed value within document
    -  **@id** : The special keyname defines unique identifier and can be also used for reference
- In addition the root object must contain:
     - **configs** : This keyame will contain a collection (array) of configuration elements like attribute definitions
    


### Data format of IdP configuration from API server
The root object is @type of **IdPConf** and doesn't contain "@id"

```json
{
    "@type": "IdPConf",
    "configs": [
    
    ],
    "apiVersion" : "1"
}
```

### Data format of a change request from API client to API server
To distinguish IdPconfiguration from change request the root object is @type of **IdPConfCR** and doesn't contain "@id"
```json
{
    "@type": "IdPConfCR",
    "configs": [
    ]
}
```
Objects inside "configs" array without one of the following key-value pairs will be ignored *(more details later in the document)*:
- "action": "delete"
- "action": "update"

### Types of configs objects
- ServiceDescriptor
- MetadataProvider
- DataSource
- Certificate
- AttributeDefinition
- DataConnector


#### Global 

##### ***"~~@type" : "Connector"~~***


**"@type": "ServiceDescription"**
Used to set global information for IdP

List of properties:

* entityID :
* idpsso : object with properties:
	* scope
	* certificates - list of nodes
		* use : *signing/encryption*
		* ref : *reference to cert id*
* aa :
	* scope
	* certificates - list of nodes
		* use : *signing/encryption*
		* ref : *reference to cert id*


```json
{
     "@id": "ServiceConfiguration",
     "@type": "ServiceDescription",
     "entityID": "https://idp.example.com/idp",
     "idpsso": {
         "certificates" : [
             {
                 "use": "signing",
                 "ref": "cert01"
             },
             {
                 "use": "encryption",
                 "ref": "cert02"
             }
         ]
     }
     
}
```


**"@type": "DataSource"**

```json
{
     "@id": "ldap01",
     "@type": "DataSource",
     "confType": "LDAPDirectory",
     "ldapURL": "ldap://localhost:389",
     "baseDN": "DC=example,DC=com",
     "bindDN": "cn=connector,dc=example,dc=com",
     "bindDNCredentials": "123"
}

```

**"@type": "DataConnector"**

Keynames used to build "DataConnector" node:

* **@id**  *[required] *: DataConnector ID is used for reference within document and for attribute release policy 
* **@type** *[required] *: defines the type of a node. In this case is "DataConnector"
* **confType**  *[required] *: defines the type of DataConnector. Convetion is taken from ShibbolethIdP *(ad:Type)*
		* LDAPDirectory
		* Static
		* ScriptedDataConnector
		* RelationalDatabase
* **confRef** *[optional] *: defines the source of configuration data. If set then the value must be existing @id
* **scriptData**: used by *ScriptedDataConnector*


example for static attributes

```json
{
    "@id": "StaticAttributes",
    "@type": "DataConnector",
    "confType": "Static",
    "attributes": [
        {
            "attrid": "ou",
            "values": [
                "Organization name"
            ]
        },
        {
            "attrid": "eduPersonEntitlement",
            "values": [
                "urn:mace:terena.org:tcs:escience-admin",
                "urn:mace:terena.org:tcs:escience-user"
            ]
        }
    ]
}

```
example for DataConnector (LDAP)
```json
{
     "@id": "myLdap",
     "@type": "DataConnector",
     "confType": "LDAPDirectory",
     "confRef": "ldap01"
}
```


**"@type": "MetadataProvider"**

* @id
* @type
* confType:	  default value
	* *FileBackedHTTPMetadataProvider*
* url
* metadataFilter: list of properties
	* requiredValidUntill
	* signatureValidation: *list of properties*
		* certificate : *referecence to id of Certificate node*
		

**"@type": "Certificate"**

* @id
* @type : Certificate
TBD

#### Attribute Resolver

There are two types of nodes: **AttributeDefinition** and **DataConnector**

***

##### 
**"@type" : "AttributeDefinition"**


Keynames used to build "AttributeDefinition" object:

* **@id**  *[required] *: attribute ID is used for reference within document and for attribute release policy 
* **@type** *[required] *: defines the type of a node. In this case is "AttributeDefinition"
* **confType**  *[required] *: defines the type of attributeDefiintion. Convetion is taken from ShibbolethIdP *(ad:Type)*
		* Simple
		* Template
		* Scoped
		* Scripted        
* **sourceAttributeId** : required by *Simple*,  *Scoped*, *Prescoped*: 
* **scope**: required by *Scoped*
* **sourceAttribute**: array of attributes; required by *Template*
* **generatedOutput**: required by *Template*
* **dependency**: list (in array) of references to nodes of @type AttributeDefinition or DataConnector
* **encodigns**:  array of  nodes having properties:
		* name
		* friendlyName
		* encType
* **scriptFile**: used by *Scripted*
* **scriptData**: used by *Scripted*
* **exposed** *[optional]*: *boolean value* defines if defined attribute may be considered to release. default is ***false***

##### ***Examples***


sample node of email attribute definition (conftype: Simple):
```json
{
    "@id": "email",
    "@type": "AttributeDefinition",
    "confType": "Simple",
    "dependency": [
       {
           "@id": "myLdap",
           "@type": "@id"
       }
    ],
    "sourceAttrIbuteId": "mail",
    "exposed": true,
    "encodings": [
        {
             "encType": "SAML1String",
              "name": "urn:mace:dir:attribute-def:mail"
       },
       {
             "encType": "SAML2String",
             "name": "urn:oid:0.9.2342.19200300.100.1.3",
             "friendlyName": "mail"
       }
    ]
}
```