# 04. Integrations And Hooks

Agent Deck supports local hook/event integrations for common coding agents.
OpenCode is retained as an integration name because it is a supported agent, not
the app brand.

## Managed Helper

The managed helper binary is installed under:

```text
~/Library/Application Support/AgentDeck/bin/AgentDeckHooks
```

The helper can also be resolved through:

```text
AGENT_DECK_HOOKS_BINARY=/path/to/AgentDeckHooks
```

## Python Remote Helper

`scripts/agent-deck-hooks.py` is the portable remote helper for SSH scenarios.
It uses:

```text
AGENT_DECK_SOCKET_PATH=/tmp/agent-deck-<uid>.sock
```

## Supported Sources

- Codex
- Claude Code
- OpenCode
- Cursor
- Gemini
- CatPaw

The CatPaw completion flow includes a guard for late events after a completed
session so an already-finished desktop pet/session state is not reopened by a
stale follow-up event.
