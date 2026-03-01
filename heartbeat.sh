#!/bin/bash

# OpenCode Heartbeat Script
# Runs every hour to perform proactive checks
# 
# Usage: ./heartbeat.sh
#
# What it does:
# 1. Reads heartbeat-state.json to track last check times
# 2. Performs proactive checks (email, calendar, weather, etc.)
# 3. Updates state file
# 4. Reports findings or replies HEARTBEAT_OK

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_FILE="$SCRIPT_DIR/heartbeat-state.json"
LOG_FILE="$SCRIPT_DIR/heartbeat.log"
OPENCODE_PROMPT="$SCRIPT_DIR/heartbeat-prompt.txt"

# Get current timestamp
TIMESTAMP=$(date +%s)
DATE=$(date "+%Y-%m-%d %H:%M:%S")

# Log function
log() {
    echo "[$DATE] $1" >> "$LOG_FILE"
}

# Check if state file exists, create if not
if [ ! -f "$STATE_FILE" ]; then
    cat > "$STATE_FILE" << 'EOF'
{
  "lastChecks": {
    "email": null,
    "calendar": null,
    "weather": null,
    "telegram": null
  },
  "enabledChecks": {
    "email": true,
    "calendar": true,
    "weather": true,
    "telegram": true
  }
}
EOF
    log "Created new state file"
fi

# Read state file
LAST_EMAIL=$(jq -r '.lastChecks.email // null' "$STATE_FILE")
LAST_CALENDAR=$(jq -r '.lastChecks.calendar // null' "$STATE_FILE")
LAST_WEATHER=$(jq -r '.lastChecks.weather // null' "$STATE_FILE")
LAST_TELEGRAM=$(jq -r '.lastChecks.telegram // null' "$STATE_FILE")

log "Heartbeat triggered. Last checks - Email: $LAST_EMAIL, Calendar: $LAST_CALENDAR, Weather: $LAST_WEATHER, Telegram: $LAST_TELEGRAM"

# Determine which check to run this hour
# Rotate: email → calendar → weather → telegram → repeat
CHECK_ORDER=("email" "calendar" "weather" "telegram")
CURRENT_HOUR=$(date +%H)
CHECK_INDEX=$((CURRENT_HOUR % 4))
CHECK_TO_RUN=${CHECK_ORDER[$CHECK_INDEX]}

log "Running check: $CHECK_TO_RUN"

# Perform the check and generate prompt response
RESPONSE=""

case $CHECK_TO_RUN in
    "email")
        # Check for unread emails (using macOS mail)
        UNREAD_COUNT=$(osascript -e 'tell application "Mail" to get unread message count of inbox' 2>/dev/null || echo "0")
        if [ "$UNREAD_COUNT" -gt 0 ]; then
            RESPONSE="📧 You have $UNREAD_COUNT unread email(s) in your inbox."
            # Update timestamp
            STATE=$(cat "$STATE_FILE" | jq ".lastChecks.email = $TIMESTAMP")
            echo "$STATE" > "$STATE_FILE"
        else
            RESPONSE="HEARTBEAT_OK"
        fi
        ;;
    "calendar")
        # Check calendar for upcoming events
        TODAY=$(date +"%Y-%m-%d")
        TOMORROW=$(date -v+1d +"%Y-%m-%d")
        EVENTS=$(osascript -e "tell application \"Calendar\" to get summary of (events of calendar \"Calendar\" whose start date > date \"$TODAY\" and start date < date \"$TOMORROW\")" 2>/dev/null | head -5)
        if [ -n "$EVENTS" ]; then
            RESPONSE="📅 Upcoming today: $EVENTS"
            STATE=$(cat "$STATE_FILE" | jq ".lastChecks.calendar = $TIMESTAMP")
            echo "$STATE" > "$STATE_FILE"
        else
            RESPONSE="HEARTBEAT_OK"
        fi
        ;;
    "weather")
        # Check weather (requires weather command or wttr.in)
        if command -v weather &> /dev/null; then
            WEATHER=$(weather 2>/dev/null | head -3)
        elif [ -f /usr/local/bin/weather ]; then
            WEATHER=$(/usr/local/bin/weather 2>/dev/null | head -3)
        else
            WEATHER=$(curl -s "wttr.in/Kuala+Lumpur?format=%c%t+%h" 2>/dev/null)
        fi
        if [ -n "$WEATHER" ]; then
            RESPONSE="🌤️ Weather in KL: $WEATHER"
            STATE=$(cat "$STATE_FILE" | jq ".lastChecks.weather = $TIMESTAMP")
            echo "$STATE" > "$STATE_FILE"
        else
            RESPONSE="HEARTBEAT_OK"
        fi
        ;;
    "telegram")
        # Check for Telegram messages (if telegram-cli or similar exists)
        # This is a placeholder - can be expanded based on your Telegram setup
        RESPONSE="HEARTBEAT_OK"
        ;;
    *)
        RESPONSE="HEARTBEAT_OK"
        ;;
esac

# If no response generated, set default
if [ -z "$RESPONSE" ]; then
    RESPONSE="HEARTBEAT_OK"
fi

# Write prompt file for OpenCode
cat > "$OPENCODE_PROMPT" << EOF
# Heartbeat Check

Current time: $(date "+%Y-%m-%d %H:%M:%S")

Last check results: $RESPONSE

Respond appropriately:
- If there are items to report, share them concisely
- If nothing important (HEARTBEAT_OK), just reply "HEARTBEAT_OK"

Do NOT perform any tasks. Just report status.
EOF

log "Heartbeat complete. Response: $RESPONSE"

# Echo response
echo "$RESPONSE"
