import AppKit
import SwiftUI

struct MenuBarContent: View {
    @ObservedObject var state: AppState

    var body: some View {
        Button(state.isVisible ? "隐藏宠物" : "显示宠物") { state.toggleVisibility() }
        Button("立即刷新") { state.refresh() }
            .keyboardShortcut("r")
        Divider()
        Toggle("锁定位置", isOn: binding(\.isLocked))
        Button("切换大小（\(state.petScaleMode.label)）") { state.togglePetScale() }
        Toggle("始终置顶", isOn: binding(\.isAlwaysOnTop))
        Toggle("点击穿透", isOn: binding(\.clickThrough))
        Toggle("登录时启动", isOn: Binding(
            get: { state.launchAtLogin },
            set: { state.setLaunchAtLogin($0) }
        ))
        Divider()
        Text("连接：\(state.connectionText)")
        Text("上次成功：\(lastRefreshText)")
        if let error = state.settingsError { Text(error) }
        Button("复制脱敏诊断信息") { state.copyDiagnostics() }
        Divider()
        Button("关于 QuotaPet") { showAbout() }
        Button("退出") { state.quit() }
            .keyboardShortcut("q")
    }

    private var lastRefreshText: String {
        state.snapshot?.fetchedAt.formatted(date: .abbreviated, time: .shortened) ?? "尚无"
    }

    private func binding(_ keyPath: ReferenceWritableKeyPath<AppState, Bool>) -> Binding<Bool> {
        Binding(get: { state[keyPath: keyPath] }, set: { state[keyPath: keyPath] = $0 })
    }

    private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "QuotaPet 0.1.0"
        alert.informativeText = "非官方开源社区项目，与 OpenAI 无隶属或背书关系。\nMIT License"
        alert.runModal()
    }
}
