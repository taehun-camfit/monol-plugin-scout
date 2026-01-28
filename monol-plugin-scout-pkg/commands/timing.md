---
description: 스마트 타이밍 설정 (한글: 타이밍, 추천시점)
argument-hint: "[after-commit | after-pr | always] [on | off]"
allowed-tools: [Read, Bash]
hooks:
  Stop:
    - hooks:
        - type: command
          command: "bash ${CLAUDE_PLUGIN_ROOT}/hooks/track-usage.sh timing"
          timeout: 5
---

# /scout timing - 스마트 타이밍 설정

skills/timing.md를 참조하여 동작합니다.

## 인자: $ARGUMENTS

## 동작 요약

1. 현재 타이밍 설정 조회
2. after-commit/after-pr 설정 변경
3. history.json smartTiming 업데이트

## 예시

```
/scout timing                 # 현재 설정 확인
/scout timing after-commit on # 커밋 후에만 추천
/scout timing after-pr on     # PR 후에만 추천
/scout timing always          # 항상 추천
```
