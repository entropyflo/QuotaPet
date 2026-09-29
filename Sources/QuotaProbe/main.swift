import Foundation
import QuotaPetCore
import Darwin

@main
enum QuotaProbe {
    static func main() async {
        guard let path = CodexExecutableLocator.locate() else {
            print("Codex executable: not found")
            exit(2)
        }
        print("Codex executable: \(URL(fileURLWithPath: path).lastPathComponent)")
        let provider = CodexAppServerProvider(executablePath: path)
        let stream = await provider.events()
        await provider.start()
        for await event in stream {
            switch event {
            case let .snapshot(snapshot):
                if let window = snapshot.fiveHour {
                    print("5-hour window: available, remaining \(Int(window.remainingPercent.rounded()))%")
                } else {
                    print("5-hour window: unavailable")
                }
                print("Weekly window: \(snapshot.weekly == nil ? "unavailable" : "available")")
                await provider.stop()
                return
            case let .connection(.disconnected(reason)):
                print("Connection failed: \(reason)")
                await provider.stop()
                exit(3)
            default:
                break
            }
        }
    }
}
