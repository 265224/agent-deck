# 01. Project Overview

`AgentDeck/` is the self-contained app project folder. It includes Swift source,
tests, docs, scripts, packaging config, iOS/watch companion source, desktop pet
source art, and app resources.

## Main Folders

| Path | Purpose |
|---|---|
| `Sources/AgentDeckApp/` | macOS SwiftUI/AppKit app shell, overlay, control center, settings |
| `Sources/AgentDeckCore/` | shared models, state reducers, bridge transport, hook payloads |
| `Sources/AgentDeckHooks/` | CLI invoked by agent hooks |
| `Sources/AgentDeckSetup/` | setup CLI for managed hook installation |
| `Tests/AgentDeckCoreTests/` | core tests |
| `Tests/AgentDeckAppTests/` | app service tests |
| `Assets/` | brand and source artwork |
| `Assets/DesktopPetSource/` | high-resolution source PNGs for desktop pet mode |
| `docs/` | product, architecture, packaging, release, and workflow docs |
| `project-docs/` | consolidated project summary docs |
| `scripts/` | build, package, smoke, setup, and helper scripts |
| `ios/` | companion mobile/watch source |

## Current Scope

Agent Deck is a local-first macOS companion for AI coding agents. It monitors
agent sessions, surfaces permission/questions, provides jump-back to the right
terminal or workspace, and can render as either an overlay panel or desktop pet.
