# 03. Architecture And Flow

`Package.swift` defines these active products:

| Target | Role |
|---|---|
| `AgentDeckCore` | shared session models, bridge transport, hook payloads, reducers, persistence |
| `AgentDeckHooks` | stdin/stdout hook CLI that forwards agent events to the app bridge |
| `AgentDeckSetup` | helper installer and managed hook setup command |
| `AgentDeckApp` | SwiftUI/AppKit macOS app, overlay panel, control center, settings |

## Runtime Flow

```text
Agent event
  -> managed hook config
  -> AgentDeckHooks --source <agent>
  -> Unix socket bridge
  -> BridgeServer
  -> AppModel
  -> UI/session state
```

For blocking permission or question flows:

```text
AgentDeckHooks waits for bridge response
  -> user responds in Agent Deck
  -> bridge returns allow/deny/answer
  -> hook writes response to stdout
```

## Socket Defaults

- Stable socket: `~/Library/Application Support/AgentDeck/bridge.sock`
- Remote/legacy-style socket path: `/tmp/agent-deck-<uid>.sock`
- Override env var: `AGENT_DECK_SOCKET_PATH`
