format:
	swiftformat .
	swift format . --recursive --in-place
	swiftlint --fix --quiet

lint:
	swiftformat --lint .
	swift format lint . --recursive --strict
	swiftlint --strict
	periphery scan

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

# Release management
release:
	@read -p "Enter version (e.g., 1.11.0): " VERSION; \
	if [ -z "$$VERSION" ]; then echo "Version is required"; exit 1; fi; \
	./scripts/release.sh $$VERSION

# CI/CD helpers
setup-ci:
	bundle install
	brew install xcodegen fastlane

test-build:
	bundle install
	xcodegen generate && cd fastlane && bundle exec fastlane tvos test_build version:test build_number:1

# Development setup
setup:
	brew install xcodegen swiftformat swiftlint periphery
	bundle install
	make hooks
	xcodegen generate

.PHONY: format lint hooks release setup-ci test-build setup
