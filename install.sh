#!/bin/bash
set -e

HOOK_DIR="$HOME/.claude/hooks/wiz"
SETTINGS="$HOME/.claude/settings.json"
SCRIPT_DIR="$(cd "$(dirname "$0")/scripts" && pwd)"

echo "=== WiZ Light for Claude Code ==="
echo ""

# 1. Prompt for bulb IP
read -p "Enter your WiZ bulb IP address [192.168.1.248]: " BULB_IP
BULB_IP="${BULB_IP:-192.168.1.248}"

# 2. Test connectivity
echo ""
echo "Testing connection to $BULB_IP..."
RESPONSE=$(echo -n '{"method":"getPilot","params":{}}' | nc -u -w2 "$BULB_IP" 38899 2>/dev/null || true)
if [ -z "$RESPONSE" ]; then
  echo "Warning: No response from $BULB_IP. Make sure:"
  echo "  - Your WiZ bulb is powered on"
  echo "  - You're on the same WiFi network"
  echo "  - The IP address is correct (check the WiZ app)"
  read -p "Continue anyway? [y/N]: " CONTINUE
  if [ "$CONTINUE" != "y" ] && [ "$CONTINUE" != "Y" ]; then
    echo "Aborted."
    exit 1
  fi
else
  echo "Bulb found!"
fi

# 3. Copy scripts
echo ""
echo "Installing scripts to $HOOK_DIR..."
mkdir -p "$HOOK_DIR"
cp "$SCRIPT_DIR/wiz-send.sh" "$HOOK_DIR/"
cp "$SCRIPT_DIR/wiz-on.sh" "$HOOK_DIR/"
cp "$SCRIPT_DIR/wiz-off.sh" "$HOOK_DIR/"
cp "$SCRIPT_DIR/wiz-notify.sh" "$HOOK_DIR/"
cp "$SCRIPT_DIR/wiz-complete.sh" "$HOOK_DIR/"
chmod +x "$HOOK_DIR"/*.sh

# 4. Set the bulb IP in the send script
sed -i '' "s/192.168.1.248/$BULB_IP/g" "$HOOK_DIR/wiz-send.sh"
echo "Scripts installed."

# 5. Configure hooks in settings.json
echo ""
echo "Configuring Claude Code hooks..."

if [ ! -f "$SETTINGS" ]; then
  echo "{}" > "$SETTINGS"
fi

python3 -c "
import json

settings_path = '$SETTINGS'
with open(settings_path, 'r') as f:
    settings = json.load(f)

if 'hooks' not in settings:
    settings['hooks'] = {}

hooks = settings['hooks']

wiz_hooks = {
    'SessionStart': {
        'matcher': 'startup',
        'hooks': [{'type': 'command', 'command': '~/.claude/hooks/wiz/wiz-on.sh', 'timeout': 5}]
    },
    'UserPromptSubmit': {
        'matcher': '',
        'hooks': [{'type': 'command', 'command': '~/.claude/hooks/wiz/wiz-on.sh', 'timeout': 5}]
    },
    'Stop': {
        'hooks': [{'type': 'command', 'command': '~/.claude/hooks/wiz/wiz-off.sh', 'timeout': 5}]
    },
    'Notification': {
        'matcher': '',
        'hooks': [{'type': 'command', 'command': '~/.claude/hooks/wiz/wiz-notify.sh', 'timeout': 5, 'async': True}]
    },
    'TaskCompleted': {
        'matcher': '',
        'hooks': [{'type': 'command', 'command': '~/.claude/hooks/wiz/wiz-complete.sh', 'timeout': 5, 'async': True}]
    }
}

for event, new_hook in wiz_hooks.items():
    if event not in hooks:
        hooks[event] = []
    # Remove any existing wiz hooks (idempotent install)
    hooks[event] = [h for h in hooks[event] if 'wiz' not in json.dumps(h)]
    hooks[event].append(new_hook)

with open(settings_path, 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')

print('Hooks configured.')
"

# 6. Quick test
echo ""
echo "Quick test - turning bulb on..."
"$HOOK_DIR/wiz-on.sh" 2>/dev/null
sleep 2
echo "Turning bulb off..."
"$HOOK_DIR/wiz-off.sh" 2>/dev/null

echo ""
echo "Installation complete! Your WiZ bulb will now respond to Claude Code events."
echo ""
echo "  Bulb ON  = Claude is working"
echo "  Bulb OFF = Claude finished responding"
echo "  Blue     = Notification — persistent blue until the next Claude event"
echo "  Green    = Task completed"
echo ""
echo "To customize colors/brightness, edit the scripts in: $HOOK_DIR"
echo "To uninstall, run: ./uninstall.sh"
