#!/bin/bash
# Plugin Scout - 추천 컨트롤러
# 추천 빈도, 무음 모드, 스마트 타이밍 관리

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}"
DATA_DIR="$PLUGIN_ROOT/data"
HISTORY_FILE="$DATA_DIR/history.json"
SESSION_FILE="$DATA_DIR/.session"
RECOMMENDATION_LOG="$DATA_DIR/.recommendations"

# 무음 모드 설정
set_quiet_mode() {
  local mode="$1"  # on, off, toggle

  if [ ! -f "$HISTORY_FILE" ]; then
    echo "History file not found"
    return 1
  fi

  if ! command -v jq &> /dev/null; then
    echo "jq required"
    return 1
  fi

  local current=$(jq -r '.preferences.quietMode // false' "$HISTORY_FILE")

  case "$mode" in
    on)
      jq '.preferences.quietMode = true' "$HISTORY_FILE" > "$HISTORY_FILE.tmp" && mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
      echo "Quiet mode enabled. No recommendations will be shown."
      ;;
    off)
      jq '.preferences.quietMode = false' "$HISTORY_FILE" > "$HISTORY_FILE.tmp" && mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
      echo "Quiet mode disabled. Recommendations will be shown."
      ;;
    toggle)
      if [ "$current" = "true" ]; then
        jq '.preferences.quietMode = false' "$HISTORY_FILE" > "$HISTORY_FILE.tmp" && mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
        echo "Quiet mode disabled."
      else
        jq '.preferences.quietMode = true' "$HISTORY_FILE" > "$HISTORY_FILE.tmp" && mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
        echo "Quiet mode enabled."
      fi
      ;;
    status)
      if [ "$current" = "true" ]; then
        echo "on"
      else
        echo "off"
      fi
      ;;
  esac
}

# 추천 가능 여부 확인 (빈도 제한)
can_show_recommendation() {
  local limit_type="${1:-session}"  # session, daily, weekly

  # 무음 모드 확인
  if [ -f "$HISTORY_FILE" ] && command -v jq &> /dev/null; then
    local quiet=$(jq -r '.preferences.quietMode // false' "$HISTORY_FILE")
    if [ "$quiet" = "true" ]; then
      echo "blocked:quiet_mode"
      return
    fi
  fi

  # 추천 로그 확인
  if [ ! -f "$RECOMMENDATION_LOG" ]; then
    echo "true"
    return
  fi

  local today=$(date +"%Y-%m-%d")
  local session_id=""
  if [ -f "$SESSION_FILE" ]; then
    session_id=$(jq -r '.sessionId // ""' "$SESSION_FILE" 2>/dev/null)
  fi

  case "$limit_type" in
    session)
      # 세션당 1회 제한
      local session_count=$(grep -c "session:$session_id" "$RECOMMENDATION_LOG" 2>/dev/null || echo "0")
      local max_per_session=$(jq -r '.preferences.maxRecommendationsPerSession // 1' "$HISTORY_FILE" 2>/dev/null || echo "1")
      if [ "$session_count" -ge "$max_per_session" ]; then
        echo "blocked:session_limit"
        return
      fi
      ;;
    daily)
      # 하루 N회 제한
      local daily_count=$(grep -c "date:$today" "$RECOMMENDATION_LOG" 2>/dev/null || echo "0")
      local max_per_day=$(jq -r '.preferences.maxRecommendationsPerDay // 3' "$HISTORY_FILE" 2>/dev/null || echo "3")
      if [ "$daily_count" -ge "$max_per_day" ]; then
        echo "blocked:daily_limit"
        return
      fi
      ;;
  esac

  echo "true"
}

# 추천 기록
record_recommendation() {
  local plugin_count="$1"
  local trigger="$2"  # post-task, manual, auto

  local today=$(date +"%Y-%m-%d")
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local session_id=""

  if [ -f "$SESSION_FILE" ]; then
    session_id=$(jq -r '.sessionId // ""' "$SESSION_FILE" 2>/dev/null)
  fi

  echo "date:$today session:$session_id time:$timestamp count:$plugin_count trigger:$trigger" >> "$RECOMMENDATION_LOG"
}

# 스마트 타이밍 체크
check_timing() {
  local event="$1"  # commit, pr, task-complete

  if [ ! -f "$HISTORY_FILE" ] || ! command -v jq &> /dev/null; then
    echo "true"
    return
  fi

  local smart_timing=$(jq -r '.preferences.smartTiming // {}' "$HISTORY_FILE")
  local only_after_commit=$(echo "$smart_timing" | jq -r '.onlyAfterCommit // false')
  local only_after_pr=$(echo "$smart_timing" | jq -r '.onlyAfterPR // false')

  # 특정 이벤트 후에만 추천하도록 설정된 경우
  if [ "$only_after_commit" = "true" ] && [ "$event" != "commit" ]; then
    echo "blocked:not_after_commit"
    return
  fi

  if [ "$only_after_pr" = "true" ] && [ "$event" != "pr" ]; then
    echo "blocked:not_after_pr"
    return
  fi

  echo "true"
}

