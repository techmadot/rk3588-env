#!/bin/bash

FFPROBE=/usr/bin/ffprobe
INPUT=$1

program_no=$($FFPROBE -hide_banner -i "$INPUT" 2>&1 | grep Program | head -n 1 | sed -E 's/.*Program ([0-9]+) .*$/\1/g')
video_sid=$($FFPROBE  -hide_banner -i "$INPUT" 2>&1 | grep Stream | grep Video | sed -e "s/^.*Stream #0:0\[0x\([0-9a-f][0-9a-f][0-9a-f]\)\].*$/\1/g")
audio_sid=$($FFPROBE  -hide_banner -i "$INPUT" 2>&1 | grep Stream | grep Audio | head -n 1 | sed -e "s/^.*Stream #0:1\[0x\([0-9a-f][0-9a-f][0-9a-f]\)\].*$/\1/g")

echo "{ \"program\": ${program_no:--1},  \"video_sid\" : ${video_sid:--1}, \"audio_sid\" : ${audio_sid:--1} }"
