# Сборка: упакованный скрипт и опционально бинарник shc.
#
#   make            → ./game5 (нужны shc, cc)
#   make standalone → game5_standalone.sh
#   make clean
#
SHELL := /bin/bash
ROOT  := $(abspath .)

LAUNCHER        := $(ROOT)/bin/game5
STANDALONE_SH   := $(ROOT)/game5_standalone.sh
GAME5_BIN       := $(ROOT)/game5
GEN             := $(ROOT)/scripts/gen_standalone.sh
PAYLOAD_FILES   := $(shell find $(ROOT)/lib $(ROOT)/levels $(ROOT)/share $(ROOT)/bin -type f 2>/dev/null | sort)

SHC ?= shc

.PHONY: all clean standalone

all: $(GAME5_BIN)

standalone: $(STANDALONE_SH)

$(STANDALONE_SH): $(LAUNCHER) $(GEN) $(PAYLOAD_FILES)
	$(GEN) "$(STANDALONE_SH)"
	bash -n "$(STANDALONE_SH)"

$(GAME5_BIN): $(STANDALONE_SH)
	@command -v $(SHC) >/dev/null || { echo "Нужен shc (пакет shc в дистрибутиве)." >&2; exit 1; }
	$(SHC) -f "$(STANDALONE_SH)" -o "$(GAME5_BIN)"
	@rm -f "$(STANDALONE_SH).x.c" "$(GAME5_BIN).x.c" 2>/dev/null || true
	@chmod +x "$(GAME5_BIN)"
	@echo "Готово: $(GAME5_BIN)"

clean:
	rm -f "$(STANDALONE_SH)" "$(GAME5_BIN)" "$(STANDALONE_SH).x.c" "$(GAME5_BIN).x.c"
