(define-module (nbl packages lilypractice)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix build-system go)
  #:use-module (gnu packages audio)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages golang)
  #:use-module (gnu packages golang-graphics)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages music)
  #:use-module (gnu packages pkg-config))

;; To update: push lilypractice, then put its commit here, and the hash
;; that `guix hash -x --serializer=nar' gives for a clean checkout of it.
(define-public lilypractice
  (let ((commit "9c4107ad2537dc92794e63dd7bf9f1ab87b1a834")
        (revision "1"))
    (package
      (name "lilypractice")
      (version (git-version "0.1" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/nbljaved/lilypractice")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "1r337n2v3gvarcs318mqc6qf1asl0mlrn3b5z6jsq0fzcnm00jld"))))
      (build-system go-build-system)
      (arguments
       (list
        #:go go-1.27
        #:install-source? #f
        #:unpack-path "lilypractice"
        #:import-path "lilypractice/cmd/lilypractice"
        #:phases
        #~(modify-phases %standard-phases
            (replace 'check
              (lambda* (#:key tests? #:allow-other-keys)
                (when tests?
                  (invoke "go" "test" "lilypractice/practice"
                          "lilypractice/score" "lilypractice/midikeys"))))
            ;; It runs LilyPond and FluidSynth, and finds the soundfont and
            ;; its icons in XDG_DATA_DIRS.
            (add-after 'install 'wrap
              (lambda _
                (wrap-program (string-append #$output "/bin/lilypractice")
                  `("PATH" prefix
                    (,(string-append #$(this-package-input "lilypond") "/bin")
                     ,(string-append #$(this-package-input "fluidsynth") "/bin")))
                  `("XDG_DATA_DIRS" suffix
                    (,(string-append #$(this-package-input "fluid-3") "/share")
                     ,(string-append #$(this-package-input "adwaita-icon-theme")
                                     "/share")))))))))
      (native-inputs (list lilypond pkg-config)) ;LilyPond for the tests
      (inputs
       (list adwaita-icon-theme
             alsa-lib
             bash-minimal
             cairo
             fluid-3
             fluidsynth
             gdk-pixbuf
             glib
             go-github-com-diamondburned-gotk4
             gobject-introspection
             graphene
             gtk
             librsvg
             lilypond
             pango))
      (home-page "https://github.com/nbljaved/lilypractice")
      (synopsis "Piano practice from LilyPond scores")
      (description
       "lilypractice shows a LilyPond score as LilyPond engraves it, with a
cursor that follows the music, and checks the notes you play on a MIDI
keyboard, the computer keyboard or the piano on screen.  It waits for your
notes, keeps time and scores them, or plays the music to you; the hand you
are not practising is played for you.")
      (license license:gpl3))))

lilypractice
