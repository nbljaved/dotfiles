# Set up Guix Home profile
if [ -f ~/.profile ]; then . ~/.profile; fi

# Merge search-paths from multiple profiles, the order matters.
if [ ! -e /run/.containerenv ] && [ ! -e /.dockerenv ]; then
    eval "$(guix package --search-paths \
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
if command -v "distrobox-host-exec" >/dev/null 2>&1; then
    command_not_found_handle() {
        # don't run if not in a container
        if [ ! -e /run/.containerenv ] && [ ! -e /.dockerenv ]; then
            exit 127
        fi

        distrobox-host-exec "${@}"
    }
    if [ -n "${BASH_VERSION-}" ]; then
        command_not_found_handler() {
            command_not_found_handle "$@"
        }
    fi
fi

