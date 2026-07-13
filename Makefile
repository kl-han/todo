DOCS_DIR ?= docs
DOCS_SOURCE ?= $(DOCS_DIR)/src
DOCS_BUILD ?= $(DOCS_DIR)/build/html
DOCS_PORT ?= 8000
UV_CACHE_DIR ?= .uv-cache
SPHINXBUILD ?= uv run --no-project --with 'sphinx>=8' --with furo sphinx-build
APP_DIR ?= apps/quadrant_todo
FLUTTER ?= $(shell if command -v flutter >/dev/null 2>&1; then printf flutter; elif command -v fvm >/dev/null 2>&1; then printf 'fvm flutter'; else printf flutter; fi)
LOCAL_TOOL_BIN ?= $(CURDIR)/.tools/ninja-venv/bin
SERVER_BIN ?= build/server/quadrant_server
export UV_CACHE_DIR

.PHONY: docs html dist-linux dist-ios dist-server
docs:
	$(SPHINXBUILD) -W --keep-going -b html $(DOCS_SOURCE) $(DOCS_BUILD)

html: docs
	python3 -m http.server $(DOCS_PORT) --directory $(DOCS_BUILD)

dist-linux:
	cd $(APP_DIR) && PATH="$(LOCAL_TOOL_BIN):$$PATH" $(FLUTTER) create --platforms=linux . && PATH="$(LOCAL_TOOL_BIN):$$PATH" $(FLUTTER) build linux --release

dist-ios:
	cd $(APP_DIR) && $(FLUTTER) create --platforms=ios . && $(FLUTTER) build ipa

dist-server:
	mkdir -p $(dir $(SERVER_BIN))
	dart compile exe server/bin/quadrant_server.dart -o $(SERVER_BIN)
