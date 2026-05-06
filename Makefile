.DEFAULT_GOAL := help

# ── Bob Protocol Configuration ───────────────────────────────────────────────
# Detect if this file is being run directly as Makefile.bob
_IS_BOB_ENTRY := $(filter %Makefile.bob,$(firstword $(MAKEFILE_LIST)))

ifdef MKF_ACTIVE

# ── Re-invocation Layer ──────────────────────────────────────────────────────
# Included by mkf.py to run the actual target.

# ── Happening Project Targets ────────────────────────────────────────────────

ifneq ($(OS),Windows_NT)
  SHELL := /bin/bash
endif

FLUTTER      := flutter
DART         := dart
APP_DIR      := app
PROXY_DIR    := proxy
DIST_DIR     := dist

ifeq ($(OS),Windows_NT)
  VERSION    := $(shell powershell -Command "(Select-String -Path $(APP_DIR)/pubspec.yaml -Pattern '^version:').Line.Split(' ')[1]")
else
  VERSION    := $(shell grep '^version:' $(APP_DIR)/pubspec.yaml | awk '{print $$2}')
endif

ifeq ($(OS),Windows_NT)
  ARCH       := x64
else
  UNAME_ARCH := $(shell uname -m)
  ifeq ($(UNAME_ARCH),aarch64)
    ARCH     := arm64
  else ifeq ($(UNAME_ARCH),arm64)
    ARCH     := arm64
  else
    ARCH     := x64
  endif
endif

LLVM_BIN     := /usr/lib/llvm-20/bin
PUB_STAMP    := $(APP_DIR)/.dart_tool/package_config.json

$(FLUTTER):
ifeq ($(OS),Windows_NT)
	@powershell -Command "if (-not (Test-Path '$(FLUTTER)')) { Write-Host '==> Flutter SDK not found — cloning stable into .flutter/flutter ...'; mkdir -p .flutter; git clone https://github.com/flutter/flutter.git --branch stable --depth 1 .flutter/flutter; Write-Host '✓ flutter SDK cloned' }"
else
	./scripts/setup.sh
endif

.PHONY: setup install-hooks
setup: install-hooks
	./scripts/setup.sh
	cd $(APP_DIR) && $(FLUTTER) pub get

$(PUB_STAMP): $(FLUTTER) $(APP_DIR)/pubspec.yaml $(APP_DIR)/pubspec.lock
	cd $(APP_DIR) && $(FLUTTER) pub get

install-hooks:
ifeq ($(OS),Windows_NT)
	@powershell -Command "Copy-Item -Force scripts/pre-commit .git/hooks/pre-commit"
	@echo "Git hooks installed."
else
	@cp scripts/pre-commit .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "Git hooks installed."
endif

.PHONY: run run-linux run-macos run-windows run-windows-test run-windows-simple
run:
	@echo "Please specify a platform: make run-linux, run-macos, or run-windows"

run-linux: $(PUB_STAMP)
	cd $(APP_DIR) && PATH="$(LLVM_BIN):$$PATH" GDK_BACKEND=x11 $(FLUTTER) run -d linux

run-macos: $(PUB_STAMP)
	cd $(APP_DIR) && $(FLUTTER) run -d macos

run-windows: $(PUB_STAMP)
	@powershell -Command "if (Test-Path $(APP_DIR)/windows/flutter/ephemeral) { Remove-Item -Recurse -Force $(APP_DIR)/windows/flutter/ephemeral }"
	cd $(APP_DIR) && $(FLUTTER) run -d windows

run-windows-test: $(PUB_STAMP)
	cd $(APP_DIR) && $(FLUTTER) run -d windows --target lib/windows_test.dart

run-windows-simple: $(PUB_STAMP)
	cd $(APP_DIR) && $(FLUTTER) run -d windows --target lib/simple_main.dart

CLICK_TEST_DIR := tools/click_through_test

.PHONY: run-click-test run-click-test-x11 build-click-test
# Native Wayland: wl_surface.set_input_region — honored by Mutter
run-click-test:
	cd $(CLICK_TEST_DIR) && GDK_BACKEND=wayland $(FLUTTER) run -d linux

# XWayland: X11 SHAPE extension — may not be honored by Wayland compositor
run-click-test-x11:
	cd $(CLICK_TEST_DIR) && GDK_BACKEND=x11 $(FLUTTER) run -d linux

build-click-test:
	cd $(CLICK_TEST_DIR) && $(FLUTTER) build linux --release

.PHONY: test update-goldens test-watch
test: $(PUB_STAMP)
	cd $(APP_DIR) && $(FLUTTER) test --coverage $(FILE) $(ARGS)

