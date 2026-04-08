# Shell Master — сборка standalone и опционально бинарника shc.
#   make / make help — список целей
#   make all           — ./shell-master (нужны shc, cc)
#   make standalone    — shell-master_standalone.sh
#   make clean     — артефакты сборки (+ устаревшие имена game5*)
#   make distclean — то же + quest/ и terminal_game_* в корне репо
#
SHELL := /bin/bash
ROOT  := $(abspath .)

LAUNCHER        := $(ROOT)/bin/shell-master
STANDALONE_SH   := $(ROOT)/shell-master_standalone.sh
COMPILED_BIN    := $(ROOT)/shell-master
GEN             := $(ROOT)/scripts/gen_standalone.sh
PAYLOAD_FILES   := $(shell find $(ROOT)/lib $(ROOT)/levels $(ROOT)/share $(ROOT)/bin -type f 2>/dev/null | sort)

SHC ?= shc

.DEFAULT_GOAL := help

.PHONY: help all clean distclean standalone

help:
	@echo "Shell Master — цели make:"
	@echo ""
	@echo "  make help        Справка (по умолчанию при вызове make без аргументов)."
	@echo "  make all         Собрать ./shell-master через shc (нужны shc и компилятор)."
	@echo "  make standalone  Только ./shell-master_standalone.sh (bash, без shc)."
	@echo "  make clean       Артефакты сборки shc/standalone и старые game5* в корне репо."
	@echo "  make distclean   Как clean + каталоги данных игры: ./quest и ./terminal_game_*."
	@echo ""
	@echo "  Переменная SHC=... задаёт команду shc, если она не в PATH."

all: $(COMPILED_BIN)

standalone: $(STANDALONE_SH)

$(STANDALONE_SH): $(LAUNCHER) $(GEN) $(PAYLOAD_FILES)
	$(GEN) "$(STANDALONE_SH)"
	bash -n "$(STANDALONE_SH)"

$(COMPILED_BIN): $(STANDALONE_SH)
	@command -v $(SHC) >/dev/null || { echo "Нужен shc (пакет shc в дистрибутиве)." >&2; exit 1; }
	$(SHC) -f "$(STANDALONE_SH)" -o "$(COMPILED_BIN)"
	@rm -f "$(STANDALONE_SH).x.c" "$(COMPILED_BIN).x.c" 2>/dev/null || true
	@chmod +x "$(COMPILED_BIN)"
	@echo "Готово: $(COMPILED_BIN)"

clean:
	rm -f "$(STANDALONE_SH)" "$(COMPILED_BIN)" "$(ROOT)/shell-master.x"
	rm -f "$(STANDALONE_SH).x.c" "$(COMPILED_BIN).x.c"
	rm -f "$(ROOT)/game5_standalone.sh" "$(ROOT)/game5" "$(ROOT)/game5.x"
	rm -f "$(ROOT)/game5_standalone.sh.x.c" "$(ROOT)/game5.x.c"

distclean: clean
	rm -rf "$(ROOT)/quest" $(wildcard $(ROOT)/terminal_game_*)
