#!/bin/bash

TRIES=3

counter=0
cat 'queries.sql' | while read -r SQL; do

    echo -n "["

    for i in $(seq 1 $TRIES); do
            QUERY="{\"query\":\"$SQL\"}"
            curl -X POST 'http://localhost:9200/hits/_cache/clear?pretty' &>/dev/null

            RSP=$(curl -s -X POST 'http://localhost:9200/_plugins/_sql?format=json' -H 'Content-Type: application/json' -d"$QUERY")
            TIME=$(echo $RSP | jq -r '.took')
            TIME=$(echo "scale=4; $TIME / 1000" | bc)

            [[ "$( jq 'has("error")' <<< $RSP )" == "true" ]] && echo -n "null" || echo -n "$TIME"
            [[ "$i" != $TRIES ]] && echo -n ", "
    done

    echo "],"
    counter=$((counter+1))
done;