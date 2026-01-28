---
description: 스케줄 관리 (한글: 예약, 스케줄, 정기작업)
argument-hint: "[list | add | remove | run]"
allowed-tools: [Read, Bash, AskUserQuestion]
hooks:
  Stop:
    - hooks:
        - type: command
          command: "bash ${CLAUDE_PLUGIN_ROOT}/hooks/track-usage.sh schedule"
          timeout: 5
---

# /scout schedule - 스케줄 관리

skills/schedule.md를 참조하여 동작합니다.

## 인자: $ARGUMENTS

## 동작 요약

1. 예약된 작업 목록 조회
2. 작업 추가/삭제
3. 대기 중인 작업 실행

## 예시

```
/scout schedule                          # 목록
/scout schedule add cleanup weekly       # 주간 정리 추가
/scout schedule remove abc123            # 삭제
/scout schedule run                      # 대기 작업 실행
```
