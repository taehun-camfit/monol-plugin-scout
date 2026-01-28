#!/bin/bash
# Plugin Scout - 스킬 사용 추적
# 사용법: track-usage.sh <skill-name>

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}"
DATA_DIR="$PLUGIN_ROOT/data"
SESSION_FILE="$DATA_DIR/.session"
SKILL_NAME="${1:-unknown}"

# sync 모듈 로드
if [ -f "$PLUGIN_ROOT/lib/sync.sh" ]; then
  source "$PLUGIN_ROOT/lib/sync.sh"
fi

# 데이터 디렉토리 확인
mkdir -p "$DATA_DIR"

# 세션 파일이 없으면 생성
if [ ! -f "$SESSION_FILE" ]; then
  cat > "$SESSION_FILE" << EOF
{
  "started": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "recommended": false,
  "skills_used": []
}
EOF
fi

# jq가 있으면 사용, 없으면 sed로 대체
if command -v jq &> /dev/null; then
  TEMP_FILE=$(mktemp)
  jq --arg skill "$SKILL_NAME" '
    if (.skills_used | index($skill)) then .
    else .skills_used += [$skill]
    end
  ' "$SESSION_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$SESSION_FILE"
else
  # jq 없이 간단한 추가 (중복 체크 없음)
  if grep -q '"skills_used": \[\]' "$SESSION_FILE"; then
    sed -i.bak "s/\"skills_used\": \[\]/\"skills_used\": [\"$SKILL_NAME\"]/" "$SESSION_FILE"
  elif ! grep -q "\"$SKILL_NAME\"" "$SESSION_FILE"; then
    sed -i.bak "s/\"skills_used\": \[/\"skills_used\": [\"$SKILL_NAME\", /" "$SESSION_FILE"
  fi
  rm -f "$SESSION_FILE.bak"
fi

# 서버에 스킬 사용 이벤트 전송
if type sync_skill_used &>/dev/null; then
  sync_skill_used "$SKILL_NAME"
fi

# 팀 통계에 플러그인 사용 기록
if [ -f "$PLUGIN_ROOT/lib/team-manager.sh" ]; then
  CURRENT_USER="${USER:-unknown}"
  if command -v jq &> /dev/null && [ -f "$SESSION_FILE" ]; then
    CURRENT_USER=$(jq -r '.user // "unknown"' "$SESSION_FILE")
  fi
  bash "$PLUGIN_ROOT/lib/team-manager.sh" record "$CURRENT_USER" "$SKILL_NAME" >/dev/null 2>&1
fi
