#!/bin/bash
# Plugin Scout - 프로필 학습 시스템
# 사용자 선호도 및 활동 패턴을 학습하여 개인화된 추천 제공

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}"
DATA_DIR="$PLUGIN_ROOT/data"
PROFILE_FILE="$DATA_DIR/profile.json"

# 프로필 초기화
init_profile() {
  if [ ! -f "$PROFILE_FILE" ]; then
    mkdir -p "$DATA_DIR"
    echo '{
  "version": "1.0.0",
  "lastUpdated": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
  "preferences": {
    "categories": {},
    "projectTypes": {},
    "tags": {}
  },
  "activityPatterns": {
    "hourly": {},
    "daily": {},
    "weekly": {}
  },
  "installHistory": [],
  "usageStats": {
    "totalInstalls": 0,
    "totalRecommendations": 0,
    "acceptRate": 0
  }
}' > "$PROFILE_FILE"
  fi
}

# 카테고리 선호도 업데이트
update_category_preference() {
  local category="$1"
  local action="$2"  # accept, reject, install, uninstall
  local weight=1

  case "$action" in
    accept) weight=2 ;;
    install) weight=5 ;;
    reject) weight=-1 ;;
    uninstall) weight=-3 ;;
  esac

  init_profile

  if command -v jq &> /dev/null; then
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local current=$(jq -r ".preferences.categories[\"$category\"] // 0" "$PROFILE_FILE")
    local new_score=$((current + weight))

    # 점수는 -100 ~ 100 범위로 제한
    if [ "$new_score" -gt 100 ]; then new_score=100; fi
    if [ "$new_score" -lt -100 ]; then new_score=-100; fi

    jq --arg cat "$category" \
       --argjson score "$new_score" \
       --arg ts "$timestamp" \
       '
       .lastUpdated = $ts |
       .preferences.categories[$cat] = $score
       ' "$PROFILE_FILE" > "$PROFILE_FILE.tmp" && mv "$PROFILE_FILE.tmp" "$PROFILE_FILE"

    echo "Updated category preference: $category = $new_score"
  fi
}

