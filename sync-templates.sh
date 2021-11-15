#!/bin/bash

set -e

NEXT_TOKEN=""
rm -f list-templates.json

while
    aliyun oos ListTemplates --ShareType Public --MaxResults 100 --NextToken $NEXT_TOKEN > list-templates-next-token.json
    NEXT_TOKEN=`cat list-templates-next-token.json | jq -r '.NextToken'`
    NEW_TEMPALTES=`cat list-templates-next-token.json | jq 'with_entries(select([.key] | inside(["Templates"])))'`
    if [ -f list-templates.json ]; then
        ORIGIN_TEMPLATES=`cat list-templates.json`
        echo $ORIGIN_TEMPLATES $NEW_TEMPALTES | jq -s '.[0].Templates=([.[].Templates]|flatten)|.[0]' > list-templates.json
    else
        echo $NEW_TEMPALTES > list-templates.json
    fi
    [ "$NEXT_TOKEN" != "null" ]
do :; done

cat list-templates.json | jq -cr '.Templates[].TemplateName' | xargs -n1 sh -c 'sleep 1 && aliyun oos GetTemplate --TemplateName $1 | jq -r ".Content" > "templates/$1.yaml"' sh
rm -f list-templates-next-token.json
