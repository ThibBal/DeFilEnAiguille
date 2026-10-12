import Foundation

/// Dates au format AAAA-MM-JJ, dans le fuseau de l'appareil, et leurs affichages en français.
enum DateKey {
    private static func formatter(_ format: String, french: Bool) -> DateFormatter {
        let f = DateFormatter()
        f.locale = french ? Locale(identifier: "fr_FR") : Locale(identifier: "en_US_POSIX")
        f.dateFormat = format
        return f
    }

    static var today: String { formatter("yyyy-MM-dd", french: false).string(from: Date()) }

    static func date(_ key: String) -> Date {
        formatter("yyyy-MM-dd", french: false).date(from: key) ?? Date()
    }

    /// « dim. 11 octobre »
    static func long(_ key: String) -> String { formatter("EEE d MMMM", french: true).string(from: date(key)) }
    /// « dim. 11 oct. »
    static func short(_ key: String) -> String { formatter("EEE d MMM", french: true).string(from: date(key)) }
    /// « Samedi 10 octobre »
    static func full(_ key: String) -> String {
        let s = formatter("EEEE d MMMM", french: true).string(from: date(key))
        return s.prefix(1).uppercased() + s.dropFirst()
    }
    /// « Octobre 2026 »
    static func month(_ key: String) -> String {
        let s = formatter("LLLL yyyy", french: true).string(from: date(key))
        return s.prefix(1).uppercased() + s.dropFirst()
    }
    /// « 11 »
    static func day(_ key: String) -> String { formatter("d", french: true).string(from: date(key)) }
    /// « dim. »
    static func weekday(_ key: String) -> String { formatter("EEE", french: true).string(from: date(key)) }
}
