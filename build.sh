#!/bin/bash

# DIT FolderGen Build Script
# Builds the macOS app and creates distributable package

set -e

echo "🛠️  Building DIT FolderGen..."

# Clean and build for release
xcodebuild -project DIT_FolderGen.xcodeproj \
           -scheme DIT_FolderGen \
           -configuration Release \
           -derivedDataPath ./build \
           clean build

echo "✅ Build completed successfully!"

# Copy app to release folder
RELEASE_DIR="./Release"
APP_PATH="./build/Build/Products/Release/DIT_FolderGen.app"

if [ -d "$APP_PATH" ]; then
    echo "📦 Creating release package..."
    
    # Create release directory
    mkdir -p "$RELEASE_DIR"
    
    # Copy app
    cp -R "$APP_PATH" "$RELEASE_DIR/"
    
    # Copy presets folder
    cp -R "./Presets" "$RELEASE_DIR/"
    
    # Copy readme
    cp "./README.md" "$RELEASE_DIR/"
    
    # Create DMG (optional - requires create-dmg tool)
    if command -v create-dmg &> /dev/null; then
        echo "🖱️  Creating DMG..."
        create-dmg \
            --volname "DIT FolderGen" \
            --volicon "$APP_PATH/Contents/Resources/AppIcon.icns" \
            --window-pos 200 120 \
            --window-size 800 400 \
            --icon-size 100 \
            --icon "DIT_FolderGen.app" 200 190 \
            --hide-extension "DIT_FolderGen.app" \
            --app-drop-link 600 185 \
            "$RELEASE_DIR/DIT_FolderGen.dmg" \
            "$RELEASE_DIR/"
        
        echo "✅ DMG created successfully!"
    else
        echo "ℹ️  create-dmg not found. Creating ZIP instead..."
        cd "$RELEASE_DIR"
        zip -r "DIT_FolderGen_v1.0.zip" "DIT_FolderGen.app" "Presets/" "README.md"
        cd ..
        echo "✅ ZIP package created successfully!"
    fi
    
    echo "🎉 Release package ready in $RELEASE_DIR/"
    open "$RELEASE_DIR"
    
else
    echo "❌ Build failed - app not found at expected path"
    exit 1
fi