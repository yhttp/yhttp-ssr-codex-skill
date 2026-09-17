SKILL_NAME ?= yhttp-ssr
SKILLS_DIR ?= $(if $(CODEX_HOME),$(CODEX_HOME)/skills,$(HOME)/.codex/skills)
INSTALL_DIR ?= $(SKILLS_DIR)/$(SKILL_NAME)
INSTALL_PATH = $(abspath $(INSTALL_DIR))

INSTALL_FILES = SKILL.md README.md LICENSE agents

.PHONY: install uninstall

install:
	@mkdir -p "$(INSTALL_PATH)"
	@cp -R $(INSTALL_FILES) "$(INSTALL_PATH)/"
	@echo "Installed $(SKILL_NAME) to $(INSTALL_PATH)"

uninstall:
	@test -n "$(INSTALL_PATH)"
	@test "$(INSTALL_PATH)" != "/"
	@test "$(INSTALL_PATH)" != "$(CURDIR)"
	@rm -rf -- "$(INSTALL_PATH)"
	@echo "Uninstalled $(SKILL_NAME) from $(INSTALL_PATH)"
