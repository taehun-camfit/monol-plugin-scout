#!/bin/bash
# Plugin Scout - 스케줄러
# 플러그인 체크, 알림, 정기 작업 예약

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}"
DATA_DIR="$PLUGIN_ROOT/data"
SCHEDULE_FILE="$DATA_DIR/schedules.json"

# 스케줄 파일 초기화
init_schedules() {
  if [ ! -f "$SCHEDULE_FILE" ]; then
    cat > "$SCHEDULE_FILE" << 'EOF'
{
  "version": "1.0.0",
  "tasks": [],
  "lastRun": null
}
EOF
  fi
}

# 스케줄 추가
add_schedule() {
  local task_type="$1"    # check-updates, cleanup, audit, remind
  local interval="$2"     # daily, weekly, monthly, once
  local target="$3"       # plugin name, category, or "all"
  local message="$4"      # reminder message
  local now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  init_schedules

  if ! command -v jq &> /dev/null; then
    echo "Error: jq required"
    return 1
  fi

  # 다음 실행 시간 계산
  local next_run
  case "$interval" in
    daily)
      next_run=$(date -v+1d -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -d "+1 day" -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
      ;;
    weekly)
      next_run=$(date -v+7d -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -d "+7 days" -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
      ;;
    monthly)
      next_run=$(date -v+1m -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -d "+1 month" -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
      ;;
    once)
      next_run="$now"
      ;;
    *)
      next_run=$(date -v+1d -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -d "+1 day" -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
      ;;
  esac

  local task_id=$(date +%s%N | md5 2>/dev/null | head -c 8 || echo "$RANDOM")

  jq --arg id "$task_id" --arg type "$task_type" --arg interval "$interval" \
     --arg target "${target:-all}" --arg msg "${message:-}" \
     --arg created "$now" --arg next "$next_run" '
    .tasks += [{
      "id": $id,
      "type": $type,
      "interval": $interval,
      "target": $target,
      "message": $msg,
      "createdAt": $created,
      "nextRun": $next,
      "lastRun": null,
      "enabled": true
    }]
  ' "$SCHEDULE_FILE" > "$SCHEDULE_FILE.tmp" && mv "$SCHEDULE_FILE.tmp" "$SCHEDULE_FILE"

  echo "Schedule added: $task_type ($interval) - ID: $task_id"
}

# 스케줄 삭제
remove_schedule() {
  local task_id="$1"

  init_schedules

  jq --arg id "$task_id" '.tasks = [.tasks[] | select(.id != $id)]' \
    "$SCHEDULE_FILE" > "$SCHEDULE_FILE.tmp" && mv "$SCHEDULE_FILE.tmp" "$SCHEDULE_FILE"

  echo "Schedule removed: $task_id"
}

# 스케줄 목록
list_schedules() {
  init_schedules

  echo "=== Scheduled Tasks ==="
  echo ""

  jq -r '.tasks[] | "[\(.id)] \(.type) (\(.interval)) - Target: \(.target) - Next: \(.nextRun | split("T")[0]) - \(if .enabled then "enabled" else "disabled" end)"' "$SCHEDULE_FILE"
}

# 스케줄 활성화/비활성화
toggle_schedule() {
  local task_id="$1"

  init_schedules

  jq --arg id "$task_id" '
    .tasks = [.tasks[] | if .id == $id then .enabled = (.enabled | not) else . end]
  ' "$SCHEDULE_FILE" > "$SCHEDULE_FILE.tmp" && mv "$SCHEDULE_FILE.tmp" "$SCHEDULE_FILE"

  echo "Schedule toggled: $task_id"
}

# 실행 대기 중인 스케줄 확인
check_due() {
  init_schedules

  local now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  jq -r --arg now "$now" '
    .tasks[] | select(.enabled == true and .nextRun <= $now) | .id
  ' "$SCHEDULE_FILE"
}

