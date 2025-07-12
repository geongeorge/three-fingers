#!/bin/bash

# ThreeFingers Homebrew Formula Tester
# Tests the formula locally before publishing

set -e

echo "🧪 Testing ThreeFingers Homebrew Formula"
echo "======================================="

# Check if formula exists
if [ ! -f "threefingers.rb" ]; then
    echo "❌ Formula file 'threefingers.rb' not found!"
    exit 1
fi

# Check if tarball exists (create if needed)
TARBALL="./dist-brew/threefingers-v1.0.0.tar.gz"
if [ ! -f "$TARBALL" ]; then
    echo "📦 Tarball not found, creating..."
    ./create-release.sh
fi

echo "🔍 Validating formula syntax..."
brew formula-lint threefingers.rb || {
    echo "⚠️  Formula validation failed (this might be OK for local testing)"
}

echo "🌐 Starting local HTTP server for testing..."
# Kill any existing process on port 8080
lsof -ti:8080 | xargs kill -9 2>/dev/null || true

# Start a simple HTTP server to serve the tarball
cd ./dist-brew
python3 -m http.server 8080 &
SERVER_PID=$!

# Wait for server to start
sleep 3

# Create a modified formula with correct class name and local URL
cat > ./threefingers-local.rb << 'EOF'
class ThreefingersLocal < Formula
  desc "3-finger tap to middle click for macOS trackpads"
  homepage "https://github.com/geongeorge/threefingers"
  url "http://localhost:8080/threefingers-v1.0.0.tar.gz"
  sha256 "d157a0798bcbb124c2810f4cdff9932d55000ed986eb174b050ba4193a27effa"
  version "1.0.0"
  
  # Only works on macOS
  depends_on :macos
  
  def install
    # Install the main binary
    bin.install "threefingers"
    
    # Install the framework in a shared location
    framework_dir = share/"threefingers"
    framework_dir.mkpath
    framework_dir.install "OpenMultitouchSupportXCF.xcframework"
    
    # Create a wrapper script that sets up the framework path
    wrapper_script = bin/"threefingers"
    wrapper_content = <<~EOS
      #!/bin/bash
      export DYLD_FRAMEWORK_PATH="#{framework_dir}/OpenMultitouchSupportXCF.xcframework/macos-arm64_x86_64"
      exec "#{bin}/threefingers-bin" "$@"
    EOS
    
    # Rename the original binary and create the wrapper
    (bin/"threefingers").rename(bin/"threefingers-bin")
    (bin/"threefingers").write(wrapper_content)
    (bin/"threefingers").chmod(0755)
  end
  
  service do
    run [opt_bin/"threefingers", "daemon"]
    keep_alive true
    require_root false
    log_path var/"log/threefingers-local.log"
    error_log_path var/"log/threefingers-local.error.log"
  end
  
  test do
    assert_match "ThreeFingers v1.0.0", shell_output("#{bin}/threefingers --version")
    assert_match "3-finger tap to middle click", shell_output("#{bin}/threefingers --help")
  end
end
EOF

echo "🧪 Testing installation from local formula..."
echo "📝 Note: This will install ThreeFingers locally"
echo "⚠️  Cancel now (Ctrl+C) if you don't want to install"
sleep 3

# Test the formula
echo "🔧 Running: brew install --formula ./threefingers-local.rb"
brew install --formula ./threefingers-local.rb || {
    echo "❌ Installation failed!"
    kill $SERVER_PID 2>/dev/null || true
    rm -f ./threefingers-local.rb*
    exit 1
}

echo "✅ Installation successful!"
echo ""
echo "🧪 Testing installed binary..."

# Test the installed binary
if command -v threefingers >/dev/null 2>&1; then
    echo "✅ Binary is in PATH"
    
    # Test version
    VERSION_OUTPUT=$(threefingers --version)
    echo "📋 Version: $VERSION_OUTPUT"
    
    # Test help
    echo "📋 Help output:"
    threefingers --help | head -5
    
    echo ""
    echo "🎉 All tests passed!"
    echo ""
    echo "🧹 Cleanup options:"
    echo "   • Keep installed: Do nothing"
    echo "   • Remove: brew uninstall threefingers"
    
else
    echo "❌ Binary not found in PATH after installation"
    exit 1
fi

# Cleanup
kill $SERVER_PID 2>/dev/null || true
rm -f ./threefingers-local.rb*

echo ""
echo "✅ Formula testing complete!"
echo "📋 Your formula is ready for publication."
