import AppKit
import SwiftUI

@MainActor
final class PetPanelController: NSObject, NSWindowDelegate {
    private let panel: NSPanel
    private unowned let state: AppState
    private let defaults = UserDefaults.standard
    private static let frameKey = "pet.windowFrame"
    private static let defaultSize = NSSize(width: 300, height: 280)
    private var moveStartFrame: NSRect?
    private var moveStartMouse: NSPoint?

    init(state: AppState) {
        self.state = state
        let initialSize = Self.size(for: state.petScaleMode)
        panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: initialSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        super.init()
        panel.delegate = self
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.acceptsMouseMovedEvents = true
        panel.minSize = Self.size(for: .half)
        panel.maxSize = Self.size(for: .full)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        let hostingView = NSHostingView(rootView: PetView(state: state))
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = hostingView
        restorePosition()
        applySettings()
    }

    func applySettings() {
        panel.level = state.isAlwaysOnTop ? .floating : .normal
        panel.ignoresMouseEvents = state.clickThrough
        panel.isMovableByWindowBackground = false
        panel.isMovable = !state.isLocked
    }

    func show() { panel.orderFrontRegardless() }
    func hide() { panel.orderOut(nil) }

    func beginMoving(initialTranslation: CGSize) {
        guard !state.isLocked else { return }
        if moveStartFrame == nil {
            moveStartFrame = panel.frame
            let currentMouse = NSEvent.mouseLocation
            moveStartMouse = NSPoint(
                x: currentMouse.x - initialTranslation.width,
                y: currentMouse.y + initialTranslation.height
            )
        }
    }

    func moveToCurrentMouseLocation() {
        guard !state.isLocked,
              let start = moveStartFrame,
              let startMouse = moveStartMouse else { return }
        let currentMouse = NSEvent.mouseLocation
        let origin = NSPoint(
            x: start.origin.x + currentMouse.x - startMouse.x,
            y: start.origin.y + currentMouse.y - startMouse.y
        )
        panel.setFrameOrigin(origin)
    }

    func endMoving() {
        moveStartFrame = nil
        moveStartMouse = nil
        saveFrame()
    }

    func applyScaleMode() {
        let current = panel.frame
        let size = Self.size(for: state.petScaleMode)
        let frame = NSRect(
            x: current.minX,
            y: current.maxY - size.height,
            width: size.width,
            height: size.height
        )
        panel.setFrame(frame, display: true)
        saveFrame()
    }

    func windowDidMove(_ notification: Notification) {
        guard !state.isLocked, moveStartFrame == nil else { return }
        saveFrame()
    }

    func windowDidResize(_ notification: Notification) {
        guard moveStartFrame == nil else { return }
        saveFrame()
    }

    private func saveFrame() {
        guard !state.isPreviewMode else { return }
        defaults.set(NSStringFromRect(panel.frame), forKey: Self.frameKey)
    }

    private func restorePosition() {
        if !state.isPreviewMode, let raw = defaults.string(forKey: Self.frameKey) {
            let saved = NSRectFromString(raw)
            if NSScreen.screens.contains(where: { $0.visibleFrame.intersects(saved) }) {
                let size = Self.size(for: state.petScaleMode)
                panel.setFrame(
                    NSRect(x: saved.minX, y: saved.maxY - size.height, width: size.width, height: size.height),
                    display: false
                )
                return
            }
        }
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        panel.setFrameOrigin(NSPoint(x: visible.maxX - panel.frame.width - 32, y: visible.minY + 80))
    }

    private static func size(for mode: PetScaleMode) -> NSSize {
        let scale = CGFloat(mode.rawValue)
        return NSSize(width: defaultSize.width * scale, height: defaultSize.height * scale)
    }
}
