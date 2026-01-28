---
description: 스케줄 관리 - 정기 작업 예약 (한글: 예약, 스케줄, 정기작업)
argument-hint: "[list | add | remove] ..."
allowed-tools: [Read, Bash, AskUserQuestion]
---

# /scout schedule - 스케줄 관리

정기적인 플러그인 관련 작업을 예약합니다.

## 사용법

```
/scout schedule                          # 예약된 작업 목록
/scout schedule add <type> <interval>    # 작업 추가
/scout schedule remove <id>              # 작업 삭제
/scout schedule run                      # 대기 중인 작업 실행
```

## 인자: $ARGUMENTS

## 동작

### 목록 조회 (기본)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/lib/scheduler.sh list
```

### 작업 추가

```bash
bash ${CLAUDE_PLUGIN_ROOT}/lib/scheduler.sh add <type> <interval> [target] [message]
```

작업 유형:
- `check-updates` - 플러그인 업데이트 확인
- `cleanup` - 캐시 및 로그 정리
- `audit` - 보안 감사
- `remind` - 리마인더

주기:
- `daily` - 매일
- `weekly` - 매주
- `monthly` - 매월
- `once` - 일회성

### 작업 삭제

```bash
bash ${CLAUDE_PLUGIN_ROOT}/lib/scheduler.sh remove <task-id>
```

### 대기 중인 작업 실행

```bash
bash ${CLAUDE_PLUGIN_ROOT}/lib/scheduler.sh run-due
```

## 출력 형식

```markdown
## 예약된 작업

| ID | 유형 | 주기 | 대상 | 다음 실행 | 상태 |
|----|------|------|------|----------|------|
| abc123 | cleanup | weekly | all | 2026-01-29 | 활성 |
| def456 | check-updates | daily | all | 2026-01-23 | 활성 |

### 명령어
- `/scout schedule add cleanup weekly` - 주간 정리 추가
- `/scout schedule add remind once all "플러그인 검토하기"` - 리마인더 추가
- `/scout schedule remove abc123` - 작업 삭제
```

## 예시

```
/scout schedule
→ 예약된 작업 목록

/scout schedule add cleanup weekly
→ 주간 정리 작업 추가

/scout schedule add remind daily all "플러그인 업데이트 확인"
→ 매일 리마인더 추가

/scout schedule remove abc123
→ 작업 삭제
```

## 관련 명령어

- `/scout quiet` - 무음 모드
- `/scout frequency` - 추천 빈도 설정
