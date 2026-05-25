#!/bin/bash
status=$(/home/vxe/bin/dropbox status 2>/dev/null | head -1)
case "$status" in
  "Up to date")              echo "DB ok" ;;
  *"yncing"*|*"pload"*|*"ownload"*) echo "DB sync" ;;
  *"sn't running"*|*"ot running"*)  echo "DB --" ;;
  *)                         echo "DB ..." ;;
esac
