import AppKit
import Combine
import SwiftUI

private final class QuoteFloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor final class QuotePanelController {
    private let panel: NSPanel
    private let store: QuoteStore
    private let preferences: Preferences
    private var draft = ""
    private var quote: SavedQuote?
    private var dismissTask: Task<Void, Never>?
    private var dismissDeadline: Date?
    private var remainingSeconds: TimeInterval = 0
    private var pointerInside = false
    private var isClosing = false
    private var isEntering = false
    private var presentationID = UUID()
    private var durationSubscription: AnyCancellable?

    init(store: QuoteStore, preferences: Preferences) {
        self.store = store
        self.preferences = preferences
        panel = QuoteFloatingPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.appearance = NSAppearance(named: .darkAqua)
        panel.hasShadow = true
        panel.animationBehavior = .none
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isReleasedWhenClosed = false
        durationSubscription = preferences.$quoteDisplaySeconds.dropFirst().sink { [weak self] _ in
            DispatchQueue.main.async {
                guard let self, self.quote != nil, self.panel.isVisible, !self.isClosing else { return }
                self.remainingSeconds = TimeInterval(self.preferences.quoteDisplaySeconds)
                self.scheduleDismissal()
            }
        }
    }

    func capture(_ text: String) {
        cancelDismissal()
        draft = text.trimmingCharacters(in: .whitespacesAndNewlines)
        quote = nil
        present()
    }

    func show(_ quote: SavedQuote) {
        // A scheduled reminder must not replace the source information being edited.
        guard !(panel.isVisible && self.quote == nil && !isClosing) else { return }
        presentQuote(quote)
    }

    private func presentQuote(_ quote: SavedQuote) {
        cancelDismissal()
        self.quote = quote
        draft = ""
        remainingSeconds = TimeInterval(preferences.quoteDisplaySeconds)
        present()
    }

    func close() {
        guard panel.isVisible, !isClosing else { return }
        cancelDismissal()
        isClosing = true
        isEntering = false
        pointerInside = false
        presentationID = UUID()
        let closingID = presentationID
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            finishClosing(closingID)
            return
        }
        let destination = panel.frame.offsetBy(dx: 90, dy: 0)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.45
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(destination, display: true)
            panel.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            Task { @MainActor in self?.finishClosing(closingID) }
        }
    }

    private func finishClosing(_ id: UUID) {
        // An older animation must never hide a newly opened capture or quote.
        guard presentationID == id else { return }
        panel.orderOut(nil)
        panel.alphaValue = 1
        isClosing = false
    }

    private func targetScreen() -> NSScreen? {
        if preferences.displayID != "auto",
           let selected = NSScreen.screens.first(where: { IslandPanelController.displayID($0) == preferences.displayID }) { return selected }
        return NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) ?? NSScreen.main
    }

    private func present() {
        guard let screen = targetScreen() else { return }
        presentationID = UUID()
        let enteringID = presentationID
        isClosing = false
        isEntering = true
        pointerInside = false
        let width = min(400, screen.visibleFrame.width - 48)
        let contentHeight = quote.map {
            Self.readingHeight(for: $0, width: width, maximum: min(480, screen.visibleFrame.height - 192))
        } ?? 0
        let root = QuotePanelView(draftText: draft, quote: quote, width: width, contentHeight: contentHeight,
            preferences: preferences,
            onSave: { [weak self] text, author, source in
                guard let self else { return }
                self.store.add(text: text, source: source, author: author)
                if let saved = self.store.quotes.first { self.presentQuote(saved) }
            }, onClose: { [weak self] in self?.close() }, onHover: { [weak self] in self?.hover($0) })
        let hosting = NSHostingView(rootView: root)
        let size = hosting.fittingSize
        hosting.sizingOptions = []
        panel.contentView = hosting
        let frame = NSRect(x: screen.visibleFrame.maxX - size.width - 24,
                           y: screen.visibleFrame.midY - size.height / 2,
                           width: size.width, height: size.height)
        let wasVisible = panel.isVisible
        if !wasVisible {
            panel.setFrame(frame.offsetBy(dx: 72, dy: 0), display: true)
            panel.alphaValue = 0
        }
        panel.orderFrontRegardless()
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            panel.setFrame(frame, display: true)
            panel.alphaValue = 1
            finishEntering(enteringID)
        } else {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.7
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().setFrame(frame, display: true)
                panel.animator().alphaValue = 1
            } completionHandler: { [weak self] in
                Task { @MainActor in self?.finishEntering(enteringID) }
            }
        }
    }

    static func readingHeight(for quote: SavedQuote, width: CGFloat, maximum: CGFloat) -> CGFloat {
        let measurement = NSHostingView(rootView: QuoteReadingContent(quote: quote).frame(width: width - 48))
        return min(max(90, ceil(measurement.fittingSize.height)), max(90, maximum))
    }

    private func finishEntering(_ id: UUID) {
        guard presentationID == id else { return }
        isEntering = false
        pointerInside = panel.frame.contains(NSEvent.mouseLocation)
        scheduleDismissal()
    }

    private func hover(_ inside: Bool) {
        guard !isClosing else { return }
        pointerInside = inside
        if inside {
            if let dismissDeadline { remainingSeconds = max(0.1, dismissDeadline.timeIntervalSinceNow) }
            cancelDismissal()
        } else { scheduleDismissal() }
    }

    private func cancelDismissal() {
        dismissTask?.cancel()
        dismissTask = nil
        dismissDeadline = nil
    }

    private func scheduleDismissal() {
        cancelDismissal()
        guard quote != nil, panel.isVisible, !isClosing, !isEntering, !pointerInside,
              preferences.quoteDisplaySeconds > 0 else { return }
        let delay = max(0.1, remainingSeconds)
        dismissDeadline = Date().addingTimeInterval(delay)
        dismissTask = Task { [weak self] in
            do { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) } catch { return }
            self?.close()
        }
    }
}

