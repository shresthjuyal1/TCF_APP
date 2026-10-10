import SwiftUI
import UIKit

/// All the app's colors in one place. The app always uses this bright, light look,
/// whatever the phone's dark/light setting is.
enum Theme {
    // Surfaces
    static let background = Color(hex: 0xFFF7EC)
    static let card = Color.white
    static let cardBorder = Color(hex: 0xEFE3D3)
    static let softFill = Color(hex: 0xFBEFDF)

    // Main blue
    static let accent = Color(hex: 0x2B7BFF)
    static let accentShadow = Color(hex: 0x1C5ED1)
    static let accentBackground = Color(hex: 0xE4EEFF)

    // Feedback
    static let correct = Color(hex: 0x35C25C)
    static let correctShadow = Color(hex: 0x249546)
    static let correctBackground = Color(hex: 0xE2F8E7)
    static let wrong = Color(hex: 0xFF5A5F)
    static let wrongShadow = Color(hex: 0xD43C41)
    static let wrongBackground = Color(hex: 0xFFE6E6)

    // Playful extras
    static let gold = Color(hex: 0xFFC233)
    static let goldShadow = Color(hex: 0xDE9C00)
    static let orange = Color(hex: 0xFF9A1F)
    static let orangeShadow = Color(hex: 0xDB7600)
    static let pink = Color(hex: 0xFF6FAE)
    static let pinkShadow = Color(hex: 0xD84C8A)
    static let purple = Color(hex: 0x9B6BFF)
    static let purpleShadow = Color(hex: 0x7447DB)
    static let teal = Color(hex: 0x1CC5C9)
    static let tealShadow = Color(hex: 0x10999C)
    static let freeze = Color(hex: 0x5BC8FF)

    // Locked things
    static let locked = Color(hex: 0xE9E1D5)
    static let lockedShadow = Color(hex: 0xD2C7B7)
    static let lockedIcon = Color(hex: 0xADA191)

    /// Bright colors used in turn for lists of things (themes, tests…).
    static let palette: [(face: Color, shadow: Color)] = [
        (accent, accentShadow), (pink, pinkShadow), (teal, tealShadow),
        (purple, purpleShadow), (orange, orangeShadow), (correct, correctShadow),
    ]

    static func paletteColor(_ index: Int) -> (face: Color, shadow: Color) {
        palette[index % palette.count]
    }

    /// Every CEFR level has its own color on the path, chips and badges.
    static func levelColor(_ level: Level) -> (face: Color, shadow: Color) {
        switch level {
        case .a1: (teal, tealShadow)
        case .a2: (correct, correctShadow)
        case .b1: (accent, accentShadow)
        case .b2: (purple, purpleShadow)
        case .c1: (pink, pinkShadow)
        case .c2: (orange, orangeShadow)
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// The big "3D" button that sinks down when pressed (Check, Continue…).
struct ChunkyButtonStyle: ButtonStyle {
    var face: Color = Theme.accent
    var shadow: Color = Theme.accentShadow
    var text: Color = .white

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(.headline.weight(.heavy))
            .textCase(.uppercase)
            .foregroundStyle(isEnabled ? text : Theme.lockedIcon)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(RoundedRectangle(cornerRadius: 16).fill(isEnabled ? face : Theme.locked))
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isEnabled ? shadow : Theme.lockedShadow)
                    .offset(y: pressed ? 0 : 4)
            )
            .offset(y: pressed ? 4 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: pressed)
    }
}

/// A white rounded card with a soft border, used across the app.
struct CardBackground: ViewModifier {
    var cornerRadius: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .background(RoundedRectangle(cornerRadius: cornerRadius).fill(Theme.card))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).strokeBorder(Theme.cardBorder, lineWidth: 2))
    }
}

/// A rounded square with a white icon, like an app icon. Used for themes, tests and lessons.
struct IconTile: View {
    let systemName: String
    let color: Color
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.45, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: size * 0.28).fill(color.gradient))
    }
}

extension View {
    func card(cornerRadius: CGFloat = 18) -> some View {
        modifier(CardBackground(cornerRadius: cornerRadius))
    }
}
