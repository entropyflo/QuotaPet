import Foundation

public enum RateLimitParser {
    public static func parse(data: Data, now: Date = Date()) throws -> QuotaSnapshot {
        let json = try JSONSerialization.jsonObject(with: data)
        let windows = findWindows(in: json)
        return select(windows: windows, now: now)
    }

    public static func select(windows: [QuotaWindow], now: Date = Date()) -> QuotaSnapshot {
        QuotaSnapshot(
            fiveHour: bestWindow(duration: 300, in: windows),
            weekly: bestWindow(duration: 10_080, in: windows),
            fetchedAt: now
        )
    }

    private static func bestWindow(duration: Int, in windows: [QuotaWindow]) -> QuotaWindow? {
        windows
            .filter { $0.windowDurationMins == duration }
            .max { $0.resetsAt < $1.resetsAt }
    }

    private static func findWindows(in value: Any) -> [QuotaWindow] {
        if let object = value as? [String: Any] {
            var result: [QuotaWindow] = []
            if let duration = integer(object["windowDurationMins"]),
               let used = number(object["usedPercent"]),
               let reset = number(object["resetsAt"]) {
                result.append(QuotaWindow(
                    usedPercent: used.isFinite ? used : 100,
                    windowDurationMins: duration,
                    resetsAt: Date(timeIntervalSince1970: reset)
                ))
            }
            for child in object.values {
                result.append(contentsOf: findWindows(in: child))
            }
            return result
        }
        if let array = value as? [Any] {
            return array.flatMap(findWindows(in:))
        }
        return []
    }

    private static func number(_ value: Any?) -> Double? {
        if let value = value as? NSNumber { return value.doubleValue }
        if let value = value as? String { return Double(value) }
        return nil
    }

    private static func integer(_ value: Any?) -> Int? {
        guard let number = number(value), number.isFinite else { return nil }
        return Int(number)
    }
}
