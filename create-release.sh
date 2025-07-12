#!/bin/bash

# ThreeFingers Release Creator
# Creates a tarball suitable for Homebrew distribution

set -e

# Get version from command line argument or default to 1.0.0
VERSION="${1:-1.0.0}"

# Validate version format (basic check)
if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ Invalid version format: $VERSION"
    echo "💡 Use format: X.Y.Z (e.g., 1.0.0)"
    echo "📋 Usage: $0 [version]"
    echo "📋 Example: $0 1.1.0"
    exit 1
fi
RELEASE_NAME="threefingers-v${VERSION}"
BREW_DIST_DIR="./dist-brew"
TEMP_DIR="${BREW_DIST_DIR}/${RELEASE_NAME}"

echo "🚀 Creating ThreeFingers release v${VERSION}..."

# Clean up any existing dist-brew directory and create fresh
rm -rf "${BREW_DIST_DIR}"
mkdir -p "${TEMP_DIR}"

# Build the project first
echo "🔨 Building project..."
make clean && make package

# Copy distribution files
echo "📦 Copying distribution files..."
cp dist/threefingers "${TEMP_DIR}/"
cp -R dist/OpenMultitouchSupportXCF.xcframework "${TEMP_DIR}/"

# Create additional files for the release
echo "📝 Creating release files..."

# Create a README for the release
cat > "${TEMP_DIR}/README.md" << 'EOF'
# ThreeFingers v1.0.0

3-finger tap to middle click for macOS trackpads using OpenMultitouchSupport.

## Installation

### Homebrew (Recommended)
```bash
brew install geongeorge/tap/threefingers
threefingers setup
brew services start threefingers
```

### Manual Installation
```bash
# Extract this archive to /usr/local/bin/
sudo cp threefingers /usr/local/bin/
sudo mkdir -p /usr/local/share/threefingers/
sudo cp -R OpenMultitouchSupportXCF.xcframework /usr/local/share/threefingers/

# Create wrapper script
sudo tee /usr/local/bin/threefingers-wrapper << 'WRAPPER'
#!/bin/bash
export DYLD_FRAMEWORK_PATH="/usr/local/share/threefingers/OpenMultitouchSupportXCF.xcframework/macos-arm64_x86_64"
exec /usr/local/bin/threefingers-bin "$@"
WRAPPER

sudo mv /usr/local/bin/threefingers /usr/local/bin/threefingers-bin
sudo mv /usr/local/bin/threefingers-wrapper /usr/local/bin/threefingers
sudo chmod +x /usr/local/bin/threefingers

# Setup permissions
threefingers setup
```

## Usage

- `threefingers setup` - Interactive permission setup
- `threefingers` - Run the service
- `threefingers --help` - Show help

## Requirements

- macOS 13.0+
- Accessibility permissions
EOF

# Create the tarball
echo "🗜️  Creating tarball..."
cd "${BREW_DIST_DIR}"
tar -czf "${RELEASE_NAME}.tar.gz" "${RELEASE_NAME}/"

# Calculate SHA256 (go back to original directory first)
cd ..
TARBALL_PATH="${BREW_DIST_DIR}/${RELEASE_NAME}.tar.gz"
SHA256=$(shasum -a 256 "${TARBALL_PATH}" | cut -d' ' -f1)

echo ""
echo "✅ Release created successfully!"
echo "📁 Tarball: ${TARBALL_PATH}"
echo "🔐 SHA256: ${SHA256}"
echo ""

# Update the Homebrew formula automatically
echo "🔧 Updating Homebrew formula..."
FORMULA_FILE="./threefingers.rb"

if [ -f "$FORMULA_FILE" ]; then
    # Update the URL
    sed -i.bak "s|url \".*\"|url \"https://github.com/geongeorge/threefingers/releases/download/v${VERSION}/${RELEASE_NAME}.tar.gz\"|g" "$FORMULA_FILE"
    
    # Update the SHA256
    sed -i.bak "s|sha256 \".*\"|sha256 \"${SHA256}\"|g" "$FORMULA_FILE"
    
    # Update the version
    sed -i.bak "s|version \".*\"|version \"${VERSION}\"|g" "$FORMULA_FILE"
    
    # Remove backup file
    rm -f "${FORMULA_FILE}.bak"
    
    echo "✅ Formula updated successfully!"
    echo "📝 Changes made to ${FORMULA_FILE}:"
    echo "   - URL: https://github.com/geongeorge/threefingers/releases/download/v${VERSION}/${RELEASE_NAME}.tar.gz"
    echo "   - SHA256: ${SHA256}"
    echo "   - Version: ${VERSION}"
else
    echo "⚠️  Formula file not found at ${FORMULA_FILE}"
    echo "🔧 Manual formula update needed:"
    echo "  url \"https://github.com/geongeorge/threefingers/releases/download/v${VERSION}/${RELEASE_NAME}.tar.gz\""
    echo "  sha256 \"${SHA256}\""
fi

echo ""
echo "📋 Next steps:"
echo "1. Upload ${RELEASE_NAME}.tar.gz to GitHub Releases"
echo "2. Commit and push the updated formula to your Homebrew tap"
echo "3. Test with: brew upgrade threefingers"

# Keep the dist-brew directory for easy access
echo "📁 Files available in: ${BREW_DIST_DIR}/"
