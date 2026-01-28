#!/bin/bash
# Plugin Scout - 우선순위 스코어링 시스템
# 다양한 요소를 기반으로 플러그인 우선순위 계산

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}"
DATA_DIR="$PLUGIN_ROOT/data"
HISTORY_FILE="$DATA_DIR/history.json"
USAGE_FILE="$DATA_DIR/usage.json"
TEAM_FILE="$DATA_DIR/team.json"

# 기본 가중치 설정
WEIGHT_PROJECT_MATCH=40
WEIGHT_TEAM_POPULARITY=25
WEIGHT_PERSONAL_HISTORY=20
WEIGHT_FRESHNESS=15

# 프로젝트 매칭 점수 계산
calc_project_match_score() {
  local plugin="$1"
  local project_types="$2"
  local frameworks="$3"

  # 간단한 매칭 로직 (실제로는 더 정교하게)
  local score=50  # 기본 점수

  # 플러그인-프레임워크 매핑
  case "$plugin" in
    *react*) echo "$frameworks" | grep -q "react" && score=90 ;;
    *typescript*|*ts*) echo "$project_types" | grep -q "typescript" && score=90 ;;
    *eslint*) echo "$frameworks" | grep -q "eslint" && score=85 ;;
    *jest*|*vitest*|*test*) echo "$frameworks" | grep -qE "(jest|vitest|playwright)" && score=85 ;;
    *docker*) echo "$project_types" | grep -q "docker" && score=80 ;;
    *prisma*) echo "$frameworks" | grep -q "prisma" && score=85 ;;
    *python*|*py*) echo "$project_types" | grep -q "python" && score=80 ;;
    *) score=50 ;;
  esac

  echo "$score"
}

