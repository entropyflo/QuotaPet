import Foundation

public struct QuotaWindow: Codable, Equatable, Sendable {
    public let usedPercent: Double
    public let windowDurationMins: Int
    public let resetsAt: Date

    public init(usedPercent: Double, windowDurationMins: Int, resetsAt: Date) {
        self.usedPercent = usedPercent
        self.windowDurationMins = windowDurationMins
        self.resetsAt = resetsAt
    }

    public var remainingPercent: Double {
        min(100, max(0, 100 - usedPercent))
    }

    public func remainingMinutes(at now: Date) -> Int {
        max(0, Int(ceil(resetsAt.timeIntervalSince(now) / 60)))
    }

    public func remainingTimeDescription(at now: Date) -> String {
        let totalMinutes = remainingMinutes(at: now)
        return "\(totalMinutes / 60)小时 \(totalMinutes % 60)分钟"
    }
}

public struct QuotaSnapshot: Equatable, Sendable {
    public let fiveHour: QuotaWindow?
    public let weekly: QuotaWindow?
    public let fetchedAt: Date
    public var isStale: Bool

    public init(fiveHour: QuotaWindow?, weekly: QuotaWindow?, fetchedAt: Date, isStale: Bool = false) {
        self.fiveHour = fiveHour
        self.weekly = weekly
        self.fetchedAt = fetchedAt
        self.isStale = isStale
    }
}

public enum ConnectionState: Equatable, Sendable {
    case disconnected(String)
    case connecting
    case connected
}

public enum QuotaProviderEvent: Sendable {
    case snapshot(QuotaSnapshot)
    case connection(ConnectionState)
}
