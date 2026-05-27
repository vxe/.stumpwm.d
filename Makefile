POLYBAR_DIR = $(HOME)/.config/polybar

.PHONY: all polybar

all: polybar

polybar:
	mkdir -p $(POLYBAR_DIR)
	cp polybar/config.ini $(POLYBAR_DIR)/config.ini
	cp polybar/date-display.sh $(POLYBAR_DIR)/date-display.sh
	chmod +x $(POLYBAR_DIR)/date-display.sh
