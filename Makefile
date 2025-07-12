APP_NAME = threefingers
SCHEME = threefingers
CONFIG = Release
BUILD_DIR = $(shell xcodebuild -scheme $(SCHEME) -configuration $(CONFIG) -showBuildSettings | awk '/CONFIGURATION_BUILD_DIR/ {print $$3; exit}')
OUTPUT_DIR = ./dist

package: build copy-framework wrap-launcher
	@echo "✅ Done! Portable CLI tool is ready in $(OUTPUT_DIR)/"

copy-framework: build
	@echo "📦 Locating OpenMultitouchSupportXCF.xcframework..."
	@FRAMEWORK_PATH=$$(find ~/Library/Developer/Xcode/DerivedData -type d -name "OpenMultitouchSupportXCF.xcframework" | head -n 1); \
	if [ -z "$$FRAMEWORK_PATH" ]; then \
		echo "❌ Could not locate OpenMultitouchSupportXCF.xcframework. Ensure it's downloaded via Xcode."; exit 1; \
	fi; \
	echo "✅ Found: $$FRAMEWORK_PATH"; \
	cp -R "$$FRAMEWORK_PATH" $(OUTPUT_DIR)/

build:
	@echo "🔨 Building $(APP_NAME)..."
	xcodebuild -scheme $(SCHEME) -configuration $(CONFIG)
	@mkdir -p $(OUTPUT_DIR)
	@cp "$(BUILD_DIR)/$(APP_NAME)" $(OUTPUT_DIR)/

wrap-launcher: build
	@echo "🚀 Creating launcher script..."
	@echo '#!/bin/bash' > $(OUTPUT_DIR)/$(APP_NAME).sh
	@echo 'DIR="$$(cd "$$(dirname "$$0")" && pwd)"' >> $(OUTPUT_DIR)/$(APP_NAME).sh
	@echo 'export DYLD_FRAMEWORK_PATH="$$DIR/OpenMultitouchSupportXCF.xcframework/macos-arm64_x86_64"' >> $(OUTPUT_DIR)/$(APP_NAME).sh
	@echo '"$$DIR/$(APP_NAME)" "$$@"' >> $(OUTPUT_DIR)/$(APP_NAME).sh
	@chmod +x $(OUTPUT_DIR)/$(APP_NAME).sh

clean:
	rm -rf $(OUTPUT_DIR)