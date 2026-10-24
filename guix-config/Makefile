# Source-of-truth direction:
#   * `make sync`  captures the live system INTO the repo
#                  (/etc/config.scm + Nix profile  ->  this repo).
#                  Guix packages are not captured: they are declared in
#                  home.scm, and `sync-guix` only lists what is left in
#                  the scratch ~/.guix-profile.
#   * `make apply-*` pushes the repo OUT to the live system
#                  (this repo  ->  /etc/config.scm + reconfigure).
# Treat the repo as canonical: edit here, then `apply`. Use `sync`
# only to import ad-hoc changes you made directly on the machine.
#
# Target families:
#   sync-*       live system  ->  repo (capture; report-only for Guix
#                packages)
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
#   thinkpad  Debian + Guix package manager. No system config.
#   pc        Guix System, configured by HOST_CONFIG.
# Both use HOME_CONFIG for Guix Home, which holds every user package and
# picks the host-only packages and services by hostname.
HOME_CONFIG := home.scm
ifeq ($(HOSTNAME), pc)
HOST_CONFIG := config-pc.scm
endif

.PHONY: help all sync sync-guix sync-nix \
        check-guix-system check-guix-home \
        apply-guix-system apply-guix-home apply-nix-profile \
        distrobox distrobox-build distrobox-recreate

help: ## Show this help (list of targets and what they do)
	@echo "Usage: make <target>    (default target: sync)"
	@echo
	@grep -hE '^[a-zA-Z0-9_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-24s\033[0m %s\n", $$1, $$2}'

all: sync ## Alias for `sync` (the default target)

sync: sync-guix sync-nix ## Run sync-guix and sync-nix

sync-guix: ## Link channels.scm; pc: capture /etc/config.scm; list what is left in the scratch ~/.guix-profile
ifdef HOST_CONFIG
	cat /etc/config.scm > $(HOST_CONFIG)
endif
	@echo ""
# cat /etc/xremap.yaml > xremap.yaml
	# Guix: Configure channels
	ln -sf ~/dotfiles/guix-config/channels.scm ~/.config/guix/channels.scm
	# Guix: every package is declared in home.scm, so there is no
	# profile to capture.  ~/.guix-profile is only for trying packages
	# out: list what is in it, to add to home.scm or remove.
	@if [ -n "$$(guix package -I)" ]; then \
		echo "In ~/.guix-profile (add to home.scm, then 'guix package -r' it):"; \
		guix package -I; \
	fi
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

apply-guix-home: ## Reconfigure Guix Home from home.scm (every user package, atuin's config; pc also gets PipeWire services)
	guix home reconfigure $(HOME_CONFIG) -L modules

check-guix-home: ## Build home.scm for this host to catch breakage (does NOT activate)
	guix home build $(HOME_CONFIG) -L modules

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
