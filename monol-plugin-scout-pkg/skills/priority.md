---
description: 우선순위 분석 - 플러그인 점수 상세 분석 (한글: 우선순위, 점수, 분석)
argument-hint: "<plugin-name>"
allowed-tools: [Read, Bash]
---

# /scout priority - 우선순위 분석

플러그인의 종합 점수와 상세 분석을 제공합니다.

## 사용법

```
/scout priority <plugin>     # 플러그인 점수 분석
```

## 인자: $ARGUMENTS

## 동작

```bash
bash ${CLAUDE_PLUGIN_ROOT}/lib/priority-scorer.sh breakdown "$ARGUMENTS"
```

## 점수 구성

| 요소 | 가중치 | 설명 |
|------|--------|------|
| 프로젝트 매칭 | 40% | 현재 프로젝트와의 적합성 |
| 팀 인기도 | 25% | 팀 내 사용률 및 추천 |
| 개인 이력 | 20% | 이전 설치/거절 이력 |
| 신선도 | 15% | 최근 업데이트 여부 |

## 점수 해석

| 점수 | 등급 | 의미 |
|------|------|------|
| 80+ | Excellent | 강력 추천 |
| 60-79 | Good | 추천 |
| 40-59 | Fair | 검토 권장 |
| 40 미만 | Poor | 비추천 |

## 출력 형식

```markdown
## 플러그인 점수 분석: eslint-fix

| 요소 | 점수 | 가중치 |
|------|------|--------|
| 프로젝트 매칭 | 85 | 40% |
| 팀 인기도 | 65 | 25% |
| 개인 이력 | 50 | 20% |
| 신선도 | 80 | 15% |

**종합 점수: 72점 (Good)**

### 분석
- 프로젝트의 eslint 설정과 높은 호환성
- 팀 내 2명이 사용 중, 1건의 공유 추천
- 이전 거절 이력 없음
- 최근 30일 내 업데이트됨
```

## 예시

```
/scout priority eslint-fix
→ eslint-fix 플러그인의 상세 점수 분석

/scout priority typescript-lsp
→ typescript-lsp 플러그인의 상세 점수 분석
```

## 관련 명령어

- `/scout` - 플러그인 추천 (점수 기반 정렬)
- `/scout compare` - 플러그인 비교
