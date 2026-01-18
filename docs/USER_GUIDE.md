# Plugin Scout v2 - 사용자 가이드

## 개요

Plugin Scout는 Claude Code 플러그인을 발견, 평가, 관리하는 에이전트입니다.

---

## 빠른 시작

### 플러그인 추천 받기
```
플러그인 추천해줘
이 프로젝트에 맞는 플러그인 찾아줘
```

### 플러그인 비교하기
```
/scout compare typescript-lsp pyright-lsp
```

### 미사용 플러그인 정리
```
/scout cleanup
```

---

## 주요 기능

### 1. 프로젝트 스캔 & 추천

프로젝트를 분석하여 적합한 플러그인을 추천합니다.

**작동 방식:**
1. `package.json`, `requirements.txt` 등 설정 파일 분석
2. 언어/프레임워크 감지
3. 마켓플레이스 스캔
4. 종합 점수 계산 (프로젝트 매칭 40% + 인기도 30% + 보안 30%)
5. 인터뷰식 설치 제안

**사용 예시:**
```
> 플러그인 추천해줘

📊 Plugin Scout Report

프로젝트: TypeScript + React + Node.js

추천 플러그인:
1. typescript-lsp (93점) - TS/JS 코드 인텔리전스
2. code-review (88점) - PR 자동 리뷰

설치할까요?
```

---

### 2. `/scout compare` - 플러그인 비교

두 개 이상의 플러그인을 비교합니다.

**사용법:**
```
/scout compare <plugin1> <plugin2> [plugin3]
```

**예시:**
```
> /scout compare sentry firebase

┌─────────────┬─────────────────┬─────────────────┐
│             │ sentry          │ firebase        │
├─────────────┼─────────────────┼─────────────────┤
│ 카테고리    │ monitoring      │ database        │
│ 점수        │ 95              │ 95              │
│ 설치        │ ✅              │ ❌              │
└─────────────┴─────────────────┴─────────────────┘

💡 둘 다 프로젝트에 적합합니다. 용도가 다르므로 함께 사용 가능.
```

---

### 3. `/scout cleanup` - 미사용 플러그인 정리

30일 이상 사용하지 않은 플러그인을 정리 제안합니다.

**사용법:**
```
/scout cleanup
```

**예시:**
```
📊 플러그인 정리 제안

오래된 미사용 플러그인이 1개 있습니다:

• old-plugin
  설치: 2025-10-01 (98일 전)
  마지막 사용: 2025-10-15 (84일 전)

나머지 6개 플러그인은 최근 활발히 사용 중입니다. ✅

[제거할 플러그인 선택]
```

---

### 4. 작업 완료 후 추천

작업 완료 시 관련 플러그인을 간략히 추천합니다.

**트리거 시점:**
- PR 생성 후
- 새 기능 구현 후
- 테스트 작성 후
- 에러 디버깅 후

**예시:**
```
💡 관련 플러그인 팁이 있어요. 볼까요?
• 설치된 거 활용법
• 새 플러그인 추천
• 다음에
```

---

## 익스텐션 시스템

### 5. 플러그인 커스터마이징 (Override)

기존 플러그인에 커스텀 규칙을 추가합니다.

**위치:**
```
.claude/plugin-overrides/<plugin-name>/override.md
```

**예시 (code-review 커스텀):**
```markdown
---
plugin: code-review
version: ">=1.0.0"
---

# 추가 체크 항목
- 한국어 주석 권장
- console.log 사용 금지
- any 타입 경고

# 무시 항목
- 테스트 파일 (*.test.ts)
```

---

### 6. 플러그인 조합 (Combos)

여러 플러그인을 순차 실행하는 워크플로우를 정의합니다.

**위치:**
```
.claude/combos/<combo-name>.yaml
```

**예시 (full-review.yaml):**
```yaml
name: full-review
trigger: "/full-review"
steps:
  - plugin: commit-commands
    action: commit
  - plugin: code-review
    action: review
  - plugin: commit-commands
    action: pr
```