# 프로젝트 타입 선호도 업데이트
update_project_type_preference() {
  local project_type="$1"
  local plugin_name="$2"
  local success="$3"  # true/false

  init_profile

  if command -v jq &> /dev/null; then
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local weight=1
    if [ "$success" = "true" ]; then weight=1; else weight=-1; fi

    local current=$(jq -r ".preferences.projectTypes[\"$project_type\"].score // 0" "$PROFILE_FILE")
    local new_score=$((current + weight))

    jq --arg pt "$project_type" \
       --arg plugin "$plugin_name" \
       --argjson score "$new_score" \
       --arg ts "$timestamp" \
       '
       .lastUpdated = $ts |
       .preferences.projectTypes[$pt].score = $score |
       .preferences.projectTypes[$pt].plugins = ((.preferences.projectTypes[$pt].plugins // []) + [$plugin] | unique)
       ' "$PROFILE_FILE" > "$PROFILE_FILE.tmp" && mv "$PROFILE_FILE.tmp" "$PROFILE_FILE"

    echo "Updated project type preference: $project_type"
  fi
}

# 활동 패턴 기록
record_activity() {
  local action="$1"
  local hour=$(date +"%H")
  local day=$(date +"%u")  # 1-7 (월-일)
  local week=$(date +"%W")

  init_profile

  if command -v jq &> /dev/null; then
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    jq --arg hour "$hour" \
       --arg day "$day" \
       --arg week "$week" \
       --arg action "$action" \
       --arg ts "$timestamp" \
       '
       .lastUpdated = $ts |
       .activityPatterns.hourly[$hour] = ((.activityPatterns.hourly[$hour] // 0) + 1) |
       .activityPatterns.daily[$day] = ((.activityPatterns.daily[$day] // 0) + 1) |
       .activityPatterns.weekly[$week] = ((.activityPatterns.weekly[$week] // 0) + 1)
       ' "$PROFILE_FILE" > "$PROFILE_FILE.tmp" && mv "$PROFILE_FILE.tmp" "$PROFILE_FILE"
  fi
}

# 설치 이력 기록
record_install() {
  local plugin_name="$1"
  local category="$2"
  local project_type="$3"

  init_profile

  if command -v jq &> /dev/null; then
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    jq --arg plugin "$plugin_name" \
       --arg cat "$category" \
       --arg pt "$project_type" \
       --arg ts "$timestamp" \
       '
       .lastUpdated = $ts |
       .installHistory = ([{
         "plugin": $plugin,
         "category": $cat,
         "projectType": $pt,
         "installedAt": $ts
       }] + .installHistory) | .[0:100] |
       .usageStats.totalInstalls = (.usageStats.totalInstalls + 1)
       ' "$PROFILE_FILE" > "$PROFILE_FILE.tmp" && mv "$PROFILE_FILE.tmp" "$PROFILE_FILE"

    # 카테고리/프로젝트 타입 선호도도 업데이트
    update_category_preference "$category" "install"
    update_project_type_preference "$project_type" "$plugin_name" "true"
    record_activity "install"

    echo "Recorded install: $plugin_name"
  fi
}

# 추천 수락률 업데이트
update_accept_rate() {
  local accepted="$1"  # true/false

  init_profile

  if command -v jq &> /dev/null; then
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local total=$(jq -r '.usageStats.totalRecommendations // 0' "$PROFILE_FILE")
    local current_rate=$(jq -r '.usageStats.acceptRate // 0' "$PROFILE_FILE")
    local new_total=$((total + 1))

    local add_to_rate=0
    if [ "$accepted" = "true" ]; then add_to_rate=1; fi

    # 이동 평균 계산
    local new_rate=$(echo "scale=2; ($current_rate * $total + $add_to_rate) / $new_total" | bc 2>/dev/null || echo "$current_rate")

    jq --arg ts "$timestamp" \
       --argjson total "$new_total" \
       --arg rate "$new_rate" \
       '
       .lastUpdated = $ts |
       .usageStats.totalRecommendations = $total |
       .usageStats.acceptRate = ($rate | tonumber)
       ' "$PROFILE_FILE" > "$PROFILE_FILE.tmp" && mv "$PROFILE_FILE.tmp" "$PROFILE_FILE"
  fi
}

# 선호 카테고리 목록 반환
get_preferred_categories() {
  local min_score="${1:-10}"

  init_profile

  if command -v jq &> /dev/null; then
    jq -r --argjson min "$min_score" '
      .preferences.categories | to_entries |
      map(select(.value >= $min)) |
      sort_by(-.value) |
      .[].key
    ' "$PROFILE_FILE"
  fi
}

# 가장 활동적인 시간대 반환
get_peak_hours() {
  init_profile

  if command -v jq &> /dev/null; then
    jq -r '
      .activityPatterns.hourly | to_entries |
      sort_by(-.value) |
      .[0:3] |
      .[].key
    ' "$PROFILE_FILE"
  fi
}

# 프로필 요약 출력
get_profile_summary() {
  init_profile

  if [ ! -f "$PROFILE_FILE" ]; then
    echo "No profile data"
    return
  fi

  if ! command -v jq &> /dev/null; then
    echo "jq required for profile summary"
    return
  fi

  echo "=== Profile Summary ==="
  echo ""
  echo "Preferred Categories (top 5):"
  jq -r '.preferences.categories | to_entries | sort_by(-.value) | .[0:5] | .[] | "  \(.key): \(.value)"' "$PROFILE_FILE"
  echo ""
  echo "Project Types:"
  jq -r '.preferences.projectTypes | to_entries | .[0:5] | .[] | "  \(.key): \(.value.score // 0) (\(.value.plugins | length) plugins)"' "$PROFILE_FILE"
  echo ""
  echo "Activity Patterns:"
  echo "  Peak hours: $(get_peak_hours | tr '\n' ', ' | sed 's/,$//')"
  echo ""
  echo "Stats:"
  jq -r '"  Total installs: \(.usageStats.totalInstalls)\n  Accept rate: \(.usageStats.acceptRate | . * 100 | floor)%"' "$PROFILE_FILE"
}

# 프로필 기반 추천 점수 조정
get_score_adjustment() {
  local plugin_name="$1"
  local category="$2"
  local project_type="$3"

  init_profile

  if ! command -v jq &> /dev/null; then
    echo "0"
    return
  fi

  local cat_score=$(jq -r ".preferences.categories[\"$category\"] // 0" "$PROFILE_FILE")
  local pt_score=$(jq -r ".preferences.projectTypes[\"$project_type\"].score // 0" "$PROFILE_FILE")

  # 선호도에 따라 -20 ~ +20 범위로 점수 조정
  local adjustment=$(echo "scale=0; ($cat_score + $pt_score) / 10" | bc 2>/dev/null || echo "0")

  if [ "$adjustment" -gt 20 ]; then adjustment=20; fi
  if [ "$adjustment" -lt -20 ]; then adjustment=-20; fi

  echo "$adjustment"
}

# 프로필 초기화 (리셋)
reset_profile() {
  if [ -f "$PROFILE_FILE" ]; then
    rm "$PROFILE_FILE"
    init_profile
    echo "Profile reset successfully"
  else
    echo "No profile to reset"
  fi
}

# CLI 인터페이스
case "$1" in
  init)
    init_profile
    echo "Profile initialized"
    ;;
  category)
    update_category_preference "$2" "$3"
    ;;
  project-type)
    update_project_type_preference "$2" "$3" "$4"
    ;;
  activity)
    record_activity "$2"
    ;;
  install)
    record_install "$2" "$3" "$4"
    ;;
  accept-rate)
    update_accept_rate "$2"
    ;;
  preferred-categories)
    get_preferred_categories "$2"
    ;;
  peak-hours)
    get_peak_hours
    ;;
  summary)
    get_profile_summary
    ;;
  score-adjustment)
    get_score_adjustment "$2" "$3" "$4"
    ;;
  reset)
    reset_profile
    ;;
  *)
    echo "Usage: $0 {init|category|project-type|activity|install|accept-rate|preferred-categories|peak-hours|summary|score-adjustment|reset}"
    echo ""
    echo "Commands:"
    echo "  init                                    - Initialize profile"
    echo "  category <cat> <action>                 - Update category preference (accept|reject|install|uninstall)"
    echo "  project-type <type> <plugin> <success>  - Update project type preference"
    echo "  activity <action>                       - Record activity pattern"
    echo "  install <plugin> <cat> <project_type>   - Record plugin install"
    echo "  accept-rate <true|false>                - Update recommendation accept rate"
    echo "  preferred-categories [min_score]        - Get preferred categories"
    echo "  peak-hours                              - Get peak activity hours"
    echo "  summary                                 - Show profile summary"
    echo "  score-adjustment <plugin> <cat> <pt>    - Get score adjustment based on profile"
    echo "  reset                                   - Reset profile"
    ;;
esac
