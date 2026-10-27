import AppKit
import SwiftUI
import BrimletCore

private final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

private final class IslandHostingView: NSHostingView<IslandView> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

@MainActor final class IslandPanelController {
    let panel: NSPanel
    private let model: AppModel
    private var screen: NSScreen?
    private var observers: [NSObjectProtocol] = []
    private var mouseMonitor: Any?
    private var keyMonitor: Any?
    private var fullscreenTimer: Timer?
    private var inFullscreen = false

    init(model: AppModel, observeSystem: Bool = true) {
        self.model = model
        panel = FloatingPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.title = "Ada"
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.appearance = NSAppearance(named: .darkAqua)
        panel.hasShadow = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isMovable = false
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .none
        let hosting = IslandHostingView(rootView: IslandView(model: model))
        hosting.sizingOptions = []
        panel.contentView = hosting
        model.onPresentationChange = { [weak self] in self?.updatePresentation() }
        refreshScreen()
        guard observeSystem else { return }
        observers.append(NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.refreshScreen() }
        })
        let workspace = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.didWakeNotification, NSWorkspace.screensDidWakeNotification, NSWorkspace.activeSpaceDidChangeNotification] {
            observers.append(workspace.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in
                    self?.model.collapse()
                    self?.model.refreshAfterWake()
                    self?.refreshScreen()
                    self?.checkFullscreen()
                }
            })
        }
        observers.append(workspace.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.checkFullscreen() }
        })
        observers.append(workspace.addObserver(forName: NSWorkspace.screensDidSleepNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.model.isPresented = false
                self?.panel.orderOut(nil)
            }
        })
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.model.isExpanded, !self.model.todos.isEditorPresented else { return }
                if !self.panel.frame.contains(NSEvent.mouseLocation) { self.model.collapse() }
            }
        }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.model.todos.isEditorPresented == true { return event }
            if event.keyCode == 53, self?.model.isExpanded == true {
                self?.model.collapse()
                return nil
            }
            return event
        }
        let timer = Timer(timeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkFullscreen() }
        }
        RunLoop.main.add(timer, forMode: .common)
        fullscreenTimer = timer
    }

    static func displayID(_ screen: NSScreen) -> String {
        guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else { return screen.localizedName }
        return number.stringValue
    }

    func refreshScreen() {
        model.availableDisplays = NSScreen.screens.map { (Self.displayID($0), $0.localizedName) }
        screen = targetScreen()
        guard let screen else { panel.orderOut(nil); return }
        let inset = screen.safeAreaInsets.top
        let notch: CGFloat
        if inset > 0, let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea {
            notch = max(0, screen.frame.width - left.width - right.width)
        } else { notch = 0 }
        model.geometry = IslandGeometry(notchWidth: notch, topInset: inset, screenWidth: screen.frame.width)
        updatePresentation(animated: false)
    }

    private func targetScreen() -> NSScreen? {
        if model.preferences.displayID != "auto",
           let chosen = NSScreen.screens.first(where: { Self.displayID($0) == model.preferences.displayID }) { return chosen }
        return NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) ?? NSScreen.screens.first
    }

    func updatePresentation(animated: Bool = true) {
        let target = targetScreen()
        if target.map(Self.displayID) != screen.map(Self.displayID) {
            refreshScreen()
            return
        }
        guard let screen else { return }
        if model.hidden || (model.preferences.hideInFullscreen && inFullscreen) {
            if model.isPresented { model.isPresented = false }
            panel.orderOut(nil)
            return
        }
        if !model.isPresented { model.isPresented = true }
        let frame = NSRect(x: screen.frame.midX - model.width / 2,
                           y: screen.frame.maxY - model.geometry.topMargin - model.height,
                           width: model.width, height: model.height)
        if animated && panel.isVisible && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            NSAnimationContext.runAnimationGroup { context in
                let verticalResize = model.isExpanded && abs(panel.frame.width - frame.width) < 1
                context.duration = verticalResize ? LyricsPresentation.resizeDuration : 0.22
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().setFrame(frame, display: true)
            }
        } else { panel.setFrame(frame, display: true) }
        panel.orderFrontRegardless()
    }

    /// Uses window bounds only; does not read titles or capture screen contents.
    /// Full-screen-sized foreground windows are conservatively treated as full screen.
    private func checkFullscreen() {
        guard model.preferences.hideInFullscreen, let screen,
              let front = NSWorkspace.shared.frontmostApplication,
              front.processIdentifier != ProcessInfo.processInfo.processIdentifier else {
            if inFullscreen { inFullscreen = false; updatePresentation(animated: false) }
            return
        }
        guard let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]],
              let primary = NSScreen.screens.first else { return }
        let screenBounds = CGRect(x: screen.frame.minX, y: primary.frame.maxY - screen.frame.maxY,
                                  width: screen.frame.width, height: screen.frame.height)
        let fullscreen = windows.contains { info in
            guard info[kCGWindowOwnerPID as String] as? pid_t == front.processIdentifier,
                  info[kCGWindowLayer as String] as? Int == 0,
                  let bounds = info[kCGWindowBounds as String] as? [String: Any],
                  let rect = CGRect(dictionaryRepresentation: bounds as CFDictionary) else { return false }
            return rect.insetBy(dx: -2, dy: -2).contains(screenBounds)
        }
        if fullscreen != inFullscreen {
            inFullscreen = fullscreen
            updatePresentation(animated: false)
        }
    }
}
