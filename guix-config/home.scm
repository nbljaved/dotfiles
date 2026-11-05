;; Guix Home for both hosts: every user package, config file and user
;; service.  `(gethostname)' picks the host-only packages and services.
;;
;;   pc        Guix System.  Also runs PipeWire as user services.  Its
;;             system packages stay in config-pc.scm.
;;   thinkpad  Debian, whose systemd user units already run PipeWire, so it
;;             must not get Guix's: a second PipeWire/WirePlumber would
;;             fight Debian's for the sound card.
;;
;; It also makes every link from $HOME into ~/dotfiles (see `dotfile').
;; ~/.guix-profile stays empty, for trying packages out; `make sync-guix'
;; lists anything left in it.  Apply with `make apply-guix-home`.

(use-modules (gnu home)
             (gnu home services)        ; home-files-service-type, home-xdg-…
             (gnu home services desktop)
             (gnu home services sound)
             (gnu packages)             ; specifications->packages
             (gnu packages linux)       ; pipewire, wireplumber
             (gnu services)
             (guix gexp)
             (ice-9 match))

;; Both hosts.  Specifications, as for `guix install'; "nbl-emacs",
;; "lilypractice" and "pianoteq-trial" come from modules/nbl, hence
;; `-L modules'.
(define common-packages
  (list "acpi"
        "age"
        "arandr"
        "ardour"
        "atool"
        "atuin"
        "autoconf"
        "bat"
        "beancount"
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
        "ddcui"
        "ddcutil"
        "desktop-file-utils"
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
        "emacs-lilypond-mode"
        "emacs-magit"
        "emacs-magit-annex"
        "emacs-magit-todos"
        "emacs-pdf-tools"
        "emacs-popper"
        "emacs-telega"
        "emacs-vterm"
        "evince"
        "eza"
        "fd"
        "feh"
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
        "git-annex"
        "glances"
        "glibc-locales"
        "gnome-themes-extra"
        "gnupg"
        "go"
        ;; Sets GI_TYPELIB_PATH so solfege finds xlib-2.0.typelib, which
        ;; its wrapper lacks (gobject-introspection is missing from Guix's
        ;; solfege inputs).  Drop this once Guix fixes the recipe.
        "gobject-introspection"
        "google-chrome-stable"
        "guile"
        "guile-colorized"
        "guile-hall"
        "guile-readline"
        "htop"
        "jq"
        "kitty"
        "libedit"
        "libreoffice"
        "librewolf"
        "libtool"
        "lilypond"
        "lilypractice"
        "lsof"
        "magic-wormhole"
        "make"
        "moreutils"
        "mpv"
        "nautilus"
        "nbl-emacs"
        "ncdu"
        "neofetch"
        "netcat"
        "nmap"
        "node"
        "nss-certs"
        "obs"
        "okular"
        "pamixer"
        "pandoc"
        "pavucontrol"
        "perl-image-exiftool"
        "pianobooster"
        "pianoteq-trial"
        "picom"
        "pinentry"
        "playerctl"                     ; StumpWM's media keys
        "python"
        "python-ipython"
        "python-sortedcontainers"
        "qpwgraph"
        "readline"
        "ripgrep"
        "rofi"
        "roswell"
        "setxkbmap"
        "simplescreenrecorder"
        "sox"
        "solfege"
        "sqlite"
        "starship"
        "strace"
        "supercollider"
        "supercollider:ide"
        "telegram-desktop"
        "tmux"
        "trash-cli"
        "typst"
        "udiskie"
        "units"
        "unzip"
        "v4l-utils"                     ; v4l2-ctl --list-devices
        "vim"
        "whois"
        "wmctrl"
        "xclip"
        "xdg-utils"
        "xdpyinfo"
        "xfontsel"
        "xrandr"
        "xremap-x11"
        "xset"
        "xsettingsd"
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

(define dotfiles
  (string-append (getenv "HOME") "/dotfiles"))

;; A link to FILE in ~/dotfiles itself, not a copy of it in the store: the
;; store item is only a symlink to that path.  So an edit takes effect at
;; once, without `make apply-guix-home', and programs that write their own
;; config (git, Emacs, scide) still can.  Only adding or removing a link
;; needs the command.  A FILE that doesn't exist is an error here, rather
;; than a dangling link later.
(define (dotfile file)
  (let ((target (string-append dotfiles "/" file)))
    (unless (file-exists? target)
      (error "home.scm: not in ~/dotfiles:" file))
    ;; Store names can't start with a dot.
    (computed-file (string-append "dotfile-"
                                  (string-trim (basename file) #\.))
                   #~(symlink #$target #$output))))

;; Both hosts.
(define common-services
  (list
   ;; Relative to $HOME.
   (simple-service 'dotfiles home-files-service-type
                   `((".bashrc"       ,(dotfile "shell-config/.bashrc"))
                     (".bash_profile" ,(dotfile "shell-config/.bash_profile"))
                     (".blerc"        ,(dotfile "shell-config/.blerc"))
                     (".sbclrc"       ,(dotfile "shell-config/.sbclrc"))
                     (".gitconfig"    ,(dotfile "shell-config/.gitconfig"))
                     (".emacs.d"      ,(dotfile "emacs.d"))
                     (".nix-channels" ,(dotfile "guix-config/nix-config/nix-channels"))
                     (".claude/skills/screenshot/SKILL.md"
                      ,(dotfile "guix-config/.config/useful-docker-images/shot-scraper/claude-skills/shot-scraper.md"))))
   ;; Relative to ~/.config.  Atuin's config keeps history local: no sync,
   ;; no update check.
   (simple-service 'dotfiles-xdg home-xdg-configuration-files-service-type
                   `(("atuin/config.toml" ,(dotfile "guix-config/.config/atuin/config.toml"))
                     ("git/ignore"        ,(dotfile "shell-config/git/ignore"))
                     ("guix/channels.scm" ,(dotfile "guix-config/channels.scm"))
                     ("kitty"             ,(dotfile "shell-config/kitty"))
                     ("starship.toml"     ,(dotfile "shell-config/starship/starship.toml"))
                     ("stumpwm/config"    ,(dotfile "stumpwm.d/init.lisp"))
                     ;; Only these two: the rest of that directory is cache.
                     ("SuperCollider/sc_ide_conf.yaml"
                      ,(dotfile "guix-config/.config/SuperCollider/sc_ide_conf.yaml"))
                     ("SuperCollider/sclang_conf.yaml"
                      ,(dotfile "guix-config/.config/SuperCollider/sclang_conf.yaml"))))))

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

(define thinkpad-services
  (list
   ;; `startx' reads it.  The pc logs in through GDM, which never does.
   (simple-service 'dotfiles-thinkpad home-files-service-type
                   `((".xinitrc" ,(dotfile "stumpwm.d/xinitrc"))))))

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
