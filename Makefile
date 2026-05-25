POLYBAR_DIR = $(HOME)/.config/polybar

.PHONY: all polybar

all: polybar

polybar:
	mkdir -p $(POLYBAR_DIR)
	cp polybar/config.ini $(POLYBAR_DIR)/config.ini
	cp polybar/dropbox-status.sh $(POLYBAR_DIR)/dropbox-status.sh
	chmod +x $(POLYBAR_DIR)/dropbox-status.sh
