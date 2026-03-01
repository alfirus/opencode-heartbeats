# OpenCode Heartbeats

Automated heartbeat system for OpenCode AI assistant.

## Overview

This provides periodic "heartbeat" checks for OpenCode, enabling proactive monitoring and notifications without manual prompts.

## What It Does

Every hour, the script runs a rotating check:
- **Hour 0, 4, 8, 12, 16, 20**: Email check (unread count)
- **Hour 1, 5, 9, 13, 17, 21**: Calendar check (upcoming events)
- **Hour 2, 6, 10, 14, 18, 22**: Weather check (KL weather)
- **Hour 3, 7, 11, 15, 19, 23**: Telegram check (placeholder)

## Files

| File | Description |
|------|-------------|
| `heartbeat.sh` | Main heartbeat script |
| `heartbeat-state.json` | Tracks last check times |
| `heartbeat.log` | Log file |
| `heartbeat-prompt.txt` | Generated prompt for OpenCode |

## Installation

### 1. Clone or Copy

```bash
cd ~/Projects
git clone https://github.com/alfirus/opencode-heartbeats.git
```

### 2. Make Executable

```bash
chmod +x ~/Projects/opencode-heartbeats/heartbeat.sh
```

### 3. Set Up Cron (Every Hour)

```bash
crontab -e
```

Add this line:

```
0 * * * * /Users/alfirusahmad/Projects/opencode-heartbeats/heartbeat.sh >> /Users/alfirusahmad/Projects/opencode-heartbeats/cron.log 2>&1
```

### 4. Test

```bash
./heartbeat.sh
```

## Output

The script:
1. Checks system (Mail, Calendar, Weather)
2. Writes result to `heartbeat-prompt.txt`
3. Echoes response (e.g., "📧 You have 5 unread emails" or "HEARTBEAT_OK")

## Integration with OpenCode

To use with OpenCode, you can:
1. Pipe the output to a notification system
2. Use the prompt file for further AI processing
3. Send results to Telegram/Discord

## Requirements

- macOS (for Mail/Calendar integration)
- `jq` (JSON parsing): `brew install jq`
- `curl` (for weather): usually pre-installed
- Optional: `weather` command: `brew install weather`

## Notes

- Telegram check is a placeholder - expand based on your setup
- All times are in Asia/Kuala_Lumpur (GMT+8)
- State file prevents duplicate notifications

---
*Created: 2026-03-01*
