---
description: 스마트 타이밍 - 추천 시점 설정 (한글: 타이밍, 추천시점, 언제추천)
argument-hint: "[after-commit | after-pr | always] [on | off]"
allowed-tools: [Read, Bash]
---

# /scout timing - 스마트 타이밍 설정

플러그인 추천이 표시되는 시점을 제어합니다.

## 사용법

```
/scout timing                      # 현재 설정 확인
/scout timing after-commit on      # 커밋 후에만 추천
/scout timing after-pr on          # PR 후에만 추천
/scout timing always               # 항상 추천 (기본값)
```

## 인자: $ARGUMENTS

## 동작

### 현재 설정 확인 (기본)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/lib/recommendation-controller.sh status
```

### 커밋 후 추천만 활성화

```bash
bash ${CLAUDE_PLUGIN_ROOT}/lib/recommendation-controller.sh smart-timing after-commit true
```

커밋 완료 후에만 플러그인 추천이 표시됩니다.

### PR 후 추천만 활성화

```bash
bash ${CLAUDE_PLUGIN_ROOT}/lib/recommendation-controller.sh smart-timing after-pr true
```

PR 생성 후에만 플러그인 추천이 표시됩니다.

### 항상 추천 (기본값)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/lib/recommendation-controller.sh smart-timing after-commit false
bash ${CLAUDE_PLUGIN_ROOT}/lib/recommendation-controller.sh smart-timing after-pr false
```

## 스마트 타이밍 옵션

| 옵션 | 설명 | 적합한 상황 |
|------|------|------------|
| always | 항상 추천 | 기본 설정 |
| after-commit | 커밋 후에만 | 작업 완료 시점에 추천 원할 때 |
| after-pr | PR 후에만 | 코드 리뷰 전 추천 원할 때 |

## 출력 형식

```markdown
## 스마트 타이밍 설정

| 설정 | 상태 |
|------|------|
| 커밋 후 추천 | 비활성화 |
| PR 후 추천 | 비활성화 |
| 현재 모드 | 항상 추천 |

### 설정 변경
- `/scout timing after-commit on` - 커밋 후에만 추천
- `/scout timing after-pr on` - PR 후에만 추천
- `/scout timing always` - 항상 추천
```

## 예시

```
/scout timing
→ 현재 스마트 타이밍 설정 표시

/scout timing after-commit on
→ 커밋 후에만 추천 활성화

/scout timing after-pr on
→ PR 후에만 추천 활성화

/scout timing always
→ 모든 타이밍 제한 해제
```

## 관련 명령어

- `/scout quiet` - 무음 모드 (모든 추천 비활성화)
- `/scout frequency` - 추천 빈도 설정
