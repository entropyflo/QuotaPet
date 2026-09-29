import Foundation

public struct SanitizedDiagnostics: Sendable {
    public let executableFound: Bool
    public let executableLocation: String
    public let connectionState: String
    public let lastSuccess: Date?
    public let stale: Bool

    public init(executablePath: String?, connectionState: String, lastSuccess: Date?, stale: Bool) {
        executableFound = executablePath != nil
        executableLocation = executablePath.map { URL(fileURLWithPath: $0).lastPathComponent } ?? "none"
        self.connectionState = connectionState
        self.lastSuccess = lastSuccess
        self.stale = stale
    }

    public var text: String {
        let refreshed = lastSuccess?.formatted(date: .numeric, time: .standard) ?? "never"
        return """
        QuotaPet diagnostics
        Codex executable: \(executableFound ? "found (\(executableLocation))" : "not found")
        Connection: \(connectionState)
        Last successful refresh: \(refreshed)
        Data stale: \(stale)
        No account IDs, tokens, cookies, prompts, or responses are included.
        """
    }
}
