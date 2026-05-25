#!/bin/bash
CITY_FILE=$HOME/.config/polybar/date-city
[ -f "$CITY_FILE" ] || echo "Europe/London" > "$CITY_FILE"
TZ_NAME=$(cat "$CITY_FILE")
CITY="${TZ_NAME##*/}"
CITY="${CITY//_/ }"
TZ="$TZ_NAME" date "+$CITY %H:%M"
