# OpenCode Heartbeats

Automated heartbeat system for OpenCode AI assistant.

## Overview

This provides periodic "heartbeat" checks for OpenCode, enabling proactive monitoring and notifications without manual prompts.

## What It Does

Every hour, the script runs a rotating check:
- **Hour 0, 4, 8, 12, 16, 20**: Email check (unread count)
- **Hour 1, 5, 9, 13, 17, 21**: Calendar check (upcoming events)
- **Hour 2, 6, 10, 14, 18, 22**: Weather check
- **Hour 3, 7, 11, 15, 19, 23**: Telegram check (customizable)

## Quick Start

```bash
# 1. Clone
git clone https://github.com/alfirus/opencode-heartbeats.git
cd opencode-heartbeats

# 2. Make executable
chmod +x heartbeat.sh

# 3. Configure (see below)
# Edit heartbeat.sh to set YOUR paths and settings

# 4. Test
./heartbeat.sh

# 5. Set up cron
crontab -e
# Add: 0 * * * * /path/to/heartbeat.sh >> cron.log 2>&1
```

---

## ⚙️ Configuration Required

Before using, you MUST configure these in `heartbeat.sh`:

### 1. Script Directory
```bash
# Line 8: Set YOUR path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

### 2. Weather Location
```bash
# Line ~113: Change "Kuala+Lumpur" to YOUR city
WEATHER=$(curl -s "wttr.in/YOUR-CITY?format=%c%t+%h" 2>/dev/null)
```

### 3. Calendar Name (macOS)
```bash
# Line ~86: Change "Calendar" to YOUR calendar name
EVENTS=$(osascript -e "tell application \"Calendar\" to get summary of (events of calendar \"YOUR-CALENDAR\" ...")
```

### 4. Telegram Bot (Optional)
To enable Telegram notifications:
1. Create a bot via @BotFather on Telegram
2. Get your bot token
3. Get your chat ID
4. Uncomment and configure the Telegram section in heartbeat.sh

---

## 📋 Configuration Checklist

| Item | Line | Default | Change To |
|------|------|---------|-----------|
| Script path | 8 | Auto-detect | ✅ OK |
| Weather city | ~113 | Kuala+Lumpur | Your city |
| Calendar name | ~86 | Calendar | Your calendar |
| Telegram bot | ~120 | Disabled | Optional |

---

## 🖥️ Platform-Specific Setup

### macOS (Recommended)

**Requirements:**
- macOS (for Mail/Calendar integration)
- `jq`: `brew install jq`
- `curl`: pre-installed

**Email check:** Uses AppleScript to read Mail.app
```bash
UNREAD_COUNT=$(osascript -e 'tell application "Mail" to get unread message count of inbox')
```

**Calendar check:** Uses AppleScript to read Calendar.app
```bash
osascript -e "tell application \"Calendar\" to get summary of events ..."
```

### Linux

**Requirements:**
- `jq`: `sudo apt install jq` or `brew install jq`
- `curl`: pre-installed

**Email check:** Use `offlineimap` or `mutt` instead of AppleScript
```bash
# Example for mutt
UNREAD_COUNT=$(find ~/Maildir/INBOX/new -type f | wc -l)
```

**Calendar check:** Use `gcalcli`
```bash
gcalcli calw
```

### Windows (WSL)

Run within WSL for best compatibility with macOS scripts.

---

## 📁 Files

| File | Description |
|------|-------------|
| `heartbeat.sh` | Main heartbeat script (EDIT THIS) |
| `heartbeat-state.json` | Tracks last check times (auto-generated) |
| `heartbeat.log` | Log file (auto-generated) |
| `heartbeat-prompt.txt` | Generated prompt for OpenCode |
| `README.md` | This file |

---

## 🔔 Notification Options

### Option 1: Terminal Output (Default)
Simply echoes result to stdout.

### Option 2: macOS Notification Center
Add to heartbeat.sh:
```bash
osascript -e 'display notification "You have 5 unread emails" with title "Heartbeat"'
```

### Option 3: Telegram
Uncomment Telegram section and configure:
```bash
curl -s "https://api.telegram.org/botYOUR_TOKEN/sendMessage?chat_id=YOUR_CHAT_ID&text=$RESPONSE"
```

### Option 4: Discord Webhook
```bash
curl -H "Content-Type: application/json" -X POST -d '{"content":"'"$RESPONSE"'"}' YOUR_WEBHOOK_URL
```

---

## ⏰ Cron Setup

### Every Hour (Recommended)
```bash
crontab -e
# Add this line:
0 * * * * /path/to/opencode-heartbeats/heartbeat.sh >> /path/to/opencode-heartbeats/cron.log 2>&1
```

### Every 30 Minutes
```bash
0,30 * * * * /path/to/opencode-heartbeats/heartbeat.sh >> /path/to/opencode-heartbeats/cron.log 2>&1
```

### Every 15 Minutes
```bash
*/15 * * * * /path/to/opencode-heartbeats/heartbeat.sh >> /path/to/opencode-heartbeats/cron.log 2>&1
```

---

## 🧪 Testing

```bash
# Test manually
./heartbeat.sh

