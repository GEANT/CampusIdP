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
     - **configs** : This keyame will contains all IdP configuration elements in array
    


### Data format of IdP configuration from API server
The root object is @type of **IdPConf** and doesn't contain "@id"

```json
{
    "@type": "IdPConf",
    "configs": [
    
    ]
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

#### Attribute Resolver

There are two types of special object: AttributeDefinition and DataConnector

***

##### ***"@type" : "AttributeDefinition"***
example for defining email attribute:
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
    "sourceAttrId": "mail",
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
example final document containing only one attribute definition

```json

 {
    "@type": "IdPConf",
    "configs": [
        [
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
                "sourceAttrId": "mail",
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
        ]
    ]
}
```

Keynames used to build "AttributeDefinition" object:
- **@id**  *[required] *: attribute ID is used for reference within document and for attribute release policy 
- **@type** *[required] *: defines the type of an object. In this case is "AttributeDefinition"
- **confType**  *[required] *: defines the type of attributeDefiintion. Convetion is taken from ShibbolethIdP *(ad:Type)*
- **sourceAttrId** *[TBC]*: 
- **exposed** *[optional]*: *boolean value* defines if defined attribute may be considered to release. default is ***false***



***

**"@type": "DataConnector"**

To be continue....
