#!/bin/bash
# Plugin Scout - 프로젝트 분석기
# 프로젝트 구조와 의존성을 분석하여 추천에 활용

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}"
PROJECT_ROOT="${PWD}"

# 프로젝트 타입 감지
detect_project_type() {
  local types=()

  # Node.js/JavaScript/TypeScript
  if [ -f "$PROJECT_ROOT/package.json" ]; then
    types+=("nodejs")
    if [ -f "$PROJECT_ROOT/tsconfig.json" ]; then
      types+=("typescript")
    fi
  fi

  # Python
  if [ -f "$PROJECT_ROOT/requirements.txt" ] || [ -f "$PROJECT_ROOT/pyproject.toml" ] || [ -f "$PROJECT_ROOT/setup.py" ]; then
    types+=("python")
  fi

  # Rust
  if [ -f "$PROJECT_ROOT/Cargo.toml" ]; then
    types+=("rust")
  fi

  # Go
  if [ -f "$PROJECT_ROOT/go.mod" ]; then
    types+=("go")
  fi

  # Java
  if [ -f "$PROJECT_ROOT/pom.xml" ] || [ -f "$PROJECT_ROOT/build.gradle" ]; then
    types+=("java")
  fi

  # PHP
  if [ -f "$PROJECT_ROOT/composer.json" ]; then
    types+=("php")
  fi

  # Ruby
  if [ -f "$PROJECT_ROOT/Gemfile" ]; then
    types+=("ruby")
  fi

  # Claude Code Plugin
  if [ -f "$PROJECT_ROOT/plugin.json" ] || [ -d "$PROJECT_ROOT/.claude" ]; then
    types+=("claude-plugin")
  fi

  # Docker
  if [ -f "$PROJECT_ROOT/Dockerfile" ] || [ -f "$PROJECT_ROOT/docker-compose.yml" ]; then
    types+=("docker")
  fi

  # 결과 출력 (JSON)
  printf '%s\n' "${types[@]}" | jq -R -s -c 'split("\n") | map(select(. != ""))'
}

# 프레임워크 감지
detect_frameworks() {
  local frameworks=()

  # Node.js 프레임워크 (package.json에서)
  if [ -f "$PROJECT_ROOT/package.json" ]; then
    local deps=$(cat "$PROJECT_ROOT/package.json" | grep -E '"(dependencies|devDependencies)"' -A 100 | head -100)

    # Frontend
    echo "$deps" | grep -q '"react"' && frameworks+=("react")
    echo "$deps" | grep -q '"vue"' && frameworks+=("vue")
    echo "$deps" | grep -q '"@angular/core"' && frameworks+=("angular")
    echo "$deps" | grep -q '"svelte"' && frameworks+=("svelte")
    echo "$deps" | grep -q '"next"' && frameworks+=("nextjs")
    echo "$deps" | grep -q '"nuxt"' && frameworks+=("nuxtjs")
    echo "$deps" | grep -q '"astro"' && frameworks+=("astro")

    # Backend
    echo "$deps" | grep -q '"express"' && frameworks+=("express")
    echo "$deps" | grep -q '"fastify"' && frameworks+=("fastify")
    echo "$deps" | grep -q '"@nestjs/core"' && frameworks+=("nestjs")
    echo "$deps" | grep -q '"hono"' && frameworks+=("hono")
    echo "$deps" | grep -q '"koa"' && frameworks+=("koa")

    # Testing
    echo "$deps" | grep -q '"jest"' && frameworks+=("jest")
    echo "$deps" | grep -q '"vitest"' && frameworks+=("vitest")
    echo "$deps" | grep -q '"mocha"' && frameworks+=("mocha")
    echo "$deps" | grep -q '"playwright"' && frameworks+=("playwright")
    echo "$deps" | grep -q '"cypress"' && frameworks+=("cypress")

    # Build tools
    echo "$deps" | grep -q '"webpack"' && frameworks+=("webpack")
    echo "$deps" | grep -q '"vite"' && frameworks+=("vite")
    echo "$deps" | grep -q '"esbuild"' && frameworks+=("esbuild")
    echo "$deps" | grep -q '"turbo"' && frameworks+=("turborepo")

    # Styling
    echo "$deps" | grep -q '"tailwindcss"' && frameworks+=("tailwind")
    echo "$deps" | grep -q '"styled-components"' && frameworks+=("styled-components")

    # State management
    echo "$deps" | grep -q '"redux"' && frameworks+=("redux")
    echo "$deps" | grep -q '"zustand"' && frameworks+=("zustand")
    echo "$deps" | grep -q '"jotai"' && frameworks+=("jotai")

    # Database/ORM
    echo "$deps" | grep -q '"prisma"' && frameworks+=("prisma")
    echo "$deps" | grep -q '"drizzle-orm"' && frameworks+=("drizzle")
    echo "$deps" | grep -q '"mongoose"' && frameworks+=("mongoose")
    echo "$deps" | grep -q '"typeorm"' && frameworks+=("typeorm")

    # API
    echo "$deps" | grep -q '"graphql"' && frameworks+=("graphql")
    echo "$deps" | grep -q '"trpc"' && frameworks+=("trpc")
  fi

  # Python 프레임워크
  if [ -f "$PROJECT_ROOT/requirements.txt" ]; then
    local reqs=$(cat "$PROJECT_ROOT/requirements.txt")
    echo "$reqs" | grep -qi "django" && frameworks+=("django")
    echo "$reqs" | grep -qi "flask" && frameworks+=("flask")
    echo "$reqs" | grep -qi "fastapi" && frameworks+=("fastapi")
    echo "$reqs" | grep -qi "pytest" && frameworks+=("pytest")
  fi

  printf '%s\n' "${frameworks[@]}" | jq -R -s -c 'split("\n") | map(select(. != ""))'
}