# Check log
cat heartbeat.log

# Check state
cat heartbeat-state.json | jq .
```

---

## 🔧 Customization

### Add New Checks

Add new checks in the case statement (around line 70):
```bash
"custom")
    # Your custom check
    RESPONSE="Custom check result"
    # Update state
    STATE=$(cat "$STATE_FILE" | jq ".lastChecks.custom = $TIMESTAMP")
    echo "$STATE" > "$STATE_FILE"
    ;;
```

### Change Check Rotation

Modify `CHECK_ORDER` array (around line 56):
```bash
CHECK_ORDER=("email" "calendar" "weather" "telegram" "custom")
```

### Disable Checks

Edit `heartbeat-state.json`:
```json
{
  "enabledChecks": {
    "email": true,
    "calendar": true,
    "weather": true,
    "telegram": false
  }
}
```

---

## ❓ Troubleshooting

### "jq: command not found"
```bash
brew install jq
```

### "curl: command not found"
```bash
# macOS
brew install curl

# Linux
sudo apt install curl
```

### Calendar not working
- Check calendar name is exact (case-sensitive)
- Grant Calendar access in System Preferences > Security & Privacy

### Email not working
- Grant Mail access in System Preferences > Security & Privacy
- Check Mail.app is not in sandbox mode

---

## 📝 License

MIT - Feel free to use and modify!

---

## 👤 Author

Created by [Alfirus](https://github.com/alfirus)

---

## 🤖 Integrating with AI (OpenCode/Claude)

To make your AI aware of the heartbeat system, add this to your AGENTS.md or CLAUDE.md:

```markdown
## 💓 Heartbeats - OpenCode External Heartbeat System

We use an external heartbeat system for proactive checks:

**Location:** `~/Projects/opencode-heartbeats/`

**What it does:**
- Runs every hour via cron job
- Rotating checks: email → calendar → weather → telegram
- Writes results to `heartbeat-prompt.txt`
- Logs to `heartbeat.log`

**Cron setup:**
```bash
0 * * * * /path/to/opencode-heartbeats/heartbeat.sh >> cron.log 2>&1
```

**Files:**
- `heartbeat.sh` - Main script
- `heartbeat-state.json` - Tracks last check times
- `heartbeat.log` - Log file
- `heartbeat-prompt.txt` - Generated prompt for AI

**How AI uses it:**
1. At startup, check if `heartbeat-prompt.txt` exists
2. Read the file for any pending notifications
3. If content is not "HEARTBEAT_OK", report to user
4. Delete or archive after reporting

**State tracking:**
- Check `heartbeat-state.json` for last check times
- Don't spam - respect quiet hours (23:00-08:00)
```

---

## 📞 Support

- **Issues:** https://github.com/alfirus/opencode-heartbeats/issues
- **Discussions:** https://github.com/alfirus/opencode-heartbeats/discussions

---

*For issues and contributions: https://github.com/alfirus/opencode-heartbeats*