# 미니 모드 출력
show_mini_notification() {
  local count="$1"

  if [ "$count" -eq 0 ]; then
    return
  fi

  echo "💡 $count개의 플러그인 추천이 있습니다. \`/scout\`로 확인하세요."
}

# 추천 빈도 설정
set_frequency() {
  local key="$1"
  local value="$2"

  if [ ! -f "$HISTORY_FILE" ] || ! command -v jq &> /dev/null; then
    echo "Error: history file or jq not found"
    return 1
  fi

  case "$key" in
    session)
      jq --argjson val "$value" '.preferences.maxRecommendationsPerSession = $val' "$HISTORY_FILE" > "$HISTORY_FILE.tmp" && mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
      echo "Max recommendations per session: $value"
      ;;
    daily)
      jq --argjson val "$value" '.preferences.maxRecommendationsPerDay = $val' "$HISTORY_FILE" > "$HISTORY_FILE.tmp" && mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
      echo "Max recommendations per day: $value"
      ;;
    cooldown)
      jq --argjson val "$value" '.preferences.recommendationCooldown = $val' "$HISTORY_FILE" > "$HISTORY_FILE.tmp" && mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
      echo "Recommendation cooldown: $value minutes"
      ;;
  esac
}

# 스마트 타이밍 설정
set_smart_timing() {
  local key="$1"
  local value="$2"

  if [ ! -f "$HISTORY_FILE" ] || ! command -v jq &> /dev/null; then
    echo "Error: history file or jq not found"
    return 1
  fi

  case "$key" in
    after-commit)
      jq --argjson val "$value" '.preferences.smartTiming.onlyAfterCommit = $val' "$HISTORY_FILE" > "$HISTORY_FILE.tmp" && mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
      echo "Only recommend after commit: $value"
      ;;
    after-pr)
      jq --argjson val "$value" '.preferences.smartTiming.onlyAfterPR = $val' "$HISTORY_FILE" > "$HISTORY_FILE.tmp" && mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
      echo "Only recommend after PR: $value"
      ;;
  esac
}

# 추천 로그 정리 (7일 이상 된 기록 삭제)
cleanup_logs() {
  if [ ! -f "$RECOMMENDATION_LOG" ]; then
    return
  fi

  local week_ago=$(date -v-7d +"%Y-%m-%d" 2>/dev/null || date -d "7 days ago" +"%Y-%m-%d" 2>/dev/null)

  if [ -n "$week_ago" ]; then
    grep -v "date:$week_ago" "$RECOMMENDATION_LOG" | grep -v "date:$(date -v-8d +%Y-%m-%d 2>/dev/null)" > "$RECOMMENDATION_LOG.tmp" 2>/dev/null
    mv "$RECOMMENDATION_LOG.tmp" "$RECOMMENDATION_LOG" 2>/dev/null
  fi
}

# 상태 요약
status() {
  echo "=== Recommendation Controller Status ==="
  echo ""

  if [ -f "$HISTORY_FILE" ] && command -v jq &> /dev/null; then
    local quiet=$(jq -r '.preferences.quietMode // false' "$HISTORY_FILE")
    local max_session=$(jq -r '.preferences.maxRecommendationsPerSession // 1' "$HISTORY_FILE")
    local max_daily=$(jq -r '.preferences.maxRecommendationsPerDay // 3' "$HISTORY_FILE")
    local cooldown=$(jq -r '.preferences.recommendationCooldown // 30' "$HISTORY_FILE")

    echo "Quiet Mode: $quiet"
    echo "Max per Session: $max_session"
    echo "Max per Day: $max_daily"
    echo "Cooldown: $cooldown min"
    echo ""

    if [ -f "$RECOMMENDATION_LOG" ]; then
      local today=$(date +"%Y-%m-%d")
      local today_count=$(grep -c "date:$today" "$RECOMMENDATION_LOG" 2>/dev/null || echo "0")
      echo "Today's Recommendations: $today_count"
    fi
  else
    echo "Configuration not available"
  fi
}

# CLI 인터페이스
case "$1" in
  quiet)
    set_quiet_mode "${2:-status}"
    ;;
  can-recommend)
    can_show_recommendation "${2:-session}"
    ;;
  record)
    record_recommendation "$2" "$3"
    ;;
  timing)
    check_timing "$2"
    ;;
  mini)
    show_mini_notification "$2"
    ;;
  frequency)
    set_frequency "$2" "$3"
    ;;
  smart-timing)
    set_smart_timing "$2" "$3"
    ;;
  cleanup)
    cleanup_logs
    ;;
  status)
    status
    ;;
  *)
    echo "Usage: $0 {quiet|can-recommend|record|timing|mini|frequency|smart-timing|cleanup|status}"
    echo ""
    echo "Commands:"
    echo "  quiet [on|off|toggle|status]      - Set quiet mode"
    echo "  can-recommend [session|daily]     - Check if can show recommendation"
    echo "  record <count> <trigger>          - Record a recommendation"
    echo "  timing <event>                    - Check smart timing"
    echo "  mini <count>                      - Show mini notification"
    echo "  frequency <session|daily> <value> - Set frequency limit"
    echo "  smart-timing <key> <value>        - Set smart timing"
    echo "  cleanup                           - Clean old logs"
    echo "  status                            - Show status"
    ;;
esac
