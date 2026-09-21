#!/bin/bash
set -e

echo "🌌 Building Stellar Lift .ipa for Sideloading (AltStore / SideStore)..."

# 1. Clean build directory
rm -rf build
mkdir -p build/Payload

# 2. Archive unsigned release build
xcodebuild archive \
  -project StellarLift.xcodeproj \
  -scheme StellarLift \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath build/StellarLift.xcarchive \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY=""

# 3. Package into .ipa
echo "📦 Packaging StellarLift.app into StellarLift.ipa..."
cp -r build/StellarLift.xcarchive/Products/Applications/StellarLift.app build/Payload/
cd build
zip -qr StellarLift.ipa Payload
cd ..

echo "✅ Done! Sideloadable IPA created at: $(pwd)/build/StellarLift.ipa"
echo "You can now install this IPA directly via AltStore, SideStore, or TrollStore."
