# WiZ Light for Claude Code

Turn your [WiZ smart bulb](https://www.wizconnected.com/) into a real-time activity indicator for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

The bulb lights up when Claude is working, turns off when it's done, flashes blue for notifications, and flashes green when tasks complete.

## How It Works

Uses [Claude Code hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) to trigger bash scripts that send UDP commands directly to your WiZ bulb on the local network. Zero external dependencies — just `netcat` (pre-installed on macOS/Linux).

| Claude Code Event | Bulb Behavior |
|---|---|
| You send a prompt | Warm white ON (2700K, 80%) |
| Claude finishes responding | OFF |
| Notification (waiting for input) | Blue flash, then warm white |
| Task completed | Green flash, then warm white |

## Requirements

- A [WiZ](https://www.wizconnected.com/) smart bulb on the same WiFi network
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- macOS or Linux (uses `nc` for UDP)

## Install

```bash
git clone https://github.com/yourusername/wiz-light-claude.git
cd wiz-light-claude
./install.sh
```

The installer will:
1. Ask for your bulb's IP address (find it in the WiZ app under Device Info)
2. Test the connection
3. Copy scripts to `~/.claude/hooks/wiz/`
4. Add hooks to your Claude Code settings
5. Run a quick on/off test

## Uninstall

```bash
./uninstall.sh
```

Removes the scripts and hook configuration. Your other Claude Code hooks are preserved.

## Finding Your Bulb's IP Address

Open the **WiZ app** > tap your bulb > **Settings** (gear icon) > **Device info** > look for **IP address**.

## Customization

Edit the installed scripts in `~/.claude/hooks/wiz/` to change behavior:

### Change the working light color/brightness

Edit `~/.claude/hooks/wiz/wiz-on.sh`:

```bash
# Warm white at 80%
'{"id":1,"method":"setPilot","params":{"state":true,"temp":2700,"dimming":80}}'

# Cool daylight at full brightness
'{"id":1,"method":"setPilot","params":{"state":true,"temp":6200,"dimming":100}}'

# Custom RGB color (purple)
'{"id":1,"method":"setPilot","params":{"state":true,"r":128,"g":0,"b":255,"dimming":100}}'
```

### Change notification/completion colors

Edit `wiz-notify.sh` or `wiz-complete.sh` — modify the RGB values in the first `setPilot` call.

### Change the bulb IP

Edit `~/.claude/hooks/wiz/wiz-send.sh` and update the default IP, or set the `WIZ_BULB_IP` environment variable:

```bash
export WIZ_BULB_IP=192.168.1.100
```

### Available parameters

| Parameter | Range | Description |
|---|---|---|
| `state` | `true`/`false` | Power on/off |
| `temp` | 2200-6200 | Color temperature in Kelvin |
| `dimming` | 10-100 | Brightness percentage |
| `r`, `g`, `b` | 0-255 | RGB color values |
| `sceneId` | 1-35 | Built-in light scenes |
| `speed` | 10-200 | Dynamic scene speed |

## How It Works (Technical)

WiZ bulbs run a local UDP server on port 38899 that accepts JSON commands — no cloud, no authentication, no API keys. The scripts use `netcat` to send single UDP packets:

```bash
echo -n '{"id":1,"method":"setPilot","params":{"state":true}}' | nc -u -w1 192.168.1.248 38899
```

Claude Code [hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) are configured in `~/.claude/settings.json` to run these scripts on lifecycle events like `SessionStart`, `Stop`, `Notification`, etc.

## Troubleshooting

**Bulb doesn't respond:**
- Verify the IP: open the WiZ app > Device Info
- Check you're on the same WiFi network
- Test manually: `~/.claude/hooks/wiz/wiz-on.sh`

**Bulb IP changed:**
- WiZ bulbs get IPs via DHCP, so the IP may change. Set a static IP/DHCP reservation in your router, or update `~/.claude/hooks/wiz/wiz-send.sh`.

**Scripts work manually but not via hooks:**
- Run `claude --debug` to see hook execution logs
- Check `~/.claude/settings.json` is valid JSON

## License

MIT
