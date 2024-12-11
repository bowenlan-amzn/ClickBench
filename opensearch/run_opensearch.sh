#!/bin/bash

TRIES=3

cat 'queries.dsl' | while read -r QUERY; do

    echo -n "["

    for i in $(seq 1 $TRIES); do
	  curl -X POST 'http://localhost:9200/hits/_cache/clear?pretty' &>/dev/null
	  RSP=$(curl -s -X GET "http://localhost:9200/hits/_search" -H 'Content-Type: application/json' -d"$QUERY" )
	  TIME=$(echo $RSP | jq -r '.took')
	  TIME=$(echo "scale=4; $TIME / 1000" | bc)

	  [[ "$( jq 'has("error")' <<< $RSP )" == "true" ]] && echo -n "null" || echo -n "$TIME"
	  [[ "$i" != $TRIES ]] && echo -n ", "
    done;

    echo "],"

done;
