(define-module (nbl packages pianoteq)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix monads)
  #:use-module (guix store)
  #:use-module (guix utils)
  #:use-module (nonguix build-system binary)
  #:use-module (nonguix licenses)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages fonts)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages xorg))

;; The trial has no fixed URL.  Its download page signs each visit, and
;; Modartt's API trades that signature for a one-time link, as the
;; page's Download button does (and nixpkgs' fetchPianoteqTrial).
(define* (modartt-trial-fetch file hash-algo hash
                              #:optional name
                              #:key (system (%current-system))
                              (guile (default-guile)))
  "Return a fixed-output derivation that downloads FILE, a Pianoteq trial
tarball, from modartt.com."
  (define build
    (with-imported-modules '((guix build utils))
      #~(begin
          (use-modules (guix build utils)
                       (ice-9 regex)
                       (ice-9 textual-ports))

          ;; --insecure as Guix's own downloads: HASH checks the result.
          (define curl-command
            (list #+(file-append curl "/bin/curl")
                  "--silent" "--show-error" "--fail" "--location"
                  "--retry" "3" "--insecure"
                  "--cookie-jar" "cookies" "--cookie" "cookies"))

          (define (fetch . args)
            (apply invoke (append curl-command '("--output" "reply") args))
            (call-with-input-file "reply" get-string-all))

          (define (extract pattern text what)
            (match:substring
             (or (string-match pattern text)
                 (error "modartt.com changed: no" what))
             1))

          (let* ((page (fetch (string-append
                               "https://www.modartt.com/try?file=" #$file)))
                 (signature (extract "data-mrtc-signature=\"([^\"]+)\"" page
                                     "signature on the download page"))
                 (reply (fetch "--header" "modartt-json: request"
                               "--header" "origin: https://www.modartt.com"
                               "--header" "content-type: application/json"
                               "--data-raw"
                               (string-append "{\"file\": \"" #$file
                                              "\", \"get\": \"url\","
                                              " \"signature\": \""
                                              signature "\"}")
                               "https://www.modartt.com/api/0/download"))
                 (url (extract "\"url\" *: *\"([^\"]+)\"" reply
                               "download link from the API")))
            (apply invoke
                   (append curl-command
                           (list "--output" #$output
                                 ;; The JSON escapes its slashes.
                                 (regexp-substitute/global
                                  #f "\\\\/" url 'pre "/" 'post))))))))

  (mlet %store-monad ((guile (package->derivation guile system)))
    (gexp->derivation (or name file) build
                      #:system system
                      #:hash-algo hash-algo
                      #:hash hash
                      #:local-build? #t
                      #:guile-for-build guile)))

;; To update: put the new version here, and the hash from the "hash
;; mismatch" error that the next build stops with.
(define-public pianoteq-trial
  (package
    (name "pianoteq-trial")
    (version "9.3.0")
    (source
     (origin
       (method modartt-trial-fetch)
       (uri (string-append "pianoteq_trial_v" (string-delete #\. version)
                           ".tar.xz"))
       (sha256
        (base32 "0jmjfq66wd2km13fsfwhqwv6r6x1y3wllb4kq0dnvhcs9hly1bbk"))))
    (build-system binary-build-system)
    (arguments
     (list
      #:strip-binaries? #f
      ;; Besides what they link against, Pianoteq and its plugins dlopen
      ;; the X11 libraries, and Pianoteq OpenSSL and JACK, which PipeWire's
      ;; JACK library serves.
      #:patchelf-plan
      #~(let ((x11 '("libx11" "libxcursor" "libxext" "libxi" "libxinerama"
                     "libxrandr" "libxscrnsaver"))
              (plugin '("libc" "gcc" "curl" "fontconfig-minimal" "freetype")))
          `(("x86-64bit/Pianoteq 9"
             ("libc" "gcc" "alsa-lib" "curl" "fontconfig-minimal" "freetype"
              "mesa" "openssl" ("pipewire" "/lib/pipewire-0.3/jack") ,@x11))
            ("x86-64bit/Pianoteq 9.lv2/Pianoteq_9.so" (,@plugin ,@x11))
            ("x86-64bit/Pianoteq 9.vst3/Contents/x86_64-linux/Pianoteq 9.so"
             (,@plugin ,@x11))
            ("x86-64bit/extra/lame" ("libc"))))
      ;; Pianoteq looks for extra/lame (MP3 export) next to itself, so it
      ;; keeps that layout in lib/pianoteq, and bin/pianoteq links to it.
      #:install-plan
      #~'(("x86-64bit/Pianoteq 9" "lib/pianoteq/")
          ("x86-64bit/extra" "lib/pianoteq/extra")
          ("x86-64bit/Pianoteq 9.lv2" "lib/lv2/Pianoteq 9.lv2")
          ("x86-64bit/Pianoteq 9.vst3" "lib/vst3/Pianoteq 9.vst3")
          ("README_LINUX.txt" "share/doc/pianoteq/")
          ("Licence.rtf" "share/doc/pianoteq/")
          ("Documentation" "share/doc/pianoteq/"))
      #:phases
      #~(modify-phases %standard-phases
          ;; Pianoteq draws with JUCE, which finds fonts in the <dir>s of
          ;; /etc/fonts/fonts.conf, or else in JUCE_FONT_PATH.  Guix System
          ;; has no such file, and without fonts Pianoteq shows no text.
          ;; The plugins run in their host, which must set it for them.
          (add-after 'install 'wrap-fonts
            (lambda _
              (wrap-program (string-append #$output "/lib/pianoteq/Pianoteq 9")
                `("JUCE_FONT_PATH" ";" prefix
                  (,#$(file-append (this-package-input "font-dejavu")
                                   "/share/fonts"))))))
          (add-after 'wrap-fonts 'link-bin
            (lambda _
              (mkdir-p (string-append #$output "/bin"))
              (symlink "../lib/pianoteq/Pianoteq 9"
                       (string-append #$output "/bin/pianoteq")))))))
    (inputs
     (list alsa-lib
           bash-minimal
           curl
           font-dejavu
           fontconfig
           freetype
           `(,gcc "lib")
           libx11
           libxcursor
           libxext
           libxi
           libxinerama
           libxrandr
           libxscrnsaver
           mesa
           openssl
           pipewire))
    (supported-systems '("x86_64-linux"))
    (home-page "https://www.modartt.com/pianoteq")
    (synopsis "Physically modelled piano (trial)")
    (description
     "Pianoteq is a virtual piano that models the instrument physically
instead of playing back samples.  It runs on its own, with ALSA or JACK, or
as an LV2 or VST3 plugin.  This is the free trial.")
    (license (undistributable "file://Licence.rtf"))))

pianoteq-trial
