;; Guix Home for the pc (Guix System).  The thinkpad runs Debian, whose
;; systemd user units already run PipeWire, so it must not use this file:
;; a second PipeWire/WirePlumber would fight Debian's for the sound card.
;;
;; Packages stay in current-profile-manifest; this only adds services.
;; Apply with `make apply-guix-home`.

(use-modules (gnu home)
             (gnu home services desktop)
             (gnu home services sound)
             (gnu packages linux)       ; pipewire, wireplumber
             (gnu services))

(home-environment
 (services
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
             (extra-content ""))))))
