import AppKit
import Combine
import Foundation
import QuotaPetCore
import ServiceManagement

@MainActor
final class AppState: NSObject, ObservableObject {
    @Published var snapshot: QuotaSnapshot?
    @Published var connection: ConnectionState = .connecting
    @Published var now = Date()
    @Published var isVisible = true
    @Published var isLocked: Bool {
        didSet { defaults.set(isLocked, forKey: Keys.locked); panel?.applySettings() }
    }
    @Published var isAlwaysOnTop: Bool {
        didSet { defaults.set(isAlwaysOnTop, forKey: Keys.alwaysOnTop); panel?.applySettings() }
    }
    @Published var clickThrough: Bool {
        didSet { defaults.set(clickThrough, forKey: Keys.clickThrough); panel?.applySettings() }
    }
    @Published var petScaleMode: PetScaleMode {
        didSet {
            defaults.set(petScaleMode.rawValue, forKey: Keys.petScaleMode)
            panel?.applyScaleMode()
        }
    }
    @Published var launchAtLogin = SMAppService.mainApp.status == .enabled
    @Published var settingsError: String?

    let executablePath: String?
    let isPreviewMode: Bool
    private let provider: any QuotaProvider
    private let defaults = UserDefaults.standard
    private var panel: PetPanelController?
    private var eventTask: Task<Void, Never>?
    private var clockTask: Task<Void, Never>?
    private var resetTask: Task<Void, Never>?

    private enum Keys {
        static let locked = "pet.locked"
        static let alwaysOnTop = "pet.alwaysOnTop"
        static let clickThrough = "pet.clickThrough"
        static let petScaleMode = "pet.scaleMode"
    }

    override init() {
        let arguments = ProcessInfo.processInfo.arguments
        let environment = ProcessInfo.processInfo.environment
        isPreviewMode = arguments.contains("--preview")
            || arguments.contains(where: { $0.hasPrefix("--preview-state=") })
            || environment["QUOTAPET_PREVIEW"] != nil
        let previewScale = arguments.first { $0.hasPrefix("--preview-scale=") }?
            .split(separator: "=", maxSplits: 1).last
            .flatMap { Double($0) }
            .flatMap(PetScaleMode.init(rawValue:))
        let selection = ProviderFactory.make()
        provider = selection.provider
        executablePath = selection.executablePath
        isLocked = isPreviewMode ? false : defaults.bool(forKey: Keys.locked)
        isAlwaysOnTop = defaults.object(forKey: Keys.alwaysOnTop) as? Bool ?? true
        clickThrough = isPreviewMode ? false : defaults.bool(forKey: Keys.clickThrough)
        petScaleMode = previewScale
            ?? PetScaleMode(rawValue: defaults.double(forKey: Keys.petScaleMode))
            ?? .full
        super.init()

        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(didWake), name: NSWorkspace.didWakeNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(willTerminate), name: NSApplication.willTerminateNotification, object: nil
        )
        Task { @MainActor [weak self] in self?.launch() }
    }

    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }

    private func launch() {
        panel = PetPanelController(state: self)
        panel?.show()
        eventTask = Task { [weak self, provider] in
            let events = await provider.events()
            async let startup: Void = provider.start()
            for await event in events {
                guard let self else { break }
                await MainActor.run { self.receive(event) }
            }
            _ = await startup
        }
        clockTask = Task { [weak self, provider] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                guard let self else { break }
                await MainActor.run { self.now = Date() }
                await provider.refresh()
            }
        }
    }

    private func receive(_ event: QuotaProviderEvent) {
        switch event {
        case let .snapshot(value):
            snapshot = value
            now = Date()
            scheduleResetRefresh(for: value.fiveHour?.resetsAt)
        case let .connection(value):
            connection = value
            if case .disconnected = value, var saved = snapshot {
                saved.isStale = true
                snapshot = saved
            }
        }
    }

    func refresh() { Task { await provider.refresh() } }

    private func scheduleResetRefresh(for resetDate: Date?) {
        resetTask?.cancel()
        guard let resetDate else { return }
        let delay = resetDate.timeIntervalSinceNow
        guard delay > 0 else { return }
        resetTask = Task { [weak self, provider] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled, self != nil else { return }
            await provider.refresh()
        }
    }

    func toggleVisibility() {
        isVisible.toggle()
        isVisible ? panel?.show() : panel?.hide()
    }

    func beginMovingPet(initialTranslation: CGSize) {
        panel?.beginMoving(initialTranslation: initialTranslation)
    }

    func movePetToCurrentMouseLocation() { panel?.moveToCurrentMouseLocation() }

    func endMovingPet() { panel?.endMoving() }

    func togglePetScale() { petScaleMode = petScaleMode.next }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            launchAtLogin = enabled
            settingsError = nil
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
            settingsError = "登录项设置失败：\(error.localizedDescription)"
        }
    }

    var connectionText: String {
        switch connection {
        case .connected: return "已连接"
        case .connecting: return "正在连接"
        case let .disconnected(reason): return "已断开 · \(reason)"
        }
    }

    var diagnostics: SanitizedDiagnostics {
        SanitizedDiagnostics(
            executablePath: executablePath,
            connectionState: connectionText,
            lastSuccess: snapshot?.fetchedAt,
            stale: snapshot?.isStale ?? true
        )
    }

    func copyDiagnostics() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(diagnostics.text, forType: .string)
    }

    func quit() {
        eventTask?.cancel()
        clockTask?.cancel()
        resetTask?.cancel()
        Task {
            await provider.stop()
            await MainActor.run { NSApp.terminate(nil) }
        }
    }

    @objc private func didWake() { refresh() }
    @objc private func willTerminate() { Task { await provider.stop() } }
}