update-goldens: $(PUB_STAMP)
	cd $(APP_DIR) && $(FLUTTER) test --update-goldens test/goldens/

test-watch: $(PUB_STAMP)
	cd $(APP_DIR) && $(FLUTTER) test --coverage --watch $(FILE) $(ARGS)

.PHONY: integration-test integration-test-linux integration-test-macos integration-test-windows
integration-test:
	@echo "Please specify a platform: make integration-test-linux, integration-test-macos, or integration-test-windows"

integration-test-linux: $(PUB_STAMP)
	cd $(APP_DIR) && PATH="$(FLUTTER_SDK)\bin:$(LLVM_BIN):$$PATH" GDK_BACKEND=x11 XAUTHORITY=$$(ls /run/user/$$(id -u)/.mutter-Xwaylandauth.* 2>/dev/null | head -1) $(FLUTTER) test integration_test/ -d linux

integration-test-macos: $(PUB_STAMP)
	cd $(APP_DIR) && $(FLUTTER) test integration_test/ -d macos

integration-test-windows: $(PUB_STAMP)
	cd $(APP_DIR) && $(FLUTTER) test integration_test/ -d windows

.PHONY: build-linux build-macos build-windows
build-linux: $(PUB_STAMP)
	cd $(APP_DIR) && PATH="$(FLUTTER_SDK)\bin:$(LLVM_BIN):$$PATH" $(FLUTTER) build linux --release

build-macos: $(PUB_STAMP)
	cd $(APP_DIR) && $(FLUTTER) build macos --release

build-windows: $(PUB_STAMP)
	cd $(APP_DIR) && $(FLUTTER) build windows --release

.PHONY: dist dist-linux dist-macos dist-windows dist-windows-msix dist-proxy-linux
dist: dist-linux
	@echo "Done. Artifacts in $(DIST_DIR)/"

dist-linux: build-linux
	@mkdir -p $(DIST_DIR)
	tar -czf $(DIST_DIR)/happening-$(VERSION)-linux-$(ARCH).tar.gz \
	    -C $(APP_DIR)/build/linux/$(ARCH)/release bundle
	@echo "Linux package: $(DIST_DIR)/happening-$(VERSION)-linux-$(ARCH).tar.gz"

dist-macos: build-macos
	@mkdir -p $(DIST_DIR)
	$(eval DMG := $(DIST_DIR)/happening-$(VERSION)-macos-$(ARCH).dmg)
	hdiutil create -volname "Happening $(VERSION)" \
	    -srcfolder $(APP_DIR)/build/macos/Build/Products/Release/happening.app \
	    -ov -format UDZO \
	    $(DMG)
	@echo "macOS package: $(DMG)"

dist-windows: build-windows
	@cmd /c if not exist $(DIST_DIR) mkdir $(DIST_DIR)
	cd $(APP_DIR)/build/windows/x64/runner && zip -r $(CURDIR)/$(DIST_DIR)/happening-$(VERSION)-windows-x64.zip Release
	@echo "Windows package: $(DIST_DIR)/happening-$(VERSION)-windows-x64.zip"

dist-windows-msix: build-windows
	@cmd /c if not exist $(DIST_DIR) mkdir $(DIST_DIR)
	cd $(APP_DIR) && $(DART) run msix:create
	@powershell -Command "Copy-Item -Path '$(APP_DIR)/build/windows/x64/runner/Release/happening.msix' -Destination '$(DIST_DIR)/happening-$(VERSION)-windows-x64.msix' -Force"
	@echo "Windows MSIX package: $(DIST_DIR)/happening-$(VERSION)-windows-x64.msix"

dist-proxy-linux: proxy-setup
	@mkdir -p $(DIST_DIR)
	$(DART) compile exe $(PROXY_DIR)/bin/server.dart \
	    -o $(DIST_DIR)/happening-proxy-$(VERSION)-linux-$(ARCH)
	@echo "Proxy binary: $(DIST_DIR)/happening-proxy-$(VERSION)-linux-$(ARCH)"

.PHONY: format analyze lint lint-style lint-metrics lint-format
format: $(PUB_STAMP)
	cd $(APP_DIR) && $(DART) format lib/ test/

analyze: $(PUB_STAMP)
	cd $(APP_DIR) && ulimit -n 31706 && $(FLUTTER) analyze lib test integration_test

lint: lint-style lint-metrics lint-format

lint-style: $(PUB_STAMP)
	cd $(APP_DIR) && $(FLUTTER) analyze --fatal-warnings lib test integration_test

