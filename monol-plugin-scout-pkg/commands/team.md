---
description: 팀 협업 - 팀원 통계 및 추천 공유 (한글: 팀, 팀원, 협업)
argument-hint: "[members | stats | share | shared | summary]"
allowed-tools: [Read, Bash, AskUserQuestion]
hooks:
  Stop:
    - hooks:
        - type: command
          command: "bash ${CLAUDE_PLUGIN_ROOT}/hooks/track-usage.sh team"
          timeout: 5
---

# /scout team - 팀 협업

skills/team.md를 참조하여 동작합니다.

## 인자: $ARGUMENTS

## 동작 요약

1. 팀 데이터 초기화 (없으면)
2. 요청된 하위 명령어 실행
3. 결과 포맷팅하여 출력

## 예시

```
/scout team                  # 팀 요약
/scout team members          # 팀원 목록
/scout team share eslint     # 추천 공유
/scout team shared           # 공유 추천 목록
```
