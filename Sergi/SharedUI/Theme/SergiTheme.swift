import SwiftUI

// MARK: - Sergi Design System
// Основано на ТЗ секция XII: Дизайн-система

enum SergiTheme {

    // MARK: - Colors (oklch → sRGB approximations)

    enum Colors {
        // Primary — спокойный фиолетово-синий
        static let primary = Color(red: 0.384, green: 0.325, blue: 0.780)
        static let primaryLight = Color(red: 0.502, green: 0.443, blue: 0.890)
        static let primaryDark = Color(red: 0.280, green: 0.230, blue: 0.650)

        // Accent — солнечный желто-оранжевый
        static let accent = Color(red: 0.920, green: 0.680, blue: 0.240)
        static let accentLight = Color(red: 0.950, green: 0.750, blue: 0.350)

        // Category colors
        static let categoryHealth = Color(red: 0.298, green: 0.686, blue: 0.314)
        static let categoryLearning = Color(red: 0.412, green: 0.275, blue: 0.757)
        static let categoryProductivity = Color(red: 0.933, green: 0.545, blue: 0.200)
        static let categoryRelationships = Color(red: 0.910, green: 0.435, blue: 0.380)

        // Backgrounds
        static let backgroundLight = Color(red: 0.965, green: 0.968, blue: 0.980)
        static let backgroundDark = Color(red: 0.078, green: 0.078, blue: 0.120)

        // Surface (cards, sheets)
        static let surfaceLight = Color.white
        static let surfaceDark = Color(red: 0.118, green: 0.118, blue: 0.170)

        // Text
        static let textPrimary = Color(red: 0.100, green: 0.100, blue: 0.140)
        static let textSecondary = Color(red: 0.450, green: 0.450, blue: 0.500)
        static let textTertiary = Color(red: 0.650, green: 0.650, blue: 0.700)

        // Streak colors
        static let streakCold = Color.gray.opacity(0.4)
        static let streakWarm = Color.orange
        static let streakHot = Color.red
        static let streakFire = Color.purple

        // Semantic
        static let success = Color(red: 0.298, green: 0.686, blue: 0.314)
        static let warning = Color(red: 0.933, green: 0.545, blue: 0.200)
        static let error = Color(red: 0.898, green: 0.224, blue: 0.208)
        static let info = Color(red: 0.129, green: 0.588, blue: 0.953)

        static func streakColor(for days: Int) -> Color {
            switch days {
            case 0: return streakCold
            case 1...6: return streakWarm
            case 7...20: return streakHot
            default: return streakFire
            }
        }
    }

    // MARK: - Typography

    enum Typography {
        // Inter — основной шрифт (San Francisco как системная замена)
        static let h1 = Font.system(size: 32, weight: .bold, design: .default)
        static let h2 = Font.system(size: 24, weight: .bold, design: .default)
        static let h3 = Font.system(size: 18, weight: .semibold, design: .default)
        static let bodyLarge = Font.system(size: 16, weight: .medium, design: .default)
        static let body = Font.system(size: 15, weight: .regular, design: .default)
        static let caption = Font.system(size: 13, weight: .regular, design: .default)
        // Space Grotesk equivalent — rounded design for stats
        static let statsNumber = Font.system(size: 36, weight: .bold, design: .rounded)
        static let statsNumberSmall = Font.system(size: 24, weight: .bold, design: .rounded)
    }

    // MARK: - Spacing (4px grid)

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    enum Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xl: CGFloat = 24
        static let full: CGFloat = 100
    }

    // MARK: - Shadows

    enum Shadow {
        static func small(_ scheme: ColorScheme) -> some View {
            Color.black.opacity(scheme == .dark ? 0.3 : 0.08)
        }

        static let smallRadius: CGFloat = 4
        static let mediumRadius: CGFloat = 8
        static let largeRadius: CGFloat = 16
    }

    // MARK: - Animation

    enum Animation {
        static let microInteraction = SwiftUI.Animation.easeOut(duration: 0.15)
        static let standard = SwiftUI.Animation.easeOut(duration: 0.25)
        static let celebration = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
        static let navigation = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let breathing = SwiftUI.Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
    }
}

// MARK: - View Modifiers

struct SergiCardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: SergiTheme.Radius.large)
                    .fill(colorScheme == .dark ? SergiTheme.Colors.surfaceDark : SergiTheme.Colors.surfaceLight)
                    .shadow(
                        color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08),
                        radius: SergiTheme.Shadow.smallRadius,
                        x: 0,
                        y: 2
                    )
            )
    }
}

struct SergiButtonStyle: ButtonStyle {
    let variant: Variant

    enum Variant {
        case primary, secondary, ghost
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SergiTheme.Typography.bodyLarge)
            .padding(.horizontal, SergiTheme.Spacing.lg)
            .padding(.vertical, SergiTheme.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(background(configuration.isPressed))
            .foregroundStyle(foreground)
            .clipShape(RoundedRectangle(cornerRadius: SergiTheme.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: SergiTheme.Radius.medium)
                    .strokeBorder(borderColor, lineWidth: variant == .secondary ? 1.5 : 0)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(SergiTheme.Animation.microInteraction, value: configuration.isPressed)
    }

    private func background(_ isPressed: Bool) -> some ShapeStyle {
        switch variant {
        case .primary:
            return AnyShapeStyle(
                isPressed ? SergiTheme.Colors.primaryDark : SergiTheme.Colors.primary
            )
        case .secondary:
            return AnyShapeStyle(Color.clear)
        case .ghost:
            return AnyShapeStyle(
                isPressed ? SergiTheme.Colors.primary.opacity(0.1) : Color.clear
            )
        }
    }

    private var foreground: Color {
        switch variant {
        case .primary: return .white
        case .secondary: return SergiTheme.Colors.primary
        case .ghost: return SergiTheme.Colors.primary
        }
    }

    private var borderColor: Color {
        switch variant {
        case .secondary: return SergiTheme.Colors.primary
        default: return .clear
        }
    }
}

// MARK: - View Extensions

extension View {
    func sergiCard() -> some View {
        modifier(SergiCardStyle())
    }

    func sergiShadow(_ radius: CGFloat = SergiTheme.Shadow.smallRadius) -> some View {
        shadow(color: .black.opacity(0.08), radius: radius, x: 0, y: 2)
    }
}

extension ButtonStyle where Self == SergiButtonStyle {
    static var sergiPrimary: SergiButtonStyle { .init(variant: .primary) }
    static var sergiSecondary: SergiButtonStyle { .init(variant: .secondary) }
    static var sergiGhost: SergiButtonStyle { .init(variant: .ghost) }
}
