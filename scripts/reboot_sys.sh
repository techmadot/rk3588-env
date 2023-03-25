#!/bin/bash

host="localhost:8888"

## 録画中であるか
recording=$(curl --silent "http://${host}/api/recording?offset=0&limit=24&isHalfWidth=true"   -H 'accept: application/json' | jq '.total')
if [ $recording -gt 0 ]; then
  echo recoding progress. reboot is canceled.
  exit 1
fi

## エンコード処理中であるか
encoding=$(curl --silent -X GET "http://${host}/api/encode?isHalfWidth=true" | jq '[.runningItems, .waitItems] | map(length) | add')
if [ $encoding -gt 0 ]; then
  echo encoding progress. reboot is canceled.
  exit 1
fi

## 30分以内に録画予約があるか
time0=$(date +%s | awk '{printf "%d000",$1}')
time1=$(date -d "+30 minutes" +%s | awk '{printf "%d000",$1}')
has_reserve=$(curl --silent -X GET "http://${host}/api/reserves/lists?startAt=${time0}&endAt=${time1}" | jq '.normal | length')
if [ $has_reserve -gt 0 ]; then
  echo exist reservation. reboot is canceled.
  exit 1
fi

echo Can Reboot
/sbin/reboot

