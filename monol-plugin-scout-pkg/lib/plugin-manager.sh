#!/bin/bash
# Plugin Scout - 플러그인 매니저
# 플러그인 설치/제거/업데이트 자동화

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}"
DATA_DIR="$PLUGIN_ROOT/data"
HISTORY_FILE="$DATA_DIR/history.json"
USAGE_FILE="$DATA_DIR/usage.json"

CLAUDE_SETTINGS="$HOME/.claude/settings.json"
CLAUDE_PLUGINS_DIR="$HOME/.claude/plugins"

# 플러그인 설치
install_plugin() {
  local plugin_spec="$1"  # format: plugin-name@marketplace or plugin-name
  local source="${2:-recommendation}"

  # 플러그인명과 마켓플레이스 분리
  local plugin_name="${plugin_spec%@*}"
  local marketplace="${plugin_spec#*@}"

  if [ "$marketplace" = "$plugin_spec" ]; then
    marketplace=""
  fi

  echo "Installing plugin: $plugin_name"

  # settings.json 백업
  if [ -f "$CLAUDE_SETTINGS" ]; then
    cp "$CLAUDE_SETTINGS" "$CLAUDE_SETTINGS.bak"
  fi

  # enabledPlugins에 추가
  if command -v jq &> /dev/null && [ -f "$CLAUDE_SETTINGS" ]; then
    local plugin_key="$plugin_name"
    if [ -n "$marketplace" ]; then
      plugin_key="${plugin_name}@${marketplace}"
    fi

    jq --arg key "$plugin_key" '.enabledPlugins[$key] = true' "$CLAUDE_SETTINGS" > "$CLAUDE_SETTINGS.tmp" && mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"

    # history.json에 설치 기록
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local date_only=$(date +"%Y-%m-%d")

    if [ -f "$HISTORY_FILE" ]; then
      jq --arg plugin "$plugin_name" \
         --arg date "$date_only" \
         --arg source "$source" \
         --arg ts "$timestamp" \
         '
         .lastUpdated = $ts |
         .installed[$plugin] = {
           date: $date,
           source: $source,
           installedAt: $ts
         }
         ' "$HISTORY_FILE" > "$HISTORY_FILE.tmp" && mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
    fi

    # usage.json에 추가
    if [ -f "$USAGE_FILE" ]; then
      jq --arg plugin "$plugin_name" \
         --arg date "$date_only" \
         --arg ts "$timestamp" \
         '
         .lastUpdated = $ts |
         .plugins[$plugin] = (.plugins[$plugin] // {
           installed: $date,
           usageCount: 0,
           lastUsed: null
         })
         ' "$USAGE_FILE" > "$USAGE_FILE.tmp" && mv "$USAGE_FILE.tmp" "$USAGE_FILE"
    fi

    echo "Installed: $plugin_key"
    echo "Restart Claude Code to activate the plugin."
    return 0
  else
    echo "Error: jq required or settings.json not found"
    return 1
  fi
}

# 플러그인 제거
uninstall_plugin() {
  local plugin_name="$1"

  echo "Uninstalling plugin: $plugin_name"

  if command -v jq &> /dev/null && [ -f "$CLAUDE_SETTINGS" ]; then
    # settings.json 백업
    cp "$CLAUDE_SETTINGS" "$CLAUDE_SETTINGS.bak"

    # enabledPlugins에서 제거 (정확한 키 또는 @가 포함된 키)
    jq --arg plugin "$plugin_name" '
      .enabledPlugins |= with_entries(
        select(
          .key != $plugin and
          (.key | startswith($plugin + "@") | not)
        )
      )
    ' "$CLAUDE_SETTINGS" > "$CLAUDE_SETTINGS.tmp" && mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"

    # history.json에서 installed 제거
    if [ -f "$HISTORY_FILE" ]; then
      local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
      jq --arg plugin "$plugin_name" --arg ts "$timestamp" '
        .lastUpdated = $ts |
        del(.installed[$plugin])
      ' "$HISTORY_FILE" > "$HISTORY_FILE.tmp" && mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
    fi

    echo "Uninstalled: $plugin_name"
    echo "Restart Claude Code to complete removal."
    return 0
  else
    echo "Error: jq required or settings.json not found"
    return 1
  fi
}

