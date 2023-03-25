#!/bin/bash

exist_ffmpeg=`ps aux | grep '[f]fmpeg' | wc -l`
exist_gst=`ps aux | grep '[g]st-launch' | wc -l`

is_encoding=`ps aux | grep '[r]k-encode.js' | wc -l`

if [ ${is_encoding} -eq 0 ]; then
  exist_ffmpeg=0
  exist_gst=0
fi

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR
./senddb.sh encode_task "exist_ffmpeg=${exist_ffmpeg},exist_gst=${exist_gst}"

