#!/bin/bash
# Plugin Scout - 트렌드 학습 시스템
# 주간/월간 인기 플러그인 추적 및 카테고리별 트렌드 변화 감지

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}"
DATA_DIR="$PLUGIN_ROOT/data"
TRENDS_FILE="$DATA_DIR/trends.json"

# 트렌드 데이터 초기화
init_trends() {
  if [ ! -f "$TRENDS_FILE" ]; then
    mkdir -p "$DATA_DIR"
    echo '{
  "version": "1.0.0",
  "lastUpdated": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
  "weekly": {
    "currentWeek": "'$(date +"%Y-W%W")'",
    "plugins": {},
    "categories": {}
  },
  "monthly": {
    "currentMonth": "'$(date +"%Y-%m")'",
    "plugins": {},
    "categories": {}
  },
  "allTime": {
    "plugins": {},
    "categories": {}
  },
  "newPlugins": [],
  "trending": [],
  "alerts": []
}' > "$TRENDS_FILE"
  fi
}

# 주/월 변경 시 데이터 롤오버
check_period_rollover() {
  init_trends

  if ! command -v jq &> /dev/null; then return; fi

  local current_week=$(date +"%Y-W%W")
  local current_month=$(date +"%Y-%m")
  local stored_week=$(jq -r '.weekly.currentWeek // ""' "$TRENDS_FILE")
  local stored_month=$(jq -r '.monthly.currentMonth // ""' "$TRENDS_FILE")
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  local needs_update=false

  # 주간 롤오버
  if [ "$current_week" != "$stored_week" ]; then
    jq --arg week "$current_week" --arg ts "$timestamp" '
      .weekly.previousWeek = .weekly.plugins |
      .weekly.currentWeek = $week |
      .weekly.plugins = {} |
      .weekly.categories = {} |
      .lastUpdated = $ts
    ' "$TRENDS_FILE" > "$TRENDS_FILE.tmp" && mv "$TRENDS_FILE.tmp" "$TRENDS_FILE"
    needs_update=true
  fi

  # 월간 롤오버
  if [ "$current_month" != "$stored_month" ]; then
    jq --arg month "$current_month" --arg ts "$timestamp" '
      .monthly.previousMonth = .monthly.plugins |
      .monthly.currentMonth = $month |
      .monthly.plugins = {} |
      .monthly.categories = {} |
      .lastUpdated = $ts
    ' "$TRENDS_FILE" > "$TRENDS_FILE.tmp" && mv "$TRENDS_FILE.tmp" "$TRENDS_FILE"
    needs_update=true
  fi

  if [ "$needs_update" = "true" ]; then
    update_trending
  fi
}

