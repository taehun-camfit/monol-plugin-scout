#!/bin/bash
# Plugin Scout - 협업 학습 시스템
# 팀원 선택 패턴 통합, 팀 필수/금지 플러그인 정책, 온보딩 추천

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}"
DATA_DIR="$PLUGIN_ROOT/data"
TEAM_FILE="$DATA_DIR/team.json"
TEAM_CONFIG_FILE=".claude/team-plugins.json"

# 팀 데이터 초기화
init_team() {
  if [ ! -f "$TEAM_FILE" ]; then
    mkdir -p "$DATA_DIR"
    echo '{
  "version": "1.0.0",
  "lastUpdated": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
  "members": {},
  "sharedSelections": {},
  "policies": {
    "required": [],
    "forbidden": [],
    "recommended": []
  },
  "onboarding": {
    "completedMembers": [],
    "pendingMembers": []
  },
  "stats": {
    "totalMembers": 0,
    "activeMembers": 0,
    "commonPlugins": []
  }
}' > "$TEAM_FILE"
  fi
}

# 팀 설정 파일 로드
load_team_config() {
  local project_path="${1:-.}"
  local config_file="$project_path/$TEAM_CONFIG_FILE"

  if [ -f "$config_file" ] && command -v jq &> /dev/null; then
    cat "$config_file"
  else
    echo '{}'
  fi
}

# 팀 멤버 등록/업데이트
register_member() {
  local member_id="$1"
  local member_name="$2"

  init_team

  if ! command -v jq &> /dev/null; then
    echo "jq required"
    return
  fi

  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local exists=$(jq -r --arg id "$member_id" '.members[$id] // empty' "$TEAM_FILE")

  if [ -z "$exists" ]; then
    # 새 멤버 - 온보딩 대기열에 추가
    jq --arg id "$member_id" \
       --arg name "$member_name" \
       --arg ts "$timestamp" \
       '
       .lastUpdated = $ts |
       .members[$id] = {
         "name": $name,
         "joinedAt": $ts,
         "lastActive": $ts,
         "selections": [],
         "onboardingCompleted": false
       } |
       .onboarding.pendingMembers = (.onboarding.pendingMembers + [$id] | unique) |
       .stats.totalMembers = (.members | length)
       ' "$TEAM_FILE" > "$TEAM_FILE.tmp" && mv "$TEAM_FILE.tmp" "$TEAM_FILE"

    echo "Registered new member: $member_name ($member_id)"
  else
    # 기존 멤버 - 활동 시간 업데이트
    jq --arg id "$member_id" --arg ts "$timestamp" '
       .lastUpdated = $ts |
       .members[$id].lastActive = $ts
    ' "$TEAM_FILE" > "$TEAM_FILE.tmp" && mv "$TEAM_FILE.tmp" "$TEAM_FILE"

    echo "Updated member activity: $member_id"
  fi
}

