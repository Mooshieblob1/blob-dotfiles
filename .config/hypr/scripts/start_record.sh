#!/usr/bin/env bash

notify-send "Screen Recording Started" "Select a region to record..." -u normal
wf-recorder -g "$(slurp)" -f ~/Videos/recording_$(date +'%Y-%m-%d_%H-%M-%S').mp4
