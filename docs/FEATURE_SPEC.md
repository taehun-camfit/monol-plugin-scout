# Plugin Scout v2 - Feature Specifications

## Overview

Plugin Scout v2는 기존 추천 기능에 더해 비교, 정리, 익스텐션, 학습 기능을 추가한 확장 버전입니다.

---

## Feature 1: `/scout compare` - 플러그인 비교

### 기능 정의
두 개 이상의 플러그인을 비교표로 보여주는 명령어

### 입력
```
/scout compare <plugin1> <plugin2> [plugin3]
```

### 출력
```
┌─────────────┬─────────────────┬─────────────────┐
│             │ plugin1         │ plugin2         │
├─────────────┼─────────────────┼─────────────────┤
│ 카테고리    │ development     │ development     │
│ 점수        │ 84              │ 82              │
│ 기능        │ LSP, 자동완성   │ 타입체크, LSP   │
│ 저자        │ Anthropic       │ Anthropic       │
│ 설치 여부   │ ✅              │ ❌              │
│ 추천        │ ⭐ 현재 프로젝트에 적합           │
└─────────────┴─────────────────┴─────────────────┘
```

### 구현 계획
1. 플러그인 메타데이터 로드 함수
2. 비교 항목 추출 (카테고리, 점수, 기능, 저자, 설치여부)
3. 프로젝트 컨텍스트 기반 추천 로직
4. 테이블 포맷 출력

### 테스트 케이스

| TC-ID | 조건 | 과정 | 예상 결과 |
|-------|------|------|-----------|
| TC-C1 | 2개 플러그인 비교 | `/scout compare typescript-lsp pyright-lsp` | 비교표 출력 |
| TC-C2 | 존재하지 않는 플러그인 | `/scout compare typescript-lsp fake-plugin` | 에러 메시지 |
| TC-C3 | 동일 플러그인 | `/scout compare sentry sentry` | 경고 메시지 |
| TC-C4 | 3개 플러그인 | `/scout compare A B C` | 3열 비교표 |

---

## Feature 2: `/scout cleanup` - 미사용 플러그인 정리

### 기능 정의
설치된 플러그인 중 사용하지 않는 것을 식별하고 제거 제안

### 입력
```
/scout cleanup
```

### 출력
```
사용 빈도 분석 (최근 30일)
───────────────────────

자주 사용 ⭐⭐⭐
• commit-commands (23회)

가끔 사용 ⭐⭐
• typescript-lsp (8회)

거의 안 씀 ⭐
• plugin-dev (0회)

[제거할 플러그인 선택] (복수 선택 가능)
```

### 구현 계획
1. 사용 기록 저장 시스템 (`.claude/scout-usage.json`)
2. 플러그인 호출 Hook 등록
3. 사용 빈도 분석 로직
4. 인터뷰식 제거 플로우

### 테스트 케이스

| TC-ID | 조건 | 과정 | 예상 결과 |
|-------|------|------|-----------|
| TC-CL1 | 미사용 플러그인 존재 | `/scout cleanup` | 미사용 목록 표시 |
| TC-CL2 | 모든 플러그인 사용 중 | `/scout cleanup` | "정리할 플러그인 없음" |
| TC-CL3 | 플러그인 제거 선택 | 목록에서 선택 후 확인 | 플러그인 제거 실행 |
| TC-CL4 | 사용 기록 없음 | 첫 실행 | "사용 기록 수집 시작" 안내 |

---

## Feature 3: 플러그인 커스터마이징 (override.md)

### 기능 정의
기존 플러그인에 커스텀 규칙/설정 추가

### 구조
```
.claude/plugin-overrides/<plugin-name>/override.md
```

### override.md 형식
```markdown
---
plugin: code-review
version: ">=1.0.0"
---

# 추가 규칙

## 체크 항목 추가
- 한국어 주석 권장
- console.log 사용 금지

## 무시 항목
- 테스트 파일 (*.test.ts)
```

### 구현 계획
1. override 디렉토리 스캔
2. 플러그인 로드 시 override 병합
3. 규칙 적용 로직

### 테스트 케이스

| TC-ID | 조건 | 과정 | 예상 결과 |
|-------|------|------|-----------|
| TC-O1 | override 파일 존재 | 플러그인 실행 | 커스텀 규칙 적용 |
| TC-O2 | 버전 불일치 | override version > 설치 버전 | 경고 표시 |
| TC-O3 | 잘못된 형식 | YAML 파싱 에러 | 에러 메시지 + 기본 동작 |

