#!/bin/bash

# Script to create a new release and trigger TestFlight deployment
# Usage: ./scripts/release.sh 1.11.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if version is provided
if [ $# -eq 0 ]; then
    print_error "Usage: $0 <version>"
    print_info "Example: $0 1.11.0"
    exit 1
fi

VERSION=$1

# Validate version format (semantic versioning)
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_error "Invalid version format. Use semantic versioning (e.g., 1.11.0)"
    exit 1
fi

# Check if we're on a clean working directory
if ! git diff-index --quiet HEAD --; then
    print_error "Working directory is not clean. Please commit or stash your changes first."
    exit 1
fi

# Check if tag already exists
if git tag -l | grep -q "^$VERSION$"; then
    print_error "Tag $VERSION already exists!"
    exit 1
fi

# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

print_info "Creating release $VERSION from branch $CURRENT_BRANCH"

# Confirm release
read -p "Are you sure you want to create release $VERSION? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Release cancelled."
    exit 0
fi

# Update version in project.yml (optional, as CI will do it too)
print_info "Updating MARKETING_VERSION in project.yml"
sed -i '' "s/MARKETING_VERSION: \".*\"/MARKETING_VERSION: \"$VERSION\"/" project.yml

# Commit version change if needed
if ! git diff-index --quiet HEAD --; then
    print_info "Committing version update"
    git add project.yml
    git commit -m "Bump version to $VERSION"
fi

# Create and push tag
print_info "Creating git tag $VERSION"
git tag "$VERSION"

print_info "Pushing tag to origin"
git push origin "$VERSION"

print_info "✅ Release $VERSION created successfully!"
print_info "GitHub Actions will now build and deploy to TestFlight automatically."
print_info "Monitor the progress at: https://github.com/midori-no-me/ichime/actions"

# Wait a moment and try to open the actions page
if command -v open >/dev/null 2>&1; then
    print_info "Opening GitHub Actions page..."
    sleep 2
    open "https://github.com/midori-no-me/ichime/actions"
fi