# 팀 인기도 점수 계산
calc_team_popularity_score() {
  local plugin="$1"

  if [ ! -f "$TEAM_FILE" ] || ! command -v jq &> /dev/null; then
    echo "50"  # 기본 점수
    return
  fi

  # 팀 내 사용자 수 확인
  local team_users=$(jq -r --arg p "$plugin" '
    [.members | to_entries[] | select(.value.pluginsUsed | index($p))] | length
  ' "$TEAM_FILE" 2>/dev/null || echo "0")

  local total_members=$(jq -r '.stats.totalMembers // 1' "$TEAM_FILE" 2>/dev/null || echo "1")

  # 팀 추천 확인
  local is_shared=$(jq -r --arg p "$plugin" '
    if (.sharedRecommendations | map(.plugin) | index($p)) != null then "1" else "0" end
  ' "$TEAM_FILE" 2>/dev/null || echo "0")

  # 점수 계산
  local score=50
  if [ "$total_members" -gt 0 ]; then
    local usage_rate=$(( team_users * 100 / total_members ))
    score=$(( 50 + usage_rate / 2 ))
  fi

  # 팀 추천이면 보너스
  if [ "$is_shared" = "1" ]; then
    score=$(( score + 15 ))
  fi

  # 0-100 범위로 제한
  [ "$score" -gt 100 ] && score=100
  [ "$score" -lt 0 ] && score=0

  echo "$score"
}

# 개인 이력 점수 계산
calc_personal_history_score() {
  local plugin="$1"

  if [ ! -f "$HISTORY_FILE" ] || ! command -v jq &> /dev/null; then
    echo "50"
    return
  fi

  # 거절 여부 확인
  local declined_count=$(jq -r --arg p "$plugin" '.declined[$p].count // 0' "$HISTORY_FILE" 2>/dev/null || echo "0")

  # 이전 사용 여부 확인
  local was_installed=$(jq -r --arg p "$plugin" '
    if .installed[$p] then "1" else "0" end
  ' "$HISTORY_FILE" 2>/dev/null || echo "0")

  # 점수 계산
  local score=50

  # 거절 이력이 있으면 감점
  if [ "$declined_count" -gt 0 ]; then
    score=$(( 50 - declined_count * 20 ))
  fi

  # 이전에 설치했었다면 가점
  if [ "$was_installed" = "1" ]; then
    score=$(( score + 20 ))
  fi

  # 0-100 범위로 제한
  [ "$score" -gt 100 ] && score=100
  [ "$score" -lt 0 ] && score=0

  echo "$score"
}

# 신선도 점수 계산 (최근 업데이트)
calc_freshness_score() {
  local plugin="$1"
  local last_update="$2"  # ISO 8601 날짜

  if [ -z "$last_update" ]; then
    echo "50"
    return
  fi

  # 현재 시간과 비교 (일 단위)
  local now=$(date +%s)
  local update_ts=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_update" +%s 2>/dev/null || date -d "$last_update" +%s 2>/dev/null)

  if [ -z "$update_ts" ]; then
    echo "50"
    return
  fi

  local days_old=$(( (now - update_ts) / 86400 ))

  # 최근 업데이트일수록 높은 점수
  local score
  if [ "$days_old" -lt 7 ]; then
    score=95
  elif [ "$days_old" -lt 30 ]; then
    score=85
  elif [ "$days_old" -lt 90 ]; then
    score=70
  elif [ "$days_old" -lt 180 ]; then
    score=55
  else
    score=40
  fi

  echo "$score"
}

# 종합 점수 계산
calc_total_score() {
  local plugin="$1"
  local project_types="${2:-}"
  local frameworks="${3:-}"
  local last_update="${4:-}"

  # 각 요소별 점수 계산
  local project_score=$(calc_project_match_score "$plugin" "$project_types" "$frameworks")
  local team_score=$(calc_team_popularity_score "$plugin")
  local history_score=$(calc_personal_history_score "$plugin")
  local fresh_score=$(calc_freshness_score "$plugin" "$last_update")

  # 가중 평균 계산
  local total=$((
    project_score * WEIGHT_PROJECT_MATCH / 100 +
    team_score * WEIGHT_TEAM_POPULARITY / 100 +
    history_score * WEIGHT_PERSONAL_HISTORY / 100 +
    fresh_score * WEIGHT_FRESHNESS / 100
  ))

  echo "$total"
}

# 점수 상세 분석
score_breakdown() {
  local plugin="$1"
  local project_types="${2:-}"
  local frameworks="${3:-}"
  local last_update="${4:-}"

  local project_score=$(calc_project_match_score "$plugin" "$project_types" "$frameworks")
  local team_score=$(calc_team_popularity_score "$plugin")
  local history_score=$(calc_personal_history_score "$plugin")
  local fresh_score=$(calc_freshness_score "$plugin" "$last_update")
  local total=$(calc_total_score "$plugin" "$project_types" "$frameworks" "$last_update")

  echo "=== Score Breakdown: $plugin ==="
  echo ""
  printf "%-20s %3d (weight: %d%%)\n" "Project Match:" "$project_score" "$WEIGHT_PROJECT_MATCH"
  printf "%-20s %3d (weight: %d%%)\n" "Team Popularity:" "$team_score" "$WEIGHT_TEAM_POPULARITY"
  printf "%-20s %3d (weight: %d%%)\n" "Personal History:" "$history_score" "$WEIGHT_PERSONAL_HISTORY"
  printf "%-20s %3d (weight: %d%%)\n" "Freshness:" "$fresh_score" "$WEIGHT_FRESHNESS"
  echo "---"
  printf "%-20s %3d\n" "TOTAL:" "$total"
}

# 플러그인 목록 정렬
sort_by_score() {
  local plugins_json="$1"
  local project_types="${2:-}"
  local frameworks="${3:-}"

  if [ -z "$plugins_json" ] || ! command -v jq &> /dev/null; then
    echo "$plugins_json"
    return
  fi

  # 각 플러그인에 점수 추가 후 정렬
  echo "$plugins_json" | jq -r '.[]' | while read plugin; do
    local score=$(calc_total_score "$plugin" "$project_types" "$frameworks")
    echo "$score $plugin"
  done | sort -rn | awk '{print $2}' | jq -R -s -c 'split("\n") | map(select(. != ""))'
}

# CLI 인터페이스
case "$1" in
  score)
    calc_total_score "$2" "$3" "$4" "$5"
    ;;
  breakdown)
    score_breakdown "$2" "$3" "$4" "$5"
    ;;
  project)
    calc_project_match_score "$2" "$3" "$4"
    ;;
  team)
    calc_team_popularity_score "$2"
    ;;
  history)
    calc_personal_history_score "$2"
    ;;
  fresh)
    calc_freshness_score "$2" "$3"
    ;;
  sort)
    sort_by_score "$2" "$3" "$4"
    ;;
  *)
    echo "Usage: $0 {score|breakdown|project|team|history|fresh|sort}"
    echo ""
    echo "Commands:"
    echo "  score <plugin> [types] [frameworks] [update]  - Calculate total score"
    echo "  breakdown <plugin> [...]                      - Show score breakdown"
    echo "  project <plugin> <types> <frameworks>         - Project match score"
    echo "  team <plugin>                                 - Team popularity score"
    echo "  history <plugin>                              - Personal history score"
    echo "  fresh <plugin> <last_update>                  - Freshness score"
    echo "  sort <plugins_json> [types] [frameworks]      - Sort plugins by score"
    echo ""
    echo "Score Weights:"
    echo "  Project Match:    $WEIGHT_PROJECT_MATCH%"
    echo "  Team Popularity:  $WEIGHT_TEAM_POPULARITY%"
    echo "  Personal History: $WEIGHT_PERSONAL_HISTORY%"
    echo "  Freshness:        $WEIGHT_FRESHNESS%"
    ;;
esac
