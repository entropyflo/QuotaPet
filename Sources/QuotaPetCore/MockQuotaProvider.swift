import Foundation

public actor MockQuotaProvider: QuotaProvider {
    public enum Scenario: String, Sendable {
        case healthy = "95"
        case low = "20"
        case empty = "0"
        case offline
    }

    private let scenario: Scenario
    private let now: @Sendable () -> Date
    private var continuation: AsyncStream<QuotaProviderEvent>.Continuation?
    private lazy var stream = AsyncStream<QuotaProviderEvent> { continuation in
        self.continuation = continuation
    }

    public init(scenario: Scenario = .healthy, now: @escaping @Sendable () -> Date = Date.init) {
        self.scenario = scenario
        self.now = now
    }

    public func events() -> AsyncStream<QuotaProviderEvent> { stream }

    public func start() async {
        if scenario == .offline {
            continuation?.yield(.connection(.disconnected("Preview: offline")))
        } else {
            continuation?.yield(.connection(.connected))
            await refresh()
        }
    }

    public func refresh() async {
        guard scenario != .offline else { return }
        let date = now()
        let remaining = Double(scenario.rawValue) ?? 95
        continuation?.yield(.snapshot(QuotaSnapshot(
            fiveHour: QuotaWindow(
                usedPercent: 100 - remaining,
                windowDurationMins: 300,
                resetsAt: date.addingTimeInterval(87 * 60)
            ),
            weekly: QuotaWindow(
                usedPercent: 38,
                windowDurationMins: 10_080,
                resetsAt: date.addingTimeInterval(4 * 86_400)
            ),
            fetchedAt: date
        )))
    }

    public func stop() async { continuation?.finish() }
}
