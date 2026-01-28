---
description: 팀 협업 - 팀원 통계 및 추천 공유 (한글: 팀, 팀원, 협업)
argument-hint: "[members | stats | share | shared | summary]"
allowed-tools: [Read, Bash, AskUserQuestion]
---

# /scout team - 팀 협업

팀원별 플러그인 사용 통계와 추천 공유 기능입니다.

## 사용법

```
/scout team                  # 팀 요약
/scout team members          # 팀원 목록
/scout team stats            # 팀 통계 갱신
/scout team share <plugin>   # 플러그인 추천 공유
/scout team shared           # 공유된 추천 목록
/scout team name <name>      # 팀 이름 설정
```

## 인자: $ARGUMENTS

## 동작

### 팀 요약 (기본)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/lib/team-manager.sh summary
```

팀 전체 현황을 표시합니다:
- 총 멤버 수, 활성 멤버 수
- 사용된 플러그인 수
- 인기 플러그인 TOP 3
- 공유된 추천

### 팀원 목록

```bash
bash ${CLAUDE_PLUGIN_ROOT}/lib/team-manager.sh members
```

### 팀 통계 갱신

```bash
bash ${CLAUDE_PLUGIN_ROOT}/lib/team-manager.sh stats
```

7일 내 활성 멤버, 전체 플러그인 사용량 등을 계산합니다.

### 플러그인 추천 공유

```bash
bash ${CLAUDE_PLUGIN_ROOT}/lib/team-manager.sh share <plugin> "<reason>"
```

팀원들에게 플러그인을 추천합니다. 추천 사유를 함께 남기면 좋습니다.

### 공유된 추천 목록

```bash
bash ${CLAUDE_PLUGIN_ROOT}/lib/team-manager.sh shared
```

## 출력 형식

```markdown
## 팀 요약: [팀 이름]

### 멤버
- 총 멤버: 4명
- 활성 멤버 (7일 내): 3명

### 플러그인 사용
- 총 사용 플러그인: 12개
- 인기 플러그인:
  1. commit-commands (4명 사용)
  2. code-review (3명 사용)
  3. typescript-lsp (2명 사용)

### 공유 추천
| 플러그인 | 추천 사유 | 추천자 |
|----------|----------|--------|
| eslint-fix | 코드 품질 향상 | kent |
| prettier | 포맷 통일 | john |

### 관리
- `/scout team name <팀명>` - 팀 이름 설정
- `/scout team share <plugin> "<사유>"` - 추천 공유
```

## 예시

```
/scout team
→ 팀 요약 표시

/scout team share eslint-fix "코드 품질 향상에 필수!"
→ eslint-fix 플러그인을 팀에 추천

/scout team shared
→ 공유된 추천 목록

/scout team name "Frontend Team"
→ 팀 이름을 "Frontend Team"으로 설정
```

## 자동 등록

세션 시작 시 현재 사용자가 자동으로 팀에 등록됩니다.
Git 사용자 정보(user.name, user.email)가 함께 저장됩니다.

## 관련 명령어

- `/scout console` - 콘솔에서 팀 통계 확인
- `/scout` - 개인 추천 (팀 추천과 병합 가능)
