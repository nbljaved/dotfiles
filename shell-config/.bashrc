#!/bin/bash

##############################################################################
## ble.sh
BLESH=$( guix package -I blesh | awk '{print $4}')
BLESH="$BLESH/share/blesh/ble.sh"
# Add this lines at the top of .bashrc:
[[ $- == *i* ]] && source "$BLESH" --noattach

# If not running interactively, don't do anything
[[ $- != *i* ]] && return
##########

if [[ $- != *i* ]]
then
    # We are being invoked from a non-interactive shell.  If this
    # is an SSH session (as in "ssh host command"), source
    # /etc/profile so we get PATH and other essential variables.
    [[ -n "$SSH_CLIENT" ]] && source /etc/profile

    # Don't do anything else.
    return
fi

# Bash initialization for interactive non-login shells and
# for remote shells (info "(bash) Bash Startup Files").

# Export 'SHELL' to child processes.  Programs such as 'screen'
# honor it and otherwise use /bin/sh.
export SHELL

# history
export HISTSIZE=10000
export HISTFILESIZE=10000
 
## Racket
export PATH="$HOME/racket/bin:$PATH"

## Kitty
source <(kitty + complete setup bash)

export TERM=xterm-256color # otherwise ssh has keyboard problems

## Common Lisp
# SBCL
# export SBCL_HOME="/home/nabeel/.guix-profile/lib/sbcl/"
# Roswell
#export PATH="$PATH:/home/nabeel/.roswell/bin"

alias python='python3'
alias em='emacsclient --alternate-editor="" --create-frame --no-wait'


# lazy
alias ld='lazydocker'
alias lg='lazygit'
alias ls='ls -alh'
alias cat='bat'
alias l='eza --color=auto --icons -l'
alias rgi='rg --no-ignore --hidden -i'

# Set up fzf key bindings and fuzzy completion
# fuzzy completion using **<TAB>
# CTRL-T - Paste the selected files and directories onto the command-line
# CTRL-R - Paste the selected command from history onto the command-line
if command -v "fzf" >/dev/null 2>&1 ; then
    eval "$(fzf --bash)"
    # Print tree structure in the preview window
    export FZF_ALT_C_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'tree -C {}'"
    # Preview file content using bat (https://github.com/sharkdp/bat)
    export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"
    # Options to fzf command
    export FZF_COMPLETION_OPTS='--border --info=inline'
    # Options for path completion (e.g. vim **<TAB>)
    export FZF_COMPLETION_PATH_OPTS='--walker file,dir,follow,hidden'
    # Options for directory completion (e.g. cd **<TAB>)
    export FZF_COMPLETION_DIR_OPTS='--walker dir,follow'    
fi

#safety
alias rm='echo "Use trash-cli instead of: rm"'

# Golang
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:"$HOME/go/bin"


# Adjust the prompt depending on whether we're in 'guix environment'.
if [ -n "$GUIX_ENVIRONMENT" ]
then
    PS1='\u@\h \w [guix-env]\$ '
else
    PS1='\u@\h \w\$ '
fi

## Guix
GUIX=$(command -v "guix")
GUIX_SYSTEM=$(grep '^ID=guix' /etc/os-release)
if [ -z "$GUIX_SYSTEM" ] && [ -n "$GUIX" ]; then
    export GUIX_LOCPATH="$HOME/.guix-profile/lib/locale"
    export GUIX_PROFILE="$HOME/.guix-profile"
    source "$GUIX_PROFILE/etc/profile"
    export GUIX_CHECKOUT="$HOME/src/guix"
    #
    export PKG_CONFIG_PATH=$GUIX_PROFILE/lib/pkgconfig
    # SSL certificate
    export SSL_CERT_DIR="$HOME/.guix-profile/etc/ssl/certs"
    export SSL_CERT_FILE="$HOME/.guix-profile/etc/ssl/certs/ca-certificates.crt"
    export GIT_SSL_CAINFO="$SSL_CERT_FILE"
fi

##########
## Emacs-start

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='emacs'
else
  export EDITOR='emacs'
fi

## Vterm - https://github.com/akermu/emacs-libvterm
# vterm shell-side configuration
vterm_printf() {
    if [ -n "$TMUX" ] \
        && { [ "${TERM%%-*}" = "tmux" ] \
            || [ "${TERM%%-*}" = "screen" ]; }; then
        # Tell tmux to pass the escape sequences through
        printf "\ePtmux;\e\e]%s\007\e\\" "$1"
    elif [ "${TERM%%-*}" = "screen" ]; then
        # GNU screen (screen, screen-256color, screen-256color-bce)
        printf "\eP\e]%s\007\e\\" "$1"
    else
        printf "\e]%s\e\\" "$1"
    fi
}
# vterm-clear-scrollback (C-c C-l)
if [ "$INSIDE_EMACS" = 'vterm' ]; then
    clear() {
        vterm_printf "51;Evterm-clear-scrollback";
        tput clear;
    }
fi
# https://github.com/akermu/emacs-libvterm?tab=readme-ov-file#vterm-buffer-name-string
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }"'echo -ne "\033]0;${HOSTNAME}:${PWD}\007"'
# https://github.com/akermu/emacs-libvterm#message-passing
vterm_cmd() {
    local vterm_elisp
    vterm_elisp=""
    while [ $# -gt 0 ]; do
        vterm_elisp="$vterm_elisp""$(printf '"%s" ' "$(printf "%s" "$1" | sed -e 's|\\|\\\\|g' -e 's|"|\\"|g')")"
        shift
    done
    vterm_printf "51;E$vterm_elisp"
}
# https://github.com/akermu/emacs-libvterm#how-can-i-get-the-directory-tracking-in-a-more-understandable-way
vterm_set_directory() {
    vterm_cmd update-pwd "$PWD/"
}
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }vterm_set_directory"

## Emacs-end
######

# zoxide
eval "$(zoxide init --cmd cd bash)"
# Direnv
eval "$(direnv hook bash)"
# starship
export PATH="$PATH":/usr/local/bin
eval "$(starship init bash)"

# nvm
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# uv
export PATH="$HOME/.local/bin:$PATH"
export UV_PYTHON_DOWNLOADS="manual"
export UV_PYTHON_PREFERENCE="system"

if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
fi

# when facing gdk_pixbuf_errors
# unset GDK_PIXBUF_MODULE_FILE
#
# when facing errors relating to 'gio'
# unset GIO_EXTRA_MODULES

# vscode
# code --verbose  --vmodule="*/components/os_crypt/*=1" --password-store="gnome-libsecret"

# Nix
if command -v "nix" >/dev/null 2>&1; then
    source /run/current-system/profile/etc/profile.d/nix.sh
fi

##############################################################################
## ble.sh
# Add this line at the end of .bashrc:
[[ ${BLE_VERSION-} ]] && ble-attach

