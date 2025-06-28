# Set up Guix Home profile
if [ -f ~/.profile ]; then . ~/.profile; fi

# Merge search-paths from multiple profiles, the order matters.
eval "$(guix package --search-paths \
-p $HOME/.config/guix/current \
-p $HOME/.guix-home/profile \
-p $HOME/.guix-profile \
-p /run/current-system/profile)"

# Honor per-interactive-shell startup file
if [ -f ~/.bashrc ]; then . ~/.bashrc; fi

# Prepend setuid programs.
export PATH=/run/setuid-programs:$PATH
