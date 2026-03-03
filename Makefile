PROJECT_NAME = Joiner
SCHEME = Joiner
BUILD_DIR = .build
ARCHIVE_PATH = $(BUILD_DIR)/$(PROJECT_NAME).xcarchive
APP_PATH = $(ARCHIVE_PATH)/Products/Applications/$(PROJECT_NAME).app
DMG_PATH = $(BUILD_DIR)/$(PROJECT_NAME).dmg
DERIVED_DATA = $(BUILD_DIR)/DerivedData

.PHONY: all setup generate build run test clean archive sign notarize dmg deploy

# ──── Setup ────

setup:
	@echo "🔧 Installing dependencies..."
	@which xcodegen > /dev/null 2>&1 || brew install xcodegen
	@echo "✅ Dependencies ready."

generate: setup
	@echo "📦 Generating Xcode project..."
	@cd /Users/mateus.pontes/Development/joiner-app && xcodegen generate
	@echo "✅ Project generated."

# ──── Development ────

build: generate
	@echo "🔨 Building $(PROJECT_NAME)..."
	xcodebuild -project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-configuration Debug \
		-derivedDataPath $(DERIVED_DATA) \
		build | tail -20

run: build
	@echo "🚀 Launching $(PROJECT_NAME)..."
	@open $(DERIVED_DATA)/Build/Products/Debug/$(PROJECT_NAME).app

test: generate
	@echo "🧪 Running tests..."
	xcodebuild -project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-configuration Debug \
		-derivedDataPath $(DERIVED_DATA) \
		test | tail -30

# ──── Release ────

archive: generate
	@echo "📦 Archiving $(PROJECT_NAME)..."
	xcodebuild -project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-configuration Release \
		-archivePath $(ARCHIVE_PATH) \
		-derivedDataPath $(DERIVED_DATA) \
		archive

sign: archive
	@echo "🔏 Code signing..."
	./scripts/codesign.sh "$(APP_PATH)"

notarize: sign
	@echo "📤 Notarizing..."
	./scripts/notarize.sh "$(APP_PATH)"

dmg: notarize
	@echo "💿 Creating DMG..."
	./scripts/create-dmg.sh "$(APP_PATH)" "$(DMG_PATH)"

deploy: dmg
	@echo "✅ Deploy complete: $(DMG_PATH)"

# ──── Cleanup ────

clean:
	@echo "🧹 Cleaning..."
	rm -rf $(BUILD_DIR) $(PROJECT_NAME).xcodeproj DerivedData
	@echo "✅ Clean."
