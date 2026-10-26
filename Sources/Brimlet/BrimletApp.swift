import AppKit
import Combine
import SwiftUI

@main struct BrimletApp {
    @MainActor static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let delegate = AppDelegate()
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }
}

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    private var model: AppModel!
    private var island: IslandPanelController!
    private var statusItem: NSStatusItem!
    private var updateItem: NSMenuItem!
    private let updateSeparator = NSMenuItem.separator()
    private var updateSubscription: AnyCancellable?
    private var settingsWindow: NSWindow?
    private var settingsController: SettingsController?
    private var externalReceiver: ExternalNotificationReceiver!
    private var quotePanel: QuotePanelController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let modes: [(String, @MainActor () -> Void)] = [("--capture-quote-previews", PreviewCapture.runQuotes), ("--capture-previews", PreviewCapture.run),
                                                        ("--capture-demo", DemoCapture.run), ("--smoke-test", SmokeTest.run)]
        for (flag, run) in modes where CommandLine.arguments.contains(flag) {
            run()
            NSApp.terminate(nil)
            return
        }
        let otherInstances = NSWorkspace.shared.runningApplications.filter {
            $0.bundleIdentifier == Bundle.main.bundleIdentifier && $0.processIdentifier != ProcessInfo.processInfo.processIdentifier
        }
        if let existing = otherInstances.first {
            existing.activate(options: [])
            NSApp.terminate(nil)
            return
        }
        Migration.run()
        model = AppModel()
        quotePanel = QuotePanelController(store: model.quotes, preferences: model.preferences)
        model.onShowQuote = { [weak self] quote in self?.quotePanel.show(quote) }
        NSApp.servicesProvider = self
        NSUpdateDynamicServices()
        island = IslandPanelController(model: model)
        externalReceiver = ExternalNotificationReceiver(model: model)
        externalReceiver.start()
        model.onOpenSettings = { [weak self] in self?.openSettings(nil) }
        createStatusItem()
        model.updater.start()
        if !UserDefaults.standard.bool(forKey: "didWelcome") {
            UserDefaults.standard.set(true, forKey: "didWelcome")
            model.expand()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        openSettings(nil)
        return true
    }

    private func createStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        // The template image is only in the app bundle; a bare `swift build` binary falls back to the symbol.
        let image = NSImage(named: "MenuBarIconTemplate") ?? NSImage(systemSymbolName: "capsule.tophalf.filled", accessibilityDescription: nil)
        image?.isTemplate = true
        image?.accessibilityDescription = "Brimlet"
        statusItem.button?.image = image
        statusItem.button?.toolTip = "Brimlet"
        let menu = NSMenu()
        updateItem = item("", action: #selector(showUpdate), key: "")
        menu.addItem(updateItem)
        menu.addItem(updateSeparator)
        menu.addItem(item(String(localized: "Open Brimlet"), action: #selector(showIsland), key: "o"))
        menu.addItem(item(String(localized: "Show or Hide"), action: #selector(toggleIsland), key: "h"))
        menu.addItem(.separator())
        menu.addItem(item(String(localized: "Settings…"), action: #selector(openSettingsFromMenu), key: ","))
        menu.addItem(item(String(localized: "Check for Updates…"), action: #selector(checkForUpdates), key: ""))
        menu.addItem(.separator())
        menu.addItem(item(String(localized: "Quit Brimlet"), action: #selector(quit), key: "q"))
        statusItem.menu = menu
        updateSubscription = model.updater.$release.combineLatest(model.updater.$status).sink { [weak self] release, status in
            let title = Updater.menuTitle(release, status)
            self?.updateItem.title = title ?? ""
            self?.updateItem.isHidden = title == nil
            self?.updateSeparator.isHidden = title == nil
        }
    }

    private func item(_ title: String, action: Selector, key: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    @objc private func showIsland() {
        model.hidden = false
        model.expand()
    }

    @objc private func toggleIsland() {
        model.hidden.toggle()
        island.updatePresentation()
    }

    @objc private func showUpdate() { openSettings(.general) }

    @objc private func checkForUpdates() {
        model.updater.check(manual: true)
        openSettings(.general)
    }

    @objc private func openSettingsFromMenu() { openSettings(nil) }

    private func openSettings(_ tab: SettingsTab?) {
        guard model != nil else { return }
        model.collapse()
        if let tab { model.settingsTab = tab }
        if settingsWindow == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 620),
                                  styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
            window.title = String(localized: "Brimlet Settings")
            window.titlebarAppearsTransparent = true
            window.backgroundColor = .windowBackgroundColor
            window.isReleasedWhenClosed = false
            let controller = SettingsController(model: model)
            settingsController = controller
            window.contentViewController = controller
            window.center()
            settingsWindow = window
        }
        settingsController?.select(model.settingsTab)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func quit() { NSApp.terminate(nil) }

    @objc func addSelectedText(_ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        let plainTextType = NSPasteboard.PasteboardType("public.utf8-plain-text")
        let text = pasteboard.string(forType: .string) ?? pasteboard.string(forType: plainTextType)
        guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            error.pointee = String(localized: "The selected text couldn’t be read.") as NSString
            return
        }
        DispatchQueue.main.async { [weak self] in self?.quotePanel.capture(text) }
    }
}
