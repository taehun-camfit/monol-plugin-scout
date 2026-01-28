# Changelog

## [4.0.0] - 2026-01-22

### Added
- **우선순위 스코어러** (`lib/priority-scorer.sh`)
  - 다중 요소 기반 점수 계산
  - 프로젝트 매칭 (40%)
  - 팀 인기도 (25%)
  - 개인 이력 (20%)
  - 신선도 (15%)
  - 점수 상세 분석

- **스케줄러** (`lib/scheduler.sh`)
  - 정기 작업 예약 (daily, weekly, monthly)
  - 작업 유형: check-updates, cleanup, audit, remind
  - 자동 다음 실행 시간 계산
  - 기본 스케줄 자동 설정

- **새 명령어**
  - `/scout priority` - 플러그인 우선순위 분석
  - `/scout schedule` - 스케줄 관리

### Changed
- 추천 결과가 우선순위 점수로 정렬됨
- 팀 추천이 점수에 반영됨

### Technical
- 가중 평균 기반 스코어링 시스템
- 스케줄 파일 (`data/schedules.json`)

---

## [3.1.0] - 2026-01-22

### Added
- **데이터 검증기** (`lib/data-validator.sh`)
  - JSON 파일 유효성 검사
  - 스키마 검증 (history, usage, team)
  - 자동 백업 및 복구
  - 손상 파일 복구

- **에러 핸들러** (`lib/error-handler.sh`)
  - 구조화된 에러 코드 (E001~E007)
  - 안전한 JSON 읽기/쓰기
  - 자동 복구 시도
  - 시스템 상태 확인

- **캐싱 시스템** (`lib/cache.sh`)
  - TTL 기반 캐싱 (기본 5분)
  - 프로젝트 분석 캐싱
  - 팀 추천 캐싱
  - 캐시 통계 및 정리

- **로깅 시스템** (`lib/logger.sh`)
  - 레벨별 로그 (DEBUG, INFO, WARN, ERROR)
  - 구조화된 이벤트 로그 (JSONL)
  - 로그 검색 및 통계
  - 자동 로그 정리

### Technical
- bash 3.x 호환성 (macOS 기본 bash)
- 백업 디렉토리 (`data/backups/`)
- 로그 디렉토리 (`data/logs/`)
- 캐시 디렉토리 (`data/.cache/`)

---

## [3.0.0] - 2026-01-22

### Added
- **팀 매니저** (`lib/team-manager.sh`)
  - 팀원 자동 등록 (세션 시작 시)
  - 팀원별 플러그인 사용 추적
  - 팀 통계 (활성 멤버, 인기 플러그인)
  - 공유 추천 시스템

- **새 명령어**
  - `/scout team` - 팀 요약 및 관리
  - `/scout team members` - 팀원 목록
  - `/scout team share` - 플러그인 추천 공유
  - `/scout team shared` - 공유된 추천 목록

- **팀 데이터 구조** (`data/team.json`)
  - members: 팀원 정보 (세션 수, 사용 플러그인)
  - sharedRecommendations: 공유된 추천
  - sharedSettings: 기본/차단 플러그인
  - stats: 팀 통계

### Changed
- `hooks/on-session-start.sh` - 팀 등록 자동화
- `hooks/track-usage.sh` - 팀 통계에 사용 기록

### Technical
- Git 사용자 정보 기반 팀원 식별
- 7일 내 활성 멤버 추적
- 플러그인 사용량 집계

---

## [2.7.0] - 2026-01-22

### Added
- **추천 컨트롤러** (`lib/recommendation-controller.sh`)
  - 무음 모드 (quiet mode)
  - 추천 빈도 제한 (세션당/일일)
  - 쿨다운 설정
  - 스마트 타이밍 (커밋 후/PR 후 추천)
  - 미니 알림 모드

- **새 명령어**
  - `/scout quiet` - 무음 모드 on/off
  - `/scout frequency` - 추천 빈도 설정
  - `/scout timing` - 스마트 타이밍 설정

### Changed
- `history.json` preferences 확장
  - `quietMode` - 무음 모드 상태
  - `maxRecommendationsPerSession` - 세션당 최대 추천
  - `maxRecommendationsPerDay` - 일일 최대 추천
  - `recommendationCooldown` - 추천 간격 (분)
  - `smartTiming` - 스마트 타이밍 설정

### Technical
- 추천 로그 기록 (`.recommendations`)
- 7일 이상 된 로그 자동 정리

---

## [2.6.0] - 2026-01-22

### Added
- **거절 학습 시스템** (`lib/rejection-learner.sh`)
  - 플러그인 거절 이유 추적 및 저장
  - 재추천 쿨다운 (30일 기본)
  - 3회 이상 거절 시 영구 차단
  - 카테고리별 거절 패턴 학습
  - 거절 통계 조회 (`stats` 명령)

- **프로젝트 분석기 개선** (`lib/project-analyzer.sh`)
  - 의존성 기반 플러그인 추천 (`recommend_by_deps`)
  - 프레임워크 감지 확장 (30+ 프레임워크 지원)
  - 카테고리 추천 로직 개선 (database, api, ai 추가)
  - 프로젝트 복잡도 분석

- **플러그인 매니저** (`lib/plugin-manager.sh`)
  - `/scout install <plugin>` - 플러그인 설치
  - `/scout uninstall <plugin>` - 플러그인 제거
  - 활성화/비활성화 토글
  - 설치 전 백업 생성
  - 설치/제거 이력 기록

