(define-module (nbl packages tailscale)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix utils)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix build-system go)
  #:use-module (gnu packages golang)
  #:use-module (guix records)
  #:use-module (ice-9 match)
  #:use-module (guix git-download)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages base)
  #:use-module (gnu)
  #:use-module (gnu packages linux)) ; for iptables

(define go-package go-1.27)
(define tailscale-version "1.104.5")
(define tailscale-go-git-ref-hash "0wwr54km7hri7aa67rickjqlp47yv8h93ds61i2x9h7rxq2jkbka")
(define tailscale-go-fetch-vendor-hash "19w2fnygfx171wlyccg18z1dfqgmzm6sb0h6x3dwyzd1n8vi7z9j")

(define-record-type* <go-git-reference>
  go-git-reference make-go-git-reference
  go-git-reference?
  (url go-git-reference-url)
  (commit go-git-reference-commit)
  (sha go-git-reference-sha256))

(define* (go-fetch-vendored uri hash-algorithm hash-value name #:key system)
  ;; NAME is also given to the git checkout, so that a name holding the
  ;; version changes both store paths on a version bump: a fixed-output
  ;; store path depends only on its name and hash, so with the same name
  ;; and hash Guix would reuse the old version's source without fetching.
  (let* ((name (or name "go-git-checkout"))
         (src
          (match uri
            (($ <go-git-reference> url commit sha)
             (origin
               (method git-fetch)
               (uri (git-reference
                     (url url)
                     (commit commit)))
               (file-name name)
               (sha256 sha))))))
    (gexp->derivation
     (string-append name "-vendored.tar.gz")
     (with-imported-modules '((guix build utils))
       #~(begin
           (use-modules (guix build utils))
           (let ((inputs (list
                          #+go-package
                          #+tar
                          #+bzip2
                          #+gzip)))
             (set-path-environment-variable "PATH" '("/bin") inputs))
           (mkdir "source")
           (chdir "source")
           (if (file-is-directory? #$src) ;; this is taken (lightly edited) from unpack in gnu-build-system.scm
               (begin
                 ;; Preserve timestamps (set to the Epoch) on the copied tree so that
                 ;; things work deterministically.
                 (copy-recursively #$src "."
                                   #:keep-mtime? #t)
                 ;; Make the source checkout files writable, for convenience.
                 (for-each (lambda (f)
                             (false-if-exception (make-file-writable f)))
                           (find-files ".")))
               (begin
                 (cond
                  ((string-suffix? ".zip" #$src)
                   (invoke "unzip" #$src))
                  ((tarball? #$src)
                   (invoke "tar" "xvf" #$src))
                  (else
                   (let ((name (strip-store-file-name #$src))
                         (command (compressor #$src)))
                     (copy-file #$src name)
                     (when command
                       (invoke command "--decompress" name)))))))

           (setenv "GOCACHE" "/tmp/gc")
           (setenv "GOMODCACHE" "/tmp/gmc")
           (setenv "GOTOOLCHAIN" "local")
           (setenv "SSL_CERT_DIR" #+(file-append nss-certs "/etc/ssl/certs/"))

           (invoke "go" "mod" "vendor")

           (invoke "tar" "czvf" #$output
                   ;; Avoid non-determinism in the archive.
                   "--mtime=@0"
                   "--owner=root:0"
                   "--group=root:0"
                   "--sort=name"
                   "--hard-dereference"
                   ".")))
     #:hash hash-value
     #:hash-algo hash-algorithm)))

(define tailscale-source
  (origin
    (method go-fetch-vendored)
    (uri (go-git-reference
          (url "https://github.com/tailscale/tailscale")
          (commit (string-append "v" tailscale-version))
          (sha (base32 tailscale-go-git-ref-hash))))
    (file-name (git-file-name "tailscale" tailscale-version))
    (sha256
     (base32 tailscale-go-fetch-vendor-hash))))

(define-public tailscale
  (package
    (name "tailscale")
    (version tailscale-version)
    (source tailscale-source)
    (build-system go-build-system)
    (arguments
     `(#:import-path "tailscale.com/cmd/tailscale"
       #:unpack-path "tailscale.com"
       #:install-source? #f
       #:phases
       (modify-phases %standard-phases
         (delete 'check))
       #:go ,go-package))
    (home-page "https://tailscale.com")
    (synopsis "Tailscale client")
    (description "Tailscale client")
    (license license:bsd-3)))

(define-public tailscaled
  (package
    (inherit tailscale)
    (name "tailscaled")
    (arguments
     (substitute-keyword-arguments (package-arguments tailscale)
       ((#:import-path _ #f)
        "tailscale.com/cmd/tailscaled")
       ((#:phases phases #~%standard-phases)
        #~(modify-phases #$phases
            (replace 'build
              (lambda _
                (unsetenv "GO111MODULE")
                (chdir "./src/tailscale.com")
                (invoke "go" "build" "-o" "tailscaled"
                        "tailscale.com/cmd/tailscaled")
                (chdir "../..")))
            (replace 'install
              (lambda _
                (install-file "src/tailscale.com/tailscaled"
                              (string-append #$output "/bin"))))))))
    (synopsis "Tailscale daemon")
    (description "Tailscale daemon")))