**사용:**
```
/full-review
→ 커밋 → 리뷰 → PR 생성 자동 진행
```

---

### 7. `/scout fork` - 플러그인 포크

플러그인을 복사하여 커스텀 버전을 만듭니다.

**사용법:**
```
/scout fork code-review my-code-review
```

**결과:**
```
.claude/plugins/my-code-review/
├── plugin.json
├── agents/
└── FORKED_FROM.txt
```

---

## 학습 시스템

Plugin Scout는 사용자 행동을 학습합니다:

### 거절 학습
- 3번 거절한 플러그인은 추천에서 제외
- `.claude/scout-history.json`에 기록

### 선호도 학습
- 자주 설치하는 카테고리 우선 추천
- 프로젝트 패턴 기억

---

## 파일 구조

```
.claude/
├── agents/
│   └── plugin-scout.md          # 메인 에이전트
├── skills/
│   └── plugin-evaluation/
│       ├── SKILL.md             # 평가 스킬
│       ├── FEATURE_SPEC.md      # 기능 명세
│       ├── TEST_RESULTS.md      # 테스트 결과
│       ├── USER_GUIDE.md        # 이 문서
│       └── references/
├── plugins/                      # 포크한 플러그인
├── plugin-overrides/             # 커스텀 규칙
│   └── code-review/
│       └── override.md
├── combos/                       # 워크플로우
│   ├── full-review.yaml
│   └── quick-commit.yaml
├── scout-history.json            # 학습 데이터
└── scout-usage.json              # 사용 기록
```

---

## 활용 예시

### 예시 1: 새 프로젝트 시작

```
> 새 TypeScript 프로젝트를 시작했어. 유용한 플러그인 있어?

[Plugin Scout가 프로젝트 분석]

추천:
1. typescript-lsp - 코드 인텔리전스
2. commit-commands - Git 워크플로우
3. code-review - PR 리뷰

설치할까요?
> 1, 2번 설치해줘

✅ typescript-lsp 설치 완료
✅ commit-commands 설치 완료
```

### 예시 2: 기존 통합 활용

```
> 이 프로젝트에 Sentry 쓰고 있는데 관련 플러그인 있어?

[프로젝트 스캔: @sentry/node 발견]

sentry 플러그인을 설치하면:
- 에러 리포트 직접 조회
- 스택 트레이스 분석
- 이슈 검색

설치할까요?
```

### 예시 3: 워크플로우 자동화

```
> 커밋부터 PR까지 한번에 할 수 있어?

[combos/full-review.yaml 발견]

/full-review 명령으로 가능해요:
1. 변경사항 커밋
2. 코드 리뷰
3. PR 생성

실행할까요?
```

### 예시 4: 플러그인 정리

```
> 설치된 플러그인 중에 안 쓰는 거 있어?

/scout cleanup

📊 플러그인 정리 제안

오래된 미사용 플러그인 1개:
• old-plugin (84일간 미사용)

제거할까요?
```

---

## 설정

### 무음 모드
```
/scout quiet on   # 자동 추천 끄기
/scout quiet off  # 다시 켜기
```

### 히스토리 초기화
```
/scout reset-history
```

---

## FAQ

**Q: 플러그인이 자동으로 설치되나요?**
A: 아니요. 항상 사용자 동의 후에만 설치됩니다.

**Q: 추천을 끌 수 있나요?**
A: `/scout quiet on`으로 자동 추천을 끌 수 있습니다.

**Q: 팀과 설정을 공유할 수 있나요?**
A: `.claude/` 폴더를 git에 커밋하면 팀과 공유됩니다.

---

## 문제 해결

### 플러그인이 안 보여요
```
/plugin marketplace list
/plugin marketplace update
```

### 추천이 안 맞아요
```
/scout reset-history
```
히스토리를 초기화하고 다시 학습합니다.

---

## 버전 정보

- **v1.0**: 기본 추천, 인터뷰식 설치
- **v2.0**: compare, cleanup, 익스텐션 시스템, 학습
