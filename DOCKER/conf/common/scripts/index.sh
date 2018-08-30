#!/usr/bin/env bash

ATTRIBUTEDEF=/opt/shibboleth-idp/conf/attribute-resolver.xml
HEADER="$(cat <<EOF
<!DOCTYPE html>

<html lang="en">
<head>
    <meta charset="utf-8">
    <title>Identity Provider Information Page</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="author" content="Jan Oppolzer; jan@oppolzer.cz">
    <meta name="generator" content="VIM - Vi IMproved 8.0">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" integrity="sha256-916EbMg70RQy9LHiGkXzG8hSg9EdNy97GazNG/aiY1w= sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u sha256-6MXa8B6uaO18Hid6blRMetEIoPqHf7Ux1tnyIQdpt9qI5OACx7C+O3IVTr98vwGnlcg0LOLa02i9Y1HpVhlfiw==" crossorigin="anonymous">
    <link rel="stylesheet" href="css/style.css">
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.2.1/jquery.min.js" integrity="sha256-hwg4gsxgFZhOsEEamdOYGBf13FyQuiTwlAQgxVSNgt4= sha384-xBuQ/xzmlsLoJpyjoggmTEz8OWUFM0/RC5BsqQBDX2v5cMvDHcMakNTNrHIW2I5f sha512-3P8rXCuGJdNZOnUx/03c1jOTnMn3rP63nBip5gOP2qmUh5YAdVAvFZ1E+QLZZbC1rtMrQb+mah3AfYW11RUrWA==" crossorigin="anonymous"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js" integrity="sha256-U5ZEeKfGNOja007MMD3YBI0A3OSZOQbeG6z2f2Y0hu8= sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa sha512-iztkobsvnjKfAtTNdHkGVjAYTrrtlC7mGp/54c40wowO7LhURYl3gVzzcEqGl/qKXQltJ2HwMrdLcNUdo+N/RQ==" crossorigin="anonymous"></script>
</head>
<body>

<div class="container">

    <div class="row">
        <div class="col-md-12">

                <div class="jumbotron text-center">
                    <h1>Indentity Provider </h1>
                    <p>of</p>
                    <h2>CESNET</h2>
            </div>

        </div>
    </div>

    <div class="row">
        <div class="col-md-12">

            <p>This is an Identity Provider for <em>CESNET</em> running <a
            href="https://www.shibboleth.net/products/identity-provider/">Shibboleth
            Identity Provider</a> inside a Docker container. It is a live
            implementation of <em>GÉANT</em> project called <em>Campus
            IdP</em>.</p>

            <h2>Technical Information</h2>
            <p>To register this Identity Provider to a federation, use this <a
            href="/idp/metadata">metadata</a>, however, be careful as it might
            be needed to tweak it a little bit depending on federation's
            policy.</p>
            <p>In case of any technical issues with this IdP, contact <a
            href="mailto:jan.oppolzer@cesnet.cz">Jan Oppolzer</a> of <a
            href="https://www.cesnet.cz/">CESNET</a>.</p>

            <h2>Available Attributes</h2>
            <p>This Identity Provider implements attributes listed in the table
            below. It does not mean that all attributes are available to all
            federated services, tough. Contact technical support in case
            something does not work as expected.</p>

            <div class="table-responsive">
                <table class="table table-striped table-bordered table-hover">
                    <thead>
                        <tr>
                            <th>Attribute Name</th>
                            <th>Attribute Meaning</th>
                        </tr>
                    </thead>
                    <tbody>
EOF
)"
FOOTER="$(cat <<EOF
                    </tbody>
                </table>
            </div>

            <hr>

            <p class="text-right"><small>Any issues should be reported to <a href="mailto:jan.oppolzer@cesnet.cz">Jan Oppolzer</a>.</small></p>
        </div>
    </div>

</div>

</body>
</html>
EOF
)"
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

echo "${HEADER}" > ${OUTPUT}

for attribute in ${name[*]}; do
    if [[ "$attributes" == *$attribute* ]]; then
        printf "                        <tr><td><code>%s</code></td><td>%s</td></tr>\n" "${attribute}" "${description[${attribute}]}" >> ${OUTPUT}
    fi
done

echo "${FOOTER}" >> ${OUTPUT}
