#!/bin/sh
# Usage: webcam-stream.sh [DEVICE]   (default /dev/video0)
#
# Streams a webcam to http://127.0.0.1:8080/cam.mjpg, to watch it from the
# phone.  It listens on localhost only, so it is reached through SSH.  From
# Termux, over Tailscale (the path is relative to $HOME):
#
#   ssh -t -L 8080:127.0.0.1:8080 nabeel@pc
#   then run dotfiles/guix-config/other/scripts/webcam-stream.sh
#
# then open http://localhost:8080/cam.mjpg in the phone's browser.  Ctrl-C
# stops it.  If OBS has the webcam, start its virtual camera and pass
# /dev/video11.
set -eu

device=${1:-/dev/video0}
port=8080

# Without a terminal nothing stops ffmpeg when the SSH connection drops, and
# it keeps the camera.  `ssh -t' gives one, which sends SIGHUP on a drop.
if [ ! -t 0 ]; then
    echo "No terminal: run it with ssh -t." >&2
    exit 1
fi

# Without MJPEG, V4L2 gives raw video, at most 640x480 on most webcams.
input_opts=
if v4l2-ctl -d "$device" --list-formats 2>/dev/null | grep -q "'MJPG'"; then
    input_opts="-input_format mjpeg -video_size 1280x720"
fi

log=$(mktemp)
trap 'rm -f "$log"' EXIT
# ffmpeg serves one viewer and exits when it leaves, so it is started again
# for the next one, e.g. after a reload.  ffmpeg exits normally on Ctrl-C or
# a hang-up, which alone wouldn't end the loop.
trap 'exit 1' INT HUP TERM

echo "Open http://localhost:$port/cam.mjpg (Ctrl-C to stop)" >&2
while :; do
    start=$(date +%s)
    # 10 fps at 960 px wide is about 0.5 Mbit/s; the camera's own 720p MJPEG
    # is over 100.  $input_opts is unquoted: two options, or none.
    ffmpeg -hide_banner -loglevel error -nostdin \
           -f v4l2 $input_opts -i "$device" \
           -vf "fps=10,scale='min(960,iw)':-2" -c:v mjpeg -q:v 7 \
           -f mpjpeg -content_type "multipart/x-mixed-replace;boundary=ffmpeg" \
           -listen 1 "http://127.0.0.1:$port/cam.mjpg" 2>"$log" || true
    # Failing within seconds means it never started (camera busy, port
    # taken): show why and stop, rather than retry forever.  Otherwise the
    # viewer left, and ffmpeg's errors about the closed connection are noise.
    if [ $(($(date +%s) - start)) -lt 3 ]; then
        cat "$log" >&2
        exit 1
    fi
    echo "Viewer left; waiting for the next one." >&2
done
