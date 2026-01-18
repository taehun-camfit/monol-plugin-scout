#!/bin/bash
# fetch-plugin-metadata.sh
# Extract metadata from plugin manifest for evaluation

set -euo pipefail

PLUGIN_PATH="${1:-}"

usage() {
    echo "Usage: fetch-plugin-metadata.sh <plugin-path>"
    echo ""
    echo "Extracts metadata from a local plugin directory."
    echo ""
    echo "Example:"
    echo "  fetch-plugin-metadata.sh ./my-plugin"
    exit 1
}

if [ -z "$PLUGIN_PATH" ]; then
    usage
fi

if [ ! -d "$PLUGIN_PATH" ]; then
    echo "{\"error\": \"Directory not found: $PLUGIN_PATH\"}" >&2
    exit 1
fi

# Check for plugin.json in standard location
MANIFEST="$PLUGIN_PATH/.claude-plugin/plugin.json"

if [ ! -f "$MANIFEST" ]; then
    # Try alternative location
    MANIFEST="$PLUGIN_PATH/plugin.json"
fi

if [ ! -f "$MANIFEST" ]; then
    echo "{\"error\": \"No plugin.json found in $PLUGIN_PATH\"}" >&2
    exit 1
fi

# Extract and format metadata using jq if available
if command -v jq &> /dev/null; then
    cat "$MANIFEST" | jq '{
        name: .name,
        description: .description,
        version: .version,
        author: .author,
        license: .license,
        homepage: .homepage,
        repository: .repository,
        keywords: .keywords,
        commands: (.commands | if type == "array" then length else 0 end),
        agents: (.agents | if type == "array" then length else 0 end),
        skills: (.skills | if type == "array" then length else 0 end),
        hooks: (.hooks | if type == "object" then keys else [] end),
        source: "local"
    }'
else
    # Fallback: just output the raw manifest
    cat "$MANIFEST"
fi
