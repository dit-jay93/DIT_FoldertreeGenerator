#!/bin/bash

# ============================================================
# DIT FolderGen - Build & Distribution Script
# Creates a distributable DMG installer for macOS
# ============================================================

set -e

# Configuration
APP_NAME="DIT_FolderGen"
DISPLAY_NAME="DIT FolderGen"
VERSION="1.0.0"
BUILD_DIR="./build"
RELEASE_DIR="./Release"
DMG_DIR="./dmg_staging"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  DIT FolderGen - Build & Package Script${NC}"
echo -e "${BLUE}  Version: ${VERSION}${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Step 1: Clean previous builds
echo -e "${BLUE}[1/4]${NC} Cleaning previous builds..."
rm -rf "$BUILD_DIR" "$RELEASE_DIR" "$DMG_DIR"
echo "  ✅ Clean complete"

# Step 2: Build for Release
echo ""
echo -e "${BLUE}[2/4]${NC} Building ${DISPLAY_NAME} for Release..."
xcodebuild -project ${APP_NAME}.xcodeproj \
           -scheme ${APP_NAME} \
           -configuration Release \
           -derivedDataPath "$BUILD_DIR" \
           clean build \
           MACOSX_DEPLOYMENT_TARGET=13.0 \
           2>&1 | tail -20

APP_PATH="${BUILD_DIR}/Build/Products/Release/${APP_NAME}.app"

if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}  ❌ Build failed - app not found at expected path${NC}"
    exit 1
fi

echo "  ✅ Build completed successfully!"

# Step 3: Strip code signature for unsigned distribution
echo ""
echo -e "${BLUE}[3/4]${NC} Preparing app for distribution..."

# Remove existing code signature (Xcode auto-signs with local cert)
codesign --remove-signature "$APP_PATH" 2>/dev/null || true

# Ad-hoc sign so macOS can verify the app is intact
codesign --force --deep --sign - "$APP_PATH"
echo "  ✅ App signed (ad-hoc)"

# Step 4: Create DMG
echo ""
echo -e "${BLUE}[4/4]${NC} Creating DMG installer..."

mkdir -p "$RELEASE_DIR"
mkdir -p "$DMG_DIR"

# Copy app to staging
cp -R "$APP_PATH" "${DMG_DIR}/${APP_NAME}.app"

# Copy Presets folder alongside the app
cp -R "./Presets" "${DMG_DIR}/Presets"

# Create Applications symlink for drag & drop install
ln -s /Applications "${DMG_DIR}/Applications"

# Create DMG
DMG_PATH="${RELEASE_DIR}/${APP_NAME}_v${VERSION}.dmg"

hdiutil create \
    -volname "${DISPLAY_NAME}" \
    -srcfolder "$DMG_DIR" \
    -ov \
    -format UDZO \
    -imagekey zlib-level=9 \
    "$DMG_PATH"

echo "  ✅ DMG created: ${DMG_PATH}"

# Clean up staging
rm -rf "$DMG_DIR"

# Also create a ZIP as backup
echo ""
echo -e "${BLUE}[+]${NC} Creating ZIP backup..."
cd "$RELEASE_DIR"
mkdir -p "${APP_NAME}_v${VERSION}"
cp -R "../${BUILD_DIR}/Build/Products/Release/${APP_NAME}.app" "${APP_NAME}_v${VERSION}/"
cp -R "../Presets" "${APP_NAME}_v${VERSION}/"
cp "../README.md" "${APP_NAME}_v${VERSION}/"
zip -r -q "${APP_NAME}_v${VERSION}.zip" "${APP_NAME}_v${VERSION}/"
rm -rf "${APP_NAME}_v${VERSION}"
cd ..
echo "  ✅ ZIP created: ${RELEASE_DIR}/${APP_NAME}_v${VERSION}.zip"

# Summary
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Build Complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "  📦 Distributable files in ${RELEASE_DIR}/:"
echo "     - ${APP_NAME}_v${VERSION}.dmg  (DMG installer)"
echo "     - ${APP_NAME}_v${VERSION}.zip  (ZIP backup)"
echo ""
echo -e "  ${BLUE}Note:${NC} This app is not notarized."
echo "  Recipients may need to right-click → Open"
echo "  on first launch to bypass Gatekeeper."
echo ""

# Open release folder
open "$RELEASE_DIR"
