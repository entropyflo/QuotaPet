import Foundation

public actor CodexAppServerProvider: QuotaProvider {
    private let executablePath: String?
    private let reconnectPolicy: ReconnectPolicy
    private let matcher = JSONRPCResponseMatcher()
    private var process: Process?
    private var input: FileHandle?
    private var lineBuffer = Data()
    private var nextID = 1
    private var reconnectAttempt = 0
    private var shouldRun = false
    private var continuation: AsyncStream<QuotaProviderEvent>.Continuation?
    private lazy var stream: AsyncStream<QuotaProviderEvent> = {
        AsyncStream { continuation in self.continuation = continuation }
    }()

    public init(
        executablePath: String? = CodexExecutableLocator.locate(),
        reconnectPolicy: ReconnectPolicy = ReconnectPolicy()
    ) {
        self.executablePath = executablePath
        self.reconnectPolicy = reconnectPolicy
    }

    public func events() -> AsyncStream<QuotaProviderEvent> { stream }

    public func start() async {
        guard !shouldRun else { return }
        shouldRun = true
        await connect()
    }

    public func refresh() async {
        guard process?.isRunning == true else {
            continuation?.yield(.connection(.disconnected("Codex App Server is not connected")))
            return
        }
        do {
            let data = try await request(method: "account/rateLimits/read", params: [:])
            let snapshot = try RateLimitParser.parse(data: data)
            continuation?.yield(.snapshot(snapshot))
            continuation?.yield(.connection(.connected))
        } catch {
            continuation?.yield(.connection(.disconnected("Refresh failed: \(shortDescription(error))")))
        }
    }

    public func stop() async {
        shouldRun = false
        input?.closeFile()
        process?.terminationHandler = nil
        if process?.isRunning == true { process?.terminate() }
        process = nil
        input = nil
        continuation?.finish()
    }

    private func connect() async {
        guard shouldRun else { return }
        guard let executablePath else {
            continuation?.yield(.connection(.disconnected("Codex executable not found")))
            return
        }
        continuation?.yield(.connection(.connecting))

        let child = Process()
        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        child.executableURL = URL(fileURLWithPath: executablePath)
        child.arguments = ["app-server", "--listen", "stdio://"]
        child.standardInput = stdinPipe
        child.standardOutput = stdoutPipe
        child.standardError = stderrPipe
        child.terminationHandler = { [weak self] _ in
            Task { await self?.processTerminated() }
        }
        do {
            try child.run()
            process = child
            input = stdinPipe.fileHandleForWriting
            lineBuffer = Data()
            startReader(stdoutPipe.fileHandleForReading)
            drain(stderrPipe.fileHandleForReading)

            _ = try await request(method: "initialize", params: [
                "clientInfo": ["name": "QuotaPet", "title": "QuotaPet", "version": "0.1.0"],
                "capabilities": [:]
            ])
            try sendNotification(method: "initialized", params: [:])
            reconnectAttempt = 0
            continuation?.yield(.connection(.connected))
            await refresh()
        } catch {
            continuation?.yield(.connection(.disconnected("Connection failed: \(shortDescription(error))")))
            if child.isRunning { child.terminate() }
        }
    }

    private func startReader(_ handle: FileHandle) {
        Task.detached { [weak self] in
            while true {
                let data = handle.availableData
                guard !data.isEmpty else { break }
                await self?.receive(data)
            }
        }
    }

    private nonisolated func drain(_ handle: FileHandle) {
        Task.detached {
            while !handle.availableData.isEmpty {}
        }
    }

    private func receive(_ data: Data) async {
        lineBuffer.append(data)
        while let newline = lineBuffer.firstIndex(of: 0x0A) {
            let line = lineBuffer[..<newline]
            lineBuffer.removeSubrange(...newline)
            guard !line.isEmpty else { continue }
            await receiveLine(Data(line))
        }
    }

    private func receiveLine(_ data: Data) async {
        switch JSONRPCLineDecoder.decode(data) {
        case let .response(id, payload):
            await matcher.receive(id: id, payload: payload)
        case let .notification(method, _):
            if method == "account/rateLimits/updated" {
                await refresh()
            }
        default:
            break
        }
    }

    private func request(method: String, params: [String: Any]) async throws -> Data {
        let id = nextID
        nextID += 1
        try writeJSON(["id": id, "method": method, "params": params])
        let response = try await matcher.wait(id: id)
        if let object = try JSONSerialization.jsonObject(with: response) as? [String: Any],
           let error = object["error"] as? [String: Any] {
            throw JSONRPCError.server((error["message"] as? String) ?? "unknown server error")
        }
        return response
    }

    private func sendNotification(method: String, params: [String: Any]) throws {
        try writeJSON(["method": method, "params": params])
    }

    private func writeJSON(_ value: [String: Any]) throws {
        guard let input else { throw JSONRPCError.disconnected }
        var data = try JSONSerialization.data(withJSONObject: value)
        data.append(0x0A)
        try input.write(contentsOf: data)
    }

    private func processTerminated() async {
        process = nil
        input = nil
        guard shouldRun else { return }
        reconnectAttempt += 1
        let delay = reconnectPolicy.delay(forAttempt: reconnectAttempt)
        continuation?.yield(.connection(.disconnected("App Server exited; retrying in \(Int(delay))s")))
        do { try await Task.sleep(for: .seconds(delay)) } catch { return }
        await connect()
    }

    private func shortDescription(_ error: Error) -> String {
        if let rpcError = error as? JSONRPCError {
            switch rpcError {
            case .timeout: return "request timed out"
            case let .server(message): return message
            case .disconnected: return "disconnected"
            }
        }
        return String(describing: error)
    }
}
