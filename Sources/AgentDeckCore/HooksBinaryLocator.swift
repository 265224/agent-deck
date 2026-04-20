import Foundation

public enum ManagedHooksBinary {
    public static let binaryName = "AgentDeckHooks"
    public static let bridgeShimName = "agent-deck-bridge"

    public static func defaultURL(fileManager: FileManager = .default) -> URL {
        installDirectory(fileManager: fileManager)
            .appendingPathComponent(binaryName)
            .standardizedFileURL
    }

    public static func candidateURLs(fileManager: FileManager = .default) -> [URL] {
        [
            defaultURL(fileManager: fileManager)
        ]
    }

    @discardableResult
    public static func install(
        from sourceURL: URL,
        to destinationURL: URL? = nil,
        fileManager: FileManager = .default
    ) throws -> URL {
        let resolvedSourceURL = sourceURL.standardizedFileURL
        let resolvedDestinationURL = (destinationURL ?? defaultURL(fileManager: fileManager)).standardizedFileURL

        try fileManager.createDirectory(
            at: resolvedDestinationURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        if resolvedSourceURL != resolvedDestinationURL {
            if fileManager.fileExists(atPath: resolvedDestinationURL.path) {
                try fileManager.removeItem(at: resolvedDestinationURL)
            }
            try fileManager.copyItem(at: resolvedSourceURL, to: resolvedDestinationURL)
        }

        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: resolvedDestinationURL.path)
        if resolvedDestinationURL == defaultURL(fileManager: fileManager).standardizedFileURL {
            try installLegacyBridgeShims(targeting: resolvedDestinationURL, fileManager: fileManager)
        }
        return resolvedDestinationURL
    }

    /// Overwrites the installed hooks binary if the bundle source differs.
    /// Returns `true` if the binary was updated.
    @discardableResult
    public static func updateIfNeeded(
        from sourceURL: URL,
        fileManager: FileManager = .default
    ) throws -> Bool {
        let installedURL = defaultURL(fileManager: fileManager)
        guard fileManager.fileExists(atPath: installedURL.path) else {
            return false
        }

        let sourceData = try Data(contentsOf: sourceURL)
        let installedData = try Data(contentsOf: installedURL)
        let didUpdate = sourceData != installedData

        if didUpdate {
            try fileManager.removeItem(at: installedURL)
            try fileManager.copyItem(at: sourceURL, to: installedURL)
            try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: installedURL.path)
        }

        try installLegacyBridgeShims(targeting: installedURL, fileManager: fileManager)
        return didUpdate
    }

    private static func installDirectory(fileManager: FileManager) -> URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("AgentDeck", isDirectory: true)
            .appendingPathComponent("bin", isDirectory: true)
    }

    private static func legacyBridgeShimDirectory(fileManager: FileManager) -> URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".agent-deck", isDirectory: true)
            .appendingPathComponent("bin", isDirectory: true)
    }

    private static func installLegacyBridgeShims(
        targeting hooksBinaryURL: URL,
        fileManager: FileManager
    ) throws {
        let directory = legacyBridgeShimDirectory(fileManager: fileManager)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let script = """
        #!/bin/zsh
        # Agent Deck compatibility shim for already-running agents that cached the legacy hook path.
        exec \(shellQuote(hooksBinaryURL.path)) "$@"
        """

        let shimURL = directory.appendingPathComponent(bridgeShimName)
        if fileManager.fileExists(atPath: shimURL.path) {
            try fileManager.removeItem(at: shimURL)
        }
        try Data(script.utf8).write(to: shimURL, options: .atomic)
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: shimURL.path)
    }

    private static func shellQuote(_ string: String) -> String {
        guard !string.isEmpty else {
            return "''"
        }

        return "'\(string.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}

public enum HooksBinaryLocator {
    public static func locate(
        fileManager: FileManager = .default,
        currentDirectory: URL? = nil,
        executableDirectory: URL? = nil,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> URL? {
        if let explicitPath = environment["AGENT_DECK_HOOKS_BINARY"],
           fileManager.isExecutableFile(atPath: explicitPath) {
            return URL(fileURLWithPath: explicitPath).standardizedFileURL
        }

        let currentDirectory = currentDirectory
            ?? URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
        let candidates = [
            executableDirectory?.appendingPathComponent("AgentDeckHooks"),
            executableDirectory?.deletingLastPathComponent().appendingPathComponent("AgentDeckHooks"),
            executableDirectory?.deletingLastPathComponent().appendingPathComponent("Helpers/AgentDeckHooks"),
        ].compactMap { $0 } + ManagedHooksBinary.candidateURLs(fileManager: fileManager) + {
            #if arch(arm64)
            let archTriple = "arm64-apple-macosx"
            #elseif arch(x86_64)
            let archTriple = "x86_64-apple-macosx"
            #endif
            return [
                currentDirectory.appendingPathComponent(".build/\(archTriple)/release/AgentDeckHooks"),
                currentDirectory.appendingPathComponent(".build/release/AgentDeckHooks"),
                currentDirectory.appendingPathComponent(".build/\(archTriple)/debug/AgentDeckHooks"),
                currentDirectory.appendingPathComponent(".build/debug/AgentDeckHooks"),
            ]
        }()

        for candidate in candidates where fileManager.isExecutableFile(atPath: candidate.path) {
            return candidate.standardizedFileURL
        }

        return nil
    }
}
