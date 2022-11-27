# https://www.emacswiki.org/emacs/TrampMode#h5o-1
# Additionally, with the default settings, using sshx rather than ssh will likely work because it will tell the remote host to run /bin/sh instead of zsh.
# However, telling Tramp in advance like that might not be your preference; as an alternative, try placing this in your .zshrc:
# [[ $TERM == "dumb" ]] && unsetopt zle && PS1='$ ' && return

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/home/nabeel/.oh-my-zsh"
export TERM=xterm-256color # otherwise ssh has keyboard problems
# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
#ZSH_THEME="robbyrussell"
ZSH_THEME="powerlevel10k/powerlevel10k"
# set emacs mode
bindkey -e
export EDITOR=emacs
bindkey -M emacs '\M-Y' yank-pop
bindkey -M emacs '\M-W' copy-region-as-kill
bindkey -M emacs '\C-W' kill-region
bindkey -M emacs '\C-P' up-line-or-search
bindkey -M emacs '\C-N' down-line-or-history


# bindkey -M emacs

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# Caution: this setting can cause issues with multiline prompts (zsh 5.7.1 and newer seem to work)
# See https://github.com/ohmyzsh/ohmyzsh/issues/5765
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git
	 # fish like history search after entering some text
	 # history-substring-search
	 zsh-syntax-highlighting
	 zsh-autocomplete
	 colored-man-pages
	)

source $ZSH/oh-my-zsh.sh

#######  Plugin settins

## zsh-syntax-highlighting
source /home/nabeel/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

## history-substring-search
# source /home/nabeel/.oh-my-zsh/custom/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh 
# bindkey -M emacs '^P' history-substring-search-up
# bindkey -M emacs '^N' history-substring-search-down

## zsh-autocomplete
zstyle ':autocomplete:*' min-delay 0.3  # number of seconds (float)
# 0.0: Start autocompletion immediately when you stop typing.
# 0.4: Wait 0.4 seconds for more keyboard input before showing completions.
zstyle ':autocomplete:*' insert-unambiguous yes
# no:  Tab inserts the top completion.
# yes: Tab first inserts substring common to all listed completions, if any.
zstyle ':autocomplete:*' widget-style menu-select
# complete-word: (Shift-)Tab inserts the top (bottom) completion.
# menu-complete: Press again to cycle to next (previous) completion.
# menu-select:   Same as `menu-complete`, but updates selection in menu.
# ⚠️ NOTE: This can NOT be changed at runtime.
zstyle ':autocomplete:*' fzf-completion no
# no:  Tab uses Zsh's completion system only.
# yes: Tab first tries Fzf's completion, then falls back to Zsh's.
# ⚠️ NOTE: This can NOT be changed at runtime and requires that you have
# installed Fzf's shell extensions.
source /home/nabeel/.oh-my-zsh/custom/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh
#
# NOTE: All settings below should come AFTER sourcing zsh-autocomplete!
#
bindkey -M emacs '^P' up-line-or-search
# up-line-or-search:  Open history menu.
# up-line-or-history: Cycle to previous history line.
bindkey -M emacs '^N' down-line-or-search
# down-line-or-select:  Open completion menu.
# down-line-or-history: Cycle to next history line.
bindkey -M emacs $key[Control-Space] set-mark-command
# list-expand:      Reveal hidden completions.
# set-mark-command: Activate text selection.
bindkey -M menuselect $key[Return] accept-line
# .accept-line: Accept command line.
# accept-line:  Accept selection and exit menu.
################




## User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='emacs'
else
  export EDITOR='emacs'
fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


########################################
## MY SETTINGS
######################################
## Racket
#export PATH="$HOME/racket/bin:$PATH"

## Doom emacs
export PATH="$HOME/.emacs.d/bin:$PATH"

## Haskell
# stack
export PATH="$HOME/.local/bin:$PATH"

## Kitty
source <(kitty + complete setup zsh)

## Go
export PATH="$HOME/go/bin/:$PATH"

## Common Lisp
# SBCL
# export SBCL_HOME="/home/nabeel/.guix-profile/lib/sbcl/"
# Roswell
export PATH="$PATH:/home/nabeel/.roswell/bin"

#### GUIX
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

####
###Archlinux
###
#export PATH="/usr/bin:/usr/local/bin:$PATH"

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
#[ -f "/home/nabeel/.ghcup/env" ] && source "/home/nabeel/.ghcup/env" # ghcup-env


################################################################

alias sbcl="ros run --"
#lispworks
alias lispworks="/home/nabeel/.roswell/impls/x86-64/linux/LispWorks/lispworks-8-0-0-amd64-linux"
alias lw-console="/home/nabeel/.roswell/impls/x86-64/linux/LispWorks/lw-console" 

# [ -f "/home/nabeel/.ghcup/env" ] && source "/home/nabeel/.ghcup/env" # ghcup-env

source /usr/share/nvm/init-nvm.sh
