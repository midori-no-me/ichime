.PHONY: help format lint release hooks

help:
	@echo "Available commands:"
	@echo "  make format"
	@echo "  make lint"
	@echo "  make hooks"
	@echo "  make release VERSION=x.y.z"
	@echo ""
	@echo "Example:"
	@echo "  make release VERSION=1.12.1"

format:
	swiftformat .
	swift format . --recursive --in-place
	swiftlint --fix --quiet

lint:
	swiftformat --lint .
	swift format lint . --recursive --strict
	swiftlint --strict
	periphery scan

release:
	@if [ -z "$(VERSION)" ]; then \
		echo "Usage: make release VERSION=x.y.z"; \
		echo "Example: make release VERSION=1.12.1"; \
		exit 2; \
	fi
	./scripts/release.sh "$(VERSION)"

hooks:
	echo "#!/bin/sh" > $$(git rev-parse --show-toplevel)/.git/hooks/pre-commit
	echo "swiftformat ." >> $$(git rev-parse --show-toplevel)/.git/hooks/pre-commit
	echo "swift format . --recursive --in-place" >> $$(git rev-parse --show-toplevel)/.git/hooks/pre-commit
	echo "swiftlint --fix --quiet" >> $$(git rev-parse --show-toplevel)/.git/hooks/pre-commit
	chmod +x $$(git rev-parse --show-toplevel)/.git/hooks/pre-commit

	echo "#!/bin/sh" > $$(git rev-parse --show-toplevel)/.git/hooks/post-checkout
	echo "xcodegen generate --use-cache" >> $$(git rev-parse --show-toplevel)/.git/hooks/post-checkout
	chmod +x $$(git rev-parse --show-toplevel)/.git/hooks/post-checkout

	echo "#!/bin/sh" > $$(git rev-parse --show-toplevel)/.git/hooks/post-merge
	echo "xcodegen generate --use-cache" >> $$(git rev-parse --show-toplevel)/.git/hooks/post-merge
	chmod +x $$(git rev-parse --show-toplevel)/.git/hooks/post-merge

	echo "#!/bin/sh" > $$(git rev-parse --show-toplevel)/.git/hooks/post-rewrite
	echo "xcodegen generate --use-cache" >> $$(git rev-parse --show-toplevel)/.git/hooks/post-rewrite
	chmod +x $$(git rev-parse --show-toplevel)/.git/hooks/post-rewrite
