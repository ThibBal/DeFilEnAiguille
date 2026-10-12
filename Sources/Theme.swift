import SwiftUI

extension UIColor {
    convenience init(hex: UInt) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension Color {
    /// Couleur qui suit le mode clair ou sombre du système.
    init(light: UInt, dark: UInt) {
        self.init(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }
}

/// Palettes de l'app : papier crème et encre sombre, vert pour le fil et les bonnes réponses, rouge pour les mauvaises.
enum Palette {
    static let paper = Color(light: 0xF6F3EC, dark: 0x171612)
    static let ink = Color(light: 0x1D1B18, dark: 0xF2EEE5)
    static let muted = Color(light: 0x6B665C, dark: 0xA39D90)
    static let card = Color(light: 0xFBF9F4, dark: 0x201E19)
    static let border = Color(light: 0xD9D3C6, dark: 0x3A362E)
    static let hair = Color(light: 0xE2DCCF, dark: 0x2B2923)
    static let accent = Color(light: 0x2F7D4F, dark: 0x5FBF84)
    static let accentSoft = Color(light: 0xDDEEE2, dark: 0x1F3326)
    static let ring = Color(light: 0xCFE6D7, dark: 0x2A4A36)
    static let bad = Color(light: 0xB3261E, dark: 0xEE7469)
    static let wrongBg = Color(light: 0xF6DEDA, dark: 0x3A1F1C)
    static let wrongInk = Color(light: 0x7A1F18, dark: 0xF2B8B1)
    static let dimBorder = Color(light: 0xE5E0D4, dark: 0x2B2923)
    static let dotOff = Color(light: 0x8A8477, dark: 0x7C7669)
    static let seg = Color(light: 0xCFC8B9, dark: 0x4A463D)
    static let body = Color(light: 0x3A372F, dark: 0xD8D3C7)
}

/// Polices embarquées : Instrument Serif (titres, chiffres, questions) et Hanken Grotesk (texte).
enum AppFont {
    static func serif(_ size: CGFloat) -> Font { .custom("InstrumentSerif-Regular", size: size) }
    static func serifItalic(_ size: CGFloat) -> Font { .custom("InstrumentSerif-Italic", size: size) }
    static func sans(_ size: CGFloat) -> Font { .custom("HankenGrotesk-Regular", size: size) }
    static func sansMedium(_ size: CGFloat) -> Font { .custom("HankenGrotesk-Medium", size: size) }
    static func sansSemi(_ size: CGFloat) -> Font { .custom("HankenGrotesk-SemiBold", size: size) }
}
