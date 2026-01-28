---
description: 추천 빈도 설정 - 세션/일일 추천 횟수 제한 (한글: 빈도, 횟수, 추천빈도)
argument-hint: "[session | daily] <count>"
allowed-tools: [Read, Bash]
---

# /scout frequency - 추천 빈도 설정

플러그인 추천이 표시되는 빈도를 제어합니다.

## 사용법

```
/scout frequency                     # 현재 설정 확인
/scout frequency session <count>     # 세션당 최대 추천 횟수
/scout frequency daily <count>       # 하루 최대 추천 횟수
/scout frequency cooldown <minutes>  # 추천 간 최소 간격
```

## 인자: $ARGUMENTS

## 동작

### 현재 설정 확인 (기본)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/lib/recommendation-controller.sh status
```

### 세션당 빈도 설정

```bash
bash ${CLAUDE_PLUGIN_ROOT}/lib/recommendation-controller.sh frequency session <count>
```

### 일일 빈도 설정

```bash
bash ${CLAUDE_PLUGIN_ROOT}/lib/recommendation-controller.sh frequency daily <count>
```

### 쿨다운 설정

```bash
bash ${CLAUDE_PLUGIN_ROOT}/lib/recommendation-controller.sh frequency cooldown <minutes>
```

## 기본값

| 설정 | 기본값 | 설명 |
|------|--------|------|
| 세션당 | 1 | 한 세션에 1회만 추천 |
| 일일 | 3 | 하루에 최대 3회 추천 |
| 쿨다운 | 30분 | 추천 간 최소 30분 간격 |

## 출력 형식

```markdown
## 추천 빈도 설정

| 설정 | 현재 값 |
|------|---------|
| 세션당 최대 | 1회 |
| 일일 최대 | 3회 |
| 쿨다운 | 30분 |
| 오늘 추천 횟수 | 2회 |

### 설정 변경
- `/scout frequency session 2` - 세션당 2회로 변경
- `/scout frequency daily 5` - 일일 5회로 변경
- `/scout frequency cooldown 60` - 1시간 간격으로 변경
```

## 예시

```
/scout frequency
→ 현재 설정 표시

/scout frequency session 2
→ 세션당 최대 2회 추천으로 변경

/scout frequency daily 5
→ 하루 최대 5회로 변경

/scout frequency cooldown 60
→ 추천 간격을 1시간으로 변경
```

## 관련 명령어

- `/scout quiet` - 무음 모드 (모든 추천 비활성화)
- `/scout timing` - 스마트 타이밍 설정
