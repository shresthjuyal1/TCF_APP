import SwiftUI
import UIKit

/// All the app's colors in one place. Each color has a light-mode and a dark-mode version.
enum Theme {
    static let accent = Color(light: 0x1F6FEB, dark: 0x4C8DF6)
    static let accentShadow = Color(light: 0x1452B5, dark: 0x2D63C4)
    static let accentBackground = Color(light: 0xE6F0FE, dark: 0x16294A)

    static let correct = Color(light: 0x2EB352, dark: 0x3DCC63)
    static let correctShadow = Color(light: 0x1F8A3C, dark: 0x269447)
    static let correctBackground = Color(light: 0xE3F7E8, dark: 0x173D22)

    static let wrong = Color(light: 0xE5484D, dark: 0xF2555A)
    static let wrongShadow = Color(light: 0xB3262B, dark: 0xB53035)
    static let wrongBackground = Color(light: 0xFDE7E8, dark: 0x4A1C1E)

    static let gold = Color(light: 0xF5B400, dark: 0xF7C53B)
    static let goldShadow = Color(light: 0xC28E00, dark: 0xB88F1F)

    static let locked = Color(light: 0xE1E4EA, dark: 0x3A3D44)
    static let lockedShadow = Color(light: 0xC3C8D2, dark: 0x2A2C31)
    static let lockedIcon = Color(light: 0xA3AAB8, dark: 0x6B707A)

    static let cardBorder = Color(light: 0xE1E4EA, dark: 0x3A3D44)
    static let card = Color(uiColor: .systemBackground)
}

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

/// The big "3D" button that sinks down when pressed (Vérifier, Continuer…).
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
