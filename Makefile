format:
	swift format . --recursive --in-place

lint:
	swift format lint . --recursive --strict

hooks:
	echo "#!/bin/bash" > $$(git rev-parse --show-toplevel)/.git/hooks/pre-commit
	echo "xcodegen cache" >> $$(git rev-parse --show-toplevel)/.git/hooks/pre-commit
	echo "swift format . --recursive --in-place" >> $$(git rev-parse --show-toplevel)/.git/hooks/pre-commit
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
