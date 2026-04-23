# Almas Pomodoro — Makefile
#
# Fast-feedback targets for building and running a menu-bar-only macOS app
# without Xcode project ceremony. See docs/BUILD.md for details.

SHELL        := /bin/bash
.SHELLFLAGS  := -eu -o pipefail -c
.DEFAULT_GOAL := dev

BIN_NAME    := almas-pomodoro
APP_NAME    := AlmasPomodoro
BUNDLE_ID   := sh.almas.pomodoro
BUILD_DIR   := .build
APP_DIR     := $(BUILD_DIR)/$(APP_NAME).app
INSTALL_DIR := $(HOME)/Applications
LINK_DIR    := $(HOME)/.local/bin
LINK_NAME   := almaspom

DEBUG_BIN   := $(BUILD_DIR)/debug/$(BIN_NAME)
RELEASE_BIN := $(BUILD_DIR)/release/$(BIN_NAME)

SWIFT       ?= swift

.PHONY: help
help: ## Show this help.
	@awk 'BEGIN { FS = ":.*##"; printf "\nTargets:\n" } \
		/^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

.PHONY: build
build: ## Debug build (fast, incremental).
	$(SWIFT) build

.PHONY: release
release: ## Optimised release build.
	$(SWIFT) build -c release

.PHONY: run
run: build kill ## Build debug, kill any running instance, launch fresh.
	@echo "→ launching $(DEBUG_BIN)"
	@nohup "$(DEBUG_BIN)" >/tmp/$(BIN_NAME).log 2>&1 &
	@echo "   log: /tmp/$(BIN_NAME).log   (tail -f)"

.PHONY: dev
dev: run ## Alias for `run` — the default fast rebuild-and-launch loop.

.PHONY: kill
kill: ## Kill any running instance of the app.
	@pkill -x $(BIN_NAME) 2>/dev/null || true
	@pkill -f "$(APP_DIR)/Contents/MacOS/$(BIN_NAME)" 2>/dev/null || true

.PHONY: test
test: ## Run XCTest suite.
	$(SWIFT) test

.PHONY: watch
watch: ## Rebuild + relaunch on every source change (requires fswatch).
	@command -v fswatch >/dev/null || { echo "install fswatch: brew install fswatch"; exit 1; }
	@echo "→ watching Sources/ — Ctrl-C to stop"
	@while true; do \
		$(MAKE) --no-print-directory run || true; \
		fswatch -1 -r Sources >/dev/null; \
	done

.PHONY: app
app: release ## Package a minimal .app bundle under .build/ (for Finder launch).
	@rm -rf "$(APP_DIR)"
	@mkdir -p "$(APP_DIR)/Contents/MacOS"
	@mkdir -p "$(APP_DIR)/Contents/Resources"
	@cp "$(RELEASE_BIN)" "$(APP_DIR)/Contents/MacOS/$(BIN_NAME)"
	@printf '%s\n' \
		'<?xml version="1.0" encoding="UTF-8"?>' \
		'<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' \
		'<plist version="1.0">' \
		'<dict>' \
		'  <key>CFBundleName</key><string>$(APP_NAME)</string>' \
		'  <key>CFBundleDisplayName</key><string>Almas Pomodoro</string>' \
		'  <key>CFBundleIdentifier</key><string>$(BUNDLE_ID)</string>' \
		'  <key>CFBundleExecutable</key><string>$(BIN_NAME)</string>' \
		'  <key>CFBundlePackageType</key><string>APPL</string>' \
		'  <key>CFBundleVersion</key><string>0.1.0</string>' \
		'  <key>CFBundleShortVersionString</key><string>0.1.0</string>' \
		'  <key>LSMinimumSystemVersion</key><string>13.0</string>' \
		'  <key>LSUIElement</key><true/>' \
		'  <key>NSHighResolutionCapable</key><true/>' \
		'</dict>' \
		'</plist>' \
		> "$(APP_DIR)/Contents/Info.plist"
	@echo "→ bundled: $(APP_DIR)"

.PHONY: install
install: app ## Copy the .app bundle into ~/Applications.
	@mkdir -p "$(INSTALL_DIR)"
	@rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	@cp -R "$(APP_DIR)" "$(INSTALL_DIR)/"
	@echo "→ installed: $(INSTALL_DIR)/$(APP_NAME).app"

.PHONY: restart
restart: install ## Reinstall and relaunch the app from ~/Applications.
	@pkill -x $(BIN_NAME) 2>/dev/null || true
	@sleep 1
	@open "$(INSTALL_DIR)/$(APP_NAME).app"
	@echo "→ relaunched: $(INSTALL_DIR)/$(APP_NAME).app"

.PHONY: link
link: install ## Symlink the CLI at ~/.local/bin/almaspom.
	@mkdir -p "$(LINK_DIR)"
	@ln -sf "$(INSTALL_DIR)/$(APP_NAME).app/Contents/MacOS/$(BIN_NAME)" "$(LINK_DIR)/$(LINK_NAME)"
	@echo "→ linked: $(LINK_DIR)/$(LINK_NAME)"
	@case ":$$PATH:" in *":$(LINK_DIR):"*) ;; \
		*) echo "   (add $(LINK_DIR) to your PATH to use '$(LINK_NAME)' from anywhere)";; \
	esac

.PHONY: unlink
unlink: ## Remove the CLI symlink.
	@rm -f "$(LINK_DIR)/$(LINK_NAME)"
	@echo "→ removed: $(LINK_DIR)/$(LINK_NAME)"

.PHONY: log
log: ## Tail the launched-app log.
	@tail -f /tmp/$(BIN_NAME).log

.PHONY: clean
clean: kill ## Kill the app and wipe build artifacts.
	@rm -rf $(BUILD_DIR)
	@echo "→ cleaned"

.PHONY: fmt
fmt: ## Format Swift sources (requires swift-format).
	@command -v swift-format >/dev/null || { echo "install swift-format: brew install swift-format"; exit 1; }
	@swift-format -i -r Sources Tests

.PHONY: lint
lint: ## Lint Swift sources (requires swift-format).
	@command -v swift-format >/dev/null || { echo "install swift-format: brew install swift-format"; exit 1; }
	@swift-format lint -r Sources Tests
