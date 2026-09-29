import Foundation

public enum JSONRPCMessage: Equatable, Sendable {
    case response(id: Int, payload: Data)
    case notification(method: String, payload: Data)
    case request(id: Int, method: String, payload: Data)
    case unknown
}

public enum JSONRPCLineDecoder {
    public static func decode(_ data: Data) -> JSONRPCMessage {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .unknown
        }
        let payload = data
        let id = (object["id"] as? NSNumber)?.intValue
        let method = object["method"] as? String
        if let id, let method { return .request(id: id, method: method, payload: payload) }
        if let id, object["result"] != nil || object["error"] != nil {
            return .response(id: id, payload: payload)
        }
        if let method { return .notification(method: method, payload: payload) }
        return .unknown
    }
}

public actor JSONRPCResponseMatcher {
    private var responses: [Int: Data] = [:]

    public init() {}

    public func receive(id: Int, payload: Data) {
        responses[id] = payload
    }

    public func take(id: Int) -> Data? {
        responses.removeValue(forKey: id)
    }

    public func wait(id: Int, timeout: Duration = .seconds(8)) async throws -> Data {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while clock.now < deadline {
            if let data = take(id: id) { return data }
            try await clock.sleep(for: .milliseconds(20))
        }
        throw JSONRPCError.timeout
    }
}

public enum JSONRPCError: Error, Equatable {
    case timeout
    case server(String)
    case disconnected
}
