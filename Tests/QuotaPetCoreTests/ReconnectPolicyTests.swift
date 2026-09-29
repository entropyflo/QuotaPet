import Testing
@testable import QuotaPetCore

struct ReconnectPolicyTests {
    @Test func exponentialBackoffIsCapped() {
        let policy = ReconnectPolicy(baseDelay: 1, maximumDelay: 30)
        #expect(policy.delay(forAttempt: 0) == 0)
        #expect(policy.delay(forAttempt: 1) == 1)
        #expect(policy.delay(forAttempt: 2) == 2)
        #expect(policy.delay(forAttempt: 5) == 16)
        #expect(policy.delay(forAttempt: 6) == 30)
        #expect(policy.delay(forAttempt: 20) == 30)
    }
}
