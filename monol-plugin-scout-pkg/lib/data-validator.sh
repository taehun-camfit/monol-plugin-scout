#!/bin/bash
# Plugin Scout - 데이터 검증 유틸리티
# JSON 파일 검증 및 복구

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}"
DATA_DIR="$PLUGIN_ROOT/data"
BACKUP_DIR="$DATA_DIR/backups"

# 백업 디렉토리 생성
mkdir -p "$BACKUP_DIR"

# JSON 파일 유효성 검사
validate_json() {
  local file="$1"

  if [ ! -f "$file" ]; then
    echo "error:not_found"
    return 1
  fi

  if ! command -v jq &> /dev/null; then
    echo "error:jq_not_found"
    return 1
  fi

  if jq empty "$file" 2>/dev/null; then
    echo "valid"
    return 0
  else
    echo "error:invalid_json"
    return 1
  fi
}

# 파일 백업
backup_file() {
  local file="$1"
  local filename=$(basename "$file")
  local timestamp=$(date +"%Y%m%d_%H%M%S")
  local backup_path="$BACKUP_DIR/${filename}.${timestamp}.bak"

  if [ -f "$file" ]; then
    cp "$file" "$backup_path"
    echo "$backup_path"
  fi
}

# history.json 스키마 검증
validate_history() {
  local file="$DATA_DIR/history.json"

  if ! validate_json "$file" >/dev/null; then
    echo "invalid"
    return 1
  fi

  # 필수 필드 검증
  local has_version=$(jq -r 'has("version")' "$file")
  local has_declined=$(jq -r 'has("declined")' "$file")
  local has_preferences=$(jq -r 'has("preferences")' "$file")

  if [ "$has_version" = "true" ] && [ "$has_declined" = "true" ] && [ "$has_preferences" = "true" ]; then
    echo "valid"
    return 0
  else
    echo "missing_fields"
    return 1
  fi
}

# usage.json 스키마 검증
validate_usage() {
  local file="$DATA_DIR/usage.json"

  if ! validate_json "$file" >/dev/null; then
    echo "invalid"
    return 1
  fi

  # 필수 필드 검증
  local has_plugins=$(jq -r 'has("plugins")' "$file")
  local has_sessions=$(jq -r 'has("sessions")' "$file")

  if [ "$has_plugins" = "true" ] && [ "$has_sessions" = "true" ]; then
    echo "valid"
    return 0
  else
    echo "missing_fields"
    return 1
  fi
}

# team.json 스키마 검증
validate_team() {
  local file="$DATA_DIR/team.json"

  if ! validate_json "$file" >/dev/null; then
    echo "invalid"
    return 1
  fi

  # 필수 필드 검증
  local has_version=$(jq -r 'has("version")' "$file")
  local has_members=$(jq -r 'has("members")' "$file")
  local has_stats=$(jq -r 'has("stats")' "$file")

  if [ "$has_version" = "true" ] && [ "$has_members" = "true" ] && [ "$has_stats" = "true" ]; then
    echo "valid"
    return 0
  else
    echo "missing_fields"
    return 1
  fi
}

# history.json 초기화
init_history() {
  local file="$DATA_DIR/history.json"
  local now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # 기존 파일 백업
  if [ -f "$file" ]; then
    backup_file "$file"
  fi

  cat > "$file" << EOF
{
  "version": "2.0.0",
  "declined": {},
  "installed": {},
  "viewed": [],
  "rejectionPatterns": {
    "byCategory": {},
    "byReason": {}
  },
  "rejectionReasons": {
    "not-relevant": "프로젝트에 관련 없음",
    "wrong-language": "다른 언어용",
    "already-have": "유사 플러그인 보유",
    "too-complex": "복잡함",
    "security": "보안 우려",
    "other": "기타"
  },
  "preferences": {
    "categories": [],
    "autoInstall": false,
    "quietMode": false,
    "recommendationCooldown": 30,
    "maxRejectionsBeforeBlock": 3,
    "maxRecommendationsPerSession": 1,
    "maxRecommendationsPerDay": 3,
    "smartTiming": {
      "onlyAfterCommit": false,
      "onlyAfterPR": false
    }
  },
  "updatedAt": "$now"
}
EOF

  echo "initialized"
}

