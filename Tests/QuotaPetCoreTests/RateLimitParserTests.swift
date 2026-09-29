import Foundation
import Testing
@testable import QuotaPetCore

struct RateLimitParserTests {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    @Test func selectsWindowsByDurationNotOrder() throws {
        let json = """
        {"result":{"rateLimits":{"primary":{"usedPercent":25,"windowDurationMins":10080,"resetsAt":1700600000},"secondary":{"usedPercent":40,"windowDurationMins":300,"resetsAt":1700000121}}}}
        """.data(using: .utf8)!
        let snapshot = try RateLimitParser.parse(data: json, now: now)
        #expect(snapshot.fiveHour?.remainingPercent == 60)
        #expect(snapshot.weekly?.remainingPercent == 75)
        #expect(snapshot.fiveHour?.remainingMinutes(at: now) == 3)
    }

    @Test func clampsPercentagesAndCountdown() {
        let future = QuotaWindow(usedPercent: -50, windowDurationMins: 300, resetsAt: now.addingTimeInterval(1))
        let past = QuotaWindow(usedPercent: 150, windowDurationMins: 300, resetsAt: now.addingTimeInterval(-100))
        #expect(future.remainingPercent == 100)
        #expect(future.remainingMinutes(at: now) == 1)
        #expect(past.remainingPercent == 0)
        #expect(past.remainingMinutes(at: now) == 0)
    }

    @Test func formatsCountdownAsHoursAndMinutes() {
        let window = QuotaWindow(
            usedPercent: 50,
            windowDurationMins: 300,
            resetsAt: now.addingTimeInterval(121 * 60)
        )
        #expect(window.remainingTimeDescription(at: now) == "2小时 1分钟")
        let expired = QuotaWindow(
            usedPercent: 100,
            windowDurationMins: 300,
            resetsAt: now.addingTimeInterval(-1)
        )
        #expect(expired.remainingTimeDescription(at: now) == "0小时 0分钟")
    }

    @Test func missingFiveHourDoesNotInventQuota() throws {
        let json = """
        {"result":{"rateLimits":{"primary":{"usedPercent":10,"windowDurationMins":10080,"resetsAt":1700600000}}}}
        """.data(using: .utf8)!
        let snapshot = try RateLimitParser.parse(data: json, now: now)
        #expect(snapshot.fiveHour == nil)
        #expect(snapshot.weekly?.remainingPercent == 90)
    }

    @Test func acceptsStringNumbersAndNestedLimitMap() throws {
        let json = """
        {"result":{"rateLimitsByLimitId":{"codex":{"secondary":{"usedPercent":"99","windowDurationMins":"300","resetsAt":"1700000060"}}}}}
        """.data(using: .utf8)!
        let snapshot = try RateLimitParser.parse(data: json, now: now)
        #expect(snapshot.fiveHour?.remainingPercent == 1)
        #expect(snapshot.fiveHour?.remainingMinutes(at: now) == 1)
    }
}
