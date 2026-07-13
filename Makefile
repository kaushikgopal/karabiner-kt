WINDOW_LAYOUT_NAME := custom-karabiner-windowlayout-server
WINDOW_LAYOUT_LABEL := sh.kau.$(WINDOW_LAYOUT_NAME)
WINDOW_LAYOUT_PACKAGE := $(CURDIR)/$(WINDOW_LAYOUT_NAME)
WINDOW_LAYOUT_APP := $(HOME)/Applications/$(WINDOW_LAYOUT_NAME).app
WINDOW_LAYOUT_PROGRAM := $(WINDOW_LAYOUT_APP)/Contents/MacOS/$(WINDOW_LAYOUT_NAME)
WINDOW_LAYOUT_AGENT := $(HOME)/Library/LaunchAgents/$(WINDOW_LAYOUT_LABEL).plist
WINDOW_LAYOUT_LOG := $(HOME)/Library/Logs/$(WINDOW_LAYOUT_NAME).log

.PHONY: default help kt ts install-window-server restart-karabiner ktfmt ktfmt-all

default: kt

help:			## list out commands with descriptions
	@sed -ne '/@sed/!s/## //p' $(MAKEFILE_LIST)

kt:			## generate and install karabiner.json (using kotlin)
	./gradlew run
	cp ./app/karabiner.json ~/.config/karabiner/

install-window-server:	## explicitly build and install the window server
	swift build --package-path $(WINDOW_LAYOUT_PACKAGE) --configuration release
	-@launchctl bootout gui/$(shell id -u)/$(WINDOW_LAYOUT_LABEL) 2>/dev/null
	mkdir -p $(HOME)/Applications $(HOME)/Library/LaunchAgents $(HOME)/Library/Logs
	@SOURCE_HASH=$$({ find $(WINDOW_LAYOUT_PACKAGE)/Sources -type f -name '*.swift' | sort | xargs shasum -a 256; shasum -a 256 $(WINDOW_LAYOUT_PACKAGE)/Package.swift $(WINDOW_LAYOUT_PACKAGE)/Package.resolved $(WINDOW_LAYOUT_PACKAGE)/Info.plist; } | shasum -a 256 | awk '{print $$1}'); \
	CURRENT_HASH=$$(cat $(WINDOW_LAYOUT_APP)/Contents/Resources/source.sha256 2>/dev/null || true); \
	if [ "$$SOURCE_HASH" != "$$CURRENT_HASH" ]; then \
		rm -rf $(WINDOW_LAYOUT_APP); \
		mkdir -p $(WINDOW_LAYOUT_APP)/Contents/MacOS $(WINDOW_LAYOUT_APP)/Contents/Resources; \
		install -m 755 $$(swift build --package-path $(WINDOW_LAYOUT_PACKAGE) --configuration release --show-bin-path)/CustomKarabinerWindowLayoutServer $(WINDOW_LAYOUT_PROGRAM); \
		cp $(WINDOW_LAYOUT_PACKAGE)/Info.plist $(WINDOW_LAYOUT_APP)/Contents/Info.plist; \
		printf '%s\n' "$$SOURCE_HASH" > $(WINDOW_LAYOUT_APP)/Contents/Resources/source.sha256; \
		codesign --force --deep --sign - --identifier $(WINDOW_LAYOUT_LABEL) $(WINDOW_LAYOUT_APP); \
	fi
	sed \
		-e 's|__PROGRAM_PATH__|$(WINDOW_LAYOUT_PROGRAM)|g' \
		-e 's|__LOG_PATH__|$(WINDOW_LAYOUT_LOG)|g' \
		$(WINDOW_LAYOUT_PACKAGE)/$(WINDOW_LAYOUT_LABEL).plist > $(WINDOW_LAYOUT_AGENT)
	plutil -lint $(WINDOW_LAYOUT_AGENT)
	launchctl bootstrap gui/$(shell id -u) $(WINDOW_LAYOUT_AGENT)

ts:			## generate karabiner.json (using typescript)
	ts-node --compiler-options '{"module":"commonjs","target":"es2017"}' src/ts/rules.ts
	cp ./app/karabiner.json ~/.config/karabiner/

restart-karabiner:	## restart karabiner user-server forcibly
	launchctl kickstart -k gui/$(shell id -u)/org.pqrs.service.agent.karabiner_console_user_server

ktfmt:			## ktfmt changed files on this branch
	@echo "--- This script will run ktfmt on all changed files"
	@MERGE_BASE=$$(git merge-base HEAD origin/master); \
	MODIFIED_FILES=$$(git diff $$MERGE_BASE --diff-filter=ACMR --name-only --relative -- '*.kt'); \
	for FILE in $$MODIFIED_FILES; do \
		echo "Formatting $$FILE"; \
		ktfmt -F "$$FILE"; \
	done

#restore:
#	git checkout "0ee92ff7689c95381601987653126120008aab9c" -- karabiner.json

ktfmt-all:		## ktfmt all files
	@echo "--- This script will run ktfmt on all changed files"
	@ktfmt -F $(shell find . -name '*.kt')