# usage.json 초기화
init_usage() {
  local file="$DATA_DIR/usage.json"
  local now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # 기존 파일 백업
  if [ -f "$file" ]; then
    backup_file "$file"
  fi

  cat > "$file" << EOF
{
  "plugins": {},
  "users": {},
  "sessions": {
    "total": 0,
    "thisWeek": 0
  },
  "lastUpdated": "$now"
}
EOF

  echo "initialized"
}

# 모든 데이터 파일 검증
validate_all() {
  echo "=== Data Validation ==="
  echo ""

  local all_valid=true

  # history.json
  echo -n "history.json: "
  if [ -f "$DATA_DIR/history.json" ]; then
    local result=$(validate_history)
    echo "$result"
    [ "$result" != "valid" ] && all_valid=false
  else
    echo "not_found"
    all_valid=false
  fi

  # usage.json
  echo -n "usage.json: "
  if [ -f "$DATA_DIR/usage.json" ]; then
    local result=$(validate_usage)
    echo "$result"
    [ "$result" != "valid" ] && all_valid=false
  else
    echo "not_found"
    all_valid=false
  fi

  # team.json
  echo -n "team.json: "
  if [ -f "$DATA_DIR/team.json" ]; then
    local result=$(validate_team)
    echo "$result"
    [ "$result" != "valid" ] && all_valid=false
  else
    echo "not_found (optional)"
  fi

  # .session
  echo -n ".session: "
  if [ -f "$DATA_DIR/.session" ]; then
    local result=$(validate_json "$DATA_DIR/.session")
    echo "$result"
    [ "$result" != "valid" ] && all_valid=false
  else
    echo "not_found (runtime)"
  fi

  echo ""
  if [ "$all_valid" = "true" ]; then
    echo "All data files are valid."
  else
    echo "Some data files need attention."
  fi
}

# 손상된 파일 복구
repair() {
  local file="$1"

  case "$file" in
    history)
      echo "Repairing history.json..."
      init_history
      ;;
    usage)
      echo "Repairing usage.json..."
      init_usage
      ;;
    all)
      echo "Repairing all data files..."
      init_history
      init_usage
      ;;
    *)
      echo "Usage: repair {history|usage|all}"
      ;;
  esac
}

# 백업 목록
list_backups() {
  echo "=== Backups ==="
  if [ -d "$BACKUP_DIR" ] && [ "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
    ls -la "$BACKUP_DIR"
  else
    echo "No backups found"
  fi
}

# 백업에서 복원
restore_backup() {
  local backup_file="$1"

  if [ -z "$backup_file" ]; then
    echo "Usage: restore <backup-file>"
    list_backups
    return 1
  fi

  local full_path="$BACKUP_DIR/$backup_file"
  if [ ! -f "$full_path" ]; then
    echo "Backup not found: $backup_file"
    return 1
  fi

  # 파일명에서 원본 파일명 추출
  local original_name=$(echo "$backup_file" | sed 's/\.[0-9]*_[0-9]*\.bak$//')
  local target_file="$DATA_DIR/$original_name"

  # 현재 파일 백업 후 복원
  if [ -f "$target_file" ]; then
    backup_file "$target_file"
  fi

  cp "$full_path" "$target_file"
  echo "Restored: $original_name from $backup_file"
}

# CLI 인터페이스
case "$1" in
  validate)
    validate_all
    ;;
  check)
    validate_json "$2"
    ;;
  history)
    validate_history
    ;;
  usage)
    validate_usage
    ;;
  team)
    validate_team
    ;;
  init)
    case "$2" in
      history) init_history ;;
      usage) init_usage ;;
      *) echo "Usage: init {history|usage}" ;;
    esac
    ;;
  repair)
    repair "$2"
    ;;
  backup)
    backup_file "$2"
    ;;
  backups)
    list_backups
    ;;
  restore)
    restore_backup "$2"
    ;;
  *)
    echo "Usage: $0 {validate|check|history|usage|team|init|repair|backup|backups|restore}"
    echo ""
    echo "Commands:"
    echo "  validate              - Validate all data files"
    echo "  check <file>          - Check if JSON file is valid"
    echo "  history               - Validate history.json schema"
    echo "  usage                 - Validate usage.json schema"
    echo "  team                  - Validate team.json schema"
    echo "  init <type>           - Initialize data file (history|usage)"
    echo "  repair <type>         - Repair corrupted file (history|usage|all)"
    echo "  backup <file>         - Create backup of file"
    echo "  backups               - List all backups"
    echo "  restore <backup>      - Restore from backup"
    ;;
esac
