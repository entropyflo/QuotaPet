import Foundation

public enum CodexExecutableLocator {
    public static let fixedCandidates = [
        "/Applications/ChatGPT.app/Contents/Resources/codex",
        "/Applications/ChatGPT.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex",
        "/opt/homebrew/bin/codex",
        "/usr/local/bin/codex"
    ]

    public static func locate(environment: [String: String] = ProcessInfo.processInfo.environment) -> String? {
        let manager = FileManager.default
        var candidates: [String] = []
        if let configured = environment["CODEX_EXECUTABLE"], !configured.isEmpty {
            candidates.append(configured)
        }
        candidates.append(contentsOf: fixedCandidates)
        if let path = environment["PATH"] {
            candidates.append(contentsOf: path.split(separator: ":").map { "\($0)/codex" })
        }
        return candidates.first { manager.isExecutableFile(atPath: $0) }
    }
}
