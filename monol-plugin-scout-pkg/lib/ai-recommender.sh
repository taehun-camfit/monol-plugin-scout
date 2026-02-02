#!/bin/bash
# Plugin Scout - AI 기반 추천 시스템
# 코드 구조 분석, 의존성 그래프 분석, 유사 프로젝트 참고 추천

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}"
DATA_DIR="$PLUGIN_ROOT/data"
AI_CACHE_FILE="$DATA_DIR/ai-cache.json"
PROJECT_SIGNATURES_FILE="$DATA_DIR/project-signatures.json"

# AI 캐시 초기화
init_ai_cache() {
  if [ ! -f "$AI_CACHE_FILE" ]; then
    mkdir -p "$DATA_DIR"
    echo '{
  "version": "1.0.0",
  "lastUpdated": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
  "projectAnalysis": {},
  "dependencyGraph": {},
  "recommendations": {},
  "similarProjects": {}
}' > "$AI_CACHE_FILE"
  fi
}

# 프로젝트 시그니처 DB 초기화
init_signatures() {
  if [ ! -f "$PROJECT_SIGNATURES_FILE" ]; then
    mkdir -p "$DATA_DIR"
    echo '{
  "version": "1.0.0",
  "signatures": {
    "react-typescript": {
      "markers": ["react", "typescript", "@types/react"],
      "recommendedPlugins": ["eslint-react", "prettier-ts", "jest-react"]
    },
    "node-express": {
      "markers": ["express", "node"],
      "recommendedPlugins": ["nodemon", "pm2", "swagger-gen"]
    },
    "python-ml": {
      "markers": ["numpy", "pandas", "scikit-learn", "tensorflow", "pytorch"],
      "recommendedPlugins": ["jupyter", "mlflow", "tensorboard"]
    },
    "python-web": {
      "markers": ["django", "flask", "fastapi"],
      "recommendedPlugins": ["pytest", "black", "mypy"]
    },
    "rust-cli": {
      "markers": ["clap", "tokio"],
      "recommendedPlugins": ["cargo-watch", "cargo-audit"]
    },
    "go-web": {
      "markers": ["gin", "echo", "fiber"],
      "recommendedPlugins": ["air", "golangci-lint"]
    }
  }
}' > "$PROJECT_SIGNATURES_FILE"
  fi
}

