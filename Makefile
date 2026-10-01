.DEFAULT_GOAL := help

FLUTTER      ?= flutter
DART         ?= dart
APP_DIR      := app
PROXY_DIR    := proxy
DIST_DIR     := dist

ifeq ($(OS),Windows_NT)
  include Makefile.windows
else
  SHELL      := /bin/bash
  VERSION    := $(shell cat app/assets/version.txt 2>/dev/null || echo "0.5.1")
  UNAME_OS   := $(shell uname -s)
  UNAME_ARCH := $(shell uname -m)
  ifeq ($(UNAME_ARCH),aarch64)
    ARCH     := arm64
  else ifeq ($(UNAME_ARCH),arm64)
    ARCH     := arm64
  else
    ARCH     := x64
  endif
  PYTHON     := python3
endif

LLVM_BIN     := /usr/lib/llvm-22/bin
PUB_STAMP    := $(APP_DIR)/.dart_tool/package_config.json
ANALYZE_DIRS := lib test
ifneq ($(wildcard $(APP_DIR)/integration_test),)
  ANALYZE_DIRS += integration_test
endif

# ── Happening Project Targets ────────────────────────────────────────────────

.PHONY: help
help: ## Show available make targets
	@echo "Available make targets:"
	@$(PYTHON) -c "import re; [print(f'  \033[36m{m[1]:<25}\033[0m {m[2]}') for l in open('Makefile') for m in [re.match(r'^([a-zA-Z0-9_-]+):.*?##\s*(.*)$$', l)] if m]"

$(FLUTTER):
ifeq ($(OS),Windows_NT)
	@powershell -Command "if (-not (Test-Path '$(FLUTTER)')) { Write-Host '==> Flutter SDK not found — cloning stable into .flutter/flutter ...'; mkdir -p .flutter; git clone https://github.com/flutter/flutter.git --branch stable --depth 1 .flutter/flutter; Write-Host '✓ flutter SDK cloned' }"
else ifeq ($(UNAME_OS),Darwin)
	./scripts/setup-macos.sh
else
	./scripts/setup.sh
endif

.PHONY: setup install-hooks
setup: install-hooks fetch-cities ## Set up project dependencies and git hooks
ifeq ($(UNAME_OS),Darwin)
	./scripts/setup-macos.sh
else ifeq ($(OS),Windows_NT)
	@echo "Windows setup: ensure Flutter SDK and Visual Studio are installed."
else
	./scripts/setup.sh
endif
	cd $(APP_DIR) && $(FLUTTER) pub get

$(PUB_STAMP): $(FLUTTER) $(APP_DIR)/pubspec.yaml $(APP_DIR)/pubspec.lock
	cd $(APP_DIR) && $(FLUTTER) pub get

install-hooks: ## Install Git pre-commit hooks
ifeq ($(OS),Windows_NT)
	@powershell -Command "Copy-Item -Force scripts/pre-commit .git/hooks/pre-commit"
	@echo "Git hooks installed."
else
	@cp scripts/pre-commit .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "Git hooks installed."
endif

.PHONY: run run-linux run-macos run-windows
run: ## Run application (specify platform via run-linux, run-macos, or run-windows)
	@echo "Please specify a platform: make run-linux, run-macos, or run-windows"

run-linux: $(PUB_STAMP) ## Run Flutter app on Linux
	cd $(APP_DIR) && PATH="$(LLVM_BIN):$$PATH" GDK_BACKEND=x11 $(FLUTTER) run -d linux

run-macos: $(PUB_STAMP) ## Run Flutter app on macOS
	cd $(APP_DIR) && $(FLUTTER) run -d macos

run-windows: $(PUB_STAMP) ## Run Flutter app on Windows
	@powershell -Command "if (Test-Path $(APP_DIR)/windows/flutter/ephemeral) { Remove-Item -Recurse -Force $(APP_DIR)/windows/flutter/ephemeral }"
	cd $(APP_DIR) && $(FLUTTER) run -d windows

.PHONY: test update-goldens test-watch win-test
test: $(PUB_STAMP) ## Run test suite with coverage
	cd $(APP_DIR) && $(FLUTTER) test --coverage $(FILE) $(ARGS)

win-test: $(PUB_STAMP) ## Run static analysis and unit tests (Windows compatible)
	cd $(APP_DIR) && $(FLUTTER) analyze $(ANALYZE_DIRS)
	cd $(APP_DIR) && $(FLUTTER) test $(FILE) $(ARGS)

update-goldens: $(PUB_STAMP) ## Update golden test images
	cd $(APP_DIR) && $(FLUTTER) test --update-goldens test/goldens/