# 플러그인 인기도 기록
record_plugin_popularity() {
  local plugin_name="$1"
  local category="$2"
  local event="$3"  # view, recommend, install, use

  check_period_rollover

  if ! command -v jq &> /dev/null; then return; fi

  local weight=1
  case "$event" in
    view) weight=1 ;;
    recommend) weight=2 ;;
    install) weight=5 ;;
    use) weight=3 ;;
  esac

  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  jq --arg plugin "$plugin_name" \
     --arg cat "$category" \
     --argjson weight "$weight" \
     --arg ts "$timestamp" \
     '
     .lastUpdated = $ts |
     .weekly.plugins[$plugin] = ((.weekly.plugins[$plugin] // 0) + $weight) |
     .weekly.categories[$cat] = ((.weekly.categories[$cat] // 0) + $weight) |
     .monthly.plugins[$plugin] = ((.monthly.plugins[$plugin] // 0) + $weight) |
     .monthly.categories[$cat] = ((.monthly.categories[$cat] // 0) + $weight) |
     .allTime.plugins[$plugin] = ((.allTime.plugins[$plugin] // 0) + $weight) |
     .allTime.categories[$cat] = ((.allTime.categories[$cat] // 0) + $weight)
     ' "$TRENDS_FILE" > "$TRENDS_FILE.tmp" && mv "$TRENDS_FILE.tmp" "$TRENDS_FILE"

  echo "Recorded: $plugin_name ($event)"
}

# 새 플러그인 등록
register_new_plugin() {
  local plugin_name="$1"
  local category="$2"
  local source="$3"  # marketplace, user_created, forked

  init_trends

  if ! command -v jq &> /dev/null; then return; fi

  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # 이미 등록된 플러그인인지 확인
  local exists=$(jq -r --arg plugin "$plugin_name" '.newPlugins | map(select(.name == $plugin)) | length' "$TRENDS_FILE")

  if [ "$exists" = "0" ]; then
    jq --arg plugin "$plugin_name" \
       --arg cat "$category" \
       --arg src "$source" \
       --arg ts "$timestamp" \
       '
       .lastUpdated = $ts |
       .newPlugins = ([{
         "name": $plugin,
         "category": $cat,
         "source": $src,
         "discoveredAt": $ts
       }] + .newPlugins) | .[0:50]
       ' "$TRENDS_FILE" > "$TRENDS_FILE.tmp" && mv "$TRENDS_FILE.tmp" "$TRENDS_FILE"

    # 알림 추가
    add_alert "new_plugin" "$plugin_name" "New plugin discovered: $plugin_name ($category)"

    echo "Registered new plugin: $plugin_name"
  fi
}

# 트렌딩 플러그인 업데이트
update_trending() {
  init_trends

  if ! command -v jq &> /dev/null; then return; fi

  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # 주간 기준 상위 10개 + 성장률 기반 트렌딩 계산
  jq --arg ts "$timestamp" '
    .lastUpdated = $ts |
    .trending = (
      .weekly.plugins | to_entries |
      sort_by(-.value) |
      .[0:10] |
      map({
        name: .key,
        score: .value,
        trend: (
          if .value > ((.weekly.previousWeek[.key] // 0)) then "rising"
          elif .value < ((.weekly.previousWeek[.key] // 0)) then "falling"
          else "stable"
          end
        )
      })
    )
  ' "$TRENDS_FILE" > "$TRENDS_FILE.tmp" && mv "$TRENDS_FILE.tmp" "$TRENDS_FILE"
}

# 알림 추가
add_alert() {
  local type="$1"
  local subject="$2"
  local message="$3"

  init_trends

  if ! command -v jq &> /dev/null; then return; fi

  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  jq --arg type "$type" \
     --arg subject "$subject" \
     --arg msg "$message" \
     --arg ts "$timestamp" \
     '
     .lastUpdated = $ts |
     .alerts = ([{
       "type": $type,
       "subject": $subject,
       "message": $msg,
       "createdAt": $ts,
       "read": false
     }] + .alerts) | .[0:20]
     ' "$TRENDS_FILE" > "$TRENDS_FILE.tmp" && mv "$TRENDS_FILE.tmp" "$TRENDS_FILE"
}

# 알림 읽음 처리
mark_alerts_read() {
  init_trends

  if ! command -v jq &> /dev/null; then return; fi

  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  jq --arg ts "$timestamp" '
    .lastUpdated = $ts |
    .alerts = (.alerts | map(.read = true))
  ' "$TRENDS_FILE" > "$TRENDS_FILE.tmp" && mv "$TRENDS_FILE.tmp" "$TRENDS_FILE"

  echo "All alerts marked as read"
}

# 주간 인기 플러그인 조회
get_weekly_top() {
  local limit="${1:-10}"

  check_period_rollover

  if ! command -v jq &> /dev/null; then
    echo "jq required"
    return
  fi

  jq -r --argjson limit "$limit" '
    .weekly.plugins | to_entries |
    sort_by(-.value) |
    .[0:$limit] |
    .[] | "\(.key): \(.value)"
  ' "$TRENDS_FILE"
}

# 월간 인기 플러그인 조회
get_monthly_top() {
  local limit="${1:-10}"

  check_period_rollover

  if ! command -v jq &> /dev/null; then
    echo "jq required"
    return
  fi

  jq -r --argjson limit "$limit" '
    .monthly.plugins | to_entries |
    sort_by(-.value) |
    .[0:$limit] |
    .[] | "\(.key): \(.value)"
  ' "$TRENDS_FILE"
}

# 카테고리 트렌드 조회
get_category_trends() {
  check_period_rollover

  if ! command -v jq &> /dev/null; then
    echo "jq required"
    return
  fi

  echo "=== Category Trends ==="
  echo ""
  echo "This Week:"
  jq -r '.weekly.categories | to_entries | sort_by(-.value) | .[] | "  \(.key): \(.value)"' "$TRENDS_FILE"
  echo ""
  echo "This Month:"
  jq -r '.monthly.categories | to_entries | sort_by(-.value) | .[] | "  \(.key): \(.value)"' "$TRENDS_FILE"
}

# 새 플러그인 목록 조회
get_new_plugins() {
  local days="${1:-7}"

  init_trends

  if ! command -v jq &> /dev/null; then
    echo "jq required"
    return
  fi

  local cutoff=$(date -u -v-${days}d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "$days days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)

  echo "=== New Plugins (last $days days) ==="
  jq -r --arg cutoff "$cutoff" '
    .newPlugins |
    map(select(.discoveredAt >= $cutoff)) |
    .[] | "  \(.name) [\(.category)] - \(.discoveredAt | split("T")[0])"
  ' "$TRENDS_FILE"
}

# 트렌딩 플러그인 조회
get_trending() {
  update_trending

  if ! command -v jq &> /dev/null; then
    echo "jq required"
    return
  fi

  echo "=== Trending Plugins ==="
  jq -r '.trending | .[] | "  \(.name): \(.score) [\(.trend)]"' "$TRENDS_FILE"
}

# 읽지 않은 알림 조회
get_unread_alerts() {
  init_trends

  if ! command -v jq &> /dev/null; then
    echo "jq required"
    return
  fi

  local count=$(jq -r '[.alerts[] | select(.read == false)] | length' "$TRENDS_FILE")

  if [ "$count" = "0" ]; then
    echo "No unread alerts"
    return
  fi

  echo "=== Unread Alerts ($count) ==="
  jq -r '.alerts | map(select(.read == false)) | .[] | "  [\(.type)] \(.message)"' "$TRENDS_FILE"
}

# 트렌드 요약 출력
get_trends_summary() {
  check_period_rollover

  if ! command -v jq &> /dev/null; then
    echo "jq required"
    return
  fi

  echo "=== Trends Summary ==="
  echo ""
  echo "Week: $(jq -r '.weekly.currentWeek' "$TRENDS_FILE")"
  echo "Month: $(jq -r '.monthly.currentMonth' "$TRENDS_FILE")"
  echo ""
  echo "Top 5 This Week:"
  get_weekly_top 5
  echo ""
  echo "Trending:"
  jq -r '.trending | .[0:3] | .[] | "  \(.name) [\(.trend)]"' "$TRENDS_FILE"
  echo ""
  echo "New Plugins: $(jq -r '.newPlugins | length' "$TRENDS_FILE")"
  echo "Unread Alerts: $(jq -r '[.alerts[] | select(.read == false)] | length' "$TRENDS_FILE")"
}

# 트렌드 데이터 초기화 (리셋)
reset_trends() {
  if [ -f "$TRENDS_FILE" ]; then
    rm "$TRENDS_FILE"
    init_trends
    echo "Trends data reset successfully"
  else
    echo "No trends data to reset"
  fi
}

# CLI 인터페이스
case "$1" in
  init)
    init_trends
    echo "Trends initialized"
    ;;
  record)
    record_plugin_popularity "$2" "$3" "$4"
    ;;
  new-plugin)
    register_new_plugin "$2" "$3" "$4"
    ;;
  weekly-top)
    get_weekly_top "$2"
    ;;
  monthly-top)
    get_monthly_top "$2"
    ;;
  category-trends)
    get_category_trends
    ;;
  new-plugins)
    get_new_plugins "$2"
    ;;
  trending)
    get_trending
    ;;
  alerts)
    get_unread_alerts
    ;;
  mark-read)
    mark_alerts_read
    ;;
  summary)
    get_trends_summary
    ;;
  reset)
    reset_trends
    ;;
  *)
    echo "Usage: $0 {init|record|new-plugin|weekly-top|monthly-top|category-trends|new-plugins|trending|alerts|mark-read|summary|reset}"
    echo ""
    echo "Commands:"
    echo "  init                                  - Initialize trends data"
    echo "  record <plugin> <category> <event>    - Record plugin popularity (view|recommend|install|use)"
    echo "  new-plugin <plugin> <cat> <source>    - Register new plugin"
    echo "  weekly-top [limit]                    - Get weekly top plugins"
    echo "  monthly-top [limit]                   - Get monthly top plugins"
    echo "  category-trends                       - Get category trends"
    echo "  new-plugins [days]                    - Get new plugins"
    echo "  trending                              - Get trending plugins"
    echo "  alerts                                - Get unread alerts"
    echo "  mark-read                             - Mark all alerts as read"
    echo "  summary                               - Show trends summary"
    echo "  reset                                 - Reset trends data"
    ;;
esac
