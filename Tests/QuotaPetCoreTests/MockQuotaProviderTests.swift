import Foundation
import Testing
@testable import QuotaPetCore

struct MockQuotaProviderTests {
    @Test func producesFixedSnapshotWithoutAccount() async {
        let fixed = Date(timeIntervalSince1970: 1_700_000_000)
        let provider = MockQuotaProvider(scenario: .low, now: { fixed })
        let stream = await provider.events()
        await provider.start()
        for await event in stream {
            if case let .snapshot(snapshot) = event {
                #expect(snapshot.fetchedAt == fixed)
                #expect(snapshot.fiveHour?.remainingPercent == 20)
                await provider.stop()
                return
            }
        }
        Issue.record("Mock provider did not emit a snapshot")
    }
}
