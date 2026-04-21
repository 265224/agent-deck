import Foundation

public struct CatPawHookInstallerManifest: Equatable, Codable, Sendable {
    public static let fileName = "agent-deck-catpaw-hooks-install.json"
    public static let legacyFileName = "agent-deck-catpaw-hooks-install.json"

    public var hookCommand: String
    public var installedAt: Date

    public init(hookCommand: String, installedAt: Date = .now) {
        self.hookCommand = hookCommand
        self.installedAt = installedAt
    }
}

public struct CatPawHookFileMutation: Equatable, Sendable {
    public var contents: Data?
    public var changed: Bool
    public var managedHooksPresent: Bool

    public init(contents: Data?, changed: Bool, managedHooksPresent: Bool) {
        self.contents = contents
        self.changed = changed
        self.managedHooksPresent = managedHooksPresent
    }
}

public enum CatPawHookInstallerError: Error, LocalizedError {
    case invalidHooksJSON

    public var errorDescription: String? {
        switch self {
        case .invalidHooksJSON:
            "The existing CatPaw hooks.json is not valid JSON."
        }
    }
}

public enum CatPawHookInstaller {
    private static let hookEvents = CatPawHookEventName.allCases.map(\.rawValue)

    public static func hookCommand(for binaryPath: String) -> String {
        "\(shellQuote(binaryPath)) --source catpaw"
    }

    public static func installHooksJSON(
        existingData: Data?,
        hookCommand: String
    ) throws -> CatPawHookFileMutation {
        var rootObject = try loadRootObject(from: existingData)
        var hooksObject = rootObject["hooks"] as? [String: Any] ?? [:]

        for event in hookEvents {
            var entries = hookEntries(from: hooksObject[event])
            entries = entries.filter { !isManagedHook($0, managedCommand: hookCommand) }
            entries.append(["command": hookCommand])
            hooksObject[event] = entries
        }

        rootObject["hooks"] = hooksObject
        let data = try serialize(rootObject)

        return CatPawHookFileMutation(
            contents: data,
            changed: data != existingData,
            managedHooksPresent: true
        )
    }

    public static func uninstallHooksJSON(
        existingData: Data?,
        managedCommand: String?
    ) throws -> CatPawHookFileMutation {
        guard let existingData else {
            return CatPawHookFileMutation(contents: nil, changed: false, managedHooksPresent: false)
        }

        var rootObject = try loadRootObject(from: existingData)
        var hooksObject = rootObject["hooks"] as? [String: Any] ?? [:]
        var mutated = false

        for event in hookEvents {
            guard let rawValue = hooksObject[event] else {
                continue
            }

            let entries = hookEntries(from: rawValue)
            let filtered = entries.filter { !isManagedHook($0, managedCommand: managedCommand) }
            if filtered.count != entries.count {
                mutated = true
            }

            if filtered.isEmpty {
                hooksObject.removeValue(forKey: event)
            } else if rawValue is [String: Any], filtered.count == 1 {
                hooksObject[event] = filtered[0]
            } else {
                hooksObject[event] = filtered
            }
        }

        if hooksObject.isEmpty {
            rootObject.removeValue(forKey: "hooks")
        } else {
            rootObject["hooks"] = hooksObject
        }

        let contents = rootObject.isEmpty ? nil : try serialize(rootObject)

        return CatPawHookFileMutation(
            contents: contents,
            changed: mutated || contents != existingData,
            managedHooksPresent: mutated
        )
    }

    private static func hookEntries(from value: Any?) -> [[String: Any]] {
        if let entries = value as? [[String: Any]] {
            return entries
        }

        if let entry = value as? [String: Any] {
            return [entry]
        }

        return []
    }

    private static func loadRootObject(from data: Data?) throws -> [String: Any] {
        guard let data else { return [:] }

        let object = try JSONSerialization.jsonObject(with: data)
        guard let rootObject = object as? [String: Any] else {
            throw CatPawHookInstallerError.invalidHooksJSON
        }

        return rootObject
    }

    private static func serialize(_ object: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
    }

    private static func isManagedHook(_ hook: [String: Any], managedCommand: String?) -> Bool {
        guard let command = hook["command"] as? String else { return false }

        if let managedCommand, command == managedCommand {
            return true
        }

        return isAgentDeckCatPawHookCommand(command)
    }

    private static func isAgentDeckCatPawHookCommand(_ command: String) -> Bool {
        let normalized = command.lowercased()
        guard normalized.contains("catpaw") else {
            return false
        }

        return normalized.contains("agentdeckhooks")
            || normalized.contains("vibeislandhooks")
            || normalized.contains("vibe-island")
    }

    private static func shellQuote(_ string: String) -> String {
        guard !string.isEmpty else { return "''" }
        return "'\(string.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}
