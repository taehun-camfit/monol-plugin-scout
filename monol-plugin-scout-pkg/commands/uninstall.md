---
description: 플러그인 제거 (한글: 제거, 삭제, 언인스톨)
argument-hint: "<plugin-name>"
allowed-tools: [Read, Bash, AskUserQuestion]
hooks:
  Stop:
    - hooks:
        - type: command
          command: "bash ${CLAUDE_PLUGIN_ROOT}/hooks/track-usage.sh uninstall"
          timeout: 5
---

# /scout uninstall - 플러그인 제거

skills/uninstall.md를 참조하여 동작합니다.

## 인자: $ARGUMENTS

## 동작 요약

1. 설치 여부 및 사용량 확인
2. AskUserQuestion으로 제거 확인
3. 승인 시 `lib/plugin-manager.sh uninstall` 실행
4. 비활성화만 선택 시 `lib/plugin-manager.sh disable` 실행

## 예시

```
/scout uninstall old-formatter
/scout remove unused-plugin
```
