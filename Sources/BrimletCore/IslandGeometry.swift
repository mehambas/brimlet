import Foundation

public struct IslandGeometry: Equatable, Sendable {
    public var notchWidth: Double
    public var topInset: Double
    public var screenWidth: Double

    public init(notchWidth: Double, topInset: Double, screenWidth: Double) {
        self.notchWidth = max(0, notchWidth)
        self.topInset = max(0, topInset)
        self.screenWidth = screenWidth
    }

    public var hasNotch: Bool { notchWidth > 0 && topInset > 0 }
    public var compactWidth: Double { hasNotch ? notchWidth + 108 : 218 }
    public var headerHeight: Double { hasNotch ? max(32, topInset) : 36 }
    public var expandedWidth: Double { min(max(432, compactWidth + 24), max(280, screenWidth - 32)) }
    public var topMargin: Double { hasNotch ? 0 : 8 }
    public var expandedHeight: Double { headerHeight + 236 }
}
