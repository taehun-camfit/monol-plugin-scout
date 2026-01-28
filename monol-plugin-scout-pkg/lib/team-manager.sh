#!/bin/bash
# Plugin Scout - 팀 매니저
# 팀원별 플러그인 사용 통계 및 공유 추천

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}"
DATA_DIR="$PLUGIN_ROOT/data"
TEAM_FILE="$DATA_DIR/team.json"
USAGE_FILE="$DATA_DIR/usage.json"

# 팀 데이터 초기화
init_team() {
  if [ ! -f "$TEAM_FILE" ]; then
    cat > "$TEAM_FILE" << 'EOF'
{
  "version": "1.0.0",
  "teamName": "",
  "members": {},
  "sharedRecommendations": [],
  "sharedSettings": {
    "defaultPlugins": [],
    "blockedPlugins": [],
    "categories": []
  },
  "stats": {
    "totalMembers": 0,
    "activeMembers": 0,
    "totalPluginsUsed": 0,
    "topPlugins": []
  },
  "createdAt": "",
  "updatedAt": ""
}
EOF
    # Set timestamps
    local now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    jq --arg ts "$now" '.createdAt = $ts | .updatedAt = $ts' "$TEAM_FILE" > "$TEAM_FILE.tmp" && mv "$TEAM_FILE.tmp" "$TEAM_FILE"
  fi
}

