#!/bin/bash

## 録画先ディレクトリの指定
record_dir="/mnt/sample-recorded"

######## 設定変更はここまで ########

function get_cpu_usage() {
  read cpu user nice sys idle iowait remain < /proc/stat
  idle_prev=$((idle+iowait))
  nidle_prev=$((user+nice+sys))

  sleep 2

  read cpu user nice sys idle iowait remain < /proc/stat
  idle_now=$((idle+iowait))
  nidle_now=$((user+nice+sys))

  total_prev=$((idle_prev+nidle_prev))
  total_now=$((idle_now+nidle_now))

  totaldiff=$((total_now-total_prev))
  idlediff=$((idle_now-idle_prev))

  usage=$((100*(totaldiff-idlediff)/(totaldiff+1)))
  echo $usage
  return `expr ${usage}`
}

cpu_usage=`get_cpu_usage`
cpu_temp=$(sensors | grep temp1 | tail -n1 | awk '{print $2}' | sed -e 's/[^0-9.]//g')
free_space=$(df -B1G ${record_dir} | tail -n1 | awk '{print $4 }' | sed -E 's/[^0-9]*//g')
mem_usage=$(awk '/^MemTotal:/ {total=$2} /^MemAvailable:/ {free=$2} END {print int((total-free)*100/total)}' /proc/meminfo)

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR
./senddb.sh machine "cpu_temp=${cpu_temp// /},cpu_usage=${cpu_usage// /},mem_usage=${mem_usage// /},free_disk=${free_space// /}"
