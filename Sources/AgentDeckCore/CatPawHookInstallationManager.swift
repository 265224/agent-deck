import Foundation

public struct CatPawHookInstallationStatus: Equatable, Sendable {
    public var catPawSettingsDirectory: URL
    public var hooksURL: URL
    public var manifestURL: URL
    public var hooksBinaryURL: URL?
    public var managedHooksPresent: Bool
    public var manifest: CatPawHookInstallerManifest?

    public init(
        catPawSettingsDirectory: URL,
        hooksURL: URL,
        manifestURL: URL,
        hooksBinaryURL: URL?,
        managedHooksPresent: Bool,
        manifest: CatPawHookInstallerManifest?
    ) {
        self.catPawSettingsDirectory = catPawSettingsDirectory
        self.hooksURL = hooksURL
        self.manifestURL = manifestURL
        self.hooksBinaryURL = hooksBinaryURL
        self.managedHooksPresent = managedHooksPresent
        self.manifest = manifest
    }
}

public final class CatPawHookInstallationManager: @unchecked Sendable {
    public let catPawSettingsDirectory: URL
    public let managedHooksBinaryURL: URL
    private let fileManager: FileManager

    public init(
        catPawSettingsDirectory: URL = CatPawHookInstallationManager.defaultSettingsDirectory(),
        managedHooksBinaryURL: URL = ManagedHooksBinary.defaultURL(),
        fileManager: FileManager = .default
    ) {
        self.catPawSettingsDirectory = catPawSettingsDirectory
        self.managedHooksBinaryURL = managedHooksBinaryURL.standardizedFileURL
        self.fileManager = fileManager
    }

    public static func defaultSettingsDirectory(
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> URL {
        homeDirectory
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("CatPaw", isDirectory: true)
            .appendingPathComponent("User", isDirectory: true)
            .appendingPathComponent("globalStorage", isDirectory: true)
            .appendingPathComponent("mt-idekit.mt-idekit-code", isDirectory: true)
            .appendingPathComponent("settings", isDirectory: true)
    }

    public func status(hooksBinaryURL: URL? = nil) throws -> CatPawHookInstallationStatus {
        let hooksURL = catPawSettingsDirectory.appendingPathComponent("hooks.json")
        let manifestURL = resolvedManifestURL()
        let resolvedBinaryURL = resolvedHooksBinaryURL(explicitURL: hooksBinaryURL)

        let hooksData = try? Data(contentsOf: hooksURL)
        let manifest = try loadManifest(at: manifestURL)
        let managedCommand = manifest?.hookCommand ?? resolvedBinaryURL.map {
            CatPawHookInstaller.hookCommand(for: $0.path)
        }
        let uninstallMutation = try CatPawHookInstaller.uninstallHooksJSON(
            existingData: hooksData,
            managedCommand: managedCommand
        )

        return CatPawHookInstallationStatus(
            catPawSettingsDirectory: catPawSettingsDirectory,
            hooksURL: hooksURL,
            manifestURL: manifestURL,
            hooksBinaryURL: resolvedBinaryURL,
            managedHooksPresent: uninstallMutation.managedHooksPresent,
            manifest: manifest
        )
    }

    @discardableResult
    public func install(hooksBinaryURL: URL) throws -> CatPawHookInstallationStatus {
        try fileManager.createDirectory(at: catPawSettingsDirectory, withIntermediateDirectories: true)

        let hooksURL = catPawSettingsDirectory.appendingPathComponent("hooks.json")
        let manifestURL = catPawSettingsDirectory.appendingPathComponent(CatPawHookInstallerManifest.fileName)
        let legacyManifestURL = catPawSettingsDirectory.appendingPathComponent(CatPawHookInstallerManifest.legacyFileName)
        let existingHooks = try? Data(contentsOf: hooksURL)
        let installedBinaryURL = try ManagedHooksBinary.install(
            from: hooksBinaryURL,
            to: managedHooksBinaryURL,
            fileManager: fileManager
        )
        let command = CatPawHookInstaller.hookCommand(for: installedBinaryURL.path)
        let mutation = try CatPawHookInstaller.installHooksJSON(
            existingData: existingHooks,
            hookCommand: command
        )

        if mutation.changed, fileManager.fileExists(atPath: hooksURL.path) {
            try backupFile(at: hooksURL)
        }

        if let contents = mutation.contents {
            try contents.write(to: hooksURL, options: .atomic)
        }

        let manifest = CatPawHookInstallerManifest(hookCommand: command)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(manifest).write(to: manifestURL, options: .atomic)
        if legacyManifestURL.standardizedFileURL != manifestURL.standardizedFileURL,
           fileManager.fileExists(atPath: legacyManifestURL.path) {
            try fileManager.removeItem(at: legacyManifestURL)
        }

        return try status(hooksBinaryURL: installedBinaryURL)
    }

    @discardableResult
    public func uninstall() throws -> CatPawHookInstallationStatus {
        let hooksURL = catPawSettingsDirectory.appendingPathComponent("hooks.json")
        let manifestURL = resolvedManifestURL()
        let primaryManifestURL = catPawSettingsDirectory.appendingPathComponent(CatPawHookInstallerManifest.fileName)
        let legacyManifestURL = catPawSettingsDirectory.appendingPathComponent(CatPawHookInstallerManifest.legacyFileName)
        let manifest = try loadManifest(at: manifestURL)
        let existingHooks = try? Data(contentsOf: hooksURL)
        let mutation = try CatPawHookInstaller.uninstallHooksJSON(
            existingData: existingHooks,
            managedCommand: manifest?.hookCommand
        )

        if mutation.changed, fileManager.fileExists(atPath: hooksURL.path) {
            try backupFile(at: hooksURL)
        }

        if let contents = mutation.contents {
            try contents.write(to: hooksURL, options: .atomic)
        } else if fileManager.fileExists(atPath: hooksURL.path) {
            try fileManager.removeItem(at: hooksURL)
        }

        for candidate in [primaryManifestURL, legacyManifestURL] where fileManager.fileExists(atPath: candidate.path) {
            try fileManager.removeItem(at: candidate)
        }

        return try status()
    }

    private func loadManifest(at url: URL) throws -> CatPawHookInstallerManifest? {
        guard fileManager.fileExists(atPath: url.path) else { return nil }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(CatPawHookInstallerManifest.self, from: data)
    }

    private func resolvedManifestURL() -> URL {
        let primaryURL = catPawSettingsDirectory.appendingPathComponent(CatPawHookInstallerManifest.fileName)
        if fileManager.fileExists(atPath: primaryURL.path) {
            return primaryURL
        }

        let legacyURL = catPawSettingsDirectory.appendingPathComponent(CatPawHookInstallerManifest.legacyFileName)
        return fileManager.fileExists(atPath: legacyURL.path) ? legacyURL : primaryURL
    }

    private func resolvedHooksBinaryURL(explicitURL: URL?) -> URL? {
        if let explicitURL {
            return explicitURL.standardizedFileURL
        }

        guard fileManager.isExecutableFile(atPath: managedHooksBinaryURL.path) else {
            return nil
        }

        return managedHooksBinaryURL
    }

    private func backupFile(at url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else { return }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let timestamp = formatter.string(from: .now).replacingOccurrences(of: ":", with: "-")
        let backupURL = url.appendingPathExtension("backup.\(timestamp)")
        if fileManager.fileExists(atPath: backupURL.path) {
            try fileManager.removeItem(at: backupURL)
        }
        try fileManager.copyItem(at: url, to: backupURL)
    }
}
