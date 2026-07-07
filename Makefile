.PHONY: help format lint hooks tuist-generate tuist-install

help:
	@echo "Available commands:"
	@echo "  make format"
	@echo "  make lint"
	@echo "  make hooks"
	@echo "  make tuist-install"
	@echo "  make tuist-generate"

format:
	swiftformat .
	swift format . --recursive --in-place
	swiftlint --fix --quiet

lint:
	swiftformat --lint .
	swift format lint . --recursive --strict
	swiftlint --strict
	periphery scan

tuist-install:
	tuist install

tuist-generate:
	tuist generate --no-open

hooks:
	echo "#!/bin/sh" > $$(git rev-parse --show-toplevel)/.git/hooks/pre-commit
	echo "swiftformat ." >> $$(git rev-parse --show-toplevel)/.git/hooks/pre-commit
	echo "swift format . --recursive --in-place" >> $$(git rev-parse --show-toplevel)/.git/hooks/pre-commit
	echo "swiftlint --fix --quiet" >> $$(git rev-parse --show-toplevel)/.git/hooks/pre-commit
	chmod +x $$(git rev-parse --show-toplevel)/.git/hooks/pre-commit

	echo "#!/bin/sh" > $$(git rev-parse --show-toplevel)/.git/hooks/post-checkout
	echo "tuist install" >> $$(git rev-parse --show-toplevel)/.git/hooks/post-checkout
	echo "tuist generate --no-open" >> $$(git rev-parse --show-toplevel)/.git/hooks/post-checkout
	chmod +x $$(git rev-parse --show-toplevel)/.git/hooks/post-checkout

	echo "#!/bin/sh" > $$(git rev-parse --show-toplevel)/.git/hooks/post-merge
	echo "tuist install" >> $$(git rev-parse --show-toplevel)/.git/hooks/post-merge
	echo "tuist generate --no-open" >> $$(git rev-parse --show-toplevel)/.git/hooks/post-merge
	chmod +x $$(git rev-parse --show-toplevel)/.git/hooks/post-merge

	echo "#!/bin/sh" > $$(git rev-parse --show-toplevel)/.git/hooks/post-rewrite
	echo "tuist install" >> $$(git rev-parse --show-toplevel)/.git/hooks/post-rewrite
	echo "tuist generate --no-open" >> $$(git rev-parse --show-toplevel)/.git/hooks/post-rewrite
	chmod +x $$(git rev-parse --show-toplevel)/.git/hooks/post-rewrite

gen:
	source .env && tuist install && tuist generate
