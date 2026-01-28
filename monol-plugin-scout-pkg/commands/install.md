---
description: 플러그인 설치 (한글: 설치, 플러그인설치)
argument-hint: "<plugin-name[@marketplace]>"
allowed-tools: [Read, Bash, AskUserQuestion]
hooks:
  Stop:
    - hooks:
        - type: command
          command: "bash ${CLAUDE_PLUGIN_ROOT}/hooks/track-usage.sh install"
          timeout: 5
---

# /scout install - 플러그인 설치

skills/install.md를 참조하여 동작합니다.

## 인자: $ARGUMENTS

## 동작 요약

1. 플러그인 존재 및 거절 이력 확인
2. AskUserQuestion으로 설치 확인
3. 승인 시 `lib/plugin-manager.sh install` 실행
4. 거절 시 `lib/rejection-learner.sh record` 실행

## 예시

```
/scout install typescript-lsp
/scout install code-review@monol
/scout install --list
```