# 멤버의 플러그인 선택 기록
record_member_selection() {
  local member_id="$1"
  local plugin_name="$2"
  local action="$3"  # install, uninstall, accept, reject

  init_team

  if ! command -v jq &> /dev/null; then
    echo "jq required"
    return
  fi

  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # 멤버 선택 기록
  jq --arg id "$member_id" \
     --arg plugin "$plugin_name" \
     --arg action "$action" \
     --arg ts "$timestamp" \
     '
     .lastUpdated = $ts |
     .members[$id].selections = ((.members[$id].selections // []) + [{
       "plugin": $plugin,
       "action": $action,
       "at": $ts
     }]) | .[-20:] |
     .members[$id].lastActive = $ts
     ' "$TEAM_FILE" > "$TEAM_FILE.tmp" && mv "$TEAM_FILE.tmp" "$TEAM_FILE"

  # 공유 선택 업데이트
  if [ "$action" = "install" ] || [ "$action" = "accept" ]; then
    jq --arg plugin "$plugin_name" --arg ts "$timestamp" '
      .sharedSelections[$plugin] = {
        "count": ((.sharedSelections[$plugin].count // 0) + 1),
        "lastSelected": $ts
      }
    ' "$TEAM_FILE" > "$TEAM_FILE.tmp" && mv "$TEAM_FILE.tmp" "$TEAM_FILE"
  fi

  echo "Recorded selection: $member_id -> $plugin_name ($action)"
}

# 팀 정책 설정
set_policy() {
  local policy_type="$1"  # required, forbidden, recommended
  local plugin_name="$2"
  local action="$3"       # add, remove

  init_team

  if ! command -v jq &> /dev/null; then
    echo "jq required"
    return
  fi

  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  if [ "$action" = "add" ]; then
    jq --arg type "$policy_type" \
       --arg plugin "$plugin_name" \
       --arg ts "$timestamp" \
       '
       .lastUpdated = $ts |
       .policies[$type] = (.policies[$type] + [$plugin] | unique)
       ' "$TEAM_FILE" > "$TEAM_FILE.tmp" && mv "$TEAM_FILE.tmp" "$TEAM_FILE"

    echo "Added to $policy_type: $plugin_name"
  else
    jq --arg type "$policy_type" \
       --arg plugin "$plugin_name" \
       --arg ts "$timestamp" \
       '
       .lastUpdated = $ts |
       .policies[$type] = (.policies[$type] | map(select(. != $plugin)))
       ' "$TEAM_FILE" > "$TEAM_FILE.tmp" && mv "$TEAM_FILE.tmp" "$TEAM_FILE"

    echo "Removed from $policy_type: $plugin_name"
  fi
}

# 플러그인이 팀 정책에 맞는지 확인
check_policy() {
  local plugin_name="$1"

  init_team

  if ! command -v jq &> /dev/null; then
    echo "allowed"
    return
  fi

  # 금지 목록 체크
  local forbidden=$(jq -r --arg plugin "$plugin_name" '
    if .policies.forbidden | index($plugin) then "forbidden" else "" end
  ' "$TEAM_FILE")

  if [ "$forbidden" = "forbidden" ]; then
    echo "forbidden"
    return
  fi

  # 필수 목록 체크 (추천용)
  local required=$(jq -r --arg plugin "$plugin_name" '
    if .policies.required | index($plugin) then "required" else "" end
  ' "$TEAM_FILE")

  if [ "$required" = "required" ]; then
    echo "required"
    return
  fi

  echo "allowed"
}

# 온보딩 상태 확인
check_onboarding() {
  local member_id="$1"

  init_team

  if ! command -v jq &> /dev/null; then
    echo "unknown"
    return
  fi

  local completed=$(jq -r --arg id "$member_id" '
    .members[$id].onboardingCompleted // false
  ' "$TEAM_FILE")

  echo "$completed"
}

# 온보딩 완료 처리
complete_onboarding() {
  local member_id="$1"

  init_team

  if ! command -v jq &> /dev/null; then
    echo "jq required"
    return
  fi

  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  jq --arg id "$member_id" --arg ts "$timestamp" '
    .lastUpdated = $ts |
    .members[$id].onboardingCompleted = true |
    .onboarding.completedMembers = (.onboarding.completedMembers + [$id] | unique) |
    .onboarding.pendingMembers = (.onboarding.pendingMembers | map(select(. != $id)))
  ' "$TEAM_FILE" > "$TEAM_FILE.tmp" && mv "$TEAM_FILE.tmp" "$TEAM_FILE"

  echo "Onboarding completed for: $member_id"
}

# 온보딩 추천 플러그인 목록
get_onboarding_recommendations() {
  local member_id="$1"

  init_team

  if ! command -v jq &> /dev/null; then
    echo "[]"
    return
  fi

  # 필수 + 추천 + 팀에서 많이 사용하는 플러그인
  jq '
    (.policies.required + .policies.recommended) as $policy |
    (.sharedSelections | to_entries | sort_by(-.value.count) | .[0:5] | map(.key)) as $popular |
    ($policy + $popular) | unique
  ' "$TEAM_FILE"
}

# 팀원 통계 업데이트
update_team_stats() {
  init_team

  if ! command -v jq &> /dev/null; then
    echo "jq required"
    return
  fi

  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # 7일 이내 활동한 멤버를 활성 멤버로 간주
  local cutoff=$(date -u -v-7d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "7 days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)

  jq --arg cutoff "$cutoff" --arg ts "$timestamp" '
    .lastUpdated = $ts |
    .stats.totalMembers = (.members | length) |
    .stats.activeMembers = ([.members | to_entries[] | select(.value.lastActive >= $cutoff)] | length) |
    .stats.commonPlugins = (
      .sharedSelections | to_entries |
      sort_by(-.value.count) |
      .[0:10] |
      map(.key)
    )
  ' "$TEAM_FILE" > "$TEAM_FILE.tmp" && mv "$TEAM_FILE.tmp" "$TEAM_FILE"

  echo "Team stats updated"
}

# 팀 공통 플러그인 추천
get_team_recommendations() {
  local member_id="$1"

  init_team

  if ! command -v jq &> /dev/null; then
    echo "[]"
    return
  fi

  # 멤버가 아직 사용하지 않는 팀 공통 플러그인 추천
  jq --arg id "$member_id" '
    (.members[$id].selections | map(.plugin) | unique) as $memberPlugins |
    .sharedSelections | to_entries |
    map(select(.key as $k | $memberPlugins | index($k) | not)) |
    sort_by(-.value.count) |
    .[0:5] |
    map(.key)
  ' "$TEAM_FILE"
}

# 팀 요약 출력
get_team_summary() {
  init_team
  update_team_stats

  if ! command -v jq &> /dev/null; then
    echo "jq required"
    return
  fi

  echo "=== Team Summary ==="
  echo ""
  echo "Members:"
  echo "  Total: $(jq -r '.stats.totalMembers' "$TEAM_FILE")"
  echo "  Active (7d): $(jq -r '.stats.activeMembers' "$TEAM_FILE")"
  echo ""
  echo "Policies:"
  echo "  Required: $(jq -r '.policies.required | join(", ")' "$TEAM_FILE")"
  echo "  Forbidden: $(jq -r '.policies.forbidden | join(", ")' "$TEAM_FILE")"
  echo "  Recommended: $(jq -r '.policies.recommended | join(", ")' "$TEAM_FILE")"
  echo ""
  echo "Common Plugins:"
  jq -r '.stats.commonPlugins | .[] | "  - \(.)"' "$TEAM_FILE"
  echo ""
  echo "Onboarding:"
  echo "  Completed: $(jq -r '.onboarding.completedMembers | length' "$TEAM_FILE")"
  echo "  Pending: $(jq -r '.onboarding.pendingMembers | length' "$TEAM_FILE")"
}

# 멤버 사용 리포트
get_member_report() {
  local member_id="$1"

  init_team

  if ! command -v jq &> /dev/null; then
    echo "jq required"
    return
  fi

  echo "=== Member Report: $member_id ==="
  echo ""
  jq -r --arg id "$member_id" '
    .members[$id] | if . then
      "Name: \(.name)\nJoined: \(.joinedAt | split("T")[0])\nLast Active: \(.lastActive | split("T")[0])\nOnboarding: \(.onboardingCompleted)\n\nRecent Selections:"
    else
      "Member not found"
    end
  ' "$TEAM_FILE"

  jq -r --arg id "$member_id" '
    .members[$id].selections | if . then
      reverse | .[0:10] | .[] | "  \(.at | split("T")[0]): \(.plugin) (\(.action))"
    else
      ""
    end
  ' "$TEAM_FILE"
}

# 팀 데이터 리셋
reset_team() {
  if [ -f "$TEAM_FILE" ]; then
    rm "$TEAM_FILE"
    init_team
    echo "Team data reset successfully"
  else
    echo "No team data to reset"
  fi
}

# CLI 인터페이스
case "$1" in
  init)
    init_team
    echo "Team learner initialized"
    ;;
  register)
    register_member "$2" "$3"
    ;;
  selection)
    record_member_selection "$2" "$3" "$4"
    ;;
  policy)
    set_policy "$2" "$3" "$4"
    ;;
  check-policy)
    check_policy "$2"
    ;;
  check-onboarding)
    check_onboarding "$2"
    ;;
  complete-onboarding)
    complete_onboarding "$2"
    ;;
  onboarding-recs)
    get_onboarding_recommendations "$2"
    ;;
  team-recs)
    get_team_recommendations "$2"
    ;;
  update-stats)
    update_team_stats
    ;;
  summary)
    get_team_summary
    ;;
  member-report)
    get_member_report "$2"
    ;;
  reset)
    reset_team
    ;;
  *)
    echo "Usage: $0 {init|register|selection|policy|check-policy|check-onboarding|complete-onboarding|onboarding-recs|team-recs|update-stats|summary|member-report|reset}"
    echo ""
    echo "Commands:"
    echo "  init                                       - Initialize team learner"
    echo "  register <member_id> <name>                - Register/update team member"
    echo "  selection <member_id> <plugin> <action>    - Record member plugin selection"
    echo "  policy <type> <plugin> <add|remove>        - Set team policy (required|forbidden|recommended)"
    echo "  check-policy <plugin>                      - Check plugin against team policy"
    echo "  check-onboarding <member_id>               - Check onboarding status"
    echo "  complete-onboarding <member_id>            - Mark onboarding as completed"
    echo "  onboarding-recs <member_id>                - Get onboarding recommendations"
    echo "  team-recs <member_id>                      - Get team-based recommendations"
    echo "  update-stats                               - Update team statistics"
    echo "  summary                                    - Show team summary"
    echo "  member-report <member_id>                  - Show member report"
    echo "  reset                                      - Reset team data"
    ;;
esac
