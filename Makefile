.PHONY: fix
fix: ## Fixes code style and applies automatic fixes to linters
	swiftformat .
	swift format . --recursive --in-place
	swiftlint --fix --quiet

.PHONY: lint
lint: ## Runs code style checks and linters
	swiftformat --lint .
	swift format lint . --recursive --strict
	swiftlint --strict
	periphery scan

.PHONY: gen
gen: ## Generates Xcode project
	source .env && tuist install && tuist generate
