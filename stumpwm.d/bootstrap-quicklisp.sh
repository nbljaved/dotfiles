#!/usr/bin/env bash
# Recreate ~/quicklisp from upstream, with its signature checked.
#
# Why this exists: ~/quicklisp is not a thing to back up.  It is 13 MB of
# upstream Lisp libraries plus one symlink, and all of it exists only to
# satisfy clx-truetype's dependencies (zpb-ttf, cl-vectors, cl-store,
# cl-fad, bordeaux-threads, trivial-features, trivial-garbage, global-vars,
# cacle), which load-fonts.lisp needs for the StumpWM font.
#
# Needs: sbcl, curl, gpg, and network access.  Nothing here uses Guix, so it
# is safe to run on a machine whose guix-daemon is unpatched.
#
# Verified on 2026-10-04: quicklisp.lisp was 57144 bytes, sha256
# 4a7a5c2aebe0716417047854267397e24a44d0cce096127411e9ce9ccfeb2c17, signed
# 2015-01-29 by the key below.  The file is stable, so a different size is
# fine but a bad signature is not.
set -euo pipefail

KEY_FPR=D7A3489DDEFE32B7D0E7CC61307965AB028B5FF7   # Quicklisp Release Signing Key
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
cd "$work"

curl -fsS -O https://beta.quicklisp.org/quicklisp.lisp \
        -O https://beta.quicklisp.org/quicklisp.lisp.asc \
        -O https://beta.quicklisp.org/release-key.txt

# release-key.txt comes from the same site as the file it signs, so the
# signature alone only proves the site is self-consistent.  The fingerprint
# below is the trust anchor: it is published at
# https://www.quicklisp.org/beta/ and on keyservers (gpg --locate-keys
# release@quicklisp.org).  Compare it yourself at least once.
export GNUPGHOME="$work/gnupg"; mkdir -m 700 "$GNUPGHOME"
gpg --quiet --import release-key.txt
gpg --with-colons --fingerprint release@quicklisp.org \
  | awk -F: -v want="$KEY_FPR" '/^fpr:/ && $10 == want { found = 1 }
      END { if (!found) { print "FINGERPRINT MISMATCH: stop"; exit 1 } }'
gpg --verify quicklisp.lisp.asc quicklisp.lisp

if [ -e "$HOME/quicklisp" ]; then
    echo "~/quicklisp already exists; remove it first if you want a fresh one." >&2
    exit 1
fi

# ql:add-to-init-file is skipped on purpose: ~/.sbclrc is a symlink into
# shell-config and already loads ~/quicklisp/setup.lisp.
sbcl --non-interactive \
     --load quicklisp.lisp \
     --eval '(quicklisp-quickstart:install)'

# clx-truetype is the goose121 fork, vendored as a submodule of this repo.
mkdir -p "$HOME/quicklisp/local-projects"
ln -sfn "$HOME/.stumpwm.d/clx-truetype" "$HOME/quicklisp/local-projects/clx-truetype"

# Pull in the dependency libraries now, so the first StumpWM start is offline-safe.
sbcl --non-interactive \
     --load "$HOME/quicklisp/setup.lisp" \
     --eval '(ql:quickload :clx-truetype)' \
     --eval '(format t "~&clx-truetype loaded: ~a~%" (asdf:system-source-directory "clx-truetype"))'

echo "Done.  ~/quicklisp/dists holds:"
ls "$HOME/quicklisp/dists/quicklisp/software"
