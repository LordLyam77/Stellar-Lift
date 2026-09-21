import SwiftUI

public enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case nebula = "Nebula"
    case deepSpace = "Deep Space"
    case supernova = "Supernova"

    public var id: String { rawValue }

    public var backgroundDeep: Color {
        switch self {
        case .nebula: return Color(hex: "#05060F")
        case .deepSpace: return Color(hex: "#020308")
        case .supernova: return Color(hex: "#0A060E")
        }
    }

    public var backgroundRaised: Color {
        switch self {
        case .nebula: return Color(hex: "#0B0E1D")
        case .deepSpace: return Color(hex: "#080B14")
        case .supernova: return Color(hex: "#140B1A")
        }
    }

    public var surfaceCard: Color {
        switch self {
        case .nebula: return Color(hex: "#131734")
        case .deepSpace: return Color(hex: "#0D1424")
        case .supernova: return Color(hex: "#1D1026")
        }
    }

    public var stroke: Color {
        switch self {
        case .nebula: return Color(hex: "#2A2F55")
        case .deepSpace: return Color(hex: "#1B2C47")
        case .supernova: return Color(hex: "#431E4D")
        }
    }

    public var primaryAccent: Color {
        switch self {
        case .nebula: return Color(hex: "#7C5CFF")      // Violet
        case .deepSpace: return Color(hex: "#00F0FF")   // Electric Cyan
        case .supernova: return Color(hex: "#FF007F")   // Magenta
        }
    }

    public var secondaryAccent: Color {
        switch self {
        case .nebula: return Color(hex: "#38E8FF")      // Cyan
        case .deepSpace: return Color(hex: "#70A5FF")   // Ice Blue
        case .supernova: return Color(hex: "#FF7B00")   // Neon Orange
        }
    }

    public var tertiaryAccent: Color {
        switch self {
        case .nebula: return Color(hex: "#FF6AD5")      // Nebula Pink
        case .deepSpace: return Color(hex: "#A855F7")   // Cosmic Purple
        case .supernova: return Color(hex: "#FFB703")   // Star Amber
        }
    }

    public var successPR: Color { Color(hex: "#4ADE80") }
    public var warningStalled: Color { Color(hex: "#FBBF24") }
    public var danger: Color { Color(hex: "#FB7185") }
    public var textPrimary: Color { Color(hex: "#EDEFFF") }
    public var textSecondary: Color { Color(hex: "#9AA0C8") }
    public var textMuted: Color { Color(hex: "#626993") }
}

public struct ThemeManager {
    @AppStorage("selectedTheme") public static var currentTheme: AppTheme = .nebula

    public static var springAnimation: Animation {
        .spring(response: 0.35, dampingFraction: 0.7)
    }
}

public extension Color {
    init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#if canImport(UIKit)
import UIKit

public extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch cleanHex.count {
        case 3:
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255.0,
            green: CGFloat(g) / 255.0,
            blue: CGFloat(b) / 255.0,
            alpha: alpha
        )
    }
}
#endif
