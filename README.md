# claude-plugin-portable-projects

Symlinks `~/.claude/projects/<absolute-slug>` to `~/.claude-projects/<portable-slug>` on every prompt, keeping Claude Code project memory portable across Linux and macOS machines.

## Why

Claude Code stores per-project memory under `~/.claude/projects/` using slugs derived from the **absolute path** on that machine. If you work on the same project on two different machines (or reinstall your OS), the paths differ — memory is lost.

This plugin solves the problem by:

1. Computing a **portable slug** (replaces `$HOME` with `~` before slugifying) that stays the same across machines.
2. Keeping the actual memory files under `~/.claude-projects/` — a directory you can track in your dotfiles or sync via cloud storage.
3. Replacing the Claude Code project directory with a symlink pointing to the portable location. Existing contents are migrated automatically.

## Installation

**Step 1.** Register the marketplace in your Claude Code settings (`~/.claude/settings.json`):

```json
{
  "extraKnownMarketplaces": {
    "portable-projects": {
      "source": {
        "source": "github",
        "repo": "disafronov/claude-plugin-portable-projects"
      }
    }
  }
}
```

**Step 2.** Enable the plugin inside Claude Code:

```shell
/plugin enable portable-projects@portable-projects
```

The `UserPromptSubmit` hook is registered automatically. On the next prompt the symlink is created (or migrated from an existing real directory).

Supported platforms: Linux and macOS. Native Windows is intentionally unsupported.

## After installation

Make `~/.claude-projects/` part of your dotfiles repo or sync it with your preferred tool (rsync, Syncthing, Dropbox, etc.). On a new machine, restore the directory before opening Claude Code — the plugin will wire up the symlinks on first use.
