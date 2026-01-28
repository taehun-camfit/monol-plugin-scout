---
description: 우선순위 분석 (한글: 우선순위, 점수)
argument-hint: "<plugin-name>"
allowed-tools: [Read, Bash]
hooks:
  Stop:
    - hooks:
        - type: command
          command: "bash ${CLAUDE_PLUGIN_ROOT}/hooks/track-usage.sh priority"
          timeout: 5
---

# /scout priority - 우선순위 분석

skills/priority.md를 참조하여 동작합니다.

## 인자: $ARGUMENTS

## 동작 요약

1. 플러그인 점수 계산
2. 요소별 상세 분석
3. 종합 점수 및 등급 표시

## 예시

```
/scout priority eslint-fix
/scout priority typescript-lsp
```