---

## Feature 4: 플러그인 조합 (Combos)

### 기능 정의
여러 플러그인을 순차적으로 실행하는 워크플로우 정의

### 구조
```
.claude/combos/<combo-name>.yaml
```

### combo.yaml 형식
```yaml
name: full-review
description: "PR 생성부터 리뷰까지 원스톱"
trigger: "/full-review"
steps:
  - plugin: commit-commands
    action: commit
  - plugin: code-review
    action: review
  - plugin: security-guidance
    action: scan
  - plugin: commit-commands
    action: pr
```

### 구현 계획
1. combos 디렉토리 스캔
2. YAML 파싱 및 검증
3. 순차 실행 엔진
4. 중간 결과 전달

### 테스트 케이스

| TC-ID | 조건 | 과정 | 예상 결과 |
|-------|------|------|-----------|
| TC-CB1 | 유효한 combo | `/full-review` | 순차 실행 |
| TC-CB2 | 미설치 플러그인 포함 | combo 실행 | 설치 제안 |
| TC-CB3 | 중간 단계 실패 | 2번째 단계 에러 | 에러 표시 + 중단/계속 선택 |

---

## Feature 5: `/scout fork` - 플러그인 포크

### 기능 정의
기존 플러그인을 복사하여 수정 가능한 로컬 버전 생성

### 입력
```
/scout fork <source-plugin> <new-name>
```

### 결과
```
.claude/plugins/<new-name>/
├── plugin.json
├── agents/
├── skills/
└── FORKED_FROM.txt
```

### 구현 계획
1. 원본 플러그인 경로 확인
2. 파일 복사
3. plugin.json 수정 (이름 변경)
4. FORKED_FROM.txt 생성

### 테스트 케이스

| TC-ID | 조건 | 과정 | 예상 결과 |
|-------|------|------|-----------|
| TC-F1 | 유효한 포크 | `/scout fork code-review my-review` | 로컬 플러그인 생성 |
| TC-F2 | 이름 중복 | 이미 존재하는 이름 | 에러 메시지 |
| TC-F3 | 미설치 플러그인 | 설치 안 된 플러그인 포크 | 설치 먼저 제안 |

---

## Feature 6: 학습/히스토리 시스템

### 기능 정의
사용자 행동 학습하여 추천 정확도 향상

### 데이터 저장
```json
// .claude/scout-history.json
{
  "declined": {
    "plugin-name": {
      "count": 3,
      "lastDeclined": "2024-01-07"
    }
  },
  "installed": {
    "plugin-name": {
      "date": "2024-01-05",
      "context": "typescript-project"
    }
  },
  "usage": {
    "plugin-name": {
      "lastUsed": "2024-01-07",
      "count": 15
    }
  }
}
```

### 구현 계획
1. 히스토리 파일 관리
2. 거절 시 기록
3. 설치 시 기록
4. 사용 시 기록 (Hook)
5. 추천 시 히스토리 반영

### 테스트 케이스

| TC-ID | 조건 | 과정 | 예상 결과 |
|-------|------|------|-----------|
| TC-H1 | 3회 거절 | 같은 플러그인 3번 거절 | 추천에서 제외 |
| TC-H2 | 자주 설치하는 카테고리 | 개발도구 3개 설치 | 개발도구 우선 추천 |
| TC-H3 | 히스토리 초기화 | `/scout reset-history` | 히스토리 삭제 |

---

## 구현 우선순위

1. **Phase 1**: compare, cleanup (핵심 유틸리티)
2. **Phase 2**: 학습/히스토리 (추천 품질)
3. **Phase 3**: override, combos, fork (익스텐션)

---

## 파일 구조 (최종)

```
.claude/
├── agents/
│   └── plugin-scout.md          # 메인 에이전트
├── skills/
│   └── plugin-evaluation/
│       ├── SKILL.md
│       ├── FEATURE_SPEC.md      # 이 문서
│       └── references/
├── plugins/                      # 포크한 플러그인
├── plugin-overrides/             # 커스텀 규칙
├── combos/                       # 워크플로우
├── scout-history.json            # 학습 데이터
└── scout-usage.json              # 사용 기록
```
