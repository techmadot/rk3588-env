#!/bin/bash

recording=$(curl --silent 'http://localhost:8888/api/recording?offset=0&limit=24&isHalfWidth=true'   -H 'accept: application/json' | jq '.total')
reserveCount=$(curl -X 'GET'   'http://localhost:8888/api/reserves/cnts'   -H 'accept: application/json' | jq .normal)

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR
./senddb.sh epgstation "recording=${recording// /},reserve=${reserveCount// /
}"