lint-metrics: $(PUB_STAMP)
	cd $(APP_DIR) && $(DART) run dart_code_linter:metrics check-unused-files lib
	cd $(APP_DIR) && $(DART) run dart_code_linter:metrics analyze lib --fatal-style --fatal-performance --fatal-warnings

lint-format: $(PUB_STAMP)
	cd $(APP_DIR) && $(DART) format --output=none --set-exit-if-changed lib/ test/

PROXY_IMAGE  := localhost/happening-proxy
PROXY_BIN    := $(DIST_DIR)/happening-proxy-$(VERSION)-linux-$(ARCH)
PROXY_TAR    := $(DIST_DIR)/happening-proxy-$(VERSION).tar

.PHONY: proxy proxy-setup export-proxy-image
proxy-setup: $(DART)
	cd $(PROXY_DIR) && $(DART) pub get

proxy: proxy-setup
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

.PHONY: clean
clean:
	cd $(APP_DIR) && $(FLUTTER) clean

# ── Bob Protocol Targets ─────────────────────────────────────────────────────

.PHONY: tldr via_index install_bob update_bob pull_bob clean_bob diff_bob

tldr: ## Show TL;DR summaries from all project files (quick orientation for agents)
	@rg --no-heading "TL;DR:" --glob "*.md" -N | sed 's|^\./||' | sort

via_index: ## Build the via index required by the via MCP server
	@via index "$(CURDIR)"

