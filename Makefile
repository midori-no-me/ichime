format:
	swift format . --recursive --in-place
	@echo "Done formatting"

lint:
	swift format lint . --recursive --strict
	@echo "Done linting"

hooks:
	echo "#!/bin/bash" > $$(git rev-parse --show-toplevel)/.git/hooks/pre-commit
	echo "xcodegen cache" >> $$(git rev-parse --show-toplevel)/.git/hooks/pre-commit
	echo "make lint" >> $$(git rev-parse --show-toplevel)/.git/hooks/pre-commit
	chmod +x $$(git rev-parse --show-toplevel)/.git/hooks/pre-commit

	echo "#!/bin/bash" > $$(git rev-parse --show-toplevel)/.git/hooks/post-rewrite
	echo "xcodegen generate --use-cache" >> $$(git rev-parse --show-toplevel)/.git/hooks/post-rewrite
	chmod +x $$(git rev-parse --show-toplevel)/.git/hooks/post-rewrite

	echo "#!/bin/bash" > $$(git rev-parse --show-toplevel)/.git/hooks/post-checkout
	echo "xcodegen generate --use-cache" >> $$(git rev-parse --show-toplevel)/.git/hooks/post-checkout
	chmod +x $$(git rev-parse --show-toplevel)/.git/hooks/post-checkout

	echo "#!/bin/bash" > $$(git rev-parse --show-toplevel)/.git/hooks/post-merge
	echo "xcodegen generate --use-cache" >> $$(git rev-parse --show-toplevel)/.git/hooks/post-merge
	chmod +x $$(git rev-parse --show-toplevel)/.git/hooks/post-merge
