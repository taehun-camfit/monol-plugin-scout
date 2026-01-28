#!/bin/bash
# Plugin Scout - 에러 처리 유틸리티
# 에러 로깅, 복구, 알림

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}"
DATA_DIR="$PLUGIN_ROOT/data"
LOG_DIR="$DATA_DIR/logs"
ERROR_LOG="$LOG_DIR/error.log"

# 로그 디렉토리 생성
mkdir -p "$LOG_DIR"

# 에러 코드 정의 (bash 3.x 호환)
get_error_message() {
  local code="$1"
  case "$code" in
    E001) echo "jq not found" ;;
    E002) echo "Invalid JSON file" ;;
    E003) echo "File not found" ;;
    E004) echo "Permission denied" ;;
    E005) echo "Network error" ;;
    E006) echo "Data corruption" ;;
    E007) echo "Unknown error" ;;
    *) echo "Unknown error" ;;
  esac
}

# 에러 로그 기록
log_error() {
  local code="$1"
  local default_msg=$(get_error_message "$code")
  local message="${2:-$default_msg}"
  local context="$3"
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # 로그 파일에 기록
  echo "[$timestamp] [$code] $message ${context:+| Context: $context}" >> "$ERROR_LOG"

  # stderr로도 출력 (디버깅용)
  if [ "$SCOUT_DEBUG" = "true" ]; then
    echo "ERROR [$code]: $message" >&2
  fi
}

# 에러 처리 및 복구 시도
handle_error() {
  local code="$1"
  local context="$2"

  log_error "$code" "" "$context"

  case "$code" in
    E001)
      echo "jq is required. Install with: brew install jq"
      return 1
      ;;
    E002)
      # Invalid JSON - 복구 시도
      echo "Attempting to recover invalid JSON..."
      if [ -f "$PLUGIN_ROOT/lib/data-validator.sh" ]; then
        bash "$PLUGIN_ROOT/lib/data-validator.sh" repair all
      fi
      ;;
    E003)
      # File not found - 초기화
      echo "File not found. Initializing..."
      if [ -f "$PLUGIN_ROOT/lib/data-validator.sh" ]; then
        bash "$PLUGIN_ROOT/lib/data-validator.sh" init history
        bash "$PLUGIN_ROOT/lib/data-validator.sh" init usage
      fi
      ;;
    E004)
      echo "Permission denied. Check file permissions."
      return 1
      ;;
    E005)
      echo "Network error. Will retry later."
      return 1
      ;;
    E006)
      echo "Data corruption detected. Attempting recovery..."
      if [ -f "$PLUGIN_ROOT/lib/data-validator.sh" ]; then
        bash "$PLUGIN_ROOT/lib/data-validator.sh" repair all
      fi
      ;;
    *)
      echo "Unknown error: $code"
      return 1
      ;;
  esac
}

# 안전한 JSON 읽기
safe_json_read() {
  local file="$1"
  local query="${2:-.}"
  local default="${3:-null}"

  if [ ! -f "$file" ]; then
    log_error "E003" "File not found" "$file"
    echo "$default"
    return 1
  fi

  if ! command -v jq &> /dev/null; then
    log_error "E001" "jq not found"
    echo "$default"
    return 1
  fi

  local result
  result=$(jq -r "$query" "$file" 2>/dev/null)
  local exit_code=$?

  if [ $exit_code -ne 0 ] || [ "$result" = "null" ] && [ "$default" != "null" ]; then
    log_error "E002" "JSON read failed" "$file: $query"
    echo "$default"
    return 1
  fi

  echo "$result"
}

# 안전한 JSON 쓰기
safe_json_write() {
  local file="$1"
  local query="$2"

  if ! command -v jq &> /dev/null; then
    log_error "E001" "jq not found"
    return 1
  fi

  if [ ! -f "$file" ]; then
    log_error "E003" "File not found" "$file"
    return 1
  fi

  local temp_file="${file}.tmp"

  if ! jq "$query" "$file" > "$temp_file" 2>/dev/null; then
    log_error "E002" "JSON write failed" "$file: $query"
    rm -f "$temp_file"
    return 1
  fi

  if ! mv "$temp_file" "$file"; then
    log_error "E004" "Permission denied" "$file"
    rm -f "$temp_file"
    return 1
  fi

  return 0
}

