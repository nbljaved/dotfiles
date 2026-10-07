# /etc/profile resets PATH, but nix-daemon.sh skips re-adding Nix when
# __ETC_PROFILE_NIX_SOURCED is inherited from the parent session
# (e.g. Emacs' exec-path-from-shell started from StumpWM).
if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    unset __ETC_PROFILE_NIX_SOURCED
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# Set up Guix Home profile
if [ -f ~/.profile ]; then . ~/.profile; fi

# Merge search-paths from multiple profiles, the order matters.
if [ ! -e /run/.containerenv ] && [ ! -e /.dockerenv ]; then
    eval "$(guix package --search-paths=prefix \
                         -p $HOME/.config/guix/current \
                         -p $HOME/.guix-home/profile \
                         -p $HOME/.guix-profile \
                         -p /run/current-system/profile)"
fi

# Honor per-interactive-shell startup file
if [ -f ~/.bashrc ]; then . ~/.bashrc; fi

# Prepend setuid programs.
export PATH=/run/setuid-programs:$PATH

# Distrobox container tries to run commands on host
# if those commands are missing in the container
# if command -v "distrobox-host-exec" >/dev/null 2>&1; then
#     command_not_found_handle() {
#         # don't run if not in a container
#         if [ ! -e /run/.containerenv ] && [ ! -e /.dockerenv ]; then
#             exit 127
#         fi

#         distrobox-host-exec "${@}"
#     }
#     if [ -n "${BASH_VERSION-}" ]; then
#         command_not_found_handler() {
#             command_not_found_handle "$@"
#         }
#     fi
# fi


# thinkpad (Debian): start X after logging in on tty1.  `exec` means
# leaving X also ends the login session, so no shell is left behind.
if [ -z "$DISPLAY" ] && [ "$(tty)" = /dev/tty1 ] && [ "$(hostname)" = thinkpad ]; then
    exec startx
fi
