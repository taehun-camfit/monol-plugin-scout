#!/bin/bash
# Plugin Scout - 로깅 시스템
# 구조화된 로그 기록 및 분석

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}"
DATA_DIR="$PLUGIN_ROOT/data"
LOG_DIR="$DATA_DIR/logs"
LOG_FILE="$LOG_DIR/scout.log"
LOG_LEVEL="${SCOUT_LOG_LEVEL:-INFO}"  # DEBUG, INFO, WARN, ERROR

# 로그 디렉토리 생성
mkdir -p "$LOG_DIR"

# 로그 레벨 숫자 변환
get_level_num() {
  case "$1" in
    DEBUG) echo 0 ;;
    INFO) echo 1 ;;
    WARN) echo 2 ;;
    ERROR) echo 3 ;;
    *) echo 1 ;;
  esac
}

# 현재 로그 레벨 확인
should_log() {
  local msg_level="$1"
  local current_level_num=$(get_level_num "$LOG_LEVEL")
  local msg_level_num=$(get_level_num "$msg_level")

  [ "$msg_level_num" -ge "$current_level_num" ]
}

# 로그 기록
log() {
  local level="$1"
  local message="$2"
  local context="$3"
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # 로그 레벨 필터링
  if ! should_log "$level"; then
    return 0
  fi

  # 로그 포맷: [timestamp] [level] message | context
  local log_line="[$timestamp] [$level] $message"
  if [ -n "$context" ]; then
    log_line="$log_line | $context"
  fi

  # 파일에 기록
  echo "$log_line" >> "$LOG_FILE"

  # DEBUG 모드면 stdout에도 출력
  if [ "$SCOUT_DEBUG" = "true" ]; then
    echo "$log_line"
  fi
}

# 편의 함수들
log_debug() { log "DEBUG" "$1" "$2"; }
log_info() { log "INFO" "$1" "$2"; }
log_warn() { log "WARN" "$1" "$2"; }
log_error() { log "ERROR" "$1" "$2"; }

# 이벤트 로깅 (구조화된 JSON)
log_event() {
  local event_type="$1"
  local event_data="$2"
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local user="${USER:-unknown}"
  local session_id=""

  # 세션 ID 가져오기
  if [ -f "$DATA_DIR/.session" ] && command -v jq &> /dev/null; then
    session_id=$(jq -r '.sessionId // ""' "$DATA_DIR/.session" 2>/dev/null)
  fi

  # JSON 이벤트 로그
  local event_log="$LOG_DIR/events.jsonl"
  echo "{\"timestamp\":\"$timestamp\",\"type\":\"$event_type\",\"user\":\"$user\",\"session\":\"$session_id\",\"data\":$event_data}" >> "$event_log"
}

# 로그 조회
view_logs() {
  local lines="${1:-50}"
  local level="${2:-}"

  if [ ! -f "$LOG_FILE" ]; then
    echo "No logs found"
    return
  fi

  if [ -n "$level" ]; then
    grep "\[$level\]" "$LOG_FILE" | tail -n "$lines"
  else
    tail -n "$lines" "$LOG_FILE"
  fi
}

# 로그 검색
search_logs() {
  local pattern="$1"
  local lines="${2:-20}"

  if [ ! -f "$LOG_FILE" ]; then
    echo "No logs found"
    return
  fi

  grep -i "$pattern" "$LOG_FILE" | tail -n "$lines"
}

# 이벤트 조회
view_events() {
  local count="${1:-20}"
  local event_type="$2"
  local event_log="$LOG_DIR/events.jsonl"

  if [ ! -f "$event_log" ]; then
    echo "No events found"
    return
  fi

  if [ -n "$event_type" ]; then
    grep "\"type\":\"$event_type\"" "$event_log" | tail -n "$count" | jq -r '"\(.timestamp) [\(.type)] \(.data)"'
  else
    tail -n "$count" "$event_log" | jq -r '"\(.timestamp) [\(.type)] \(.data)"'
  fi
}

