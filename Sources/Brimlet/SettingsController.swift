import AppKit
import Combine
import SwiftUI

@MainActor final class SettingsController: NSTabViewController {
    let model: AppModel
    private var subscriptions = Set<AnyCancellable>()
    private var ready = false

    init(model: AppModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
        tabStyle = .toolbar
        transitionOptions = []
        for tab in SettingsTab.allCases {
            let host = NSHostingController(rootView: SettingsView(model: model, preferences: model.preferences, updater: model.updater, tab: tab))
            host.sizingOptions = []
            host.title = tab.title
            let item = NSTabViewItem(viewController: host)
            item.identifier = tab.rawValue
            item.label = tab.title
            item.image = NSImage(systemSymbolName: tab.symbol, accessibilityDescription: tab.title)
            addTabViewItem(item)
        }
        model.preferences.objectWillChange.merge(with: model.quotes.objectWillChange)
            .merge(with: model.calendar.objectWillChange)
            .sink { [weak self] in DispatchQueue.main.async { self?.fitWindow() } }.store(in: &subscriptions)
    }

    required init?(coder: NSCoder) { nil }

    override func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        let item = super.toolbar(toolbar, itemForItemIdentifier: itemIdentifier, willBeInsertedIntoToolbar: flag)
        guard let item, let tab = SettingsTab(rawValue: itemIdentifier.rawValue) else { return item }
        item.view = NSHostingView(rootView: SettingsToolbarButton(model: model, tab: tab) { [weak self] in self?.select(tab) })
        toolbar.displayMode = .iconOnly
        return item
    }

    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, didSelect: tabViewItem)
        guard ready, let id = tabViewItem?.identifier as? String, let tab = SettingsTab(rawValue: id) else { return }
        if model.settingsTab != tab { model.settingsTab = tab }
        view.window?.title = tab.title
        fitWindow()
    }

    func select(_ tab: SettingsTab) {
        ready = true
        selectedTabViewItemIndex = SettingsTab.allCases.firstIndex(of: tab) ?? 0
        model.settingsTab = tab
        fitWindow()
    }

    func fitWindow() {
        guard let window = view.window else { return }
        let area = (window.screen ?? NSScreen.main)?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let chrome = window.frame.height - window.contentLayoutRect.height
        let height = min(model.settingsTab.height(model: model), area.height - chrome - 32)
        let target = window.frameRect(forContentRect: NSRect(x: 0, y: 0, width: 520, height: height))
        var frame = window.frame
        frame.origin.y += frame.height - target.height
        frame.size = target.size
        frame.origin.y = max(area.minY, min(frame.origin.y, area.maxY - frame.height))
        if frame != window.frame { window.setFrame(frame, display: true) }
        window.title = model.settingsTab.title
    }
}

private struct SettingsToolbarButton: View {
    @ObservedObject var model: AppModel
    let tab: SettingsTab
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: tab.symbol).font(.system(size: 21, weight: .regular))
                    .foregroundStyle(model.settingsTab == tab ? BrimletTheme.jade : Color.secondary)
                Text(tab.title).font(.system(size: 11))
                    .foregroundStyle(model.settingsTab == tab ? Color.primary : Color.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minWidth: 72, minHeight: 62)
            .contentShape(Rectangle())
        }.buttonStyle(.plain).help(tab.title).accessibilityLabel(tab.title)
            .accessibilityAddTraits(model.settingsTab == tab ? .isSelected : [])
    }
}
