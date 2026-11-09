#!/bin/sh
# Usage: sh other/scripts/check-ssh-canary.sh CONFIG   (relative to guix-config)
# `make apply-guix-home' and `make check-guix-home' run it first.
#
# home.scm links ~/.ssh/config to CONFIG.  Git ignores CONFIG because it holds
# an SSH canary: a decoy host whose name is a DNS canarytoken, so whoever
# steals ~/.ssh and tries that host sets off an alert.  Check that CONFIG and
# the keys it names exist, and print how to make what is missing.  Never write
# either: the token is secret and differs per machine.
set -eu

config=$1
path=$PWD/$config

if [ ! -f "$config" ]; then
    cat <<EOF
ERROR: $path is missing.

home.scm links ~/.ssh/config to it.  It is not in git because it holds an SSH
canary: a decoy host whose name sends you an alert when anyone looks it up.
To make it:

1. Make a DNS canarytoken at https://canarytokens.org/generate
   Pick "DNS", give your email and a memo naming this machine, such as
   "$(hostname): ~/.ssh/config nas".  You get a hostname like
   xxxx.canarytokens.com.

2. At your domain's DNS provider, point a subdomain at it:
       nas.example.com.  300  IN  CNAME  xxxx.canarytokens.com.
   A subdomain, not the bare domain, and DNS-only, not proxied (the grey
   cloud on Cloudflare).  Each machine gets its own subdomain and token.
   Without a domain, use xxxx.canarytokens.com itself as the HostName below.

3. Check that it fires: this should email you an alert.
       dig +short nas.example.com

4. Make the decoy key.  No passphrase: it opens nothing, and should look easy
   to use.
       ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519_nas

5. Write the file, then chmod 600 it:
       mkdir -p $(dirname "$path")
       $path:

       Host nas
           HostName nas.example.com
           User root
           IdentityFile ~/.ssh/id_ed25519_nas
           IdentitiesOnly yes

   Choose your own believable names: this template is in a public repo.  Add
   no comments that give the decoy away.  Any hosts already in ~/.ssh/config
   go in this file too, since Guix Home replaces ~/.ssh/config with a link to
   it.

6. Run make again.
EOF
    exit 1
fi

# ssh only warns about a missing IdentityFile, so the decoy would just look
# broken.  The paths have no spaces, so plain word splitting is enough.
missing=
for key in $(awk 'tolower($1) == "identityfile" { print $2 }' "$config" | sort -u); do
    case $key in
        "~/"*) key=$HOME/${key#"~/"} ;;
    esac
    if [ ! -f "$key" ]; then
        missing="$missing $key"
    fi
done

if [ -n "$missing" ]; then
    echo "ERROR: $path names keys that don't exist:"
    for key in $missing; do
        echo "  $key"
    done
    echo "Make the decoy one with no passphrase (it opens nothing, and should look"
    echo "easy to use), then run make again:"
    echo "    ssh-keygen -t ed25519 -N '' -f KEY"
    exit 1
fi
