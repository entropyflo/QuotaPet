import Foundation

public protocol QuotaProvider: Sendable {
    func events() async -> AsyncStream<QuotaProviderEvent>
    func start() async
    func refresh() async
    func stop() async
}
