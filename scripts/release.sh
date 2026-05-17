#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_YML="$ROOT_DIR/project.yml"
REMOTE="${REMOTE:-origin}"
BRANCH="${BRANCH:-main}"
VERSION="${1:-${VERSION:-}}"

fail() {
  echo "error: $*" >&2
  exit 1
}

usage() {
  cat >&2 <<'EOF'
Usage:
  make release VERSION=x.y.z

The release command must run from a clean main branch. It bumps project.yml,
commits the version change, creates a matching tag, then pushes main and tag.
EOF
}

[[ -n "$VERSION" ]] || {
  usage
  exit 2
}

[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "VERSION must be semver-like, e.g. 1.12.1"

command -v git >/dev/null || fail "git is required"
command -v python3 >/dev/null || fail "python3 is required"

current_branch="$(git -C "$ROOT_DIR" branch --show-current)"
[[ "$current_branch" == "$BRANCH" ]] || fail "release must run from $BRANCH, current branch is $current_branch"

[[ -z "$(git -C "$ROOT_DIR" status --porcelain)" ]] || fail "working tree must be clean before release"

if git -C "$ROOT_DIR" rev-parse -q --verify "refs/tags/$VERSION" >/dev/null; then
  fail "local tag $VERSION already exists"
fi

if git -C "$ROOT_DIR" ls-remote --exit-code --tags "$REMOTE" "refs/tags/$VERSION" >/dev/null 2>&1; then
  fail "remote tag $VERSION already exists on $REMOTE"
fi

IFS=. read -r major minor patch <<< "$VERSION"
build_version=$((major * 100000 + minor * 100 + patch))

PROJECT_YML="$PROJECT_YML" VERSION="$VERSION" BUILD_VERSION="$build_version" python3 <<'PY'
import os
import re
from pathlib import Path

path = Path(os.environ["PROJECT_YML"])
version = os.environ["VERSION"]
build_version = os.environ["BUILD_VERSION"]

text = path.read_text(encoding="utf-8")
updated = re.sub(
    r"(^\s*CURRENT_PROJECT_VERSION:\s*)\d+",
    rf"\g<1>{build_version}",
    text,
    flags=re.MULTILINE,
)
updated = re.sub(
    r'(^\s*MARKETING_VERSION:\s*)"[^"]+"',
    rf'\g<1>"{version}"',
    updated,
    flags=re.MULTILINE,
)

if updated == text:
    raise SystemExit("project.yml was not changed")

path.write_text(updated, encoding="utf-8")
PY

git -C "$ROOT_DIR" diff -- project.yml
git -C "$ROOT_DIR" add project.yml
git -C "$ROOT_DIR" commit -m "chore: bump version to $VERSION"
git -C "$ROOT_DIR" tag "$VERSION"
git -C "$ROOT_DIR" push "$REMOTE" "$BRANCH"
git -C "$ROOT_DIR" push "$REMOTE" "$VERSION"

echo "Released $VERSION"
