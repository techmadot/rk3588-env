#!/bin/bash

## senddb.sh (measurement) (linedata)

## 送信先の情報
token=my-recmachine-token
bucket=mybucket
dbuser=myuser
dbpassword=mypassword
organization=myorgs
influxdb_host="127.0.0.1:8086"

######## 設定変更はここまで ########
url="http://${dbuser}:${my-password}@${influxdb_host}/api/v2"
curl -X POST "${url}/write?org=${organization}&bucket=${bucket}" \
  -d "$1 $2" --header "Authorization: Token $token"
