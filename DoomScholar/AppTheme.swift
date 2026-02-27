import SwiftUI

// Centralized theme so you can re-skin easily later.
struct AppTheme {
    var background: Color = Color(.systemGroupedBackground)
    var cardBackground: Color = .white
    var textPrimary: Color = Color(.label)
    var textSecondary: Color = Color(.secondaryLabel)

    // Gradients / accents (match your screenshot vibe)
    var brandGradient: LinearGradient = LinearGradient(
        colors: [Color(red: 0.62, green: 0.27, blue: 0.98), Color(red: 0.21, green: 0.52, blue: 0.98)],
        startPoint: .leading,
        endPoint: .trailing
    )

    var primaryButtonGradient: LinearGradient = LinearGradient(
        colors: [Color(red: 0.62, green: 0.27, blue: 0.98), Color(red: 0.21, green: 0.52, blue: 0.98)],
        startPoint: .leading,
        endPoint: .trailing
    )

    var shadow: Color = .black.opacity(0.10)

    // Card corner radius
    var cornerRadius: CGFloat = 20
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = AppTheme()
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

extension View {
    func appTheme(_ theme: AppTheme) -> some View {
        environment(\.appTheme, theme)
    }
}
