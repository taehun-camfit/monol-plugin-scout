#!/bin/bash
# Plugin Scout - 거절 학습 시스템
# 플러그인 거절 패턴을 학습하여 추천 품질 향상

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}"
DATA_DIR="$PLUGIN_ROOT/data"
HISTORY_FILE="$DATA_DIR/history.json"

# 거절 기록 추가
record_rejection() {
  local plugin_name="$1"
  local reason="$2"
  local category="$3"
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local date_only=$(date +"%Y-%m-%d")

  # history.json 없으면 생성
  if [ ! -f "$HISTORY_FILE" ]; then
    echo '{
  "version": "2.0.0",
  "lastUpdated": "'$timestamp'",
  "declined": {},
  "installed": {},
  "preferences": {
    "favoriteCategories": [],
    "blockedCategories": [],
    "autoRecommend": true,
    "quietMode": false
  },
  "rejectionPatterns": {
    "byCategory": {},
    "byReason": {}
  }
}' > "$HISTORY_FILE"
  fi

  # jq로 거절 기록 업데이트
  if command -v jq &> /dev/null; then
    local current_count=$(jq -r ".declined[\"$plugin_name\"].count // 0" "$HISTORY_FILE")
    local new_count=$((current_count + 1))

    # 거절 기록 업데이트
    jq --arg plugin "$plugin_name" \
       --arg reason "$reason" \
       --arg category "$category" \
       --arg date "$date_only" \
       --arg ts "$timestamp" \
       --argjson count "$new_count" \
       '
       .lastUpdated = $ts |
       .declined[$plugin].count = $count |
       .declined[$plugin].lastDeclined = $date |
       .declined[$plugin].reason = $reason |
       .declined[$plugin].category = $category |
       .declined[$plugin].declinedAt = ((.declined[$plugin].declinedAt // []) + [$ts]) |
       .rejectionPatterns.byCategory[$category] = ((.rejectionPatterns.byCategory[$category] // 0) + 1) |
       .rejectionPatterns.byReason[$reason] = ((.rejectionPatterns.byReason[$reason] // 0) + 1)
       ' "$HISTORY_FILE" > "$HISTORY_FILE.tmp" && mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"

    echo "Recorded rejection: $plugin_name ($reason)"
  else
    echo "Warning: jq not installed, cannot record rejection"
  fi
}

# 플러그인이 추천 가능한지 확인
can_recommend() {
  local plugin_name="$1"
  local cooldown_days="${2:-30}"  # 기본 30일 쿨다운

  if [ ! -f "$HISTORY_FILE" ]; then
    echo "true"
    return
  fi

  if ! command -v jq &> /dev/null; then
    echo "true"
    return
  fi

  local declined=$(jq -r ".declined[\"$plugin_name\"]" "$HISTORY_FILE")

  if [ "$declined" = "null" ]; then
    echo "true"
    return
  fi

  local count=$(echo "$declined" | jq -r '.count // 0')
  local last_declined=$(echo "$declined" | jq -r '.lastDeclined // ""')

  # 3회 이상 거절 시 영구 차단
  if [ "$count" -ge 3 ]; then
    echo "blocked:too_many_rejections"
    return
  fi

  # 쿨다운 기간 체크
  if [ -n "$last_declined" ]; then
    local last_ts=$(date -j -f "%Y-%m-%d" "$last_declined" "+%s" 2>/dev/null || date -d "$last_declined" "+%s" 2>/dev/null)
    local now_ts=$(date "+%s")
    local diff_days=$(( (now_ts - last_ts) / 86400 ))

    if [ "$diff_days" -lt "$cooldown_days" ]; then
      echo "cooldown:$((cooldown_days - diff_days))_days_remaining"
      return
    fi
  fi

  echo "true"
}

# 카테고리가 차단되었는지 확인
is_category_blocked() {
  local category="$1"
  local threshold="${2:-5}"  # 기본 5회 이상 거절 시 차단

  if [ ! -f "$HISTORY_FILE" ]; then
    echo "false"
    return
  fi

  if ! command -v jq &> /dev/null; then
    echo "false"
    return
  fi

  local count=$(jq -r ".rejectionPatterns.byCategory[\"$category\"] // 0" "$HISTORY_FILE")

  if [ "$count" -ge "$threshold" ]; then
    echo "true"
  else
    echo "false"
  fi
}

# 거절 통계 출력
get_rejection_stats() {
  if [ ! -f "$HISTORY_FILE" ]; then
    echo "No rejection history"
    return
  fi

  if ! command -v jq &> /dev/null; then
    echo "jq required for stats"
    return
  fi

  echo "=== Rejection Statistics ==="
  echo ""
  echo "By Plugin:"
  jq -r '.declined | to_entries | sort_by(-.value.count) | .[:5] | .[] | "  \(.key): \(.value.count) times (\(.value.reason))"' "$HISTORY_FILE"
  echo ""
  echo "By Category:"
  jq -r '.rejectionPatterns.byCategory | to_entries | sort_by(-.value) | .[] | "  \(.key): \(.value) rejections"' "$HISTORY_FILE"
  echo ""
  echo "By Reason:"
  jq -r '.rejectionPatterns.byReason | to_entries | sort_by(-.value) | .[] | "  \(.key): \(.value) times"' "$HISTORY_FILE"
}

# 거절 초기화 (특정 플러그인)
reset_rejection() {
  local plugin_name="$1"

  if [ ! -f "$HISTORY_FILE" ]; then
    echo "No history file"
    return
  fi

  if ! command -v jq &> /dev/null; then
    echo "jq required"
    return
  fi

  jq --arg plugin "$plugin_name" 'del(.declined[$plugin])' "$HISTORY_FILE" > "$HISTORY_FILE.tmp" && mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
  echo "Reset rejection for: $plugin_name"
}

# 추천 필터링 (거절 학습 기반)
filter_recommendations() {
  local plugins_json="$1"  # JSON array of plugin names

  if [ ! -f "$HISTORY_FILE" ]; then
    echo "$plugins_json"
    return
  fi

  if ! command -v jq &> /dev/null; then
    echo "$plugins_json"
    return
  fi

  # 필터링 로직
  echo "$plugins_json" | jq -r '.[]' | while read plugin; do
    local status=$(can_recommend "$plugin")
    if [ "$status" = "true" ]; then
      echo "$plugin"
    fi
  done | jq -R -s -c 'split("\n") | map(select(. != ""))'
}

# CLI 인터페이스
case "$1" in
  record)
    record_rejection "$2" "$3" "$4"
    ;;
  check)
    can_recommend "$2" "$3"
    ;;
  category-blocked)
    is_category_blocked "$2" "$3"
    ;;
  stats)
    get_rejection_stats
    ;;
  reset)
    reset_rejection "$2"
    ;;
  filter)
    filter_recommendations "$2"
    ;;
  *)
    echo "Usage: $0 {record|check|category-blocked|stats|reset|filter}"
    echo ""
    echo "Commands:"
    echo "  record <plugin> <reason> <category>  - Record a rejection"
    echo "  check <plugin> [cooldown_days]       - Check if plugin can be recommended"
    echo "  category-blocked <category> [threshold] - Check if category is blocked"
    echo "  stats                                - Show rejection statistics"
    echo "  reset <plugin>                       - Reset rejection for a plugin"
    echo "  filter <json_array>                  - Filter recommendations"
    ;;
esac
