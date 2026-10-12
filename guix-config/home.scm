;; Guix Home for both hosts; `(gethostname)' picks the host-only services.
;;
;;   pc        Guix System.  Also runs PipeWire as user services.
;;   thinkpad  Debian, whose systemd user units already run PipeWire, so it
;;             must not get Guix's: a second PipeWire/WirePlumber would
;;             fight Debian's for the sound card.
;;
;; Packages stay in current-profile-manifest, except those whose config
;; file is written here.  Apply with `make apply-guix-home`.

(use-modules (gnu home)
             (gnu home services)        ; home-xdg-configuration-files-service-type
             (gnu home services desktop)
             (gnu home services sound)
             (gnu packages linux)       ; pipewire, wireplumber
             (gnu packages rust-apps)   ; atuin
             (gnu services)
             (guix gexp)
             (ice-9 match))

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

(home-environment
 ;; Shell history in SQLite; .bashrc runs `atuin init bash'.
 (packages (list atuin))
 (services
  (append common-services
          (match (gethostname)
            ("pc" pc-services)
            ("thinkpad" thinkpad-services)
            (host (error "home.scm: no Guix Home for this host:" host))))))
