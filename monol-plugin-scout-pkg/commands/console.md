---
description: 플러그인 대시보드 콘솔 - 전체 현황 및 분석 (한글: 콘솔, 대시보드, 플러그인현황)
argument-hint: "[--web | --view <dashboard|plugins|analytics|users> | --plugin <name> | --user <name>]"
allowed-tools: [Read, Glob, Grep, Bash, WebFetch, AskUserQuestion]
hooks:
  Stop:
    - hooks:
        - type: command
          command: "bash ${CLAUDE_PLUGIN_ROOT}/hooks/track-usage.sh console"
          timeout: 5
---

# /scout console - 플러그인 대시보드 콘솔

플러그인 현황을 대시보드 형태로 보여주고, 상세 정보 조회, 사용 분석, 인사이트를 제공합니다.

## 사용법

```
/scout console                    # 메인 대시보드 (CLI)
/scout console --web              # 웹 대시보드 (브라우저에서 열림)
/scout console --view dashboard   # 대시보드 뷰
/scout console --view plugins     # 플러그인 목록
/scout console --view analytics   # 사용 분석
/scout console --view users       # 사용자 분석
/scout console --plugin <name>    # 특정 플러그인 상세
/scout console --user <name>      # 특정 사용자 분석
```

## 인자: $ARGUMENTS

## 동작

### --web 옵션 (웹 대시보드)

`--web` 인자가 포함된 경우, 브라우저에서 웹 대시보드를 엽니다:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/hooks/open-console.sh
```

웹 대시보드를 연 후 안내 메시지를 표시합니다.

### CLI 대시보드 (기본)

skills/console.md를 참조하여 동일하게 동작합니다.

### 핵심 동작 요약

1. **데이터 수집**: 설치된 플러그인, 활성화 상태, 사용량 데이터, 마켓플레이스 정보 수집
2. **대시보드 렌더링**: ASCII 아트 기반 대시보드 표시
3. **인터랙티브 메뉴**: AskUserQuestion으로 다음 동작 선택
4. **뷰별 상세**: 플러그인 목록, 상세, 분석, 사용자 분석 뷰 제공

## 데이터 소스

| 데이터 | 경로 |
|--------|------|
| 설치된 플러그인 | `~/.claude/plugins/installed_plugins.json` |
| 활성화 상태 | `~/.claude/settings.json` |
| 마켓플레이스 | `~/.claude/plugins/known_marketplaces.json` |
| 사용량 | `${CLAUDE_PLUGIN_ROOT}/data/usage.json` |
| 분석 | `${CLAUDE_PLUGIN_ROOT}/data/analytics.json` |

## 예시

```
/scout console
→ 메인 대시보드 표시

/scout console --view analytics
→ 사용 분석 뷰

/scout console --plugin commit-commands
→ commit-commands 상세 정보

/scout console --user kent
→ kent 사용자 분석
```
