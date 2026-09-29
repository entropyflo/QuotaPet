import Foundation

public struct ReconnectPolicy: Equatable, Sendable {
    public let baseDelay: TimeInterval
    public let maximumDelay: TimeInterval

    public init(baseDelay: TimeInterval = 1, maximumDelay: TimeInterval = 60) {
        self.baseDelay = baseDelay
        self.maximumDelay = maximumDelay
    }

    public func delay(forAttempt attempt: Int) -> TimeInterval {
        guard attempt > 0 else { return 0 }
        return min(maximumDelay, baseDelay * pow(2, Double(attempt - 1)))
    }
}
