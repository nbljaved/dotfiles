# Source-of-truth direction:
#   * `make sync`  captures the live system INTO the repo
#                  (/etc/config.scm + profiles  ->  this repo).
#                  Exception: on the thinkpad the Guix profile is NOT
#                  captured (the shared manifest would get its host-only
#                  packages); `sync-guix` only reports differences there.
#   * `make apply-*` pushes the repo OUT to the live system
#                  (this repo  ->  /etc/config.scm + reconfigure).
# Treat the repo as canonical: edit here, then `apply`. Use `sync`
# only to import ad-hoc changes you made directly on the machine.
#
# Target families:
#   sync-*       live system  ->  repo (capture; report-only for the
#                thinkpad's Guix profile)
#   apply-*      repo  ->  live system (install/reconfigure)
#   check-*      validate without touching the live system
#   distrobox-*  container image / sandbox management
#
# Run `make help` to list every target with its description. To document
# a target in that listing, add a `## <description>` comment on its rule
# line (the text after `##` is what `help` prints).

HOSTNAME := $(shell hostname)
NIX := $(shell command -v nix >/dev/null 2>&1 && echo nix)

# Hosts:
#   thinkpad  Debian + Guix package manager. No system config; its
#             profile is the shared manifest plus HOST_MANIFEST.
#   pc        Guix System, configured by HOST_CONFIG.
ifeq ($(HOSTNAME), thinkpad)
HOST_MANIFEST := thinkpad-manifest.scm
EXTRA_MANIFESTS := -m $(HOST_MANIFEST)
endif
ifeq ($(HOSTNAME), pc)
HOST_CONFIG := config-pc.scm
HOST_HOME := home-pc.scm
endif

.PHONY: help all sync sync-guix sync-nix \
        check-guix-system check-guix-home \
        apply-guix-system apply-guix-home apply-guix-profile apply-nix-profile \
        distrobox distrobox-build distrobox-recreate

help: ## Show this help (list of targets and what they do)
	@echo "Usage: make <target>    (default target: sync)"
	@echo
	@grep -hE '^[a-zA-Z0-9_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-24s\033[0m %s\n", $$1, $$2}'

all: sync ## Alias for `sync` (the default target)

sync: sync-guix sync-nix ## Run sync-guix and sync-nix

sync-guix: ## Link channels.scm; pc: capture /etc/config.scm + Guix profile; thinkpad: report profile vs manifests (writes nothing)
ifdef HOST_CONFIG
	cat /etc/config.scm > $(HOST_CONFIG)
endif
	@echo ""
# cat /etc/xremap.yaml > xremap.yaml
	# Guix: Configure channels
	ln -sf ~/dotfiles/guix-config/channels.scm ~/.config/guix/channels.scm
	# Guix: Get current profile
	# The following command doesn't work:
	# guile ./scripts/sort-manifest.scm  current-profile-manifest > current-profile-manifest
	#
	# Can't read from same file as bash due to the 'redirection'
	# truncates the output file to zero length, therefore we need
	# to use 'sponge' from moreutils that sponges up all the output
	# from the pipe before opening the output file for writing
	#
	# guile ./scripts/sort-manifest.scm  current-profile-manifest | sponge current-profile-manifest
ifdef HOST_MANIFEST
	# This profile is current-profile-manifest plus $(HOST_MANIFEST), so
	# capturing it would leak host-only packages into the shared file.
	# Report only what needs action instead; fix the manifests by hand.
	guile ./scripts/check-host-manifest.scm current-profile-manifest $(HOST_MANIFEST)
else
	guile ./scripts/sort-manifest.scm > current-profile-manifest
endif
	@echo ""

sync-nix: ## Capture Nix channels symlink and current Nix profile manifest (if nix is installed)
ifdef NIX
	# Nix: Configure channels
	ln -sf ~/dotfiles/guix-config/nix-config/nix-channels ~/.nix-channels
	# Nix: Get current profile
	cat ~/.nix-profile/manifest.nix > ./nix-config/manifest.nix
	bash ./scripts/extract-nix-packages.sh
else
	# nix is not installed on this host
endif
	@echo ""

apply-guix-system: ## pc only: copy config-pc.scm to /etc/config.scm and (prompt to) reconfigure
ifdef HOST_CONFIG
	sudo cp $(HOST_CONFIG) /etc/config.scm
	@printf "Reconfigure system? [y/N] " && read ans; \
	if [ "$$ans" = "y" ] || [ "$$ans" = "Y" ]; then \
		sudo guix system reconfigure /etc/config.scm -L modules; \
	fi
else
	@echo "Unsupported host: $(HOSTNAME)"
endif

check-guix-system: ## pc only: dry-build config-pc.scm to catch breakage (does NOT activate)
ifndef HOST_CONFIG
	@echo "Unsupported host: $(HOSTNAME) (no Guix System config)" && exit 1
else
	# Dry build of this host's system config (evaluates + builds the
	# derivation but does NOT activate it) to catch breakage early.
	guix system build $(HOST_CONFIG) -L modules
endif

apply-guix-home: ## pc only: reconfigure Guix Home from home-pc.scm (PipeWire services)
ifdef HOST_HOME
	guix home reconfigure $(HOST_HOME) -L modules
else
	@echo "Unsupported host: $(HOSTNAME) (no Guix Home config; Debian runs PipeWire itself)"
endif

check-guix-home: ## pc only: build home-pc.scm to catch breakage (does NOT activate)
ifndef HOST_HOME
	@echo "Unsupported host: $(HOSTNAME) (no Guix Home config)" && exit 1
else
	guix home build $(HOST_HOME) -L modules
endif

apply-guix-profile: ## Make the Guix profile match current-profile-manifest (+ thinkpad-manifest.scm on thinkpad); removes anything else
	guix package -m current-profile-manifest $(EXTRA_MANIFESTS) -L modules

apply-nix-profile: ## Install the captured Nix profile from nix-config/attribute-manifest.nix
	nix-env --install --remove-all --file ./nix-config/attribute-manifest.nix

distrobox: distrobox-build distrobox-recreate ## Build the Arch image and (re)create the distrobox container

distrobox-build: ## Build the local Arch container image from .config/distrobox
	podman build --pull=newer -t localhost/arch ./.config/distrobox

distrobox-recreate: ## Recreate and enter the 'arch' distrobox container
	# delete 'arch' image
	distrobox rm arch
	# rebuild 'arch' image
	distrobox create \
          --volume /gnu:/gnu/ \
          --volume /var/guix:/var/guix \
          --volume /run/current-system:/run/current-system \
          --volume /nix:/nix \
          --image localhost/arch \
          --name arch
	# run the container
	distrobox enter arch -- ls
