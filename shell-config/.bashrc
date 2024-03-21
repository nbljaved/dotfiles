#
# ~/.bashrc
#


##############################################################################
## ble.sh
BLESH=$( guix package -I blesh | awk '{print $4}')
BLESH="$BLESH/share/blesh/ble.sh"
# Add this lines at the top of .bashrc:
[[ $- == *i* ]] && source $BLESH --noattach

# If not running interactively, don't do anything
[[ $- != *i* ]] && return
##########

# history
export HISTSIZE=2000
export HISTFILESIZE=2000
 
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
alias em='emacs -q -nw'


# lazy
alias ld='lazydocker'
alias lg='lazygit'
alias ls='ls -alh'
alias cat='bat'
alias l='exa --color automatic --icons -l'
alias rgi='rg --no-ignore --hidden -i'


# Golang
export PATH=$PATH:/usr/local/go/bin


# Automatically added by the Guix install script.
if [ -n "$GUIX_ENVIRONMENT" ]; then
    if [[ $PS1 =~ (.*)"\\$" ]]; then
        PS1="${BASH_REMATCH[1]} [env]\\\$ "
    fi
fi

## Guix
#export GUIX_LOCPATH=$HOME/.guix-profile/lib/locale
export GUIX_PROFILE="$HOME/.guix-profile"
source "$GUIX_PROFILE/etc/profile"
export GUIX_CHECKOUT="$HOME/src/guix"
#
export PKG_CONFIG_PATH=$GUIX_PROFILE/lib/pkgconfig
# SSL certificate
export SSL_CERT_DIR="$HOME/.guix-profile/etc/ssl/certs"
export SSL_CERT_FILE="$HOME/.guix-profile/etc/ssl/certs/ca-certificates.crt"
export GIT_SSL_CAINFO="$SSL_CERT_FILE"

# zoxide
eval "$(zoxide init --cmd cd bash)"
# Direnv
eval "$(direnv hook bash)"
# starship
eval "$(starship init bash)"

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='emacs'
else
  export EDITOR='emacs'
fi

# nvm
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

##############################################################################
## ble.sh
# Add this line at the end of .bashrc:
[[ ${BLE_VERSION-} ]] && ble-attach