# 로그 통계
log_stats() {
  echo "=== Log Statistics ==="
  echo ""

  if [ -f "$LOG_FILE" ]; then
    echo "Log File: $LOG_FILE"
    echo "Log Level: $LOG_LEVEL"
    echo ""
    echo "By Level:"
    for level in DEBUG INFO WARN ERROR; do
      local count=$(grep -c "\[$level\]" "$LOG_FILE" 2>/dev/null || echo "0")
      echo "  $level: $count"
    done
    echo ""
    echo "Total Lines: $(wc -l < "$LOG_FILE" | tr -d ' ')"
    echo "File Size: $(du -h "$LOG_FILE" | cut -f1)"
  else
    echo "No log file found"
  fi

  echo ""
  local event_log="$LOG_DIR/events.jsonl"
  if [ -f "$event_log" ]; then
    echo "Events:"
    echo "  Total: $(wc -l < "$event_log" | tr -d ' ')"
    if command -v jq &> /dev/null; then
      echo "  By Type:"
      jq -r '.type' "$event_log" 2>/dev/null | sort | uniq -c | sort -rn | head -5 | while read count type; do
        echo "    $type: $count"
      done
    fi
  fi
}

# 로그 정리 (오래된 로그 삭제)
cleanup_logs() {
  local days="${1:-30}"

  echo "Cleaning logs older than $days days..."

  # 메인 로그 로테이션
  if [ -f "$LOG_FILE" ]; then
    local cutoff_date=$(date -v-${days}d +"%Y-%m-%d" 2>/dev/null || date -d "$days days ago" +"%Y-%m-%d" 2>/dev/null)
    if [ -n "$cutoff_date" ]; then
      # 백업 후 정리
      cp "$LOG_FILE" "$LOG_FILE.bak"
      grep -E "^\[${cutoff_date}|^\[$(date +%Y-)" "$LOG_FILE.bak" > "$LOG_FILE" 2>/dev/null || true
      rm -f "$LOG_FILE.bak"
      echo "Main log cleaned"
    fi
  fi

  # 이벤트 로그 정리
  local event_log="$LOG_DIR/events.jsonl"
  if [ -f "$event_log" ] && command -v jq &> /dev/null; then
    local cutoff_ts=$(date -v-${days}d -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -d "$days days ago" -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
    if [ -n "$cutoff_ts" ]; then
      cp "$event_log" "$event_log.bak"
      jq -c --arg ts "$cutoff_ts" 'select(.timestamp >= $ts)' "$event_log.bak" > "$event_log" 2>/dev/null || true
      rm -f "$event_log.bak"
      echo "Event log cleaned"
    fi
  fi

  echo "Done"
}

# 로그 파일 초기화
clear_logs() {
  rm -f "$LOG_FILE"
  rm -f "$LOG_DIR/events.jsonl"
  echo "Logs cleared"
}

# CLI 인터페이스
case "$1" in
  debug)
    log_debug "$2" "$3"
    ;;
  info)
    log_info "$2" "$3"
    ;;
  warn)
    log_warn "$2" "$3"
    ;;
  error)
    log_error "$2" "$3"
    ;;
  event)
    log_event "$2" "$3"
    ;;
  view)
    view_logs "$2" "$3"
    ;;
  search)
    search_logs "$2" "$3"
    ;;
  events)
    view_events "$2" "$3"
    ;;
  stats)
    log_stats
    ;;
  cleanup)
    cleanup_logs "$2"
    ;;
  clear)
    clear_logs
    ;;
  *)
    echo "Usage: $0 {debug|info|warn|error|event|view|search|events|stats|cleanup|clear}"
    echo ""
    echo "Commands:"
    echo "  debug <msg> [ctx]      - Log debug message"
    echo "  info <msg> [ctx]       - Log info message"
    echo "  warn <msg> [ctx]       - Log warning message"
    echo "  error <msg> [ctx]      - Log error message"
    echo "  event <type> <json>    - Log structured event"
    echo "  view [lines] [level]   - View recent logs"
    echo "  search <pattern>       - Search logs"
    echo "  events [count] [type]  - View events"
    echo "  stats                  - Show log statistics"
    echo "  cleanup [days]         - Clean old logs"
    echo "  clear                  - Clear all logs"
    echo ""
    echo "Environment:"
    echo "  SCOUT_LOG_LEVEL        - Set log level (DEBUG, INFO, WARN, ERROR)"
    echo "  SCOUT_DEBUG            - Enable debug output to stdout"
    ;;
esac
