#!/bin/bash
# Plugin Scout - 인사이트 생성 스크립트
# 세션 시작 시 또는 콘솔 실행 시 호출

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}"
DATA_DIR="$PLUGIN_ROOT/data"
USAGE_FILE="$DATA_DIR/usage.json"
ANALYTICS_FILE="$DATA_DIR/analytics.json"

# jq가 없으면 종료
if ! command -v jq &> /dev/null; then
  exit 0
fi

# 파일 존재 확인
if [ ! -f "$USAGE_FILE" ] || [ ! -f "$ANALYTICS_FILE" ]; then
  exit 0
fi

NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TODAY=$(date +"%Y-%m-%d")
THIRTY_DAYS_AGO=$(date -v-30d +"%Y-%m-%d" 2>/dev/null || date -d "30 days ago" +"%Y-%m-%d" 2>/dev/null)

# 인사이트 배열 초기화
INSIGHTS="[]"

# 1. 미사용 플러그인 체크 (30일 이상)
UNUSED_PLUGINS=$(jq -r --arg threshold "$THIRTY_DAYS_AGO" '
  .plugins | to_entries |
  map(select(.value.lastUsed < $threshold or .value.lastUsed == null)) |
  .[].key
' "$USAGE_FILE" 2>/dev/null)

for plugin in $UNUSED_PLUGINS; do
  if [ -n "$plugin" ]; then
    DAYS_AGO=$(jq -r --arg p "$plugin" '.plugins[$p].lastUsed // "never"' "$USAGE_FILE")
    INSIGHT=$(jq -n --arg plugin "$plugin" --arg days "$DAYS_AGO" --arg now "$NOW" '{
      "type": "cleanup",
      "severity": "warning",
      "message": "\($plugin)이 오래 미사용 상태입니다 (마지막: \($days))",
      "action": "/scout cleanup",
      "generated": $now
    }')
    INSIGHTS=$(echo "$INSIGHTS" | jq --argjson insight "$INSIGHT" '. + [$insight]')
  fi
done

# 2. 가장 많이 사용된 플러그인 분석
TOP_PLUGIN=$(jq -r '.plugins | to_entries | sort_by(.value.usageCount) | reverse | .[0].key // ""' "$USAGE_FILE" 2>/dev/null)
if [ -n "$TOP_PLUGIN" ]; then
  TOP_COUNT=$(jq -r --arg p "$TOP_PLUGIN" '.plugins[$p].usageCount // 0' "$USAGE_FILE")
  INSIGHT=$(jq -n --arg plugin "$TOP_PLUGIN" --arg count "$TOP_COUNT" --arg now "$NOW" '{
    "type": "trend-up",
    "severity": "info",
    "message": "\($plugin)이 가장 활발히 사용됩니다 (\($count)회)",
    "action": "",
    "generated": $now
  }')
  INSIGHTS=$(echo "$INSIGHTS" | jq --argjson insight "$INSIGHT" '. + [$insight]')
fi

# 3. 사용량 없는 플러그인 체크
ZERO_USAGE=$(jq -r '.plugins | to_entries | map(select(.value.usageCount == 0)) | .[].key' "$USAGE_FILE" 2>/dev/null)
for plugin in $ZERO_USAGE; do
  if [ -n "$plugin" ]; then
    INSIGHT=$(jq -n --arg plugin "$plugin" --arg now "$NOW" '{
      "type": "cleanup",
      "severity": "warning",
      "message": "\($plugin)이 설치 후 한 번도 사용되지 않았습니다",
      "action": "/scout cleanup",
      "generated": $now
    }')
    INSIGHTS=$(echo "$INSIGHTS" | jq --argjson insight "$INSIGHT" '. + [$insight]')
  fi
done

# 4. 전체 통계 업데이트
TOTAL_PLUGINS=$(jq '.plugins | length' "$USAGE_FILE" 2>/dev/null || echo 0)
TOTAL_USAGE=$(jq '[.plugins[].usageCount] | add // 0' "$USAGE_FILE" 2>/dev/null || echo 0)
ACTIVE_PLUGINS=$(jq --arg threshold "$THIRTY_DAYS_AGO" '
  [.plugins | to_entries[] | select(.value.lastUsed >= $threshold)] | length
' "$USAGE_FILE" 2>/dev/null || echo 0)
DORMANT_PLUGINS=$((TOTAL_PLUGINS - ACTIVE_PLUGINS))

# analytics.json 업데이트
TEMP_FILE=$(mktemp)
jq --arg now "$NOW" \
   --argjson total "$TOTAL_PLUGINS" \
   --argjson active "$ACTIVE_PLUGINS" \
   --argjson dormant "$DORMANT_PLUGINS" \
   --argjson usage "$TOTAL_USAGE" \
   --argjson insights "$INSIGHTS" '
  .lastUpdated = $now |
  .summary.totalPlugins = $total |
  .summary.activePlugins = $active |
  .summary.dormantPlugins = $dormant |
  .summary.totalUsageCount = $usage |
  .insights = $insights
' "$ANALYTICS_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$ANALYTICS_FILE"

# 결과 출력 (디버그용, 필요시 주석 처리)
# echo "Insights generated: $(echo "$INSIGHTS" | jq length)"
