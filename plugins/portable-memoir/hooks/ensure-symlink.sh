#!/usr/bin/env sh
# Ensure ~/.memoir/<absolute-slug> is a symlink pointing to
# ~/.memoir-portable/<relative-slug>. Migrates existing real directory if needed.

# Resolve project directory from Claude Code, falling back to the current directory.
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_DIR=$(cd "$PROJECT_DIR" 2>/dev/null && pwd) || exit 0

# Portable slug: replace $HOME with ~, then / and . with -
if [ "${PROJECT_DIR#"$HOME"}" != "$PROJECT_DIR" ]; then
    PORTABLE_SLUG=$(printf '%s' "~${PROJECT_DIR#"$HOME"}" | tr '/.' '--')
else
    PORTABLE_SLUG=$(printf '%s' "$PROJECT_DIR" | tr '/.' '--')
fi

# Memoir slug: absolute path with / and . replaced by -
MEMOIR_SLUG=$(printf '%s' "$PROJECT_DIR" | tr '/.' '--')

PORTABLE_DIR="$HOME/.memoir-portable/$PORTABLE_SLUG"
MEMOIR_DIR="$HOME/.memoir/$MEMOIR_SLUG"

mkdir -p "$PORTABLE_DIR" "$HOME/.memoir"

# Already a correct symlink — nothing to do
if [ -L "$MEMOIR_DIR" ] && [ "$(readlink "$MEMOIR_DIR")" = "$PORTABLE_DIR" ]; then
    exit 0
fi

# Real directory exists — migrate contents, then replace with symlink
if [ -d "$MEMOIR_DIR" ] && [ ! -L "$MEMOIR_DIR" ]; then
    for item in "$MEMOIR_DIR"/* "$MEMOIR_DIR"/.[!.]* "$MEMOIR_DIR"/..?*; do
        [ -f "$item" ] || [ -d "$item" ] || [ -L "$item" ] || continue
        basename=${item##*/}
        if [ -f "$PORTABLE_DIR/$basename" ] || [ -d "$PORTABLE_DIR/$basename" ] || [ -L "$PORTABLE_DIR/$basename" ]; then
            printf '%s\n' "portable-memoir: refusing to overwrite $PORTABLE_DIR/$basename" >&2
            exit 1
        fi
    done

    for item in "$MEMOIR_DIR"/* "$MEMOIR_DIR"/.[!.]* "$MEMOIR_DIR"/..?*; do
        [ -f "$item" ] || [ -d "$item" ] || [ -L "$item" ] || continue
        mv "$item" "$PORTABLE_DIR/" || exit 1
    done
    rmdir "$MEMOIR_DIR" || exit 1
fi

if [ -L "$MEMOIR_DIR" ]; then
    rm "$MEMOIR_DIR" || exit 1
fi

ln -s "$PORTABLE_DIR" "$MEMOIR_DIR" || exit 1