test-watch: $(PUB_STAMP) ## Run tests in watch mode
	cd $(APP_DIR) && $(FLUTTER) test --coverage --watch $(FILE) $(ARGS)

.PHONY: integration-test integration-test-linux integration-test-macos integration-test-windows
integration-test: ## Run integration tests (specify platform)
	@echo "Please specify a platform: make integration-test-linux, integration-test-macos, or integration-test-windows"

integration-test-linux: $(PUB_STAMP) ## Run integration tests on Linux
	cd $(APP_DIR) && PATH="$(FLUTTER_SDK)\bin:$(LLVM_BIN):$$PATH" GDK_BACKEND=x11 XAUTHORITY=$$(ls /run/user/$$(id -u)/.mutter-Xwaylandauth.* 2>/dev/null | head -1) $(FLUTTER) test integration_test/ -d linux

integration-test-macos: $(PUB_STAMP) ## Run integration tests on macOS
	cd $(APP_DIR) && $(FLUTTER) test integration_test/ -d macos

integration-test-windows: $(PUB_STAMP) ## Run integration tests on Windows
	cd $(APP_DIR) && $(FLUTTER) test integration_test/ -d windows

.PHONY: build-linux build-macos build-windows
build-linux: $(PUB_STAMP) ## Build Linux release bundle
	cd $(APP_DIR) && PATH="$(FLUTTER_SDK)\bin:$(LLVM_BIN):$$PATH" $(FLUTTER) build linux --release

build-macos: $(PUB_STAMP) ## Build macOS release bundle
	cd $(APP_DIR) && $(FLUTTER) build macos --release

build-windows: $(PUB_STAMP) ## Build Windows release bundle
	cd $(APP_DIR) && $(FLUTTER) build windows --release

.PHONY: dist dist-linux dist-macos dist-macos-appstore dist-windows dist-windows-msix dist-proxy-linux
dist: dist-linux ## Build distribution artifact (default Linux)
	@echo "Done. Artifacts in $(DIST_DIR)/"

dist-linux: build-linux ## Create Linux tarball package
	@mkdir -p $(DIST_DIR)
	tar -czf $(DIST_DIR)/happening-$(VERSION)-linux-$(ARCH).tar.gz \
	    -C $(APP_DIR)/build/linux/$(ARCH)/release bundle
	@echo "Linux package: $(DIST_DIR)/happening-$(VERSION)-linux-$(ARCH).tar.gz"

dist-macos: build-macos ## Create macOS DMG package
	@mkdir -p $(DIST_DIR)
	$(eval DMG := $(DIST_DIR)/happening-$(VERSION)-macos-$(ARCH).dmg)
	hdiutil create -volname "Happening $(VERSION)" \
	    -srcfolder $(APP_DIR)/build/macos/Build/Products/Release/happening.app \
	    -ov -format UDZO \
	    $(DMG)
	@echo "macOS package: $(DMG)"

dist-macos-appstore: $(PUB_STAMP) ## Export and submit macOS App Store build
	@test -n "$(ASC_API_KEY_ID)"    || (echo "Error: ASC_API_KEY_ID not set";    exit 1)
	@test -n "$(ASC_API_ISSUER_ID)" || (echo "Error: ASC_API_ISSUER_ID not set"; exit 1)
	@test -n "$(ASC_API_KEY_PATH)"  || (echo "Error: ASC_API_KEY_PATH not set";  exit 1)
	xcodebuild archive \
	    -workspace $(APP_DIR)/macos/Runner.xcworkspace \
	    -scheme Runner \
	    -configuration Release \
	    -archivePath $(APP_DIR)/build/macos/Runner.xcarchive
	xcodebuild -exportArchive \
	    -archivePath $(APP_DIR)/build/macos/Runner.xcarchive \
	    -exportOptionsPlist $(APP_DIR)/macos/ExportOptions-AppStore.plist \
	    -authenticationKeyID "$(ASC_API_KEY_ID)" \
	    -authenticationKeyIssuerID "$(ASC_API_ISSUER_ID)" \
	    -authenticationKeyPath "$(ASC_API_KEY_PATH)"
	@echo "macOS v$(VERSION) submitted to App Store Connect"

dist-windows: build-windows ## Create Windows ZIP package
	@cmd /c if not exist $(DIST_DIR) mkdir $(DIST_DIR)
	cd $(APP_DIR)/build/windows/x64/runner && zip -r $(CURDIR)/$(DIST_DIR)/happening-$(VERSION)-windows-x64.zip Release
	@echo "Windows package: $(DIST_DIR)/happening-$(VERSION)-windows-x64.zip"

