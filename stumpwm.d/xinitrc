#!/bin/sh
# Symlink this to ~/.xinitrc:  ln -sf ~/.stumpwm.d/xinitrc ~/.xinitrc
#
# `startx` reads it.  Only the thinkpad needs it: that machine runs Debian,
# where Xorg comes from apt and StumpWM comes from a Guix profile, started by
# hand after a tty1 login (see Readme.org, "Starting the session").  The pc
# runs Guix System and logs in through GDM, which builds the session itself
# and never reads this file -- so everything below is written to be harmless
# anywhere, and the Debian-only parts are guarded by the hostname.
host=$(hostname 2>/dev/null || cat /etc/hostname 2>/dev/null)

# Let systemd user services (PipeWire, xdg portals) see this display.
if command -v dbus-update-activation-environment > /dev/null 2>&1; then
    dbus-update-activation-environment --systemd DISPLAY XAUTHORITY
fi

# X resources: the shared file, then this host's, if xrdb is installed.
if command -v xrdb > /dev/null 2>&1; then
    [ -f "$HOME/.stumpwm.d/Xresources" ] && xrdb -merge "$HOME/.stumpwm.d/Xresources"
    [ -f "$HOME/.stumpwm.d/Xresources.$host" ] &&
        xrdb -merge "$HOME/.stumpwm.d/Xresources.$host"
fi

setxkbmap us -variant altgr-intl

# Lock on suspend/hibernate only.
#
# xss-lock also runs the locker when the X screen saver kicks in (after
# `xset s TIMEOUT CYCLE`, see `screen-blank-time'), but blanking is all we
# want there.  xss-lock sets $XSS_SLEEP_LOCK_FD only when the system is
# going to sleep, so the wrapper locks then and does nothing otherwise.
#
# On Debian the locker must be Debian's own: it authenticates through
# Debian's PAM, which a copy out of a Guix profile cannot do.  Our Guix
# profile comes first in PATH, so name the path instead of trusting PATH.
if [ -x /usr/bin/i3lock ]; then i3lock=/usr/bin/i3lock; else i3lock=i3lock; fi
if command -v "$i3lock" > /dev/null 2>&1 && command -v xss-lock > /dev/null 2>&1; then
    xss-lock --transfer-sleep-lock -- \
        sh -c '[ -n "$XSS_SLEEP_LOCK_FD" ] && exec "$0" --nofork -c 2e2e2e' "$i3lock" &
fi

exec stumpwm
