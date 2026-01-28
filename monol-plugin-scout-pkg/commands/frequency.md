---
description: 추천 빈도 설정 (한글: 빈도, 횟수, 추천빈도)
argument-hint: "[session | daily | cooldown] <value>"
allowed-tools: [Read, Bash]
hooks:
  Stop:
    - hooks:
        - type: command
          command: "bash ${CLAUDE_PLUGIN_ROOT}/hooks/track-usage.sh frequency"
          timeout: 5
---

# /scout frequency - 추천 빈도 설정

skills/frequency.md를 참조하여 동작합니다.

## 인자: $ARGUMENTS

## 동작 요약

1. 현재 빈도 설정 조회
2. session/daily/cooldown 값 변경
3. history.json preferences 업데이트

## 예시

```
/scout frequency              # 현재 설정 확인
/scout frequency session 2    # 세션당 2회
/scout frequency daily 5      # 하루 5회
/scout frequency cooldown 60  # 1시간 간격
```
