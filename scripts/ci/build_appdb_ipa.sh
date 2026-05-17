#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_YML="$ROOT_DIR/project.yml"
PROJECT_FILE="${PROJECT_FILE:-Ichime.xcodeproj}"
SCHEME="${SCHEME:-Ichime_tvOS}"
CONFIGURATION="${CONFIGURATION:-Release}"
SDK="${SDK:-appletvos}"
DESTINATION="${DESTINATION:-generic/platform=tvOS}"
APPDB_ICON_SOURCE="${APPDB_ICON_SOURCE:-$ROOT_DIR/scripts/ci/appdb_icon.png}"

fail() {
  echo "::error::$*" >&2
  exit 1
}

extract_marketing_version() {
  awk '
    /^[[:space:]]*MARKETING_VERSION[[:space:]]*:/ {
      sub(/^[^:]*:/, "")
      sub(/[[:space:]]+#.*/, "")
      gsub(/^[[:space:]"]+|[[:space:]"]+$/, "")
      print
      exit
    }
  ' "$PROJECT_YML"
}

command -v xcodegen >/dev/null || fail "xcodegen is required"
command -v xcodebuild >/dev/null || fail "xcodebuild is required"
command -v /usr/libexec/PlistBuddy >/dev/null || fail "PlistBuddy is required"

VERSION="${VERSION:-$(extract_marketing_version)}"
[[ -n "$VERSION" ]] || fail "Could not read MARKETING_VERSION from project.yml"

PROJECT_PATH="$ROOT_DIR/$PROJECT_FILE"
[[ -d "$PROJECT_PATH" || -f "$PROJECT_PATH" ]] || {
  echo "Generating $PROJECT_FILE with XcodeGen"
  xcodegen generate --spec "$PROJECT_YML"
}

BUILD_ROOT="$ROOT_DIR/build"
APPDB_BUILD_DIR="$BUILD_ROOT/appdb"
DERIVED_DATA_PATH="$APPDB_BUILD_DIR/DerivedData"
PRODUCTS_DIR="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION-$SDK"
STAGING_DIR="$APPDB_BUILD_DIR/staging"
PAYLOAD_DIR="$STAGING_DIR/Payload"
IPA_PATH="$BUILD_ROOT/Ichime-$VERSION.ipa"

rm -rf "$APPDB_BUILD_DIR"
mkdir -p "$BUILD_ROOT"

echo "Generating Xcode project"
xcodegen generate --spec "$PROJECT_YML"

echo "Building unsigned $SCHEME for $DESTINATION"
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -sdk "$SDK" \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

APP_PATH="$PRODUCTS_DIR/$SCHEME.app"
if [[ ! -d "$APP_PATH" ]]; then
  APP_PATH="$(find "$PRODUCTS_DIR" -maxdepth 1 -type d -name "*.app" | head -n 1)"
fi

[[ -n "$APP_PATH" && -d "$APP_PATH" ]] || fail "Could not find built .app in $PRODUCTS_DIR"

echo "Packaging IPA"
rm -rf "$STAGING_DIR" "$IPA_PATH"
mkdir -p "$PAYLOAD_DIR"
ditto "$APP_PATH" "$PAYLOAD_DIR/$(basename "$APP_PATH")"

STAGED_APP_PATH="$PAYLOAD_DIR/$(basename "$APP_PATH")"
INFO_PLIST="$STAGED_APP_PATH/Info.plist"
APPDB_ICON_NAME="AppIcon"
APPDB_ICON_FILE="$APPDB_ICON_NAME.png"

[[ -f "$APPDB_ICON_SOURCE" ]] || fail "App icon source does not exist: $APPDB_ICON_SOURCE"
ditto "$APPDB_ICON_SOURCE" "$STAGED_APP_PATH/$APPDB_ICON_FILE"

/usr/libexec/PlistBuddy -c "Delete :CFBundleIcons:CFBundlePrimaryIcon" "$INFO_PLIST" >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy -c "Add :CFBundleIcons:CFBundlePrimaryIcon dict" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles array" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles:0 string $APPDB_ICON_NAME" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Delete :CFBundleIconFile" "$INFO_PLIST" >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string $APPDB_ICON_NAME" "$INFO_PLIST"

(
  cd "$STAGING_DIR"
  zip -qry "$IPA_PATH" Payload
)

[[ -f "$IPA_PATH" ]] || fail "IPA was not created at $IPA_PATH"

echo "Created $IPA_PATH"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "ipa_path=$IPA_PATH"
    echo "version=$VERSION"
  } >> "$GITHUB_OUTPUT"
fi
