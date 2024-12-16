define PRE_COMMIT_HOOK
#!/bin/bash
xcodegen cache
make lint
endef

define POST_CHECKOUT_HOOK
#!/bin/sh
xcodegen generate --use-cache
endef

define POST_MERGE_HOOK
#!/bin/sh
xcodegen generate --use-cache
endef

define POST_REWRITE_HOOK
#!/bin/bash
xcodegen generate --use-cache
endef

format:
	swift format . --recursive --in-place
	@echo "Done formatting"

lint:
	swift format lint . --recursive --strict
	@echo "Done linting"

export PRE_COMMIT_HOOK
export POST_CHECKOUT_HOOK
export POST_MERGE_HOOK
export POST_REWRITE_HOOK

hooks:
	echo "$$PRE_COMMIT_HOOK" > $$(git rev-parse --show-toplevel)/.git/hooks/pre-commit
	chmod +x $$(git rev-parse --show-toplevel)/.git/hooks/pre-commit

	echo "$$POST_CHECKOUT_HOOK" > $$(git rev-parse --show-toplevel)/.git/hooks/post-checkout
	chmod +x $$(git rev-parse --show-toplevel)/.git/hooks/post-checkout

	echo "$$POST_MERGE_HOOK" > $$(git rev-parse --show-toplevel)/.git/hooks/post-merge
	chmod +x $$(git rev-parse --show-toplevel)/.git/hooks/post-merge

	echo "$$POST_REWRITE_HOOK" > $$(git rev-parse --show-toplevel)/.git/hooks/post-rewrite
	chmod +x $$(git rev-parse --show-toplevel)/.git/hooks/post-rewrite
