# 05. Desktop Pet Mode

Desktop pet mode is included in the Agent Deck folder. It uses high-resolution
PNG frames and the app chooses the best available scale asset at runtime.

## Relevant Source Files

| Area | Path |
|---|---|
| Presentation mode state | `Sources/AgentDeckApp/AppModelTypes.swift` |
| Appearance picker | `Sources/AgentDeckApp/Views/AppearanceSettingsPane.swift` |
| Desktop pet UI | `Sources/AgentDeckApp/Views/IslandPanelView.swift` |
| Panel placement/drag persistence | `Sources/AgentDeckApp/OverlayPanelController.swift` |
| Desktop pet dimensions | `Sources/AgentDeckApp/DesktopPetMetrics.swift` |
| Localized strings | `Sources/AgentDeckApp/Resources/*.lproj/Localizable.strings` |

## Source Artwork

Original high-resolution source PNGs are copied into:

```text
Assets/DesktopPetSource/
```

| Source | Runtime resource |
|---|---|
| `idle-wave.png` | `desktop-pet-idle-wave` and fallback `desktop-pet-idle` |
| `idle-play.png` | `desktop-pet-idle-play` |
| `busy.png` | `desktop-pet-busy` |
| `success.png` | `desktop-pet-success` |

## Generated Runtime Assets

The app resources include base, `@2x`, and `@4x` versions:

```text
Sources/AgentDeckApp/Resources/desktop-pet-idle.png
Sources/AgentDeckApp/Resources/desktop-pet-idle@2x.png
Sources/AgentDeckApp/Resources/desktop-pet-idle@4x.png
```

The same scale pattern exists for `idle-wave`, `idle-play`, `busy`, and
`success`. Runtime loading prefers `@4x`, then `@2x`, then base.

## Behavior Mapping

| Session state | Pet frame |
|---|---|
| No active work / idle | wave or play idle frame |
| Agent working | busy frame |
| Session completed | success frame |
| Unknown fallback | idle frame |
