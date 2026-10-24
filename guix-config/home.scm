;; Guix Home for both hosts: every user package, config file and user
;; service.  `(gethostname)' picks the host-only packages and services.
;;
;;   pc        Guix System.  Also runs PipeWire as user services.  Its
;;             system packages stay in config-pc.scm.
;;   thinkpad  Debian, whose systemd user units already run PipeWire, so it
;;             must not get Guix's: a second PipeWire/WirePlumber would
;;             fight Debian's for the sound card.
;;
;; ~/.guix-profile stays empty, for trying packages out; `make sync-guix'
;; lists anything left in it.  Apply with `make apply-guix-home`.

(use-modules (gnu home)
             (gnu home services)        ; home-xdg-configuration-files-service-type
             (gnu home services desktop)
             (gnu home services sound)
             (gnu packages)             ; specifications->packages
             (gnu packages linux)       ; pipewire, wireplumber
             (gnu services)
             (guix gexp)
             (ice-9 match))

;; Both hosts.  Specifications, as for `guix install'; "nbl-emacs" comes
;; from modules/nbl, hence `-L modules'.
(define common-packages
  (list "acpi"
        "age"
        "anki"
        "arandr"
        "ardour"
        "atool"
        "atuin"
        "autoconf"
        "awscli"
        "bat"
        "beancount"
        "beep"
        "bind"
        "blesh"
        "blueman"
        "book-sicp"
        "brightnessctl"
        "btop"
        "bubblewrap"
        "calibre"
        "ccls"
        "cloc"
        "cmake"
        "cmatrix"
        "curlie"
        "ddcui"
        "ddcutil"
        "desktop-file-utils"
        "diffpdf"
        "direnv"
        "distrobox"
        "dmidecode"
        "du-dust"
        "duckdb"
        "dunst"
        "editline"
        "emacs-beancount"
        "emacs-eat"
        "emacs-emms"
        "emacs-exiftool"
        "emacs-guix"
        "emacs-magit"
        "emacs-magit-todos"
        "emacs-pdf-tools"
        "emacs-telega"
        "emacs-vterm"
        "evince"
        "eza"
        "fd"
        "feh"
        "figlet"
        "file"
        "flameshot"
        "font-adobe-source-sans"
        "font-awesome-nonfree"
        "font-gnu-freefont"
        "font-gnu-unifont"
        "font-google-roboto"
        "font-nerd-fira-code"
        "font-sil-gentium"
        "fzf"
        "gcc-toolchain"
        "git-lfs"
        "glances"
        "glibc-locales"
        "gnome-themes-extra"
        "gnucobol"
        "gnupg"
        "go"
        "google-chrome-stable"
        "guile"
        "guile-colorized"
        "guile-hall"
        "guile-readline"
        "htop"
        "jq"
        "kitty"
        "kmonad"
        "ktouch"
        "libedit"
        "libreoffice"
        "librewolf"
        "libtool"
        "lsof"
        "magic-wormhole"
        "make"
        "moreutils"
        "mpv"
        "mullvadbrowser"
        "nautilus"
        "nbl-emacs"
        "ncdu"
        "neofetch"
        "netcat"
        "nmap"
        "node"
        "nss-certs"
        "nyancat"
        "okular"
        "pamixer"
        "pandoc"
        "pavucontrol"
        "perl-image-exiftool"
        "picom"
        "pinentry"
        "playerctl"                     ; StumpWM's media keys
        "pre-commit"
        "python"
        "python-flake8"
        "python-icecream"
        "python-ipython"
        "python-jedi"
        "python-openpyxl"
        "python-sortedcontainers"
        "python-yapf"
        "qpdf"
        "racket"
        "readline"
        "remmina"
        "ripgrep"
        "rofi"
        "roswell"
        "setxkbmap"
        "simplescreenrecorder"
        "sox"
        "sqlite"
        "starship"
        "strace"
        "supercollider"
        "supercollider:ide"
        "tealdeer"
        "telegram-desktop"
        "tmux"
        "trash-cli"
        "typst"
        "udiskie"
        "units"
        "unzip"
        "vim"
        "whois"
        "wireshark"
        "wmctrl"
        "xclip"
        "xdg-utils"
        "xdpyinfo"
        "xfontsel"
        "xrandr"
        "xremap-x11"
        "xset"
        "xsettingsd"
        "yt-dlp"
        "z3"
        "zoxide"))

;; Guix System puts the pc's other packages in its system profile.
(define pc-packages '())

;; On Guix System these were system packages in config-thinkpad.scm; on
;; Debian they must come from here.  The rest of config-thinkpad.scm's
;; system packages come from apt instead: git, curl, i3lock (needs
;; Debian's PAM), tailscale, docker/podman and nix.
(define thinkpad-packages
  (list "font-dejavu"
        "font-fira-code"
        "fontconfig"
        "sbcl"
        "stumpwm-with-slynk"))

;; Both hosts.
(define common-services
  (list
   ;; Atuin's config: local history only, no sync, no update check.
   (service home-xdg-configuration-files-service-type
            `(("atuin/config.toml"
               ,(local-file ".config/atuin/config.toml"))))))

(define pc-services
  (list
   ;; The home `pipewire' Shepherd service declares (requirement '(dbus)),
   ;; and home-pipewire-service-type does not pull this in by itself.
   (service home-dbus-service-type)
   ;; Starts pipewire, wireplumber and pipewire-pulse at login, points
   ;; ALSA at PipeWire, and stops PulseAudio from autospawning.  JACK
   ;; apps (Ardour, scsynth) run through it with `pw-jack'.
   ;;
   ;; Every field is spelled out at its default value, see
   ;; https://guix.gnu.org/manual/devel/en/html_node/Sound-Home-Services.html
   (service home-pipewire-service-type
            (home-pipewire-configuration
             (pipewire pipewire)
             ;; The session manager that connects devices and streams.
             (wireplumber wireplumber)
             ;; Run pipewire-pulse, so PulseAudio clients (browsers,
             ;; pavucontrol) use PipeWire.
             (enable-pulseaudio? #t)
             ;; Appended to ~/.config/alsa/asoundrc.
             (extra-content "")))))

(define thinkpad-services '())

(define-values (host-packages host-services)
  (match (gethostname)
    ("pc" (values pc-packages pc-services))
    ("thinkpad" (values thinkpad-packages thinkpad-services))
    (host (error "home.scm: no Guix Home for this host:" host))))

(home-environment
 ;; atuin: shell history in SQLite; .bashrc runs `atuin init bash'.
 (packages (specifications->packages
            (append common-packages host-packages)))
 (services (append common-services host-services)))
