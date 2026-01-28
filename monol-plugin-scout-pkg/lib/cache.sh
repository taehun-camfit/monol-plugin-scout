#!/bin/bash
# Plugin Scout - 캐싱 유틸리티
# 자주 사용하는 데이터를 메모리/파일에 캐싱

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}"
DATA_DIR="$PLUGIN_ROOT/data"
CACHE_DIR="$DATA_DIR/.cache"
CACHE_TTL="${SCOUT_CACHE_TTL:-300}"  # 기본 5분

# 캐시 디렉토리 생성
mkdir -p "$CACHE_DIR"

# 캐시 키 해시 생성
get_cache_key() {
  local input="$1"
  echo "$input" | md5 2>/dev/null || echo "$input" | md5sum 2>/dev/null | cut -d' ' -f1
}

# 캐시 파일 경로
get_cache_path() {
  local key="$1"
  local hash=$(get_cache_key "$key")
  echo "$CACHE_DIR/$hash"
}

# 캐시에서 읽기
cache_get() {
  local key="$1"
  local ttl="${2:-$CACHE_TTL}"
  local cache_file=$(get_cache_path "$key")

  # 캐시 파일 존재 확인
  if [ ! -f "$cache_file" ]; then
    return 1
  fi

  # TTL 확인
  local file_age=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null) ))
  if [ "$file_age" -gt "$ttl" ]; then
    rm -f "$cache_file"
    return 1
  fi

  cat "$cache_file"
  return 0
}

# 캐시에 저장
cache_set() {
  local key="$1"
  local value="$2"
  local cache_file=$(get_cache_path "$key")

  echo "$value" > "$cache_file"
}

# 캐시 삭제
cache_delete() {
  local key="$1"
  local cache_file=$(get_cache_path "$key")

  rm -f "$cache_file"
}

# 모든 캐시 삭제
cache_clear() {
  rm -f "$CACHE_DIR"/*
  echo "Cache cleared"
}

# 캐시 통계
cache_stats() {
  echo "=== Cache Statistics ==="
  echo ""
  echo "Cache directory: $CACHE_DIR"
  echo "Cache TTL: ${CACHE_TTL}s"
  echo ""

  if [ -d "$CACHE_DIR" ]; then
    local count=$(ls -1 "$CACHE_DIR" 2>/dev/null | wc -l | tr -d ' ')
    local size=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1)
    echo "Cached items: $count"
    echo "Total size: ${size:-0}"
  else
    echo "Cache directory not found"
  fi
}

# 캐시된 함수 실행 (결과 캐싱)
cached_exec() {
  local key="$1"
  shift
  local command="$@"
  local ttl="${SCOUT_CACHE_TTL:-300}"

  # 캐시 확인
  local cached=$(cache_get "$key" "$ttl")
  if [ -n "$cached" ]; then
    echo "$cached"
    return 0
  fi

  # 명령 실행 및 캐싱
  local result
  result=$(eval "$command")
  local exit_code=$?

  if [ $exit_code -eq 0 ]; then
    cache_set "$key" "$result"
  fi

  echo "$result"
  return $exit_code
}

# 프로젝트 분석 캐싱
cached_project_analysis() {
  local key="project_analysis_$(pwd | get_cache_key)"

  cached_exec "$key" "bash '$PLUGIN_ROOT/lib/project-analyzer.sh' full"
}

# 팀 추천 캐싱
cached_team_recommendations() {
  local key="team_recommendations"

  cached_exec "$key" "bash '$PLUGIN_ROOT/lib/team-manager.sh' recommendations"
}

# 만료된 캐시 정리
cache_cleanup() {
  local ttl="${1:-$CACHE_TTL}"
  local now=$(date +%s)
  local count=0

  for file in "$CACHE_DIR"/*; do
    if [ -f "$file" ]; then
      local file_time=$(stat -f%m "$file" 2>/dev/null || stat -c%Y "$file" 2>/dev/null)
      local age=$(( now - file_time ))
      if [ "$age" -gt "$ttl" ]; then
        rm -f "$file"
        count=$((count + 1))
      fi
    fi
  done

  echo "Cleaned $count expired cache entries"
}

# CLI 인터페이스
case "$1" in
  get)
    cache_get "$2" "$3"
    ;;
  set)
    cache_set "$2" "$3"
    ;;
  delete)
    cache_delete "$2"
    ;;
  clear)
    cache_clear
    ;;
  stats)
    cache_stats
    ;;
  cleanup)
    cache_cleanup "$2"
    ;;
  project)
    cached_project_analysis
    ;;
  team)
    cached_team_recommendations
    ;;
  exec)
    shift
    cached_exec "$@"
    ;;
  *)
    echo "Usage: $0 {get|set|delete|clear|stats|cleanup|project|team|exec}"
    echo ""
    echo "Commands:"
    echo "  get <key> [ttl]     - Get cached value"
    echo "  set <key> <value>   - Set cache value"
    echo "  delete <key>        - Delete cache entry"
    echo "  clear               - Clear all cache"
    echo "  stats               - Show cache statistics"
    echo "  cleanup [ttl]       - Clean expired entries"
    echo "  project             - Cached project analysis"
    echo "  team                - Cached team recommendations"
    echo "  exec <key> <cmd>    - Execute with caching"
    ;;
esac