# 팀원 등록/업데이트
register_member() {
  local username="${1:-$USER}"
  local git_name=$(git config user.name 2>/dev/null || echo "$username")
  local git_email=$(git config user.email 2>/dev/null || echo "")
  local now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  init_team

  if ! command -v jq &> /dev/null; then
    echo "Error: jq required"
    return 1
  fi

  # Check if member exists
  local exists=$(jq -r --arg u "$username" '.members[$u] // null' "$TEAM_FILE")

  if [ "$exists" = "null" ]; then
    # New member
    jq --arg u "$username" --arg n "$git_name" --arg e "$git_email" --arg ts "$now" '
      .members[$u] = {
        "name": $n,
        "email": $e,
        "joinedAt": $ts,
        "lastActive": $ts,
        "sessions": 1,
        "pluginsUsed": [],
        "topPlugins": []
      } |
      .stats.totalMembers = (.members | length)
    ' "$TEAM_FILE" > "$TEAM_FILE.tmp" && mv "$TEAM_FILE.tmp" "$TEAM_FILE"
    echo "Member registered: $username ($git_name)"
  else
    # Update last active
    jq --arg u "$username" --arg ts "$now" '
      .members[$u].lastActive = $ts |
      .members[$u].sessions = ((.members[$u].sessions // 0) + 1)
    ' "$TEAM_FILE" > "$TEAM_FILE.tmp" && mv "$TEAM_FILE.tmp" "$TEAM_FILE"
    echo "Member updated: $username"
  fi
}

# 팀원 플러그인 사용 기록
record_plugin_usage() {
  local username="${1:-$USER}"
  local plugin="$2"
  local now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  if [ -z "$plugin" ]; then
    echo "Usage: record_plugin_usage <username> <plugin>"
    return 1
  fi

  init_team

  jq --arg u "$username" --arg p "$plugin" --arg ts "$now" '
    # Add to member pluginsUsed if not exists
    if .members[$u].pluginsUsed then
      if (.members[$u].pluginsUsed | index($p)) == null then
        .members[$u].pluginsUsed += [$p]
      else .
      end
    else . end |
    # Update last active
    .members[$u].lastActive = $ts
  ' "$TEAM_FILE" > "$TEAM_FILE.tmp" && mv "$TEAM_FILE.tmp" "$TEAM_FILE"
}

# 팀 통계 계산
calculate_stats() {
  init_team

  if ! command -v jq &> /dev/null; then
    echo "Error: jq required"
    return 1
  fi

  local now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local week_ago=$(date -v-7d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -d "7 days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)

  # Calculate active members (active in last 7 days) and plugin stats
  jq --arg ts "$now" --arg week "$week_ago" '
    # Count active members
    .stats.activeMembers = ([.members | to_entries[] | select(.value.lastActive > $week)] | length) |

    # Count total plugins used
    .stats.totalPluginsUsed = ([.members | to_entries[].value.pluginsUsed[]?] | unique | length) |

    # Get top plugins (most used across team)
    .stats.topPlugins = (
      [.members | to_entries[].value.pluginsUsed[]?] |
      group_by(.) |
      map({plugin: .[0], count: length}) |
      sort_by(-.count) |
      .[:5]
    ) |

    .updatedAt = $ts
  ' "$TEAM_FILE" > "$TEAM_FILE.tmp" && mv "$TEAM_FILE.tmp" "$TEAM_FILE"

  echo "Stats updated"
}

# 팀 추천 공유
share_recommendation() {
  local plugin="$1"
  local reason="${2:-Recommended by team member}"
  local username="${3:-$USER}"
  local now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  if [ -z "$plugin" ]; then
    echo "Usage: share_recommendation <plugin> [reason] [username]"
    return 1
  fi

  init_team

  jq --arg p "$plugin" --arg r "$reason" --arg u "$username" --arg ts "$now" '
    .sharedRecommendations += [{
      "plugin": $p,
      "reason": $r,
      "sharedBy": $u,
      "sharedAt": $ts,
      "votes": 1
    }] |
    # Remove duplicates, keep latest
    .sharedRecommendations = (
      .sharedRecommendations |
      group_by(.plugin) |
      map(sort_by(.sharedAt) | last)
    )
  ' "$TEAM_FILE" > "$TEAM_FILE.tmp" && mv "$TEAM_FILE.tmp" "$TEAM_FILE"

  echo "Shared recommendation: $plugin"
}

# 공유 추천 목록
list_shared_recommendations() {
  init_team

  jq -r '.sharedRecommendations | sort_by(-.votes) | .[] | "\(.plugin) - \(.reason) (by \(.sharedBy))"' "$TEAM_FILE"
}

# 팀 설정: 기본 플러그인 추가
add_default_plugin() {
  local plugin="$1"

  if [ -z "$plugin" ]; then
    echo "Usage: add_default_plugin <plugin>"
    return 1
  fi

  init_team

  jq --arg p "$plugin" '
    if (.sharedSettings.defaultPlugins | index($p)) == null then
      .sharedSettings.defaultPlugins += [$p]
    else . end
  ' "$TEAM_FILE" > "$TEAM_FILE.tmp" && mv "$TEAM_FILE.tmp" "$TEAM_FILE"

  echo "Default plugin added: $plugin"
}

# 팀 설정: 플러그인 차단
block_plugin() {
  local plugin="$1"

  if [ -z "$plugin" ]; then
    echo "Usage: block_plugin <plugin>"
    return 1
  fi

  init_team

  jq --arg p "$plugin" '
    if (.sharedSettings.blockedPlugins | index($p)) == null then
      .sharedSettings.blockedPlugins += [$p]
    else . end
  ' "$TEAM_FILE" > "$TEAM_FILE.tmp" && mv "$TEAM_FILE.tmp" "$TEAM_FILE"

  echo "Plugin blocked: $plugin"
}

# 팀 멤버 목록
list_members() {
  init_team

  echo "=== Team Members ==="
  jq -r '.members | to_entries[] | "\(.key): \(.value.name) (sessions: \(.value.sessions), last: \(.value.lastActive | split("T")[0]))"' "$TEAM_FILE"
}

# 팀 요약
summary() {
  init_team
  calculate_stats >/dev/null

  echo "=== Team Summary ==="
  echo ""
  jq -r '
    "Team: \(.teamName // "Unnamed")",
    "Members: \(.stats.totalMembers) total, \(.stats.activeMembers) active",
    "Plugins: \(.stats.totalPluginsUsed) used",
    "",
    "Top Plugins:",
    (.stats.topPlugins[:3][] | "  - \(.plugin): \(.count) users"),
    "",
    "Shared Recommendations: \(.sharedRecommendations | length)",
    (.sharedRecommendations[:3][] | "  - \(.plugin): \(.reason)")
  ' "$TEAM_FILE" 2>/dev/null || echo "No team data yet"
}

# 팀 추천 JSON 출력 (scout 통합용)
get_team_recommendations_json() {
  init_team

  jq '{
    sharedRecommendations: .sharedRecommendations,
    defaultPlugins: .sharedSettings.defaultPlugins,
    blockedPlugins: .sharedSettings.blockedPlugins,
    topPlugins: .stats.topPlugins
  }' "$TEAM_FILE"
}

# 플러그인 차단 여부 확인
is_plugin_blocked() {
  local plugin="$1"

  if [ -z "$plugin" ]; then
    echo "false"
    return
  fi

  init_team

  local blocked=$(jq -r --arg p "$plugin" '
    if (.sharedSettings.blockedPlugins | index($p)) != null then "true" else "false" end
  ' "$TEAM_FILE")

  echo "$blocked"
}

# 추천 플러그인 필터링 (차단된 것 제외)
filter_blocked_plugins() {
  local plugins_json="$1"

  init_team

  echo "$plugins_json" | jq --slurpfile team "$TEAM_FILE" '
    . - ($team[0].sharedSettings.blockedPlugins // [])
  '
}

# 팀 이름 설정
set_team_name() {
  local name="$1"

  if [ -z "$name" ]; then
    echo "Usage: set_team_name <name>"
    return 1
  fi

  init_team

  jq --arg n "$name" '.teamName = $n' "$TEAM_FILE" > "$TEAM_FILE.tmp" && mv "$TEAM_FILE.tmp" "$TEAM_FILE"

  echo "Team name set: $name"
}

# CLI 인터페이스
case "$1" in
  init)
    init_team
    echo "Team data initialized"
    ;;
  register)
    register_member "$2"
    ;;
  record)
    record_plugin_usage "$2" "$3"
    ;;
  stats)
    calculate_stats
    ;;
  share)
    share_recommendation "$2" "$3" "$4"
    ;;
  shared)
    list_shared_recommendations
    ;;
  default)
    add_default_plugin "$2"
    ;;
  block)
    block_plugin "$2"
    ;;
  members)
    list_members
    ;;
  summary)
    summary
    ;;
  name)
    set_team_name "$2"
    ;;
  recommendations)
    get_team_recommendations_json
    ;;
  is-blocked)
    is_plugin_blocked "$2"
    ;;
  filter)
    filter_blocked_plugins "$2"
    ;;
  *)
    echo "Usage: $0 {init|register|record|stats|share|shared|default|block|members|summary|name|recommendations|is-blocked|filter}"
    echo ""
    echo "Commands:"
    echo "  init                      - Initialize team data"
    echo "  register [username]       - Register/update team member"
    echo "  record <user> <plugin>    - Record plugin usage"
    echo "  stats                     - Calculate team statistics"
    echo "  share <plugin> [reason]   - Share a recommendation"
    echo "  shared                    - List shared recommendations"
    echo "  default <plugin>          - Add default plugin"
    echo "  block <plugin>            - Block a plugin"
    echo "  members                   - List team members"
    echo "  summary                   - Show team summary"
    echo "  name <name>               - Set team name"
    ;;
esac
