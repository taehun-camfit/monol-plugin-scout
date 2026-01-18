# monol-plugin-scout

Claude Code 플러그인 마켓플레이스 모니터링 및 추천 에이전트

## 기능

- **프로젝트 분석**: package.json, pyproject.toml 등으로 언어/프레임워크 자동 감지
- **마켓플레이스 스캔**: GitHub, NPM, 로컬 마켓플레이스 지원
- **플러그인 평가**: 프로젝트 매칭(40%) + 인기도(30%) + 보안(30%) 점수
- **인터뷰식 설치**: 대화형으로 복수 선택 가능한 설치
- **정리 제안**: 미사용 플러그인 자동 감지 및 정리

## 설치

```bash
# 1. 레포 클론
git clone https://github.com/your/monol-plugin-scout.git ~/monol-plugin-scout

# 2. Claude Code 설정에 마켓플레이스 등록
```

`~/.claude/settings.json`:
```json
{
  "extraKnownMarketplaces": {
    "monol-plugin-scout": {
      "source": {
        "source": "directory",
        "path": "~/monol-plugin-scout/.claude/plugins"
      }
    }
  },
  "enabledPlugins": {
    "monol-plugin-scout@monol-plugin-scout": true
  }
}
```

## 사용법

### 기본 추천
```
/scout                    # 프로젝트 분석 후 맞춤 추천
/scout --quick            # 점수 80+ 만 빠르게
```

### 플러그인 비교
```
/scout compare typescript-lsp pyright-lsp
```

### 미사용 정리
```
/scout cleanup
```

### 마켓플레이스 탐색
```
/scout explore development
```

### 보안 점검
```
/scout audit
```

### 플러그인 포크
```
/scout fork code-review my-code-review
```

## 점수 시스템

| 점수 | 등급 | 권장 |
|------|------|------|
| 90-100 | Excellent | 적극 추천 |
| 75-89 | Good | 추천 |
| 60-74 | Fair | 대안 검토 |
| 40-59 | Poor | 주의 |
| 0-39 | Not Recommended | 비추천 |

## 디렉토리 구조

```
monol-plugin-scout/
├── .claude/
│   └── plugins/
│       ├── marketplace.json
│       └── monol-plugin-scout/
│           ├── plugin.json
│           ├── config.yaml
│           ├── CLAUDE.md
│           ├── commands/
│           ├── skills/
│           ├── combos/
│           ├── overrides/
│           └── data/
├── docs/
├── examples/
├── tests/
├── README.md
├── CHANGELOG.md
└── ROADMAP.md
```

## 문서

- [사용자 가이드](docs/USER_GUIDE.md)
- [기능 명세](docs/FEATURE_SPEC.md)
- [테스트 결과](docs/TEST_RESULTS.md)
- [개발 일지](docs/DEV_LOG.md)

## 라이선스

MIT
