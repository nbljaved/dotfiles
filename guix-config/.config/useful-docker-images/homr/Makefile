.PHONY: all build check

all: build check

build:
	# Build the homr image from Dockerfile, models and all
	podman build -t homr .
	@echo ""

check:
	@if command -v pdf2ly >/dev/null 2>&1; then \
		echo "✓ homr and pdf2ly are available on PATH"; \
	else \
		echo "✗ homr and pdf2ly are not available on PATH"; \
		echo "Add the following to your shell configuration:"; \
		echo "export PATH=\"\$$PATH:\$$HOME/dotfiles/guix-config/.config/useful-docker-images/homr/bin\""; \
		exit 1; \
	fi
