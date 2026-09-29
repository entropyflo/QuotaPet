import Foundation
import QuotaPetCore

enum ProviderFactory {
    static func make(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> (provider: any QuotaProvider, executablePath: String?) {
        let argument = arguments.first { $0.hasPrefix("--preview-state=") }?
            .split(separator: "=", maxSplits: 1).last.map(String.init)
        let requested = argument ?? environment["QUOTAPET_PREVIEW"]
        if arguments.contains("--preview") || requested != nil {
            let scenario = MockQuotaProvider.Scenario(rawValue: requested ?? "95") ?? .healthy
            return (MockQuotaProvider(scenario: scenario), nil)
        }
        let path = CodexExecutableLocator.locate(environment: environment)
        return (CodexAppServerProvider(executablePath: path), path)
    }
}
