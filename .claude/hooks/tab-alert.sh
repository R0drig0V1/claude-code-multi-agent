#!/bin/sh
# Rings the terminal bell on the tab of the Claude session that fired the hook, so
# Terminal.app shows a bell badge on that tab and you can tell which one finished.
# Hook children run without a controlling tty, so walk up the parent chain to the
# first ancestor that has one (the claude process attached to the tab).

pid=$$
while [ -n "$pid" ] && [ "$pid" -gt 1 ]; do
  t=$(ps -o tty= -p "$pid" | tr -d ' ')
  if [ -n "$t" ] && [ "$t" != "??" ]; then printf '\a' > "/dev/$t"; exit 0; fi
  pid=$(ps -o ppid= -p "$pid" | tr -d ' ')
done
exit 0