# 의존성 추출 (상위 20개)
get_dependencies() {
  local deps=()

  if [ -f "$PROJECT_ROOT/package.json" ] && command -v jq &> /dev/null; then
    # dependencies
    local prod_deps=$(jq -r '.dependencies // {} | keys[]' "$PROJECT_ROOT/package.json" 2>/dev/null | head -10)
    # devDependencies
    local dev_deps=$(jq -r '.devDependencies // {} | keys[]' "$PROJECT_ROOT/package.json" 2>/dev/null | head -10)

    for dep in $prod_deps $dev_deps; do
      deps+=("$dep")
    done
  fi

  printf '%s\n' "${deps[@]}" | jq -R -s -c 'split("\n") | map(select(. != "")) | unique | .[:20]'
}

# 프로젝트 크기/복잡도 분석
analyze_complexity() {
  local file_count=$(find "$PROJECT_ROOT" -type f -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" -o -name "*.rs" -o -name "*.go" 2>/dev/null | wc -l | tr -d ' ')
  local dir_count=$(find "$PROJECT_ROOT" -type d 2>/dev/null | wc -l | tr -d ' ')

  local size="small"
  if [ "$file_count" -gt 100 ]; then
    size="large"
  elif [ "$file_count" -gt 30 ]; then
    size="medium"
  fi

  echo "{\"files\": $file_count, \"directories\": $dir_count, \"size\": \"$size\"}"
}

# 추천할 플러그인 카테고리 결정
suggest_categories() {
  local categories=()
  local types=$(detect_project_type)
  local frameworks=$(detect_frameworks)

  # TypeScript 프로젝트면 development 추천
  echo "$types" | grep -q "typescript" && categories+=("development")

  # 테스트 프레임워크 있으면 testing 추천
  echo "$frameworks" | grep -qE "(jest|vitest|pytest|playwright|cypress)" && categories+=("testing")

  # Frontend 프레임워크 있으면 frontend 추천
  echo "$frameworks" | grep -qE "(react|vue|angular|svelte)" && categories+=("frontend")

  # Docker 있으면 devops 추천
  echo "$types" | grep -q "docker" && categories+=("devops")

  # Database/ORM 사용하면 database 추천
  echo "$frameworks" | grep -qE "(prisma|drizzle|mongoose|typeorm)" && categories+=("database")

  # GraphQL 사용하면 api 추천
  echo "$frameworks" | grep -qE "(graphql|trpc)" && categories+=("api")

  # AI/ML 관련이면 ai 추천
  echo "$frameworks" | grep -qE "(openai|langchain|huggingface)" && categories+=("ai")

  # 기본적으로 productivity 추천
  categories+=("productivity")

  printf '%s\n' "${categories[@]}" | jq -R -s -c 'split("\n") | map(select(. != "")) | unique'
}

# 의존성 기반 플러그인 추천
recommend_by_deps() {
  local deps=$(get_dependencies)

  # 의존성 → 플러그인 매핑
  local recommendations=()

  echo "$deps" | jq -r '.[]' 2>/dev/null | while read dep; do
    case "$dep" in
      typescript|@types/*) echo "typescript-lsp" ;;
      react|react-dom) echo "react-devtools" ;;
      eslint) echo "eslint-fix" ;;
      prettier) echo "prettier-format" ;;
      jest|vitest) echo "test-runner" ;;
      prisma) echo "prisma-helper" ;;
      docker*) echo "docker-helper" ;;
      @sentry/*|sentry) echo "sentry" ;;
      @slack/*|slack*) echo "slack" ;;
      graphql) echo "graphql-helper" ;;
      tailwindcss) echo "tailwind-assist" ;;
    esac
  done | sort -u | jq -R -s -c 'split("\n") | map(select(. != ""))'
}

# 전체 프로젝트 분석 (JSON 출력)
full_analysis() {
  local types=$(detect_project_type)
  local frameworks=$(detect_frameworks)
  local deps=$(get_dependencies)
  local complexity=$(analyze_complexity)
  local suggested=$(suggest_categories)
  local recommended=$(recommend_by_deps)

  cat <<EOF
{
  "projectRoot": "$PROJECT_ROOT",
  "analyzedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "projectTypes": $types,
  "frameworks": $frameworks,
  "dependencies": $deps,
  "complexity": $complexity,
  "suggestedCategories": $suggested,
  "recommendedPlugins": $recommended
}
EOF
}

# CLI 인터페이스
case "$1" in
  types)
    detect_project_type
    ;;
  frameworks)
    detect_frameworks
    ;;
  deps|dependencies)
    get_dependencies
    ;;
  complexity)
    analyze_complexity
    ;;
  suggest)
    suggest_categories
    ;;
  recommend)
    recommend_by_deps
    ;;
  full|analyze)
    full_analysis
    ;;
  *)
    echo "Usage: $0 {types|frameworks|deps|complexity|suggest|recommend|full}"
    echo ""
    echo "Commands:"
    echo "  types       - Detect project types (nodejs, typescript, python, etc.)"
    echo "  frameworks  - Detect frameworks (react, express, jest, etc.)"
    echo "  deps        - Extract dependencies"
    echo "  complexity  - Analyze project size/complexity"
    echo "  suggest     - Suggest plugin categories"
    echo "  recommend   - Recommend plugins based on dependencies"
    echo "  full        - Full analysis (JSON)"
    ;;
esac
