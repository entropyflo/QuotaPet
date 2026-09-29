import Foundation
import Testing
@testable import QuotaPetCore

struct JSONRPCTests {
    @Test func parsesResponse() {
        let data = #"{"id":7,"result":{"ok":true}}"#.data(using: .utf8)!
        guard case let .response(id, payload) = JSONRPCLineDecoder.decode(data) else {
            Issue.record("Expected response")
            return
        }
        #expect(id == 7)
        #expect(payload == data)
    }

    @Test func parsesNotification() {
        let data = #"{"method":"account/rateLimits/updated","params":{}}"#.data(using: .utf8)!
        guard case let .notification(method, _) = JSONRPCLineDecoder.decode(data) else {
            Issue.record("Expected notification")
            return
        }
        #expect(method == "account/rateLimits/updated")
    }

    @Test func matchesOutOfOrderResponses() async throws {
        let matcher = JSONRPCResponseMatcher()
        let first = Data("first".utf8)
        let second = Data("second".utf8)
        await matcher.receive(id: 2, payload: second)
        await matcher.receive(id: 1, payload: first)
        #expect(try await matcher.wait(id: 1) == first)
        #expect(try await matcher.wait(id: 2) == second)
    }

    @Test func invalidJSONIsUnknown() {
        #expect(JSONRPCLineDecoder.decode(Data("nope".utf8)) == .unknown)
    }
}