# package.json 분석
analyze_package_json() {
  local path="${1:-.}"
  local pkg_file="$path/package.json"

  if [ ! -f "$pkg_file" ]; then
    echo "[]"
    return
  fi

  if ! command -v jq &> /dev/null; then
    echo "[]"
    return
  fi

  # 의존성 추출
  jq -r '
    ((.dependencies // {}) + (.devDependencies // {})) |
    keys
  ' "$pkg_file"
}

# requirements.txt 분석
analyze_requirements() {
  local path="${1:-.}"
  local req_file="$path/requirements.txt"

  if [ ! -f "$req_file" ]; then
    echo "[]"
    return
  fi

  # 패키지 이름만 추출 (버전 제외)
  grep -v '^#' "$req_file" 2>/dev/null | \
    grep -v '^$' | \
    sed 's/[>=<].*$//' | \
    sed 's/\[.*\]$//' | \
    jq -R -s -c 'split("\n") | map(select(. != ""))'
}

# Cargo.toml 분석
analyze_cargo() {
  local path="${1:-.}"
  local cargo_file="$path/Cargo.toml"

  if [ ! -f "$cargo_file" ]; then
    echo "[]"
    return
  fi

  # [dependencies] 섹션에서 패키지 추출
  awk '/^\[dependencies\]/,/^\[/' "$cargo_file" | \
    grep -v '^\[' | \
    grep -v '^$' | \
    sed 's/ =.*//' | \
    jq -R -s -c 'split("\n") | map(select(. != ""))'
}

# go.mod 분석
analyze_gomod() {
  local path="${1:-.}"
  local go_file="$path/go.mod"

  if [ ! -f "$go_file" ]; then
    echo "[]"
    return
  fi

  # require 블록에서 패키지 추출
  awk '/^require/,/^\)/' "$go_file" | \
    grep -v '^require' | \
    grep -v '^\)' | \
    awk '{print $1}' | \
    grep -v '^$' | \
    jq -R -s -c 'split("\n") | map(select(. != ""))'
}

# 프로젝트 분석 (통합)
analyze_project() {
  local path="${1:-.}"

  init_ai_cache

  local project_type=""
  local dependencies="[]"

  # 프로젝트 타입 감지 및 의존성 분석
  if [ -f "$path/package.json" ]; then
    project_type="node"
    dependencies=$(analyze_package_json "$path")
  elif [ -f "$path/requirements.txt" ] || [ -f "$path/pyproject.toml" ]; then
    project_type="python"
    dependencies=$(analyze_requirements "$path")
  elif [ -f "$path/Cargo.toml" ]; then
    project_type="rust"
    dependencies=$(analyze_cargo "$path")
  elif [ -f "$path/go.mod" ]; then
    project_type="go"
    dependencies=$(analyze_gomod "$path")
  elif [ -f "$path/pom.xml" ]; then
    project_type="java"
  elif [ -f "$path/composer.json" ]; then
    project_type="php"
  fi

  if ! command -v jq &> /dev/null; then
    echo "Project type: $project_type"
    return
  fi

  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local path_hash=$(echo "$path" | md5 2>/dev/null || echo "$path" | md5sum | cut -d' ' -f1)

  # 캐시에 저장
  jq --arg path "$path_hash" \
     --arg type "$project_type" \
     --argjson deps "$dependencies" \
     --arg ts "$timestamp" \
     '
     .lastUpdated = $ts |
     .projectAnalysis[$path] = {
       "type": $type,
       "dependencies": $deps,
       "analyzedAt": $ts
     }
     ' "$AI_CACHE_FILE" > "$AI_CACHE_FILE.tmp" && mv "$AI_CACHE_FILE.tmp" "$AI_CACHE_FILE"

  echo "{\"type\": \"$project_type\", \"dependencies\": $dependencies}"
}

# 의존성 그래프 구축
build_dependency_graph() {
  local path="${1:-.}"

  init_ai_cache

  local analysis=$(analyze_project "$path")

  if ! command -v jq &> /dev/null; then
    echo "jq required"
    return
  fi

  local deps=$(echo "$analysis" | jq -r '.dependencies')
  local project_type=$(echo "$analysis" | jq -r '.type')

  # 간단한 의존성 그래프 (직접 의존성만)
  local graph=$(echo "$deps" | jq '{
    "nodes": . | map({id: ., type: "dependency"}),
    "edges": []
  }')

  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local path_hash=$(echo "$path" | md5 2>/dev/null || echo "$path" | md5sum | cut -d' ' -f1)

  jq --arg path "$path_hash" \
     --argjson graph "$graph" \
     --arg ts "$timestamp" \
     '
     .lastUpdated = $ts |
     .dependencyGraph[$path] = {
       "graph": $graph,
       "builtAt": $ts
     }
     ' "$AI_CACHE_FILE" > "$AI_CACHE_FILE.tmp" && mv "$AI_CACHE_FILE.tmp" "$AI_CACHE_FILE"

  echo "$graph"
}

# 프로젝트 시그니처 매칭
match_signature() {
  local path="${1:-.}"

  init_signatures

  local analysis=$(analyze_project "$path")

  if ! command -v jq &> /dev/null; then
    echo "[]"
    return
  fi

  local deps=$(echo "$analysis" | jq -r '.dependencies | join(" ")')

  # 시그니처별 매칭 점수 계산
  jq -r --arg deps "$deps" '
    .signatures | to_entries | map({
      name: .key,
      markers: .value.markers,
      plugins: .value.recommendedPlugins,
      matched: ([.value.markers[] | select($deps | contains(.))] | length),
      total: (.value.markers | length)
    }) |
    map(select(.matched > 0)) |
    sort_by(-.matched) |
    .[0:3]
  ' "$PROJECT_SIGNATURES_FILE"
}

# AI 기반 추천 생성
generate_recommendations() {
  local path="${1:-.}"

  init_ai_cache
  init_signatures

  if ! command -v jq &> /dev/null; then
    echo "jq required"
    return
  fi

  local analysis=$(analyze_project "$path")
  local project_type=$(echo "$analysis" | jq -r '.type')
  local deps=$(echo "$analysis" | jq -r '.dependencies')

  # 시그니처 매칭
  local matches=$(match_signature "$path")

  # 추천 플러그인 추출
  local recommendations=$(echo "$matches" | jq '
    [.[].plugins] | flatten | unique
  ')

  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local path_hash=$(echo "$path" | md5 2>/dev/null || echo "$path" | md5sum | cut -d' ' -f1)

  # 캐시에 저장
  jq --arg path "$path_hash" \
     --argjson recs "$recommendations" \
     --argjson matches "$matches" \
     --arg ts "$timestamp" \
     '
     .lastUpdated = $ts |
     .recommendations[$path] = {
       "plugins": $recs,
       "matches": $matches,
       "generatedAt": $ts
     }
     ' "$AI_CACHE_FILE" > "$AI_CACHE_FILE.tmp" && mv "$AI_CACHE_FILE.tmp" "$AI_CACHE_FILE"

  echo "$recommendations"
}

# 유사 프로젝트 찾기 (간단한 구현)
find_similar_projects() {
  local path="${1:-.}"

  init_ai_cache

  if ! command -v jq &> /dev/null; then
    echo "[]"
    return
  fi

  local analysis=$(analyze_project "$path")
  local deps=$(echo "$analysis" | jq -r '.dependencies')
  local project_type=$(echo "$analysis" | jq -r '.type')

  # 캐시된 다른 프로젝트와 비교
  local path_hash=$(echo "$path" | md5 2>/dev/null || echo "$path" | md5sum | cut -d' ' -f1)

  jq --arg current "$path_hash" --argjson currentDeps "$deps" '
    .projectAnalysis | to_entries |
    map(select(.key != $current)) |
    map({
      path: .key,
      type: .value.type,
      commonDeps: ([.value.dependencies[] | select(. as $d | $currentDeps | index($d))] | length),
      totalDeps: (.value.dependencies | length)
    }) |
    map(select(.commonDeps > 0)) |
    sort_by(-.commonDeps) |
    .[0:5]
  ' "$AI_CACHE_FILE"
}

# 코드 패턴 분석 (기본적인 파일 구조 분석)
analyze_code_patterns() {
  local path="${1:-.}"

  local patterns="[]"

  # 디렉토리 구조 분석
  if [ -d "$path/src" ]; then
    patterns=$(echo "$patterns" | jq '. + ["src-structure"]')
  fi

  if [ -d "$path/test" ] || [ -d "$path/tests" ] || [ -d "$path/__tests__" ]; then
    patterns=$(echo "$patterns" | jq '. + ["has-tests"]')
  fi

  if [ -d "$path/.github" ]; then
    patterns=$(echo "$patterns" | jq '. + ["github-workflows"]')
  fi

  if [ -f "$path/.eslintrc.json" ] || [ -f "$path/.eslintrc.js" ] || [ -f "$path/eslint.config.js" ]; then
    patterns=$(echo "$patterns" | jq '. + ["eslint-config"]')
  fi

  if [ -f "$path/.prettierrc" ] || [ -f "$path/prettier.config.js" ]; then
    patterns=$(echo "$patterns" | jq '. + ["prettier-config"]')
  fi

  if [ -f "$path/docker-compose.yml" ] || [ -f "$path/Dockerfile" ]; then
    patterns=$(echo "$patterns" | jq '. + ["docker-enabled"]')
  fi

  echo "$patterns"
}

# 추천 점수 계산
calculate_recommendation_score() {
  local plugin_name="$1"
  local path="${2:-.}"

  local base_score=50

  # 시그니처 매칭 보너스
  local matches=$(match_signature "$path")
  local in_match=$(echo "$matches" | jq -r --arg plugin "$plugin_name" '
    [.[].plugins[] | select(. == $plugin)] | length
  ')

  if [ "$in_match" != "0" ]; then
    base_score=$((base_score + 30))
  fi

  # 코드 패턴 보너스 (예: 테스트가 있으면 테스트 플러그인 점수 상승)
  local patterns=$(analyze_code_patterns "$path")

  echo "$base_score"
}

# 캐시 정리
cleanup_cache() {
  local days="${1:-7}"

  init_ai_cache

  if ! command -v jq &> /dev/null; then
    echo "jq required"
    return
  fi

  local cutoff=$(date -u -v-${days}d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "$days days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  jq --arg cutoff "$cutoff" --arg ts "$timestamp" '
    .lastUpdated = $ts |
    .projectAnalysis = (.projectAnalysis | to_entries | map(select(.value.analyzedAt >= $cutoff)) | from_entries) |
    .recommendations = (.recommendations | to_entries | map(select(.value.generatedAt >= $cutoff)) | from_entries)
  ' "$AI_CACHE_FILE" > "$AI_CACHE_FILE.tmp" && mv "$AI_CACHE_FILE.tmp" "$AI_CACHE_FILE"

  echo "Cache cleaned (removed entries older than $days days)"
}

# AI 추천 요약 출력
get_ai_summary() {
  local path="${1:-.}"

  echo "=== AI Recommendation Summary ==="
  echo ""

  local analysis=$(analyze_project "$path")
  echo "Project Type: $(echo "$analysis" | jq -r '.type // "unknown"')"
  echo "Dependencies: $(echo "$analysis" | jq -r '.dependencies | length') packages"
  echo ""

  echo "Signature Matches:"
  match_signature "$path" | jq -r '.[] | "  \(.name): \(.matched)/\(.total) markers"'
  echo ""

  echo "Recommended Plugins:"
  generate_recommendations "$path" | jq -r '.[] | "  - \(.)"'
  echo ""

  echo "Code Patterns:"
  analyze_code_patterns "$path" | jq -r '.[] | "  - \(.)"'
}

# 캐시 리셋
reset_cache() {
  if [ -f "$AI_CACHE_FILE" ]; then
    rm "$AI_CACHE_FILE"
    init_ai_cache
    echo "AI cache reset successfully"
  else
    echo "No cache to reset"
  fi
}

# CLI 인터페이스
case "$1" in
  init)
    init_ai_cache
    init_signatures
    echo "AI recommender initialized"
    ;;
  analyze)
    analyze_project "$2"
    ;;
  graph)
    build_dependency_graph "$2"
    ;;
  match)
    match_signature "$2"
    ;;
  recommend)
    generate_recommendations "$2"
    ;;
  similar)
    find_similar_projects "$2"
    ;;
  patterns)
    analyze_code_patterns "$2"
    ;;
  score)
    calculate_recommendation_score "$2" "$3"
    ;;
  cleanup)
    cleanup_cache "$2"
    ;;
  summary)
    get_ai_summary "$2"
    ;;
  reset)
    reset_cache
    ;;
  *)
    echo "Usage: $0 {init|analyze|graph|match|recommend|similar|patterns|score|cleanup|summary|reset}"
    echo ""
    echo "Commands:"
    echo "  init                        - Initialize AI recommender"
    echo "  analyze [path]              - Analyze project dependencies"
    echo "  graph [path]                - Build dependency graph"
    echo "  match [path]                - Match project signature"
    echo "  recommend [path]            - Generate AI recommendations"
    echo "  similar [path]              - Find similar projects"
    echo "  patterns [path]             - Analyze code patterns"
    echo "  score <plugin> [path]       - Calculate recommendation score"
    echo "  cleanup [days]              - Clean old cache entries"
    echo "  summary [path]              - Show AI recommendation summary"
    echo "  reset                       - Reset AI cache"
    ;;
esac