# 설치된 플러그인 목록
list_installed() {
  if command -v jq &> /dev/null && [ -f "$CLAUDE_SETTINGS" ]; then
    echo "Installed Plugins:"
    jq -r '.enabledPlugins | to_entries | .[] | select(.value == true) | "  - \(.key)"' "$CLAUDE_SETTINGS"
  else
    echo "Error: jq required or settings.json not found"
  fi
}

# 플러그인 상태 확인
check_status() {
  local plugin_name="$1"

  if command -v jq &> /dev/null && [ -f "$CLAUDE_SETTINGS" ]; then
    local enabled=$(jq -r --arg plugin "$plugin_name" '
      .enabledPlugins | to_entries | .[] |
      select(.key == $plugin or (.key | startswith($plugin + "@"))) |
      .value
    ' "$CLAUDE_SETTINGS")

    if [ "$enabled" = "true" ]; then
      echo "enabled"
    else
      echo "disabled"
    fi
  else
    echo "unknown"
  fi
}

# 플러그인 활성화/비활성화
toggle_plugin() {
  local plugin_name="$1"
  local action="$2"  # enable or disable

  if command -v jq &> /dev/null && [ -f "$CLAUDE_SETTINGS" ]; then
    local value="true"
    [ "$action" = "disable" ] && value="false"

    jq --arg plugin "$plugin_name" --argjson val "$value" '
      .enabledPlugins |= with_entries(
        if .key == $plugin or (.key | startswith($plugin + "@"))
        then .value = $val
        else .
        end
      )
    ' "$CLAUDE_SETTINGS" > "$CLAUDE_SETTINGS.tmp" && mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"

    echo "Plugin $plugin_name: $action"
  else
    echo "Error: jq required or settings.json not found"
  fi
}

# 설치 명령 생성 (dry-run)
generate_install_command() {
  local plugin_name="$1"
  local marketplace="$2"

  if [ -n "$marketplace" ]; then
    echo "/plugin install ${plugin_name}@${marketplace}"
  else
    echo "/plugin install ${plugin_name}"
  fi
}

# 복원 (백업에서)
restore_backup() {
  if [ -f "$CLAUDE_SETTINGS.bak" ]; then
    cp "$CLAUDE_SETTINGS.bak" "$CLAUDE_SETTINGS"
    echo "Restored from backup"
  else
    echo "No backup found"
  fi
}

# CLI 인터페이스
case "$1" in
  install)
    install_plugin "$2" "$3"
    ;;
  uninstall|remove)
    uninstall_plugin "$2"
    ;;
  list)
    list_installed
    ;;
  status)
    check_status "$2"
    ;;
  enable)
    toggle_plugin "$2" "enable"
    ;;
  disable)
    toggle_plugin "$2" "disable"
    ;;
  command)
    generate_install_command "$2" "$3"
    ;;
  restore)
    restore_backup
    ;;
  *)
    echo "Usage: $0 {install|uninstall|list|status|enable|disable|command|restore}"
    echo ""
    echo "Commands:"
    echo "  install <plugin[@marketplace]> [source]  - Install a plugin"
    echo "  uninstall <plugin>                        - Uninstall a plugin"
    echo "  list                                      - List installed plugins"
    echo "  status <plugin>                           - Check plugin status"
    echo "  enable <plugin>                           - Enable a plugin"
    echo "  disable <plugin>                          - Disable a plugin"
    echo "  command <plugin> [marketplace]            - Generate install command"
    echo "  restore                                   - Restore from backup"
    ;;
esac
