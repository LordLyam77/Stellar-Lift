import SwiftUI

public struct GlassCardModifier: ViewModifier {
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula
    public var cornerRadius: CGFloat = 20
    public var strokeColor: Color? = nil
    public var glowing: Bool = false
    public var glowColor: Color? = nil

    public func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(selectedTheme.surfaceCard.opacity(0.55))
                    .background(.ultraThinMaterial)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                strokeColor ?? selectedTheme.primaryAccent.opacity(0.6),
                                (strokeColor ?? selectedTheme.primaryAccent).opacity(0.15),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: glowing ? (glowColor ?? selectedTheme.primaryAccent).opacity(0.35) : Color.black.opacity(0.3),
                radius: glowing ? 14 : 8,
                x: 0,
                y: glowing ? 0 : 4
            )
    }
}

public extension View {
    func glassCard(
        cornerRadius: CGFloat = 20,
        strokeColor: Color? = nil,
        glowing: Bool = false,
        glowColor: Color? = nil
    ) -> some View {
        self.modifier(
            GlassCardModifier(
                cornerRadius: cornerRadius,
                strokeColor: strokeColor,
                glowing: glowing,
                glowColor: glowColor
            )
        )
    }

    func stellarFont(_ size: CGFloat, weight: Font.Weight = .regular) -> some View {
        self.font(.system(size: size, weight: weight, design: .rounded))
    }
}

public struct StellarPrimaryButton: View {
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula
    public let title: String
    public let icon: String?
    public let action: () -> Void

    public init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                LinearGradient(
                    colors: [
                        selectedTheme.primaryAccent,
                        selectedTheme.primaryAccent.opacity(0.85)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: selectedTheme.primaryAccent.opacity(0.4), radius: 10, x: 0, y: 3)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

public struct ScaleButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(ThemeManager.springAnimation, value: configuration.isPressed)
    }
}
