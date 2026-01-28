# Plugin Scout Console - 아키텍처

## 역할 분리

### 플러그인 (로컬)
클라이언트 사이드에서 처리되는 기능

| 기능 | 데이터 소스 | 설명 |
|------|-------------|------|
| 설치된 플러그인 목록 | `~/.claude/plugins/installed_plugins.json` | 로컬에 설치된 플러그인 |
| 플러그인 활성화 상태 | `~/.claude/settings.json` | 활성/비활성 상태 |
| 사용량 추적 | `${PLUGIN_ROOT}/data/usage.json` | 로컬 사용 기록 |
| 세션 기록 | `${PLUGIN_ROOT}/data/sessions/` | 세션별 사용 로그 |
| 사용자 정보 | `$USER`, `git config user.name` | 현재 사용자 |
| 콘솔 UI 렌더링 | `web/console.html` | 브라우저에서 표시 |
| 데이터 내보내기 | 로컬 JSON 생성 | Export 기능 |

### 서버 (API)
원격 서버에서 제공해야 하는 기능

| API | 엔드포인트 | 설명 |
|-----|-----------|------|
| 마켓플레이스 목록 | `GET /api/marketplace` | 전체 플러그인 카탈로그 |
| 플러그인 검색 | `GET /api/marketplace/search?q=` | 마켓플레이스 검색 |
| 플러그인 상세 | `GET /api/marketplace/{name}` | 플러그인 상세 정보 |
| 카테고리 목록 | `GET /api/categories` | 카테고리 분류 |
| 트렌딩 | `GET /api/marketplace/trending` | 인기 플러그인 |
| 다운로드 수 | `GET /api/stats/{name}` | 플러그인 통계 |
| 팀 통계 | `GET /api/team/{teamId}/stats` | 팀 사용 현황 (옵션) |
| 인사이트 | `GET /api/insights` | 추천/알림 |

## API 스키마

### GET /api/marketplace
```json
{
  "plugins": [
    {
      "name": "string",
      "description": "string",
      "version": "string",
      "author": "string",
      "category": "string",
      "downloads": "number",
      "rating": "number",
      "trending": "boolean",
      "tags": ["string"],
      "createdAt": "ISO8601",
      "updatedAt": "ISO8601"
    }
  ],
  "total": "number",
  "page": "number",
  "pageSize": "number"
}
```

### GET /api/marketplace/search?q={query}&category={category}
```json
{
  "results": [/* plugin objects */],
  "total": "number",
  "query": "string"
}
```

### GET /api/marketplace/{name}
```json
{
  "name": "string",
  "description": "string",
  "longDescription": "string",
  "version": "string",
  "author": "string",
  "repository": "string",
  "homepage": "string",
  "category": "string",
  "tags": ["string"],
  "downloads": "number",
  "rating": "number",
  "reviewCount": "number",
  "trending": "boolean",
  "screenshots": ["string"],
  "changelog": "string",
  "dependencies": ["string"],
  "createdAt": "ISO8601",
  "updatedAt": "ISO8601"
}
```

### GET /api/categories
```json
{
  "categories": [
    {
      "id": "string",
      "name": "string",
      "icon": "string",
      "count": "number"
    }
  ]
}
```

### GET /api/marketplace/trending
```json
{
  "trending": [/* plugin objects with trendScore */],
  "period": "week|month"
}
```

### GET /api/insights
```json
{
  "insights": [
    {
      "type": "recommendation|warning|info|security",
      "severity": "low|medium|high",
      "message": "string",
      "action": "string|null",
      "plugin": "string|null",
      "createdAt": "ISO8601"
    }
  ]
}
```

## 데이터 흐름

```
┌─────────────────────────────────────────────────────────────┐
│                      Plugin Scout Console                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐          ┌──────────────────────────┐     │
│  │   로컬 데이터  │          │      서버 API (Mock)      │     │
│  ├──────────────┤          ├──────────────────────────┤     │
│  │ usage.json   │◄────┐    │ GET /api/marketplace     │     │
│  │ sessions/    │     │    │ GET /api/search          │     │
│  │ analytics.json│    │    │ GET /api/categories      │     │
│  └──────┬───────┘    │    │ GET /api/trending        │     │
│         │            │    │ GET /api/insights        │     │
│         ▼            │    └───────────┬──────────────┘     │
│  ┌──────────────┐    │                │                     │
│  │ open-console │    │                │                     │
│  │    .sh       │────┼────────────────┤                     │
│  └──────┬───────┘    │                │                     │
│         │            │                ▼                     │
│         ▼            │    ┌──────────────────────────┐     │
│  ┌──────────────┐    │    │    console.html          │     │
│  │ /tmp/console │    │    │  ┌────────────────────┐  │     │
│  │    .html     │◄───┼────┤  │ 로컬 데이터 주입     │  │     │
│  └──────┬───────┘    │    │  │ (USAGE_DATA)       │  │     │
│         │            │    │  └────────────────────┘  │     │
│         ▼            │    │  ┌────────────────────┐  │     │
│  ┌──────────────┐    │    │  │ API fetch          │  │     │
│  │   Browser    │    │    │  │ (Marketplace)      │  │     │
│  └──────────────┘    │    │  └────────────────────┘  │     │
│                      │    └──────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

## 목업 API 사용

개발 환경에서는 `api/mock/` 폴더의 JSON 파일을 사용:

```javascript
// console.html 내 API 호출
const API_BASE = '__API_BASE__'; // 주입되는 값

// 프로덕션: https://api.scout.monol.dev
// 개발/목업: file:///path/to/api/mock/

async function fetchMarketplace() {
  const res = await fetch(`${API_BASE}/marketplace.json`);
  return res.json();
}
```

## 파일 구조

```
monol-plugin-scout-pkg/
├── api/
│   └── mock/
│       ├── marketplace.json      # 마켓플레이스 전체 목록
│       ├── categories.json       # 카테고리 목록
│       ├── trending.json         # 트렌딩 플러그인
│       ├── insights.json         # 인사이트/추천
│       └── plugins/
│           ├── commit-commands.json
│           └── ...
├── data/
│   ├── usage.json               # 로컬 사용량
│   └── analytics.json           # 로컬 분석
├── web/
│   └── console.html             # 콘솔 UI
└── hooks/
    └── open-console.sh          # 콘솔 실행 스크립트
```
