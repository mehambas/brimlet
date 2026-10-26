import AppKit
import SwiftUI

enum BrimletTheme {
    static let mint = Color(hex: 0x60E7B4)
    static let ink = Color(hex: 0x04261B)
    static let primary = Color(hex: 0xF3F5F8)
    static let secondary = Color(hex: 0xACB2B9)
    static let tertiary = Color(hex: 0x81878D)
    static let surface = Color(hex: 0x111418)
    static let raised = Color(hex: 0x23282F)
    static let hover = Color(hex: 0x2C323A)
    static let jade = adaptive(light: 0x227F5F, dark: 0x1EA87B)
    static let quoteTop = adaptive(light: 0xF6F9FC, dark: 0x1A1E24)
    static let quoteBottom = adaptive(light: 0xEDF2F8, dark: 0x171A20)
    static let quoteLabel = adaptive(light: 0x1E232A, dark: 0xF3F5F8)
    static let quoteSecondary = adaptive(light: 0x5A6370, dark: 0xACB2B9)
    static let quoteAccent = adaptive(light: 0x0B7252, dark: 0x60E7B4)

    private static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let value = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
            return NSColor(srgbRed: Double((value >> 16) & 255) / 255,
                           green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255, alpha: 1)
        })
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 255) / 255,
                  green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1)
    }
}

struct MintButtonStyle: ButtonStyle {
    var prominent = true
    @Environment(\.isEnabled) private var enabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        IslandButtonFace(configuration: configuration, prominent: prominent, enabled: enabled, reduceMotion: reduceMotion)
    }

    private struct IslandButtonFace: View {
        let configuration: ButtonStyle.Configuration
        let prominent: Bool
        let enabled: Bool
        let reduceMotion: Bool
        @State private var hovered = false
        var body: some View {
            configuration.label.font(.system(size: 12, weight: .semibold))
                .foregroundStyle(prominent ? BrimletTheme.ink : BrimletTheme.primary)
                .padding(.horizontal, 14).frame(height: 28)
                .background(prominent ? (hovered ? Color(hex: 0x84F1C4) : BrimletTheme.mint) : (hovered ? BrimletTheme.hover : BrimletTheme.raised), in: RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .top) {
                    RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(prominent ? 0.35 : 0.05), lineWidth: 1)
                        .mask(LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .center))
                }
                .opacity(enabled ? (configuration.isPressed ? 0.8 : 1) : 0.4)
                .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
                .onHover { hovered = $0 }
        }
    }
}

struct IslandSelectionStyle: ButtonStyle {
    var selected = false
    @State private var hovered = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(selected ? BrimletTheme.primary : BrimletTheme.secondary)
            .background(selected ? BrimletTheme.raised : (hovered || configuration.isPressed ? BrimletTheme.surface : .clear), in: RoundedRectangle(cornerRadius: 8))
            .onHover { hovered = $0 }
    }
}
