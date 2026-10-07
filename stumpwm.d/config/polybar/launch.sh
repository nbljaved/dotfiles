#!/usr/bin/env bash

MONITOR=$(polybar -m|tail -1|sed -e 's/:.*$//g')

# Terminate already running bar instances
# If all your bars have ipc enabled, you can use
polybar-msg cmd quit
# Otherwise you can use the nuclear option:
# killall -q polybar

# Launch bar
echo "---" | tee -a /tmp/polybar.log
polybar --reload -c ~/.stumpwm.d/config/polybar/polybar.config.ini | tee -a /tmp/polybar.log & disown

echo "Bars launched..."
