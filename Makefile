default: kt

help:			## list out commands with descriptions
	@sed -ne '/@sed/!s/## //p' $(MAKEFILE_LIST)

kt:			## generate karabiner.json (using kotlin)
	./gradlew run
	cp ./app/karabiner.json ~/.config/karabiner/

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
	@echo "--- This script will run ktfmt on all files"
	@ktfmt -F $(shell find . -name '*.kt')
