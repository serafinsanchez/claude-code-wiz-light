#!/bin/bash
set -e

HOOK_DIR="$HOME/.claude/hooks/wiz"
SETTINGS="$HOME/.claude/settings.json"

echo "=== Uninstall WiZ Light for Claude Code ==="
echo ""

# 1. Remove hooks from settings.json
if [ -f "$SETTINGS" ]; then
  echo "Removing hooks from settings.json..."
  python3 -c "
import json

settings_path = '$SETTINGS'
with open(settings_path, 'r') as f:
    settings = json.load(f)

if 'hooks' in settings:
    hooks = settings['hooks']
    for event in list(hooks.keys()):
        hooks[event] = [h for h in hooks[event] if 'wiz' not in json.dumps(h)]
        if not hooks[event]:
            del hooks[event]

with open(settings_path, 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')

print('Hooks removed from settings.')
"
fi

# 2. Remove scripts
if [ -d "$HOOK_DIR" ]; then
  echo "Removing scripts from $HOOK_DIR..."
  rm -rf "$HOOK_DIR"
  echo "Scripts removed."
fi

echo ""
echo "Uninstalled. Your WiZ bulb will no longer respond to Claude Code events."
