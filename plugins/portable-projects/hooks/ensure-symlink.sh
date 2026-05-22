#!/usr/bin/env sh
# Ensure ~/.claude/projects/<absolute-slug> is a symlink pointing to
# ~/.claude-projects/<portable-slug>. Migrates existing real directory if needed.

# Resolve project directory: git root > CLAUDE_PROJECT_DIR > pwd
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-${GIT_ROOT:-$(pwd)}}"
PROJECT_DIR=$(cd "$PROJECT_DIR" 2>/dev/null && pwd) || exit 0

# Portable slug: replace $HOME with ~, then / and . with -
if [ "${PROJECT_DIR#"$HOME"}" != "$PROJECT_DIR" ]; then
    PORTABLE_SLUG=$(printf '%s' "~${PROJECT_DIR#"$HOME"}" | tr '/.' '--')
else
    PORTABLE_SLUG=$(printf '%s' "$PROJECT_DIR" | tr '/.' '--')
fi

# Claude Code slug: absolute path with / and . replaced by -
CLAUDE_SLUG=$(printf '%s' "$PROJECT_DIR" | tr '/.' '--')

PORTABLE_DIR="$HOME/.claude-projects/$PORTABLE_SLUG"
CLAUDE_DIR="$HOME/.claude/projects/$CLAUDE_SLUG"

# Already a correct symlink — nothing to do
if [ -L "$CLAUDE_DIR" ] && [ "$(readlink "$CLAUDE_DIR")" = "$PORTABLE_DIR" ]; then
    exit 0
fi

mkdir -p "$PORTABLE_DIR"

# Real directory exists — migrate contents, then replace with symlink
if [ -d "$CLAUDE_DIR" ] && [ ! -L "$CLAUDE_DIR" ]; then
    find "$CLAUDE_DIR" -maxdepth 1 -mindepth 1 -exec mv {} "$PORTABLE_DIR/" \;
    rmdir "$CLAUDE_DIR"
fi

ln -sfn "$PORTABLE_DIR" "$CLAUDE_DIR"
