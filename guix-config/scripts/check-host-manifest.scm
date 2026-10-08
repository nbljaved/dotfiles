;; Compare the live Guix profile against the shared manifest plus a
;; host-only manifest, and report only what needs attention:
;;
;;   guile ./scripts/check-host-manifest.scm SHARED-MANIFEST HOST-MANIFEST
;;
;; * packages listed in BOTH manifests (an error: a package is either
;;   shared or host-only, never both)
;; * "-" packages in a manifest but missing from the live profile
;; * "+" packages in the live profile but in neither manifest
;;
;; Exits non-zero if the manifests overlap.

(use-modules (ice-9 popen)
             (srfi srfi-1))

;; Package names from a `(specifications->manifest (list ...))' form
;; read from PORT (the reader skips leading comments).
(define (port->packages port)
  (let ((form (read port)))
    (if (and (list? form)
             (eq? 'specifications->manifest (car form))
             (list? (cadr form))
             (eq? 'list (caadr form)))
        (cdadr form)
        (error "Unexpected manifest format:" form))))

(define (file->packages file)
  (call-with-input-file file port->packages))

(define (live-packages)
  (let* ((pipe (open-input-pipe "guix package --export-manifest"))
         (packages (port->packages pipe)))
    (close-pipe pipe)
    packages))

(define (sorted lst) (sort lst string<?))

(define (print-section title prefix packages)
  (unless (null? packages)
    (format #t "~a~%" title)
    (for-each (lambda (p) (format #t "  ~a ~a~%" prefix p)) (sorted packages))
    (newline)))

(define (main shared-file host-file)
  (let* ((shared (file->packages shared-file))
         (host (file->packages host-file))
         (live (live-packages))
         (wanted (lset-union string=? shared host))
         (overlap (lset-intersection string=? shared host))
         (removed (lset-difference string=? wanted live))
         (added (lset-difference string=? live wanted)))
    (print-section
     (format #f "ERROR: in both ~a and ~a (keep it in only one):"
             shared-file host-file)
     "!" overlap)
    (print-section
     "In a manifest but not in the live profile (to install it: make apply-guix-profile):"
     "-" removed)
    (print-section
     "In the live profile but in neither manifest:"
     "+" added)
    (if (and (null? removed) (null? added))
        (format #t "Live profile matches ~a + ~a.~%" shared-file host-file)
        (format #t "What to do:
  - lines: still wanted? run `make apply-guix-profile` to install them.
           Removed on purpose? delete them from the manifest.
  + lines: wanted on every host  -> add to ~a
           wanted on this host   -> add to ~a
           not wanted            -> `make apply-guix-profile` removes them
  Note: `make apply-guix-profile` makes the profile match the manifests
  exactly, so add any + packages you want to keep BEFORE running it.
Re-run `make sync-guix` until nothing is listed, then commit.~%"
                shared-file host-file))
    (unless (null? overlap)
      (exit 1))))

(apply main (cdr (command-line)))
