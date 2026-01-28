---
description: 무음 모드 - 추천 알림 비활성화 (한글: 무음, 조용히, 알림끄기)
argument-hint: "[on | off | status]"
allowed-tools: [Read, Bash]
hooks:
  Stop:
    - hooks:
        - type: command
          command: "bash ${CLAUDE_PLUGIN_ROOT}/hooks/track-usage.sh quiet"
          timeout: 5
---

# /scout quiet - 무음 모드

skills/quiet.md를 참조하여 동작합니다.

## 인자: $ARGUMENTS

## 동작 요약

1. 현재 무음 모드 상태 확인
2. on/off/toggle로 모드 변경
3. 변경 사항 history.json에 저장

## 예시

```
/scout quiet           # 상태 확인
/scout quiet on        # 무음 모드 활성화
/scout quiet off       # 무음 모드 비활성화
/scout quiet toggle    # 토글
```
