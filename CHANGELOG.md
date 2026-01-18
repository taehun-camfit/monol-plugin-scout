# Changelog

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