- **history.json v2.0.0** 스키마 개선
  - `rejectionPatterns` - 카테고리/이유별 거절 통계
  - `rejectionReasons` - 거절 이유 코드 정의
  - `preferences` 확장 (쿨다운, 차단 임계값)

### Changed
- `scout.md` - 프로젝트 분석기 및 거절 학습 통합
- `config.yaml` - 거절 학습 설정 추가

### Technical
- lib/ 디렉토리 구조 도입
- jq 기반 JSON 조작 안정화
- 쉘 스크립트 모듈화

---

## [2.5.0] - 2026-01-22

### Added
- **웹 콘솔 프로토타입** (`web/console.html`)
  - 모던 다크 테마 UI
  - 실시간 차트 (Chart.js)
  - 플러그인/사용자/마켓플레이스 탭
  - 검색 모달 (⌘K)
  - 설정 패널

- **Mock API 구조** (`api/mock/`)
  - marketplace.json - 38개 플러그인 데이터
  - categories.json - 11개 카테고리
  - trending.json - 트렌딩 플러그인
  - insights.json - AI 인사이트

- **아키텍처 문서** (`docs/ARCHITECTURE.md`)
  - 플러그인 vs 서버 역할 분리
  - API 스키마 정의

### Technical
- 웹 콘솔은 프로토타입 상태 (HOLD)
- 실제 API 서버 연동은 추후 구현 예정

---

## [2.3.0] - 2026-01-19

### Added
- **`/scout console`** - 플러그인 대시보드 콘솔
  - 전체 현황 대시보드 (플러그인, 사용량, 사용자)
  - 플러그인 상세 뷰 (기술 스펙, 사용 통계)
  - 사용 분석 뷰 (트렌드, 카테고리별 분석)
  - 사용자 분석 뷰 (팀원별 활동)
  - 인터랙티브 메뉴 (AskUserQuestion 기반)
- **멀티유저 추적** - 팀 환경에서 사용자별 플러그인 사용 추적
  - `$USER` 및 `git config user.name` 기반 사용자 식별
  - 사용자별 플러그인 사용량, 세션 수, 마지막 활동
- **analytics.json** - 분석 데이터 스키마
  - 전체 요약 (플러그인 수, 사용량, 활성/휴면 플러그인)
  - 주간/월간 트렌드
  - 플러그인별 통계 (사용 점유율, 트렌드)
  - 자동 인사이트 생성
- **generate-insights.sh** - 인사이트 자동 생성 스크립트
  - 미사용 플러그인 감지
  - 트렌드 분석
  - 사용 패턴 분석

### Changed
- `usage.json` 스키마 확장 (`users`, `sessions` 섹션 추가)
- `on-session-start.sh` - 사용자 정보 캡처 추가
- `on-session-end.sh` - 사용자별 통계 업데이트 로직 추가

### Technical
- ASCII 아트 기반 대시보드 UI
- 멀티유저 환경 지원을 위한 데이터 구조 개선

---

## [2.2.0] - 2026-01-19

### Added
- **Stop Hook** - 작업 완료 후 자동 플러그인 추천 (`on-stop.md`)
- **SessionStart Hook** - 세션 시작 시 초기화 (`on-session-start.sh`)
- **SessionEnd Hook** - 세션 종료 시 사용 이력 기록 (`on-session-end.sh`)
- **사용 추적 스크립트** - 스킬 호출 시 실시간 기록 (`track-usage.sh`)
- 모든 스킬에 Stop hook 추가 (사용 이력 자동 추적)

### Changed
- `hooks.json` 구조 완전 개편 (Stop, SessionStart, SessionEnd 이벤트 지원)
- 사용 이력(`usage.json`)이 실제 스킬 사용에 따라 자동 갱신

### Technical
- jq 기반 JSON 파싱으로 안정성 향상
- 세션별 상태 관리 (`.session` 파일)

---

## [2.0.0] - 2026-01-07

### Added
- `/scout compare` - 플러그인 비교 기능
- `/scout cleanup` - 오래된 미사용 플러그인 정리
- `/scout fork` - 플러그인 포크 기능
- `/scout explore` - 마켓플레이스 탐색
- `/scout audit` - 보안/업데이트 점검
- Override 시스템 - 플러그인 커스터마이징
- Combos 시스템 - 워크플로우 조합
- 학습/히스토리 시스템 - 거절/선호도 학습
- 사용량 추적 시스템

### Changed
- Post-task 추천을 인터뷰식으로 변경 (간략화)
- cleanup 기준을 "오래된 미사용"으로 변경 (30일+)
- 설치 질문에 multiSelect 적용

### Documentation
- FEATURE_SPEC.md - 기능 명세서 작성
- TEST_RESULTS.md - 테스트 케이스 및 결과
- USER_GUIDE.md - 사용자 가이드 및 활용 예시

---

## [1.0.0] - 2026-01-07

### Added
- 기본 프로젝트 스캔 및 추천
- 종합 점수 계산 (프로젝트 매칭 40% + 인기도 30% + 보안 30%)
- 인터뷰식 설치 플로우
- Post-task 추천 (작업 완료 후)
- 평가 스킬 (SKILL.md)
- 참조 문서 (scoring-methodology, security-checklist, license-compatibility)

### Technical
- plugin-scout.md 에이전트 생성
- plugin-evaluation 스킬 생성
- AskUserQuestion 기반 인터뷰 플로우
