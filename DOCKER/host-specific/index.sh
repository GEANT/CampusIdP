#!/usr/bin/env bash

ATTRIBUTEDEF=/opt/shibboleth-idp/conf/attribute-resolver.xml
HEADER="/tmp/index_header.html"
FOOTER="/tmp/index_footer.html"
OUTPUT="/opt/jetty/webapps/root/index.html"

attributes=$(grep '<AttributeDefinition' ${ATTRIBUTEDEF} | sed -nr 's/.*id="([a-zA-Z]+)".*/\1/p')

name[0]=givenName
name[1]=sn
name[2]=cn
name[3]=displayName
name[4]=mail
name[5]=o
name[6]=ou
name[7]=eduPersonScopedAffiliation
name[8]=eduPersonTargetedID
name[9]=eduPersonEntitlement
name[10]=eduPersonPrincipalName
name[11]=eduPersonUniqueId

declare -A description
description[givenName]='First name'
description[sn]='Last name'
description[cn]='Full name'
description[displayName]='Display name'
description[mail]='Email address'
description[o]='Organization'
description[ou]='Organization unit'
description[eduPersonScopedAffiliation]='Role(s) in organization'
description[eduPersonTargetedID]='Unique pseudoanonymous identifier'
description[eduPersonEntitlement]='Permissions for specific services'
description[eduPersonPrincipalName]='Unique identifier'
description[eduPersonUniqueId]='Unique persistent identifier'

cat ${HEADER} > ${OUTPUT}

for attribute in ${name[*]}; do
    if [[ "$attributes" == *$attribute* ]]; then
        printf "                        <tr><td><code>%s</code></td><td>%s</td></tr>\n" "${attribute}" "${description[${attribute}]}" >> ${OUTPUT}
    fi
done

cat ${FOOTER} >> ${OUTPUT}

