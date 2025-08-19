#!/usr/bin/env bash

killall -s SIGINT wf-recorder
notify-send "Screen Recording Stopped" "Video saved in ~/Videos" -u normal
