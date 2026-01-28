---
description: 무음 모드 - 추천 알림 비활성화 (한글: 무음, 조용히, 알림끄기)
argument-hint: "[on | off | status]"
allowed-tools: [Read, Bash]
---

# /scout quiet - 무음 모드

플러그인 추천 알림을 일시적으로 비활성화합니다.

## 사용법

```
/scout quiet           # 현재 상태 확인
/scout quiet on        # 무음 모드 활성화
/scout quiet off       # 무음 모드 비활성화
/scout quiet toggle    # 무음 모드 토글
```

## 인자: $ARGUMENTS

## 동작

### 상태 확인 (기본)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/lib/recommendation-controller.sh quiet status
```

### 무음 모드 활성화

```bash
bash ${CLAUDE_PLUGIN_ROOT}/lib/recommendation-controller.sh quiet on
```

무음 모드가 활성화되면:
- Stop Hook에서 자동 추천이 표시되지 않음
- `/scout` 명령어는 정상 동작
- 수동으로 해제할 때까지 유지

### 무음 모드 비활성화

```bash
bash ${CLAUDE_PLUGIN_ROOT}/lib/recommendation-controller.sh quiet off
```

## 출력 형식

```markdown
## 무음 모드

**상태**: [활성화 | 비활성화]

무음 모드가 활성화되면 자동 추천이 표시되지 않습니다.
수동으로 `/scout`를 실행하면 추천을 확인할 수 있습니다.

### 설정 변경
- `/scout quiet on` - 무음 모드 켜기
- `/scout quiet off` - 무음 모드 끄기
```

## 예시

```
/scout quiet
→ 현재 무음 모드: 비활성화

/scout quiet on
→ 무음 모드가 활성화되었습니다.

/scout quiet off
→ 무음 모드가 비활성화되었습니다.
```
