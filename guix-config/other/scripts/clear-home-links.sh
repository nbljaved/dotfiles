#!/bin/sh
# Usage: sh other/scripts/clear-home-links.sh HOME-DIR   (the output of `guix home build')
# `make apply-guix-home' runs it before `guix home reconfigure'.
#
# Guix Home backs up whatever sits where it wants a link by copying it, which
# fails on a directory and leaves the reconfigure half done.  So, for each
# link it will make: remove an old `ln -sf' link into ~/dotfiles, and stop on
# any other directory.  Assumes the default XDG_CONFIG_HOME, ~/.config.
set -eu

home_dir=$1
blocked=

# The paths have no spaces, so plain word splitting is enough.
for rel in $(cd "$home_dir/files" && find . -type l | sed 's|^\./||'); do
    target="$HOME/$rel"
    case "$(readlink "$target" || true)" in
        "$HOME"/dotfiles/*)
            echo "Removing old link $target -> $(readlink "$target")"
            unlink "$target"
            ;;
        /gnu/store/*)
            ;;
        *)
            if [ -d "$target" ]; then
                blocked="$blocked $target"
            fi
            ;;
    esac
done

if [ -n "$blocked" ]; then
    echo "Guix Home can't back up a directory.  Move these aside, then run it again:" >&2
    for dir in $blocked; do
        echo "  $dir" >&2
    done
    exit 1
fi
