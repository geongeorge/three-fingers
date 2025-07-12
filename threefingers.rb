class Threefingers < Formula
  desc "3-finger tap to middle click for macOS trackpads"
  homepage "https://github.com/geongeorge/threefingers"
  url "https://github.com/geongeorge/threefingers/releases/download/v1.0.2/threefingers-v1.0.2.tar.gz"
  sha256 "54f2153ad5be577bfbe4bc96310ef5467ebae88eda88598e16d19701231dca83"
  version "1.0.2"
  
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
  
  def post_install
    puts ""
    puts "🎉 ThreeFingers installed successfully!"
    puts ""
    puts "🚀 Next steps:"
    puts "1. Grant permissions: threefingers setup"
    puts "2. Restart service: brew services restart threefingers"
    puts ""
    puts "💡 The setup command will guide you through granting Accessibility permissions."
  end
  
  service do
    run [opt_bin/"threefingers", "daemon"]
    keep_alive true
    require_root false
    log_path var/"log/threefingers.log"
    error_log_path var/"log/threefingers.error.log"
  end
  
  test do
    assert_match "ThreeFingers v1.0.0", shell_output("#{bin}/threefingers --version")
    assert_match "3-finger tap to middle click", shell_output("#{bin}/threefingers --help")
  end
end
