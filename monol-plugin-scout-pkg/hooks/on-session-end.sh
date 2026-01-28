#!/bin/bash
# Plugin Scout - 세션 종료 시 사용 이력 기록

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}"
DATA_DIR="$PLUGIN_ROOT/data"
USAGE_FILE="$DATA_DIR/usage.json"
ANALYTICS_FILE="$DATA_DIR/analytics.json"
SESSION_FILE="$DATA_DIR/.session"

# usage.json이 없으면 초기화 (users 섹션 포함)
if [ ! -f "$USAGE_FILE" ]; then
  cat > "$USAGE_FILE" << 'EOF'
{
  "lastUpdated": "",
  "config": {
    "unusedThresholdDays": 30,
    "lowUsageThreshold": 3
  },
  "plugins": {},
  "users": {},
  "sessions": {
    "total": 0,
    "thisWeek": 0
  }
}
EOF
fi

# analytics.json이 없으면 초기화
if [ ! -f "$ANALYTICS_FILE" ]; then
  cat > "$ANALYTICS_FILE" << 'EOF'
{
  "version": "1.0.0",
  "lastUpdated": "",
  "summary": {
    "totalPlugins": 0,
    "activePlugins": 0,
    "totalUsageCount": 0
  },
  "trends": {
    "weekly": [],
    "monthly": []
  },
  "pluginStats": {},
  "userStats": {},
  "insights": []
}
EOF
fi

# 세션 파일에서 데이터 읽기
if [ -f "$SESSION_FILE" ] && command -v jq &> /dev/null; then
  TODAY=$(date +"%Y-%m-%d")
  NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # 세션에서 사용자 및 스킬 추출
  SESSION_USER=$(jq -r '.user // "unknown"' "$SESSION_FILE" 2>/dev/null)
  SKILLS=$(jq -r '.skills_used[]' "$SESSION_FILE" 2>/dev/null)

  # 세션 카운트 증가
  TEMP_FILE=$(mktemp)
  jq --arg now "$NOW" '
    .lastUpdated = $now |
    .sessions.total += 1
  ' "$USAGE_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$USAGE_FILE"

  # 사용자별 세션 카운트
  if [ -n "$SESSION_USER" ] && [ "$SESSION_USER" != "unknown" ]; then
    TEMP_FILE=$(mktemp)
    jq --arg user "$SESSION_USER" --arg today "$TODAY" --arg now "$NOW" '
      .lastUpdated = $now |
      if .users[$user] then
        .users[$user].sessions += 1 |
        .users[$user].lastActive = $today
      else
        .users[$user] = {
          "plugins": {},
          "sessions": 1,
          "lastActive": $today,
          "firstSeen": $today
        }
      end
    ' "$USAGE_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$USAGE_FILE"
  fi

  # 스킬별 사용량 업데이트
  if [ -n "$SKILLS" ]; then
    for skill in $SKILLS; do
      if [ -n "$skill" ]; then
        # 플러그인 전체 사용량 업데이트
        TEMP_FILE=$(mktemp)
        jq --arg skill "$skill" --arg today "$TODAY" --arg now "$NOW" '
          .lastUpdated = $now |
          if .plugins[$skill] then
            .plugins[$skill].usageCount += 1 |
            .plugins[$skill].lastUsed = $today
          else
            .plugins[$skill] = {
              "installed": $today,
              "usageCount": 1,
              "lastUsed": $today
            }
          end
        ' "$USAGE_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$USAGE_FILE"

        # 사용자별 플러그인 사용량 업데이트
        if [ -n "$SESSION_USER" ] && [ "$SESSION_USER" != "unknown" ]; then
          TEMP_FILE=$(mktemp)
          jq --arg user "$SESSION_USER" --arg skill "$skill" --arg today "$TODAY" '
            if .users[$user].plugins[$skill] then
              .users[$user].plugins[$skill].usageCount += 1 |
              .users[$user].plugins[$skill].lastUsed = $today
            else
              .users[$user].plugins[$skill] = {
                "usageCount": 1,
                "lastUsed": $today
              }
            end
          ' "$USAGE_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$USAGE_FILE"
        fi

        # analytics.json 총 사용량 업데이트
        TEMP_FILE=$(mktemp)
        jq --arg now "$NOW" '
          .lastUpdated = $now |
          .summary.totalUsageCount += 1
        ' "$ANALYTICS_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$ANALYTICS_FILE"
      fi
    done
  fi

  # 세션 파일 정리
  rm -f "$SESSION_FILE"
fi

# 조용히 종료 (출력 없음)
