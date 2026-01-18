# Plugin Scout 개발 로그

## 2026-01-07 - 초기 개발 세션

### 배경

사용자가 Claude Code 플러그인 마켓플레이스를 모니터링하고 유용한 플러그인을 추천해주는 에이전트를 만들고 싶다고 요청.

### 논의 내용

1. **기본 구조 논의**
   - 에이전트 vs 스킬 선택 → 에이전트로 결정 (능동적 작업 필요)
   - 마켓플레이스 접근 방법 연구
   - 점수 계산 방법론 설계

2. **요구사항 확정**
   - 모니터링 방식: 수동 호출 + 자동 추천
   - 마켓플레이스: 모든 소스 지원 (GitHub, Git, NPM, 로컬)
   - 추천 기준: 종합 점수 (프로젝트 40% + 인기도 30% + 보안 30%)

3. **v1.0 구현**
   - plugin-scout.md 에이전트 생성
   - plugin-evaluation 스킬 생성
   - 인터뷰식 설치 플로우

4. **테스트 및 피드백**
   - 현재 프로젝트(Nextedition) 대상 테스트
   - sentry, firebase, slack 등 기존 통합 감지 확인
   - 플러그인 5개 설치 테스트 완료

5. **v2.0 확장 논의**
   - Post-task 추천 기능 추가
   - 인터뷰식 형태로 간략화 요청
   - 설치된 플러그인 활용 팁 추가

6. **확장 기능 논의**
   - 업데이트 알림
   - 사용량 추적 / 정리
   - 플러그인 비교
   - 플러그인 익스텐션 (커스터마이징, 조합, 포크)
   - 학습 기능
   - 팀 협업

7. **v2.0 구현**
   - `/scout compare` 구현
   - `/scout cleanup` 구현 (오래된 미사용만)
   - Override 시스템 구현
   - Combos 시스템 구현
   - 학습/히스토리 시스템 구현

8. **문서화**
   - FEATURE_SPEC.md 작성
   - TEST_RESULTS.md 작성
   - USER_GUIDE.md 작성

9. **프로젝트 구조화**
   - plugin-scout/ 프로젝트 폴더 생성
   - README, CHANGELOG, ROADMAP 작성

### 주요 결정사항

| 결정 | 이유 |
|-----|------|
| 에이전트로 구현 | 능동적 추천 필요 |
| 종합 점수 40/30/30 | 프로젝트 적합성 가장 중요 |
| 인터뷰식 UI | 작업 중 방해 최소화 |
| 30일+ 미사용만 정리 | 최근 설치는 아직 활용 가능성 |
| multiSelect 적용 | 복수 플러그인 한번에 선택 |

### 생성된 파일

```
.claude/
├── agents/plugin-scout.md
├── skills/plugin-evaluation/SKILL.md
└── plugin-scout/
    ├── combos/
    ├── plugin-overrides/
    ├── scout-history.json
    └── scout-usage.json

plugin-scout/
├── README.md
├── CHANGELOG.md
├── ROADMAP.md
├── src/
├── docs/
├── tests/
└── examples/
```

### 설치된 플러그인 (테스트)

1. sentry
2. slack
3. typescript-lsp
4. code-review
5. commit-commands
6. plugin-dev
7. hookify

### 다음 단계

1. UX 개선 (무음 모드, 빈도 조절)
2. 학습 기능 강화
3. 팀 협업 기능
4. 실제 사용 피드백 수집

---

## 개발 환경

- Claude Code (Opus 4.5)
- 작업 디렉토리: /Users/Kent/Work/Nextedition
- 테스트 프로젝트: camfit_backend (Strapi + MongoDB + Firebase + Sentry)
