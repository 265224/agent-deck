import Foundation

public enum CodexPromptNormalizer {
    private static let requestMarkers = [
        "## My request for Codex:",
        "## My request:",
    ]

    public static func userVisiblePrompt(from rawPrompt: String?) -> String? {
        guard var prompt = rawPrompt?.trimmingCharacters(in: .whitespacesAndNewlines),
              !prompt.isEmpty else {
            return nil
        }

        prompt = prompt
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "<image>", with: " ")
            .replacingOccurrences(of: "</image>", with: " ")

        for marker in requestMarkers {
            if let markerRange = prompt.range(of: marker, options: [.caseInsensitive]) {
                let request = String(prompt[markerRange.upperBound...])
                return collapsed(request)
            }
        }

        return collapsed(prompt)
    }

    public static func collapsed(_ value: String) -> String? {
        let collapsed = value
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .split(separator: " ", omittingEmptySubsequences: true)
            .joined(separator: " ")

        return collapsed.isEmpty ? nil : collapsed
    }
}
