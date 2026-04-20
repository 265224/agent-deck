import Foundation

public final class CodexSessionIndex: @unchecked Sendable {
    public static var defaultFileURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex/session_index.jsonl")
    }

    private let fileURL: URL
    private let fileManager: FileManager

    public init(
        fileURL: URL = CodexSessionIndex.defaultFileURL,
        fileManager: FileManager = .default
    ) {
        self.fileURL = fileURL
        self.fileManager = fileManager
    }

    public func threadName(for sessionID: String) -> String? {
        threadNames()[sessionID]
    }

    public func threadNames() -> [String: String] {
        guard fileManager.fileExists(atPath: fileURL.path),
              let contents = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return [:]
        }

        var names: [String: String] = [:]
        for line in contents.split(whereSeparator: \.isNewline) {
            guard let data = String(line).data(using: .utf8),
                  let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let id = object["id"] as? String,
                  !id.isEmpty,
                  let rawName = object["thread_name"] as? String else {
                continue
            }

            let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else {
                continue
            }

            names[id] = name
        }

        return names
    }
}