dist-windows-msix: build-windows ## Create Windows MSIX Store installer
	@cmd /c if not exist $(DIST_DIR) mkdir $(DIST_DIR)
	cd $(APP_DIR) && $(DART) run msix:create
	@powershell -Command "Copy-Item -Path '$(APP_DIR)/build/windows/x64/runner/Release/happening.msix' -Destination '$(DIST_DIR)/happening-$(VERSION)-windows-x64.msix' -Force"
	@echo "Windows MSIX package: $(DIST_DIR)/happening-$(VERSION)-windows-x64.msix"

dist-proxy-linux: proxy-setup ## Build Linux standalone proxy executable
	@mkdir -p $(DIST_DIR)
	$(DART) compile exe $(PROXY_DIR)/bin/server.dart \
	    -o $(DIST_DIR)/happening-proxy-$(VERSION)-linux-$(ARCH)
	@echo "Proxy binary: $(DIST_DIR)/happening-proxy-$(VERSION)-linux-$(ARCH)"

.PHONY: format analyze lint lint-style lint-metrics lint-format
format: $(PUB_STAMP) ## Format Dart codebase
	cd $(APP_DIR) && $(DART) format lib/ test/

analyze: $(PUB_STAMP) ## Run Dart analyze across project
ifeq ($(OS),Windows_NT)
	cd $(APP_DIR) && $(FLUTTER) analyze $(ANALYZE_DIRS)
else
	cd $(APP_DIR) && ulimit -n 31706 && $(FLUTTER) analyze $(ANALYZE_DIRS)
endif

lint: lint-style lint-metrics lint-format ## Run all lint checks (style, metrics, format)

lint-style: $(PUB_STAMP) ## Run analyzer style check
	cd $(APP_DIR) && $(FLUTTER) analyze --fatal-warnings $(ANALYZE_DIRS)

lint-metrics: $(PUB_STAMP) ## Run code metrics checks
	cd $(APP_DIR) && $(DART) run dart_code_linter:metrics check-unusedfiles lib
	cd $(APP_DIR) && $(DART) run dart_code_linter:metrics analyze lib --fatal-style --fatal-performance --fatal-warnings

lint-format: $(PUB_STAMP) ## Check code formatting compliance
	cd $(APP_DIR) && $(DART) format --output=none --set-exit-if-changed lib/ test/

PROXY_IMAGE  := localhost/happening-proxy
PROXY_BIN    := $(DIST_DIR)/happening-proxy-$(VERSION)-linux-$(ARCH)
PROXY_TAR    := $(DIST_DIR)/happening-proxy-$(VERSION).tar

.PHONY: proxy proxy-setup export-proxy-image
proxy-setup: $(DART) ## Install proxy Dart dependencies
	cd $(PROXY_DIR) && $(DART) pub get

proxy: proxy-setup ## Run OAuth proxy server locally
	@test -n "$$GOOGLE_CLIENT_SECRET" || \
		(echo "Error: GOOGLE_CLIENT_SECRET is not set. Run: export GOOGLE_CLIENT_SECRET=<secret>"; exit 1)
	cd $(PROXY_DIR) && $(DART) run bin/server.dart

export-proxy-image: dist-proxy-linux ## Compile proxy + build container image + export tar to dist/
	cp $(PROXY_BIN) $(PROXY_DIR)/bin/happening-proxy
	docker build -t $(PROXY_IMAGE):$(VERSION) $(PROXY_DIR)
	docker save -o $(PROXY_TAR) $(PROXY_IMAGE):$(VERSION)
	rm $(PROXY_DIR)/bin/happening-proxy
	@echo "Image exported to $(PROXY_TAR)"
	@echo "Deploy with: make -C /path/to/pi-patch/cluster deploy-happening TAR=$(CURDIR)/$(PROXY_TAR) VERSION=$(VERSION)"

.PHONY: fetch-cities
fetch-cities: ## Download GeoNames cities15000 and generate app/assets/data/cities.csv
	@$(PYTHON) agents/tools/fetch_cities.py

.PHONY: sync-version set-version test-tools tldr clean
sync-version: ## Synchronize build configurations based on app/assets/version.txt
	@$(PYTHON) agents/tools/sync_version.py

set-version: ## Set a new version number and sync all files (usage: make set-version VERSION=0.5.2)
	@$(PYTHON) agents/tools/sync_version.py --set "$(VERSION)"

test-tools: ## Run agents/tools Python unit tests
	@$(PYTHON) -m unittest discover -s agents/tools -p "test_*.py" -v

tldr: ## Show TL;DR summaries from all project files (quick orientation)
	@rg --no-heading "TL;DR:" --glob "*.md" -N | sed 's|^\./||' | sort

clean: ## Clean Flutter build artifacts
	cd $(APP_DIR) && $(FLUTTER) clean
