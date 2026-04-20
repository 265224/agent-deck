# 06. Assets

Agent Deck keeps app assets inside the app folder.

## Brand

| Path | Purpose |
|---|---|
| `Assets/Brand/AgentDeck.icns` | macOS bundle icon |
| `Assets/Brand/AgentDeck.iconset/` | source iconset used for `.icns` generation |
| `Assets/Brand/app-icon-cat.png` | README/app-facing cat icon artwork |
| `Assets/Brand/dmg-background@2x.png` | packaged DMG background |

## Desktop Pet

| Path | Purpose |
|---|---|
| `Assets/DesktopPetSource/` | high-resolution source PNGs |
| `Sources/AgentDeckApp/Resources/desktop-pet-*.png` | runtime pet resources |
| `Sources/AgentDeckApp/Resources/desktop-pet-*@2x.png` | Retina runtime pet resources |
| `Sources/AgentDeckApp/Resources/desktop-pet-*@4x.png` | highest-detail runtime pet resources |

## Scripted Packaging Resources

Packaging scripts read from `Assets/Brand/` and place app resources into the
bundle at build/package time. The expected app bundle is:

```text
~/Applications/Agent Deck.app
```