install_bob: ## Copy agents into a project and set up skill links (usage: make install_bob TARGET=/path/to/project)
	@[ -n "$(TARGET)" ] || { echo "Usage: make install_bob TARGET=/path/to/project"; exit 1; }
	@[ -d "$(TARGET)" ] || { echo "Error: $(TARGET) does not exist"; exit 1; }
	@echo "Installing BobProtocol into $(TARGET)..."
	@rsync -a \
		--exclude='*.docs/context.md' \
		--exclude='*.docs/current_task.md' \
		--exclude='*.docs/next_steps.md' \
		--exclude='CHAT.md' \
		agents/ $(TARGET)/agents/
	@echo "Initialising agent state files..."
	@for dir in $(TARGET)/agents/*.docs; do \
		cp agents/templates/_template_context.md    $$dir/context.md; \
		cp agents/templates/_template_current_task.md $$dir/current_task.md; \
		cp agents/templates/_template_next_steps.md $$dir/next_steps.md; \
	done
	@cp agents/templates/_template_CHAT.md $(TARGET)/agents/CHAT.md
	@echo "Installing Makefile into $(TARGET)..."
	@if [ -f "$(TARGET)/Makefile" ]; then \
		if grep -q "MKF_ACTIVE" "$(TARGET)/Makefile"; then \
			cp Makefile "$(TARGET)/Makefile" && echo "  Updated: Makefile (bob-managed)"; \
		else \
			cp Makefile "$(TARGET)/Makefile.bob" && echo "  Installed: Makefile.bob"; \
			if ! grep -q "include Makefile.bob" "$(TARGET)/Makefile"; then \
				echo "include Makefile.bob" | cat - "$(TARGET)/Makefile" > "$(TARGET)/Makefile.tmp" && mv "$(TARGET)/Makefile.tmp" "$(TARGET)/Makefile"; \
				echo "  Modified: Makefile (included Makefile.bob at top)"; \
			fi; \
		fi; \
	else \
		cp Makefile "$(TARGET)/Makefile" && echo "  Installed: Makefile (bob-managed)"; \
	fi
	@echo "Setting up Claude skill links..."
	@python $(TARGET)/agents/tools/setup_agent_links.py
	@echo ""
	@echo "Done. BobProtocol installed in $(TARGET)"
	@echo "Run 'make tldr' inside $(TARGET) to verify."

update_bob: ## Update bob-protocol personas, skills, tools, and templates in a target project (usage: make update_bob TARGET=/path/to/project)
	@[ -n "$(TARGET)" ] || { echo "Usage: make update_bob TARGET=/path/to/project"; exit 1; }
	@[ -d "$(TARGET)" ] || { echo "Error: $(TARGET) does not exist"; exit 1; }
	@echo "Updating BobProtocol in $(TARGET)..."
	@rsync -a agents/skills/ $(TARGET)/agents/skills/
	@rsync -a agents/tools/  $(TARGET)/agents/tools/
	@rsync -a agents/templates/ $(TARGET)/agents/templates/
	@for f in agents/*.docs/SKILL.md; do \
		rsync -a "$$f" "$(TARGET)/$$f"; \
	done
	@echo "Ensuring agent state files are initialised..."
	@for dir in $(TARGET)/agents/*.docs; do \
		[ -f $$dir/context.md ]      || cp agents/templates/_template_context.md      $$dir/context.md; \
		[ -f $$dir/current_task.md ] || cp agents/templates/_template_current_task.md $$dir/current_task.md; \
		[ -f $$dir/next_steps.md ]   || cp agents/templates/_template_next_steps.md   $$dir/next_steps.md; \
	done
	@[ -f $(TARGET)/agents/CHAT.md ] || cp agents/templates/_template_CHAT.md $(TARGET)/agents/CHAT.md
	@echo "Updating Makefile in $(TARGET)..."
	@if [ -f "$(TARGET)/Makefile" ]; then \
		if grep -q "MKF_ACTIVE" "$(TARGET)/Makefile"; then \
			cp Makefile "$(TARGET)/Makefile" && echo "  Updated: Makefile (bob-managed)"; \
		else \
			cp Makefile "$(TARGET)/Makefile.bob" && echo "  Updated: Makefile.bob"; \
			if ! grep -q "include Makefile.bob" "$(TARGET)/Makefile"; then \
				echo "include Makefile.bob" | cat - "$(TARGET)/Makefile" > "$(TARGET)/Makefile.tmp" && mv "$(TARGET)/Makefile.tmp" "$(TARGET)/Makefile"; \
				echo "  Modified: Makefile (included Makefile.bob at top)"; \
			fi; \
		fi; \
	else \
		cp Makefile "$(TARGET)/Makefile" && echo "  Updated: Makefile (bob-managed)"; \
	fi
	@echo "Updating Claude skill links..."
	@python $(TARGET)/agents/tools/setup_agent_links.py
	@echo ""
	@echo "Done. BobProtocol updated in $(TARGET)"

pull_bob: ## Pull bob-protocol personas, skills, tools, and templates from another project (usage: make pull_bob SRC=/path/to/project)
	@[ -n "$(SRC)" ] || { echo "Usage: make pull_bob SRC=/path/to/project"; exit 1; }
	@[ -d "$(SRC)" ] || { echo "Error: $(SRC) does not exist"; exit 1; }
	@echo "Pulling BobProtocol updates from $(SRC)..."
	@rsync -a --existing $(SRC)/agents/skills/    agents/skills/
	@rsync -a --existing $(SRC)/agents/tools/     agents/tools/
	@rsync -a --existing $(SRC)/agents/templates/ agents/templates/
	@for f in agents/*.docs/SKILL.md; do \
		[ -f "$(SRC)/$$f" ] && rsync -a "$(SRC)/$$f" "$$f" || true; \
	done
	@echo ""
	@echo "Done. BobProtocol pulled from $(SRC)"

clean_bob: ## Remove generated symlinks and reset agent memory/state files
	@echo "Removing generated symlinks..."
	@python agents/tools/teardown_agent_links.py --keep-mcp
	@echo "Resetting agent state files to templates..."
	@for dir in agents/*.docs; do \
		cp agents/templates/_template_context.md    $$dir/context.md; \
		cp agents/templates/_template_current_task.md $$dir/current_task.md; \
		cp agents/templates/_template_next_steps.md $$dir/next_steps.md; \
	done
	@cp agents/templates/_template_CHAT.md agents/CHAT.md
	@echo "Done. Environment cleaned and state reset."

diff_bob: ## Compare bob-protocol personas, skills, tools, and templates with a target project (usage: make diff_bob TARGET=/path/to/project)
	@[ -n "$(TARGET)" ] || { echo "Usage: make diff_bob TARGET=/path/to/project"; exit 1; }
	@[ -d "$(TARGET)" ] || { echo "Error: $(TARGET) does not exist"; exit 1; }
	@echo "Diffing BobProtocol: $(CURDIR) vs $(TARGET)"
	@echo ""
	@for dir in agents/skills agents/tools agents/templates; do \
		if [ -d "$(TARGET)/$$dir" ]; then \
			diff -rq "$$dir" "$(TARGET)/$$dir"; \
		else \
			echo "Only in this project: $$dir/"; \
		fi; \
	done || true
	@for f in agents/*.docs/SKILL.md; do \
		tgt="$(TARGET)/$$f"; \
		if [ -f "$$tgt" ]; then \
			diff -q "$$f" "$$tgt" || true; \
		else \
			echo "Only in this project: $$f"; \
		fi; \
	done
	@echo ""
	@echo "Done."

else

# ── Interception layer ───────────────────────────────────────────────────────
# All targets except help, chat, install_bob, update_bob, pull_bob, and clean_bob route through mkf (agents/tools/mkf.py).
# mkf captures output to build/build.out, posts status to CHAT.md,
# and prints the last 10 lines on exit.
#
# Verbosity (set V=):
#   make tldr              silent  — exit code only, full log in build/build.out
#   make tldr V=-v         stderr to terminal
#   make tldr V=-vv        stderr + filtered failures to terminal
#   make tldr V=-vvv       stderr + full stdout to terminal

.PHONY: help chat install_bob update_bob pull_bob clean_bob diff_bob
.PHONY: setup install-hooks run run-linux run-macos run-windows run-windows-test run-windows-simple
.PHONY: run-click-test run-click-test-x11 build-click-test
.PHONY: test update-goldens test-watch integration-test integration-test-linux integration-test-macos integration-test-windows
.PHONY: build-linux build-macos build-windows dist dist-linux dist-macos dist-windows dist-windows-msix dist-proxy-linux
.PHONY: format analyze lint lint-style lint-metrics lint-format proxy proxy-setup export-proxy-image clean tldr via_index

MKF_TARGETS := setup install-hooks run run-linux run-macos run-windows run-windows-test run-windows-simple \
	run-click-test run-click-test-x11 build-click-test \
	test update-goldens test-watch integration-test integration-test-linux integration-test-macos integration-test-windows \
	build-linux build-macos build-windows dist dist-linux dist-macos dist-windows dist-windows-msix dist-proxy-linux \
	format analyze lint lint-style lint-metrics lint-format proxy proxy-setup export-proxy-image clean tldr via_index

install_bob: ## Copy agents into a project and set up skill links (usage: make install_bob TARGET=/path/to/project)
	@$(MAKE) MKF_ACTIVE=1 install_bob TARGET="$(TARGET)"

update_bob: ## Update agents and skills in a project, preserving state (usage: make update_bob TARGET=/path/to/project)
	@$(MAKE) MKF_ACTIVE=1 update_bob TARGET="$(TARGET)"

pull_bob: ## Pull updates from another project using BobProtocol, preserving local state (usage: make pull_bob SRC=/path/to/project)
	@$(MAKE) MKF_ACTIVE=1 pull_bob SRC="$(SRC)"

clean_bob: ## Remove generated symlinks and reset agent memory/state files
	@$(MAKE) MKF_ACTIVE=1 clean_bob

diff_bob: ## Compare bob-protocol files with a target project, excluding state files (usage: make diff_bob TARGET=/path/to/project)
	@$(MAKE) MKF_ACTIVE=1 diff_bob TARGET="$(TARGET)"

help: ## Show available make targets
	@echo ""
	@echo "  Build output filter (mkf) is active. All targets route through agents/tools/mkf.py."
	@echo "  Full log: build/build.out   Status posted to: agents/CHAT.md"
	@echo ""
	@echo "  Verbosity: append V=-v | V=-vv | V=-vvv to any target"
	@echo "    (none)   silent — exit code only"
	@echo "    -v       stderr to terminal"
	@echo "    -vv      stderr + failures/errors to terminal"
	@echo "    -vvv     stderr + full stdout to terminal"
	@echo ""
	@echo "  Examples:"
	@echo "    make pull_bob          # silent, log → build/build.out"
	@echo "    make update_bob V=-vvv # full output"
	@echo ""
	@echo "  Targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / && !seen[$$1]++ {printf "    \033[36m%-22s\033[0m %s\n", $$1, $$2}' $(firstword $(MAKEFILE_LIST))
	@echo ""
	@echo "  Project targets:"
	@for target in $(MKF_TARGETS); do printf "    \033[36m%-22s\033[0m\n" "$$target"; done
	@echo ""

chat: ## Post a message to CHAT.md (usage: make chat MSG="<msg>" [PERSONA="<name>"] [CMD="<cmd>"] [TO="<recipient>"])
	@[ -n "$(MSG)" ] || { echo "Usage: make chat MSG=\"<message>\" [PERSONA=\"<name>\"] [CMD=\"<cmd>\"] [TO=\"<recipient>\"]"; exit 1; }
	@python agents/tools/chat.py "$(MSG)" \
		$(if $(PERSONA),--persona "$(PERSONA)") \
		$(if $(CMD),--cmd "$(CMD)") \
		$(if $(TO),--to "$(TO)")

$(MKF_TARGETS):
	@./agents/tools/mkf.py $(V) $@ \
		$(if $(FILE),FILE=$(FILE)) \
		$(if $(ARGS),ARGS=$(ARGS))

# Interception logic: 
# If we are the entry point (direct make call), intercept everything.
# If we are included, we only provide targets, unless specified.
ifeq ($(MKF_ACTIVE),)
ifdef _IS_BOB_ENTRY
%:
	@./agents/tools/mkf.py $(V) $@
endif
endif

endif
