#!/bin/zsh

set -euo pipefail


skip_setup=false
no_open=false
for arg in "$@"; do
  case "$arg" in
    --skip-setup) skip_setup=true ;;
    --no-open) no_open=true ;;
  esac
done

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
brand_icon="$repo_root/Assets/Brand/AgentDeck.icns"
bundle_dir="$HOME/Applications/Agent Deck.app"
plist_path="$bundle_dir/Contents/Info.plist"
bundle_binary="$bundle_dir/Contents/MacOS/AgentDeckApp"

cd "$repo_root"

swift build -c debug --product AgentDeckApp
swift build -c debug --product AgentDeckHooks
swift build -c debug --product AgentDeckSetup

build_root="$(swift build -c debug --show-bin-path)"
app_binary="$build_root/AgentDeckApp"
hooks_binary="$build_root/AgentDeckHooks"
setup_binary="$build_root/AgentDeckSetup"

if [ "$skip_setup" = false ]; then
  "$setup_binary" install --hooks-binary "$hooks_binary"
fi

mkdir -p "$bundle_dir/Contents/MacOS" "$bundle_dir/Contents/Helpers" "$bundle_dir/Contents/Resources" "$bundle_dir/Contents/Frameworks"

rm -f \
  "$bundle_dir/Contents/MacOS/AgentDeckApp" \
  "$bundle_dir/Contents/Helpers/AgentDeckHooks" \
  "$bundle_dir/Contents/Helpers/AgentDeckSetup" \
  "$bundle_dir/Contents/Resources/AgentDeck.icns"
rm -rf \
  "$bundle_dir/Contents/Resources/AgentDeck_AgentDeckApp.bundle" \
  "$bundle_dir/AgentDeck_AgentDeckApp.bundle"

# Kill any running instance before copying so the binary isn't locked.
osascript -e 'tell application "Agent Deck" to quit' 2>/dev/null || true
pkill -9 -f "Agent Deck" 2>/dev/null || true
sleep 2

command cp "$app_binary" "$bundle_binary"
command cp "$hooks_binary" "$bundle_dir/Contents/Helpers/AgentDeckHooks"
command cp "$setup_binary" "$bundle_dir/Contents/Helpers/AgentDeckSetup"
command cp "$brand_icon" "$bundle_dir/Contents/Resources/AgentDeck.icns"
chmod +x "$bundle_binary" "$bundle_dir/Contents/Helpers/AgentDeckHooks" "$bundle_dir/Contents/Helpers/AgentDeckSetup"

# Copy SPM resource bundle to .app root — SPM's generated Bundle.module accessor
# searches Bundle.main.bundleURL (the .app root), NOT Contents/Resources/.
resource_bundle="$build_root/AgentDeck_AgentDeckApp.bundle"
if [ -d "$resource_bundle" ]; then
    rm -rf "$bundle_dir/AgentDeck_AgentDeckApp.bundle"
    command cp -R "$resource_bundle" "$bundle_dir/"
fi

cat > "$plist_path" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>AgentDeckApp</string>
    <key>CFBundleIdentifier</key>
    <string>app.agentdeck.local</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleIconFile</key>
    <string>AgentDeck</string>
    <key>CFBundleName</key>
    <string>Agent Deck</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>Agent Deck needs automation access to focus Terminal and iTerm sessions for jump-back.</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# Dev builds on macOS 26+: the SPM resource bundle at the .app root
# causes "unsealed contents" codesign failure. Move it into
# Contents/Resources/ so signing succeeds. On the developer machine
# Bundle.module falls back to the hardcoded .build/ path, so
# localization still works. (Release builds use package-app.sh which
# has its own resource bundle handling.)
resource_bundle_name="AgentDeck_AgentDeckApp.bundle"
root_bundle="$bundle_dir/$resource_bundle_name"
resources_bundle="$bundle_dir/Contents/Resources/$resource_bundle_name"
if [ -d "$root_bundle" ] && [ ! -L "$root_bundle" ]; then
    rm -rf "$resources_bundle"
    mv "$root_bundle" "$resources_bundle"
fi
# Remove stale symlinks from previous runs.
[ -L "$root_bundle" ] && rm -f "$root_bundle"

# Detect a local stable signing identity so the dev bundle's cdhash
# stays stable across rebuilds and macOS TCC grants (Accessibility,
# Automation) persist. Without it we fall back to ad-hoc signing, which
# changes the cdhash every build and silently invalidates any TCC
# grants the developer had approved — extremely disruptive when
# iterating on features that need AX permission. See
# scripts/setup-dev-signing.sh for a one-time setup that creates this
# identity locally with zero Apple Developer Program involvement.
sign_identity="-"
if security find-identity -p codesigning -v "$HOME/Library/Keychains/login.keychain-db" 2>/dev/null \
       | grep -q '"Agent Deck Dev Local"'; then
    sign_identity="Agent Deck Dev Local"
else
    echo
    echo "⚠ Using ad-hoc signing. macOS TCC grants (Accessibility, Automation)"
    echo "  will be invalidated on every rebuild. Run once to fix:"
    echo "    zsh scripts/setup-dev-signing.sh"
    echo
fi

codesign --force --deep --sign "$sign_identity" "$bundle_dir" 2>/dev/null || true

if [ "$no_open" = false ]; then
  open -na "$bundle_dir"
fi
