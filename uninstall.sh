#!/usr/bin/env bash
set -euo pipefail

# Claude Ads Uninstaller (multi-host)
#
# Usage:
#   bash uninstall.sh                  # default: --target=claude
#   bash uninstall.sh --target=codex
#
# Removes every directory under <SKILL_BASE>/ads-* plus the orchestrator at
# <SKILL_BASE>/ads, plus the bundled audit + creative agents under <AGENT_DIR>.
# Uses glob discovery so new sub-skills don't require uninstaller updates.

resolve_target_paths() {
    local target="$1"
    case "$target" in
        claude)   SKILL_BASE="${HOME}/.claude/skills";                                   AGENT_DIR="${HOME}/.claude/agents" ;;
        codex)    SKILL_BASE="${HOME}/.codex/skills";                                    AGENT_DIR="${HOME}/.codex/agents" ;;
        cursor)   SKILL_BASE="${HOME}/.cursor/extensions/claude-ads/skills";             AGENT_DIR="${HOME}/.cursor/extensions/claude-ads/agents" ;;
        windsurf) SKILL_BASE="${HOME}/.windsurf/skills";                                 AGENT_DIR="${HOME}/.windsurf/agents" ;;
        gemini)   SKILL_BASE="${HOME}/.gemini/extensions/claude-ads/skills";             AGENT_DIR="${HOME}/.gemini/extensions/claude-ads/agents" ;;
        goose)    SKILL_BASE="${HOME}/.config/goose/skills";                             AGENT_DIR="${HOME}/.config/goose/agents" ;;
        *)        return 1 ;;
    esac
    return 0
}

main() {
    local TARGET="claude"

    while [ $# -gt 0 ]; do
        case "$1" in
            --target=*) TARGET="${1#*=}" ;;
            --target)   shift; [ $# -eq 0 ] && { echo "✗ --target requires a value" >&2; exit 1; }; TARGET="$1" ;;
            --help|-h)
                echo "Usage: bash uninstall.sh [--target=<claude|codex|cursor|windsurf|gemini|goose>]"
                exit 0
                ;;
            *) echo "✗ Unknown argument: $1" >&2; exit 1 ;;
        esac
        shift
    done

    if ! resolve_target_paths "$TARGET"; then
        echo "✗ Unknown target: $TARGET" >&2
        echo "  Valid targets: claude, codex, cursor, windsurf, gemini, goose" >&2
        exit 1
    fi

    echo "→ Uninstalling Claude Ads from ${SKILL_BASE} and ${AGENT_DIR}..."

    # Remove orchestrator (with references + scripts)
    rm -rf "${SKILL_BASE}/ads"

    # Remove all ads-* sub-skills via glob (no hardcoded list — new sub-skills
    # don't require an uninstaller update)
    if [ -d "${SKILL_BASE}" ]; then
        for d in "${SKILL_BASE}"/ads-*/; do
            [ -d "$d" ] && rm -rf "$d"
        done
    fi

    # Remove bundled audit + creative agents
    for agent in audit-google audit-meta audit-creative audit-tracking audit-budget audit-compliance audit-amazon audit-attribution audit-server-side creative-strategist visual-designer copy-writer format-adapter; do
        rm -f "${AGENT_DIR}/${agent}.md"
    done

    echo "✓ Claude Ads uninstalled."
}

main "$@"