# 스케줄 실행
run_schedule() {
  local task_id="$1"

  init_schedules

  local task=$(jq -r --arg id "$task_id" '.tasks[] | select(.id == $id)' "$SCHEDULE_FILE")

  if [ -z "$task" ]; then
    echo "Task not found: $task_id"
    return 1
  fi

  local task_type=$(echo "$task" | jq -r '.type')
  local target=$(echo "$task" | jq -r '.target')
  local message=$(echo "$task" | jq -r '.message')
  local interval=$(echo "$task" | jq -r '.interval')

  echo "Running: $task_type ($target)"

  # 작업 유형별 실행
  case "$task_type" in
    check-updates)
      echo "Checking for plugin updates..."
      # bash "$PLUGIN_ROOT/lib/plugin-manager.sh" check-updates "$target"
      ;;
    cleanup)
      echo "Running cleanup..."
      bash "$PLUGIN_ROOT/lib/recommendation-controller.sh" cleanup
      bash "$PLUGIN_ROOT/lib/cache.sh" cleanup
      ;;
    audit)
      echo "Running audit..."
      # 보안 감사 실행
      ;;
    remind)
      echo "Reminder: $message"
      ;;
    *)
      echo "Unknown task type: $task_type"
      ;;
  esac

  # 다음 실행 시간 업데이트
  local now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local next_run

  case "$interval" in
    daily)
      next_run=$(date -v+1d -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -d "+1 day" -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
      ;;
    weekly)
      next_run=$(date -v+7d -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -d "+7 days" -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
      ;;
    monthly)
      next_run=$(date -v+1m -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -d "+1 month" -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
      ;;
    once)
      # 일회성 작업은 비활성화
      jq --arg id "$task_id" '.tasks = [.tasks[] | if .id == $id then .enabled = false else . end]' \
        "$SCHEDULE_FILE" > "$SCHEDULE_FILE.tmp" && mv "$SCHEDULE_FILE.tmp" "$SCHEDULE_FILE"
      next_run="null"
      ;;
  esac

  # 실행 기록 업데이트
  if [ "$next_run" != "null" ]; then
    jq --arg id "$task_id" --arg last "$now" --arg next "$next_run" '
      .tasks = [.tasks[] | if .id == $id then .lastRun = $last | .nextRun = $next else . end] |
      .lastRun = $last
    ' "$SCHEDULE_FILE" > "$SCHEDULE_FILE.tmp" && mv "$SCHEDULE_FILE.tmp" "$SCHEDULE_FILE"
  fi
}

# 대기 중인 모든 스케줄 실행
run_due() {
  local due_tasks=$(check_due)

  if [ -z "$due_tasks" ]; then
    echo "No tasks due"
    return
  fi

  echo "$due_tasks" | while read task_id; do
    run_schedule "$task_id"
    echo ""
  done
}

# 기본 스케줄 설정
setup_defaults() {
  init_schedules

  # 기본 스케줄이 없으면 추가
  local has_cleanup=$(jq -r '.tasks[] | select(.type == "cleanup") | .id' "$SCHEDULE_FILE" | head -1)

  if [ -z "$has_cleanup" ]; then
    add_schedule "cleanup" "weekly" "all" "Weekly cleanup task"
  fi

  echo "Default schedules configured"
}

# CLI 인터페이스
case "$1" in
  add)
    add_schedule "$2" "$3" "$4" "$5"
    ;;
  remove)
    remove_schedule "$2"
    ;;
  list)
    list_schedules
    ;;
  toggle)
    toggle_schedule "$2"
    ;;
  check)
    check_due
    ;;
  run)
    run_schedule "$2"
    ;;
  run-due)
    run_due
    ;;
  setup)
    setup_defaults
    ;;
  *)
    echo "Usage: $0 {add|remove|list|toggle|check|run|run-due|setup}"
    echo ""
    echo "Commands:"
    echo "  add <type> <interval> [target] [message]  - Add schedule"
    echo "  remove <id>                               - Remove schedule"
    echo "  list                                      - List all schedules"
    echo "  toggle <id>                               - Enable/disable schedule"
    echo "  check                                     - Check for due tasks"
    echo "  run <id>                                  - Run specific task"
    echo "  run-due                                   - Run all due tasks"
    echo "  setup                                     - Setup default schedules"
    echo ""
    echo "Task Types:"
    echo "  check-updates  - Check for plugin updates"
    echo "  cleanup        - Run cleanup tasks"
    echo "  audit          - Run security audit"
    echo "  remind         - Show reminder message"
    echo ""
    echo "Intervals:"
    echo "  daily, weekly, monthly, once"
    ;;
esac
