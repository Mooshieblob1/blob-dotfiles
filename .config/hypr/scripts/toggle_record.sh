#!/usr/bin/env bash

# Check if wf-recorder is already running
if pgrep -x "wf-recorder" > /dev/null
then
    # If it's running, stop it and send a notification
    killall -s SIGINT wf-recorder
    notify-send "Screen Recording Stopped" "Video saved in ~/Videos" -u normal
else
    # If it's not running, send a notification to prompt for selection
    notify-send "Screen Recording Started" "Select a region to record..." -u normal
    # Start recording using slurp to select the area
    wf-recorder -g "$(slurp)" -f ~/Videos/recording_$(date +'%Y-%m-%d_%H-%M-%S').mp4
fi
