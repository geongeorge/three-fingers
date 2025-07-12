#!/bin/bash

# Release script for ThreeFingers Homebrew distribution

set -e

VERSION="1.0.0"
BINARY_NAME="threefingers"

echo "🍺 Preparing ThreeFingers v$VERSION for Homebrew..."

# Create release directory
mkdir -p release
cd release

# Build universal binary from Xcode
echo "🔨 Building universal binary..."
xcodebuild -project ../threefingers.xcodeproj \
    -scheme threefingers \
    -configuration Release \
    -derivedDataPath ./build \
    -arch arm64 -arch x86_64 \
    ONLY_ACTIVE_ARCH=NO

# Copy the binary
cp "./build/Build/Products/Release/$BINARY_NAME" ./$BINARY_NAME

# Verify it's universal
echo "🔍 Verifying universal binary..."
file $BINARY_NAME
lipo -info $BINARY_NAME

# Create tarball
echo "📦 Creating release tarball..."
tar -czf "${BINARY_NAME}-${VERSION}.tar.gz" $BINARY_NAME

# Generate SHA256
echo "🔐 Generating SHA256..."
SHA256=$(shasum -a 256 "${BINARY_NAME}-${VERSION}.tar.gz" | cut -d' ' -f1)
echo "SHA256: $SHA256"

# Create Homebrew formula template
echo "🍺 Creating Homebrew formula..."
cat > threefingers.rb << EOF
class Threefingers < Formula
  desc "3-finger tap to middle click for macOS trackpads"
  homepage "https://github.com/geongeorge/threefingers"
  url "https://github.com/geongeorge/threefingers/releases/download/v${VERSION}/${BINARY_NAME}-${VERSION}.tar.gz"
  sha256 "$SHA256"
  license "MIT"

  depends_on :macos

  def install
    bin.install "threefingers"
  end

  service do
    run [opt_bin/"threefingers"]
    keep_alive true
    process_type :interactive
    log_path var/"log/threefingers.log"
    error_log_path var/"log/threefingers.log"
  end

  def caveats
    <<~EOS
      ThreeFingers requires Accessibility permissions to function.
      
      To grant permissions:
        1. System Preferences → Security & Privacy → Privacy
        2. Select 'Accessibility' → Click lock → Enter password  
        3. Add 'threefingers' and enable it

      To start the service:
        brew services start threefingers

      To stop the service:
        brew services stop threefingers
    EOS
  end

  test do
    assert_match "ThreeFingers", shell_output("#{bin}/threefingers --help", 1)
  end
end
EOF

echo "✅ Release ready!"
echo ""
echo "📁 Files created:"
echo "   - $BINARY_NAME (universal binary)"
echo "   - ${BINARY_NAME}-${VERSION}.tar.gz (release archive)"
echo "   - threefingers.rb (Homebrew formula)"
echo ""
echo "📋 Next steps:"
echo "   1. Upload ${BINARY_NAME}-${VERSION}.tar.gz to GitHub releases"
echo "   2. Update the formula URL to point to your GitHub release"
echo "   3. Submit to homebrew-core or create a tap"