# 에러 로그 조회
view_errors() {
  local lines="${1:-20}"

  if [ ! -f "$ERROR_LOG" ]; then
    echo "No errors logged yet."
    return
  fi

  echo "=== Recent Errors (last $lines) ==="
  tail -n "$lines" "$ERROR_LOG"
}

# 에러 로그 정리
cleanup_errors() {
  local days="${1:-7}"

  if [ ! -f "$ERROR_LOG" ]; then
    echo "No error log to clean."
    return
  fi

  local cutoff_date=$(date -v-${days}d +"%Y-%m-%d" 2>/dev/null || date -d "$days days ago" +"%Y-%m-%d" 2>/dev/null)

  if [ -n "$cutoff_date" ]; then
    # 날짜 이후 로그만 유지
    grep -E "^\[${cutoff_date}|^\[$(date +%Y-)" "$ERROR_LOG" > "$ERROR_LOG.tmp" 2>/dev/null
    mv "$ERROR_LOG.tmp" "$ERROR_LOG"
    echo "Cleaned errors older than $days days."
  else
    echo "Could not determine cutoff date."
  fi
}

# 에러 통계
error_stats() {
  if [ ! -f "$ERROR_LOG" ]; then
    echo "No errors logged yet."
    return
  fi

  echo "=== Error Statistics ==="
  echo ""
  echo "By Error Code:"
  grep -oE '\[E[0-9]+\]' "$ERROR_LOG" | sort | uniq -c | sort -rn
  echo ""
  echo "By Date:"
  grep -oE '^\[[0-9]{4}-[0-9]{2}-[0-9]{2}' "$ERROR_LOG" | sort | uniq -c | tail -7
  echo ""
  echo "Total Errors: $(wc -l < "$ERROR_LOG" | tr -d ' ')"
}

# 시스템 상태 확인
health_check() {
  echo "=== Health Check ==="
  echo ""

  # jq 확인
  echo -n "jq: "
  if command -v jq &> /dev/null; then
    echo "OK ($(jq --version))"
  else
    echo "NOT FOUND"
  fi

  # 데이터 디렉토리 확인
  echo -n "Data directory: "
  if [ -d "$DATA_DIR" ] && [ -w "$DATA_DIR" ]; then
    echo "OK (writable)"
  else
    echo "ERROR (not writable)"
  fi

  # JSON 파일 확인
  echo ""
  echo "Data Files:"
  for file in history.json usage.json team.json; do
    echo -n "  $file: "
    if [ -f "$DATA_DIR/$file" ]; then
      if jq empty "$DATA_DIR/$file" 2>/dev/null; then
        echo "OK"
      else
        echo "INVALID JSON"
      fi
    else
      echo "NOT FOUND"
    fi
  done

  # 최근 에러 확인
  echo ""
  echo -n "Recent errors (24h): "
  if [ -f "$ERROR_LOG" ]; then
    local today=$(date +"%Y-%m-%d")
    local count=$(grep -c "^\[$today" "$ERROR_LOG" 2>/dev/null || echo "0")
    echo "$count"
  else
    echo "0"
  fi
}

# CLI 인터페이스
case "$1" in
  log)
    log_error "$2" "$3" "$4"
    ;;
  handle)
    handle_error "$2" "$3"
    ;;
  read)
    safe_json_read "$2" "$3" "$4"
    ;;
  write)
    safe_json_write "$2" "$3"
    ;;
  view)
    view_errors "$2"
    ;;
  cleanup)
    cleanup_errors "$2"
    ;;
  stats)
    error_stats
    ;;
  health)
    health_check
    ;;
  *)
    echo "Usage: $0 {log|handle|read|write|view|cleanup|stats|health}"
    echo ""
    echo "Commands:"
    echo "  log <code> [msg] [ctx]  - Log an error"
    echo "  handle <code> [ctx]     - Handle error with recovery"
    echo "  read <file> [query]     - Safe JSON read"
    echo "  write <file> <query>    - Safe JSON write"
    echo "  view [lines]            - View recent errors"
    echo "  cleanup [days]          - Clean old error logs"
    echo "  stats                   - Show error statistics"
    echo "  health                  - System health check"
    ;;
esac
