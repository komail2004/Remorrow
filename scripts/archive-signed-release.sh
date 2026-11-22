#!/bin/bash
# Signed iPhone archive/export for Remorrow 1.0 (2).
# Run ONLY on a Mac that has the owner's Apple Distribution certificate,
# current provisioning capability, and Xcode Apple Developer account configured.
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script requires macOS with Xcode and Apple signing credentials." >&2
  exit 2
fi
: "${APPLE_TEAM_ID:?Set APPLE_TEAM_ID to the actual 10-character Apple Developer team ID. Do not commit credentials.}"
if [[ ! "$APPLE_TEAM_ID" =~ ^[A-Z0-9]{10}$ ]]; then
  echo "APPLE_TEAM_ID must be the real 10-character Apple Developer team ID." >&2
  exit 2
fi
command -v xcodebuild >/dev/null
command -v xcodegen >/dev/null
command -v codesign >/dev/null
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
mkdir -p "$root/build"
archive="$root/build/Remorrow-1.0-2.xcarchive"
export_dir="$root/build/Remorrow-1.0-2-export"
options="$root/build/AppStoreExportOptions.plist"

echo "Generating project and archiving for Apple Distribution team $APPLE_TEAM_ID..."
xcodegen generate
xcodebuild \
  -project Remorrow.xcodeproj \
  -scheme Remorrow \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$archive" \
  -allowProvisioningUpdates \
  "DEVELOPMENT_TEAM=$APPLE_TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  CODE_SIGNING_ALLOWED=YES \
  archive

app="$archive/Products/Applications/Remorrow.app"
test -d "$app"
bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Info.plist")"
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Info.plist")"
build="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$app/Info.plist")"
[[ "$bundle_id" == "com.komail2004.remorrow" && "$version" == "1.0" && "$build" == "2" ]] || {
  echo "Refusing export: unexpected app identity $bundle_id, version $version ($build)" >&2
  exit 1
}
codesign --verify --deep --strict --verbose=2 "$app"
for ext in RemorrowWidget RemorrowShareExtension RemorrowTextAction; do
  test -d "$app/PlugIns/$ext.appex"
  codesign --verify --strict --verbose=2 "$app/PlugIns/$ext.appex"
done

cat > "$options" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>export</string>
  <key>signingStyle</key><string>automatic</string>
  <key>teamID</key><string>$APPLE_TEAM_ID</string>
  <key>manageAppVersionAndBuildNumber</key><false/>
  <key>uploadSymbols</key><true/>
</dict></plist>
PLIST

xcodebuild \
  -exportArchive \
  -archivePath "$archive" \
  -exportOptionsPlist "$options" \
  -exportPath "$export_dir" \
  -allowProvisioningUpdates

ipa="$(find "$export_dir" -maxdepth 1 -type f -name '*.ipa' -print -quit)"
test -n "$ipa" && test -s "$ipa"
echo
echo "Signed archive and export verified locally:"
echo "  $archive"
echo "  $ipa"
echo "Do NOT delete the existing TestFlight app. Upload this build using Xcode Organizer"
echo "or another authorized Apple upload method, then perform an in-place upgrade test."
