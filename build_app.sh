#!/bin/bash

# Local build script to create .app bundle with icon
# Usage: ./build_app.sh [debug|release]

set -e

BUILD_MODE=${1:-release}
ARCH=""

# Detect architecture
if [[ $(uname -m) == "arm64" ]]; then
    ARCH="arm64"
else
    ARCH="x86_64"
fi

echo "Building PentaKill as .app bundle..."
echo "Build mode: $BUILD_MODE"
echo "Architecture: $ARCH"

# Clean previous build
rm -rf .build
rm -rf artifacts
mkdir -p artifacts

# Build the project
if [[ $BUILD_MODE == "debug" ]]; then
    swift build
    BINARY_PATH=".build/debug/PentaKill"
else
    swift build -c release
    BINARY_PATH=".build/release/PentaKill"
fi

# Create .app directory structure
APP_NAME="PentaKill-${ARCH}.app"
mkdir -p "artifacts/${APP_NAME}/Contents/MacOS"
mkdir -p "artifacts/${APP_NAME}/Contents/Resources"

# Copy and modify Info.plist
sed -e 's/$(DEVELOPMENT_LANGUAGE)/en/' \
    -e 's/$(EXECUTABLE_NAME)/PentaKill/' \
    -e 's/$(PRODUCT_BUNDLE_IDENTIFIER)/com.github.pentakill/' \
    -e 's/$(MACOSX_DEPLOYMENT_TARGET)/13.0/' \
    -e 's/<string>icon<\/string>/<string>PentaKill<\/string>/' \
    Info.plist > "artifacts/${APP_NAME}/Contents/Info.plist"

# Copy executable
cp "$BINARY_PATH" "artifacts/${APP_NAME}/Contents/MacOS/"

# Create PkgInfo file
echo "APPL????" > "artifacts/${APP_NAME}/Contents/PkgInfo"

# Create icon set if icon exists
if [ -f "icon.png" ]; then
    echo "Creating icon set..."
    mkdir -p "artifacts/${APP_NAME}/Contents/Resources/PentaKill.iconset"

    # Create icon in different sizes using sips
    create_icon() {
        local size=$1
        local output_name=$2
        sips -z "$size" "$size" icon.png --out "artifacts/${APP_NAME}/Contents/Resources/PentaKill.iconset/${output_name}" 2>/dev/null || true
    }

    create_icon 16 "icon_16x16.png"
    create_icon 32 "icon_16x16@2x.png"
    create_icon 32 "icon_32x32.png"
    create_icon 64 "icon_32x32@2x.png"
    create_icon 128 "icon_128x128.png"
    create_icon 256 "icon_128x128@2x.png"
    create_icon 256 "icon_256x256.png"
    create_icon 512 "icon_256x256@2x.png"
    create_icon 512 "icon_512x512.png"
    create_icon 1024 "icon_512x512@2x.png"

    # Try to create icns file
    if command -v iconutil &> /dev/null; then
        echo "Creating .icns file..."
        iconutil -c icns "artifacts/${APP_NAME}/Contents/Resources/PentaKill.iconset" 2>/dev/null || {
            echo "Warning: iconutil failed, using PNG fallback"
            cp icon.png "artifacts/${APP_NAME}/Contents/Resources/"
        }
    else
        echo "Warning: iconutil not found, using PNG fallback"
        cp icon.png "artifacts/${APP_NAME}/Contents/Resources/"
    fi
else
    echo "Warning: icon.png not found"
fi

# Set executable permissions
chmod +x "artifacts/${APP_NAME}/Contents/MacOS/PentaKill"

# Create archive
echo "Creating archive..."
cd artifacts
tar -czvf "${APP_NAME}.tar.gz" "${APP_NAME}"
cd ..

echo ""
echo "Build complete!"
echo "App bundle: artifacts/${APP_NAME}"
echo "Archive: artifacts/${APP_NAME}.tar.gz"
echo ""
echo "To run the app:"
echo "open artifacts/${APP_NAME}"
echo ""
echo "To run from command line:"
echo "artifacts/${APP_NAME}/Contents/MacOS/PentaKill"