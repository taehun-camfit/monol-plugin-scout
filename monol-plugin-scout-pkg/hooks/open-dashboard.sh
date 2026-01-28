#!/bin/bash
# Plugin Scout - 웹 대시보드 열기
# 데이터를 HTML에 주입하고 브라우저에서 열기

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}"
DATA_DIR="$PLUGIN_ROOT/data"
WEB_DIR="$PLUGIN_ROOT/web"
TEMPLATE="$WEB_DIR/dashboard.html"
OUTPUT="/tmp/plugin-scout-dashboard.html"

# 데이터 파일 확인
USAGE_FILE="$DATA_DIR/usage.json"
ANALYTICS_FILE="$DATA_DIR/analytics.json"

if [ ! -f "$USAGE_FILE" ]; then
  echo "Error: usage.json not found"
  exit 1
fi

if [ ! -f "$ANALYTICS_FILE" ]; then
  echo "Error: analytics.json not found"
  exit 1
fi

if [ ! -f "$TEMPLATE" ]; then
  echo "Error: dashboard.html template not found"
  exit 1
fi

# JSON 데이터 읽기 (한 줄로 압축)
USAGE_DATA=$(cat "$USAGE_FILE" | tr -d '\n' | sed 's/"/\\"/g' | sed "s/'/\\'/g")
ANALYTICS_DATA=$(cat "$ANALYTICS_FILE" | tr -d '\n' | sed 's/"/\\"/g' | sed "s/'/\\'/g")

# 템플릿에 데이터 주입
# jq가 있으면 사용, 없으면 cat 사용
if command -v jq &> /dev/null; then
  USAGE_JSON=$(jq -c '.' "$USAGE_FILE")
  ANALYTICS_JSON=$(jq -c '.' "$ANALYTICS_FILE")
else
  USAGE_JSON=$(cat "$USAGE_FILE" | tr -d '\n')
  ANALYTICS_JSON=$(cat "$ANALYTICS_FILE" | tr -d '\n')
fi

# HTML 생성 (데이터 주입)
sed -e "s|__USAGE_DATA__|$USAGE_JSON|g" \
    -e "s|__ANALYTICS_DATA__|$ANALYTICS_JSON|g" \
    "$TEMPLATE" > "$OUTPUT"

# 브라우저에서 열기
if [[ "$OSTYPE" == "darwin"* ]]; then
  open "$OUTPUT"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  xdg-open "$OUTPUT" 2>/dev/null || sensible-browser "$OUTPUT" 2>/dev/null
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
  start "$OUTPUT"
else
  echo "Dashboard generated: $OUTPUT"
  echo "Please open this file in your browser."
fi

echo "Dashboard opened: $OUTPUT"
