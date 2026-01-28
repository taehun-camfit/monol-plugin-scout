#!/bin/bash
# Plugin Scout - 웹 콘솔 열기
# 로컬 데이터를 HTML에 주입하고 브라우저에서 열기

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}"
DATA_DIR="$PLUGIN_ROOT/data"
WEB_DIR="$PLUGIN_ROOT/web"
API_DIR="$PLUGIN_ROOT/api/mock"
TEMPLATE="$WEB_DIR/console.html"
OUTPUT="/tmp/plugin-scout-console.html"

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
  echo "Error: console.html template not found"
  exit 1
fi

# JSON 데이터 읽기
if command -v jq &> /dev/null; then
  USAGE_JSON=$(jq -c '.' "$USAGE_FILE")
  ANALYTICS_JSON=$(jq -c '.' "$ANALYTICS_FILE")

  # Mock API 데이터 읽기
  if [ -f "$API_DIR/marketplace.json" ]; then
    MARKETPLACE_JSON=$(jq -c '.' "$API_DIR/marketplace.json")
  else
    MARKETPLACE_JSON='{"plugins":[],"total":0}'
  fi

  if [ -f "$API_DIR/categories.json" ]; then
    CATEGORIES_JSON=$(jq -c '.' "$API_DIR/categories.json")
  else
    CATEGORIES_JSON='{"categories":[]}'
  fi

  if [ -f "$API_DIR/trending.json" ]; then
    TRENDING_JSON=$(jq -c '.' "$API_DIR/trending.json")
  else
    TRENDING_JSON='{"plugins":[]}'
  fi

  if [ -f "$API_DIR/insights.json" ]; then
    INSIGHTS_JSON=$(jq -c '.' "$API_DIR/insights.json")
  else
    INSIGHTS_JSON='{"insights":[]}'
  fi
else
  USAGE_JSON=$(cat "$USAGE_FILE" | tr -d '\n')
  ANALYTICS_JSON=$(cat "$ANALYTICS_FILE" | tr -d '\n')

  # Mock API 데이터 읽기 (jq 없이)
  if [ -f "$API_DIR/marketplace.json" ]; then
    MARKETPLACE_JSON=$(cat "$API_DIR/marketplace.json" | tr -d '\n')
  else
    MARKETPLACE_JSON='{"plugins":[],"total":0}'
  fi

  if [ -f "$API_DIR/categories.json" ]; then
    CATEGORIES_JSON=$(cat "$API_DIR/categories.json" | tr -d '\n')
  else
    CATEGORIES_JSON='{"categories":[]}'
  fi

  if [ -f "$API_DIR/trending.json" ]; then
    TRENDING_JSON=$(cat "$API_DIR/trending.json" | tr -d '\n')
  else
    TRENDING_JSON='{"plugins":[]}'
  fi

  if [ -f "$API_DIR/insights.json" ]; then
    INSIGHTS_JSON=$(cat "$API_DIR/insights.json" | tr -d '\n')
  else
    INSIGHTS_JSON='{"insights":[]}'
  fi
fi

# HTML 생성 (데이터 주입)
sed -e "s|__USAGE_DATA__|$USAGE_JSON|g" \
    -e "s|__ANALYTICS_DATA__|$ANALYTICS_JSON|g" \
    -e "s|__MARKETPLACE_DATA__|$MARKETPLACE_JSON|g" \
    -e "s|__CATEGORIES_DATA__|$CATEGORIES_JSON|g" \
    -e "s|__TRENDING_DATA__|$TRENDING_JSON|g" \
    -e "s|__INSIGHTS_DATA__|$INSIGHTS_JSON|g" \
    "$TEMPLATE" > "$OUTPUT"

# 브라우저에서 열기
if [[ "$OSTYPE" == "darwin"* ]]; then
  open "$OUTPUT"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  xdg-open "$OUTPUT" 2>/dev/null || sensible-browser "$OUTPUT" 2>/dev/null
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
  start "$OUTPUT"
else
  echo "Console generated: $OUTPUT"
  echo "Please open this file in your browser."
fi

echo "Console opened: $OUTPUT"
