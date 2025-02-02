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
