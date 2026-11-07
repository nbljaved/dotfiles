DOCKER := $(shell command -v docker 2>/dev/null || echo podman)

.PHONY: all build check

# Guix Home links claude-skills/shot-scraper.md as a Claude Code skill.
all: build check

build:
	# Build shot-scraper image
	$(DOCKER) build -t shot-scraper .
	@echo ""

check:
	@if command -v shot-scraper >/dev/null 2>&1; then \
		echo "✓ shot-scraper is available on PATH"; \
		shot-scraper --version; \
	else \
		echo "✗ shot-scraper is not available on PATH"; \
		echo "Add the following to your shell configuration:"; \
		echo "export PATH=\"\$$PATH:\$$HOME/dotfiles/guix-config/other/useful-docker-images/shot-scraper/bin\""; \
		exit 1; \
	fi
