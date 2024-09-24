# Name of the Xcode project or target
APP_NAME = SignApp
SCHEME = $(APP_NAME)
BUNDLE_IDENTIFIER = com.apple.sign

# Build settings
BUILD_DIR = build
CONFIGURATION = Debug
SDK = macosx

# Path to the .xcodeproj (if applicable, otherwise this is optional)
PROJECT = $(APP_NAME).xcodeproj

.PHONY: all build clean run

# Default target - build the app
all: build

# Build the app
build:
	@echo "Building the app..."
	xcodebuild -project $(PROJECT) \
	-scheme $(SCHEME) \
	-configuration $(CONFIGURATION) \
	-sdk $(SDK) \
	-derivedDataPath $(BUILD_DIR) \
	ONLY_ACTIVE_ARCH=YES

# Clean the build folder
clean:
	@echo "Cleaning the build..."
	xcodebuild clean -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIGURATION)

# Run the app
run: build
	@echo "Running the app..."
	open $(BUILD_DIR)/Build/Products/$(CONFIGURATION)/$(APP_NAME).app

# Archive the app for distribution (optional)
archive:
	@echo "Archiving the app..."
	xcodebuild archive -project $(PROJECT) \
	-scheme $(SCHEME) \
	-configuration $(CONFIGURATION) \
	-sdk $(SDK) \
	-archivePath $(BUILD_DIR)/$(APP_NAME).xcarchive \
	-derivedDataPath $(BUILD_DIR)

# Export the app for distribution (optional)
export:
	@echo "Exporting the app..."
	xcodebuild -exportArchive \
	-archivePath $(BUILD_DIR)/$(APP_NAME).xcarchive \
	-exportPath $(BUILD_DIR)/$(APP_NAME) \
	-exportOptionsPlist ExportOptions.plist
