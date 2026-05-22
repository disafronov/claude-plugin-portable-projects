#!/usr/bin/env sh
# Ensure ~/.claude/projects/<absolute-slug> is a symlink pointing to
# ~/.claude-projects/<portable-slug>. Migrates existing real directory if needed.

# Resolve project directory from Claude Code, falling back to the current directory.
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
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

mkdir -p "$PORTABLE_DIR" "$HOME/.claude/projects"

# Already a correct symlink — nothing to do
if [ -L "$CLAUDE_DIR" ] && [ "$(readlink "$CLAUDE_DIR")" = "$PORTABLE_DIR" ]; then
    exit 0
fi

# Real directory exists — migrate contents, then replace with symlink
if [ -d "$CLAUDE_DIR" ] && [ ! -L "$CLAUDE_DIR" ]; then
    for item in "$CLAUDE_DIR"/* "$CLAUDE_DIR"/.[!.]* "$CLAUDE_DIR"/..?*; do
        [ -f "$item" ] || [ -d "$item" ] || [ -L "$item" ] || continue
        basename=${item##*/}
        if [ -f "$PORTABLE_DIR/$basename" ] || [ -d "$PORTABLE_DIR/$basename" ] || [ -L "$PORTABLE_DIR/$basename" ]; then
            printf '%s\n' "portable-projects: refusing to overwrite $PORTABLE_DIR/$basename" >&2
            exit 1
        fi
    done

    for item in "$CLAUDE_DIR"/* "$CLAUDE_DIR"/.[!.]* "$CLAUDE_DIR"/..?*; do
        [ -f "$item" ] || [ -d "$item" ] || [ -L "$item" ] || continue
        mv "$item" "$PORTABLE_DIR/" || exit 1
    done
    rmdir "$CLAUDE_DIR" || exit 1
fi

if [ -L "$CLAUDE_DIR" ]; then
    rm "$CLAUDE_DIR" || exit 1
fi

ln -s "$PORTABLE_DIR" "$CLAUDE_DIR" || exit 1
