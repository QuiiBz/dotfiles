#!/usr/bin/env bash

# https://github.com/nikitabobko/AeroSpace/issues/2#issuecomment-3023036984
current_workspace=$(/usr/local/bin/aerospace list-workspaces --focused)
/usr/local/bin/aerospace list-windows --all | grep -E "(AI Chat)" | awk '{print $1}' | while read window_id; do
    if [ -n "$window_id" ]; then
        /usr/local/bin/aerospace move-node-to-workspace --window-id "$window_id" "$current_workspace"
    fi
done
