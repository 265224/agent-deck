# 02. Build, Run, Verify

Run commands from the `AgentDeck/` folder.

## Build

```bash
swift build --target AgentDeckCore
swift build --target AgentDeckHooks
swift build --target AgentDeckSetup
swift build --target AgentDeckApp
```

## Install And Launch Local App

```bash
zsh scripts/launch-dev-app.sh
```

This builds the app and helpers, installs the bundle at
`~/Applications/Agent Deck.app`, installs managed hooks when setup is not
skipped, signs the local bundle, and launches it.

For build-only installation without launching:

```bash
zsh scripts/launch-dev-app.sh --skip-setup --no-open
```

## Smoke Checks

```bash
zsh scripts/smoke-dev-app.sh
zsh scripts/smoke-all-scenarios.sh
```

Harness output is written under `output/harness/`.

## Packaging

```bash
zsh scripts/package-app.sh
```

Release artifacts are written under `output/package/`.
