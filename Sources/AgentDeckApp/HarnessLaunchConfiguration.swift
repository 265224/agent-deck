import Foundation

struct HarnessLaunchConfiguration {
    let scenario: IslandDebugScenario?
    let presentOverlay: Bool
    let shouldShowControlCenter: Bool
    let shouldShowSettings: Bool
    let settingsTabRawValue: String?
    let shouldStartBridge: Bool
    let shouldPerformBootAnimation: Bool
    let captureDelay: TimeInterval?
    let autoExitAfter: TimeInterval?
    let artifactDirectoryURL: URL?

    init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        scenario = Self.scenarioValue(from: Self.value("AGENT_DECK_HARNESS_SCENARIO", in: environment))
        presentOverlay = Self.boolValue(
            Self.value("AGENT_DECK_HARNESS_PRESENT_OVERLAY", in: environment),
            default: false
        )
        shouldShowControlCenter = Self.boolValue(
            Self.value("AGENT_DECK_HARNESS_SHOW_CONTROL_CENTER", in: environment),
            default: true
        )
        shouldShowSettings = Self.boolValue(
            Self.value("AGENT_DECK_HARNESS_SHOW_SETTINGS", in: environment),
            default: false
        )
        settingsTabRawValue = Self.value("AGENT_DECK_HARNESS_SETTINGS_TAB", in: environment)
        shouldStartBridge = Self.boolValue(
            Self.value("AGENT_DECK_HARNESS_START_BRIDGE", in: environment),
            default: true
        )
        shouldPerformBootAnimation = Self.boolValue(
            Self.value("AGENT_DECK_HARNESS_BOOT_ANIMATION", in: environment),
            default: true
        )
        captureDelay = Self.timeIntervalValue(
            from: Self.value("AGENT_DECK_HARNESS_CAPTURE_DELAY_SECONDS", in: environment)
        )
        autoExitAfter = Self.timeIntervalValue(
            from: Self.value("AGENT_DECK_HARNESS_AUTO_EXIT_SECONDS", in: environment)
        )
        artifactDirectoryURL = Self.directoryURLValue(
            from: Self.value("AGENT_DECK_HARNESS_ARTIFACT_DIR", in: environment)
        )
    }

    private static func value(_ key: String, in environment: [String: String]) -> String? {
        environment[key]
    }

    private static func scenarioValue(from rawValue: String?) -> IslandDebugScenario? {
        guard let rawValue else {
            return nil
        }

        let normalized = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            return nil
        }

        return IslandDebugScenario.allCases.first { scenario in
            scenario.rawValue.caseInsensitiveCompare(normalized) == .orderedSame
        }
    }

    private static func boolValue(_ rawValue: String?, default defaultValue: Bool) -> Bool {
        guard let rawValue else {
            return defaultValue
        }

        let normalized = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !normalized.isEmpty else {
            return defaultValue
        }

        return switch normalized {
        case "1", "true", "yes", "on":
            true
        case "0", "false", "no", "off":
            false
        default:
            defaultValue
        }
    }

    private static func timeIntervalValue(from rawValue: String?) -> TimeInterval? {
        guard let rawValue else {
            return nil
        }

        let normalized = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let seconds = TimeInterval(normalized),
              seconds > 0 else {
            return nil
        }

        return seconds
    }

    private static func directoryURLValue(from rawValue: String?) -> URL? {
        guard let rawValue else {
            return nil
        }

        let normalized = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            return nil
        }

        return URL(fileURLWithPath: normalized, isDirectory: true)
    }
}
