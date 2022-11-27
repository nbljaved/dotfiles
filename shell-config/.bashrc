#
# ~/.bashrc
#
# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# alias ls='ls --color=auto'
# PS1='[\u@\h \W]\$ '

 
## Racket
#export PATH="$HOME/racket/bin:$PATH"

## Haskell
# stack
export PATH="$HOME/.local/bin:$PATH"

## Kitty
source <(kitty + complete setup bash)

## Common Lisp
# SBCL
# export SBCL_HOME="/home/nabeel/.guix-profile/lib/sbcl/"
# Roswell
#export PATH="$PATH:/home/nabeel/.roswell/bin"

# ### GUIX
# export GUIX_LOCPATH=$HOME/.guix-profile/lib/locale
# GUIX_PROFILE="/home/nabeel/.guix-profile"
# [[ -L "${GUIX_PROFILE}" ]] && . "${GUIX_PROFILE}/etc/profile"
# source "/home/nabeel/.config/guix/current/etc/profile"
#source "$GUIX_PROFILE/etc/profile"

# # hint: After setting `PATH', run `hash guix' to make sure your shell refers to `/home/nabeel/.config/guix/current/bin/guix'.
#export PATH="/home/nabeel/.config/guix/current/bin:$PATH" 


# #X.509 Certificates
# # guix install nss-certs
# export SSL_CERT_DIR="$HOME/.guix-profile/etc/ssl/certs"
# export SSL_CERT_FILE="$HOME/.guix-profile/etc/ssl/certs/ca-certificates.crt"
# export GIT_SSL_CAINFO="$SSL_CERT_FILE"

# # export XDG_DATA_DIRS="/usr/local/share:/usr/share:$XDG_DATA_DIRS"
# # export XDG_CONFIG_DRIS="/etc/xdg:$XDG_CONFIG_DIRS"

### FISH
# run fish as interactive shell (rather set it in 'kitty' settings)
#exec fish 

# [ -f /opt/miniconda3/etc/profile.d/conda.sh ] && source /opt/miniconda3/etc/profile.d/conda.sh

## vterm
vterm_printf(){
    if [ -n "$TMUX" ] && ([ "${TERM%%-*}" = "tmux" ] || [ "${TERM%%-*}" = "screen" ] ); then
        # Tell tmux to pass the escape sequences through
        printf "\ePtmux;\e\e]%s\007\e\\" "$1"
    elif [ "${TERM%%-*}" = "screen" ]; then
        # GNU screen (screen, screen-256color, screen-256color-bce)
        printf "\eP\e]%s\007\e\\" "$1"
    else
        printf "\e]%s\e\\" "$1"
    fi
}
if [[ "$INSIDE_EMACS" = 'vterm' ]]; then
    function clear(){
        vterm_printf "51;Evterm-clear-scrollback";
        tput clear;
    }
fi
vterm_prompt_end(){
    vterm_printf "51;A$(whoami)@$(hostname):$(pwd)"
}
PS1=$PS1'\[$(vterm_prompt_end)\]'
[ -f "/home/nabeel/.ghcup/env" ] && source "/home/nabeel/.ghcup/env" # ghcup-env

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/nabeel/mambaforge/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/nabeel/mambaforge/etc/profile.d/conda.sh" ]; then
        . "/home/nabeel/mambaforge/etc/profile.d/conda.sh"
    else
        export PATH="/home/nabeel/mambaforge/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

. "$HOME/.cargo/env"
