#!/bin/bash
set -e

echo "🌌 Building Stellar Lift .ipa for Sideloading (AltStore / SideStore)..."

# 1. Clean build directory
rm -rf build
mkdir -p build/Payload

# 2. Archive unsigned release build
xcodebuild build \
  -project StellarLift.xcodeproj \
  -scheme StellarLift \
  -configuration Release \
  -sdk iphoneos \
  -destination "generic/platform=iOS" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGNING_REQUIRED=NO \
  AD_HOC_CODE_SIGNING_ALLOWED=YES \
  CONFIGURATION_BUILD_DIR=build/Release-iphoneos

# 3. Package into .ipa
echo "📦 Packaging StellarLift.app into StellarLift.ipa..."
cp -r build/Release-iphoneos/StellarLift.app build/Payload/
cd build
zip -qr StellarLift.ipa Payload
cd ..

echo "✅ Done! Sideloadable IPA created at: $(pwd)/build/StellarLift.ipa"
echo "You can now install this IPA directly via AltStore, SideStore, or TrollStore."