struct QuoteReadingContent: View {
    let quote: SavedQuote

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("“\(quote.text)”")
                .font(.system(size: 18, weight: .regular, design: .serif))
                .lineSpacing(6).foregroundStyle(Color.white.opacity(0.94))
                .fixedSize(horizontal: false, vertical: true)
            if !quote.author.isEmpty || !quote.source.isEmpty {
                HStack(alignment: .top, spacing: 10) {
                    RoundedRectangle(cornerRadius: 1).fill(BrimletTheme.mint.opacity(0.65)).frame(width: 2)
                    VStack(alignment: .leading, spacing: 5) {
                        if !quote.author.isEmpty { Text(quote.author).font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.75)) }
                        if !quote.source.isEmpty { Text(quote.source).font(.system(size: 11)).foregroundStyle(.white.opacity(0.48)) }
                    }.fixedSize(horizontal: false, vertical: true)
                }.fixedSize(horizontal: false, vertical: true)
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct QuotePanelView: View {
    let draftText: String
    let quote: SavedQuote?
    let width: CGFloat
    let contentHeight: CGFloat
    @ObservedObject var preferences: Preferences
    let onSave: (String, String, String) -> Void
    let onClose: () -> Void
    let onHover: (Bool) -> Void
    @State private var text = ""
    @State private var author = ""
    @State private var source = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Label(quote == nil ? "Add to Brimlet as Quote" : "One of your quotes", systemImage: "quote.opening")
                    .font(.system(size: 11, weight: .medium)).foregroundStyle(BrimletTheme.mint)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark").font(.system(size: 10, weight: .semibold))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.065), in: Circle())
                }.buttonStyle(.plain).foregroundStyle(.white.opacity(0.65))
                    .help("Close").accessibilityLabel("Close Quote")
            }.frame(height: 28)
            if let quote {
                ScrollView {
                    QuoteReadingContent(quote: quote)
                }.scrollBounceBehavior(.basedOnSize).frame(height: contentHeight)
                HStack {
                    Text(preferences.quoteDisplaySeconds == 0 ? "Open until you close it" : "\(preferences.quoteDisplaySeconds) s · Waits while you hover")
                        .font(.system(size: 10)).foregroundStyle(.white.opacity(0.38))
                    Spacer()
                    Button("Close", action: onClose).font(.system(size: 11, weight: .medium))
                        .buttonStyle(.plain).foregroundStyle(.white.opacity(0.7))
                }.frame(height: 28)
            } else {
                TextEditor(text: $text).font(.system(size: 14, design: .serif))
                    .scrollContentBackground(.hidden).padding(10).frame(height: 120)
                    .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
                HStack(alignment: .top, spacing: 12) {
                    sourceField("Person or author", placeholder: "Optional", value: $author)
                    sourceField("Book or source", placeholder: "Optional", value: $source)
                }
                HStack {
                    Text("Where it’s from is up to you.").font(.system(size: 10)).foregroundStyle(.white.opacity(0.4))
                    Spacer()
                    Button("Save") { onSave(text, author, source) }.buttonStyle(QuoteActionStyle())
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .padding(24).frame(width: width)
        .background(Color(red: 0.065, green: 0.085, blue: 0.08), in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(BrimletTheme.mint.opacity(0.18), lineWidth: 1))
        .foregroundStyle(.white).environment(\.colorScheme, .dark).preferredColorScheme(.dark)
        .onAppear { text = draftText }
        .onHover(perform: onHover)
        .onExitCommand(perform: onClose)
    }

    private func sourceField(_ title: LocalizedStringKey, placeholder: LocalizedStringKey, value: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.system(size: 10, weight: .medium)).foregroundStyle(.white.opacity(0.55))
            TextField(placeholder, text: value).textFieldStyle(.plain).font(.system(size: 12))
                .padding(9).background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

private struct QuoteActionStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.black)
            .padding(.horizontal, 16).padding(.vertical, 9).background(BrimletTheme.mint.opacity(configuration.isPressed ? 0.75 : 1), in: Capsule())
    }
}
