#!/bin/zsh
# clean-user-env.sh — Reset to a clean "new user" state for testing.
# Usage: zsh scripts/clean-user-env.sh [--dry-run]
#
# This removes all Agent Deck artifacts from the current user's environment,
# simulating a fresh install.

set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

red()    { printf '\033[31m%s\033[0m\n' "$1"; }
green()  { printf '\033[32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[33m%s\033[0m\n' "$1"; }

clean_path() {
    local path="$1"
    if [[ -e "$path" || -L "$path" ]]; then
        if $DRY_RUN; then
            yellow "[dry-run] would remove: $path"
        else
            /bin/rm -rf "$path"
            green "removed: $path"
        fi
    fi
}

clean_glob() {
    local pattern="$1"
    for f in $~pattern(N); do
        clean_path "$f"
    done
}

echo "==> Quit Agent Deck if running"
if ! $DRY_RUN; then
    pkill -x AgentDeckApp 2>/dev/null || true
    pkill -x agent-deck 2>/dev/null || true
    sleep 0.5
fi

uid="$(id -u)"

echo ""
echo "==> Cleaning Agent Deck artifacts"

# --- Hook configurations ---
echo "--- Hook configs ---"

# Claude: remove Agent Deck hook entries from settings.json
claude_settings=~/.claude/settings.json
if [[ -f "$claude_settings" ]]; then
    if $DRY_RUN; then
        yellow "[dry-run] would strip Agent Deck hooks from: $claude_settings"
    else
        python3 -c "
import json, sys, pathlib
p = pathlib.Path(sys.argv[1])
d = json.loads(p.read_text())
hooks = d.get('hooks', {})
changed = False
for event in list(hooks.keys()):
    original = hooks[event]
    filtered = [h for h in original
                if not any(('AgentDeckHooks' in (c.get('command','')) or
                            'agent-deck-hooks.py' in (c.get('command','')))
                           for c in h.get('hooks',[]))]
    if len(filtered) != len(original):
        changed = True
        if filtered:
            hooks[event] = filtered
        else:
            del hooks[event]
sl = d.get('statusLine', {})
if 'agent-deck' in sl.get('command', ''):
    del d['statusLine']
    changed = True
if changed:
    if not hooks and 'hooks' in d:
        del d['hooks']
    p.write_text(json.dumps(d, indent=2, ensure_ascii=False) + '\n')
    print('stripped Agent Deck hooks/statusLine from', sys.argv[1])
" "$claude_settings" 2>/dev/null && green "cleaned hooks in $claude_settings" || true
    fi
fi
clean_path ~/.claude/agent-deck-claude-hooks-install.json
clean_glob ~/.claude/'settings.json.backup.*'

# Codex: remove Agent Deck entries from hooks.json
codex_hooks=~/.codex/hooks.json
if [[ -f "$codex_hooks" ]]; then
    if $DRY_RUN; then
        yellow "[dry-run] would strip Agent Deck hooks from: $codex_hooks"
    else
        python3 -c "
import json, sys, pathlib
p = pathlib.Path(sys.argv[1])
d = json.loads(p.read_text())
# Codex hooks.json nests events under a 'hooks' key
hooks = d.get('hooks', d)
changed = False
for event in list(hooks.keys()):
    original = hooks[event]
    if not isinstance(original, list): continue
    filtered = [h for h in original
                if not any(('AgentDeckHooks' in c.get('command','') or
                            'agent-deck-hooks.py' in c.get('command',''))
                           for c in h.get('hooks',[]))]
    if len(filtered) != len(original):
        changed = True
        if filtered:
            hooks[event] = filtered
        else:
            del hooks[event]
if changed:
    p.write_text(json.dumps(d, indent=2, ensure_ascii=False) + '\n')
    print('stripped Agent Deck hooks from', sys.argv[1])
" "$codex_hooks" 2>/dev/null && green "cleaned hooks in $codex_hooks" || true
    fi
fi
clean_path ~/.codex/agent-deck-codex-hooks-install.json
clean_path ~/.codex/agent-deck-install.json
clean_glob ~/.codex/'config.toml.backup.*'
clean_glob ~/.codex/'hooks.json.backup.*'

# --- Installed hooks binary ---
echo "--- Hooks binary ---"
clean_path ~/Library/Application\ Support/AgentDeck

# --- Status line scripts ---
echo "--- Status line ---"
clean_path ~/.agent-deck

# --- Session registry & app data ---
echo "--- App data ---"
clean_path ~/Library/Application\ Support/agent-deck
clean_path ~/Library/Application\ Support/AgentDeck

# --- Temp / socket files ---
echo "--- Temp files ---"
clean_path "/tmp/agent-deck-${uid}.sock"
clean_path /tmp/agent-deck-rl.json

# --- Installed app ---
echo "--- App bundle ---"
clean_path /Applications/Agent\ Deck.app
clean_path ~/Applications/Agent\ Deck.app

# --- UserDefaults ---
echo "--- UserDefaults ---"
# Find the bundle ID used by the app
for bid in app.agentdeck.local app.agentdeck.dev; do
    plist=~/Library/Preferences/${bid}.plist
    if [[ -e "$plist" ]]; then
        if $DRY_RUN; then
            yellow "[dry-run] would remove defaults for: $bid"
        else
            defaults delete "$bid" 2>/dev/null || true
            green "removed defaults: $bid"
        fi
    fi
done

echo ""
if $DRY_RUN; then
    yellow "Dry run complete. Re-run without --dry-run to actually clean."
else
    green "Done! Environment is clean."
    echo ""
    echo "Next steps:"
    echo "  1. Install Agent Deck.dmg from the latest release"
    echo "  2. Launch the app — you are now a fresh user"
fi
