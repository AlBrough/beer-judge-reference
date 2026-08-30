import SwiftUI
import UIKit

enum JudgeColourTheme: String, CaseIterable, Identifiable {
    case forest
    case ocean
    case amber
    case slate

    var id: String { rawValue }

    var label: String {
        switch self {
        case .forest: "Forest"
        case .ocean: "Ocean"
        case .amber: "Amber"
        case .slate: "High contrast"
        }
    }

    var symbol: String {
        switch self {
        case .forest: "leaf.fill"
        case .ocean: "drop.fill"
        case .amber: "sun.max.fill"
        case .slate: "circle.lefthalf.filled"
        }
    }

    var accent: Color {
        switch self {
        case .forest:
            adaptive(light: rgb(0.08, 0.38, 0.23), dark: rgb(0.39, 0.84, 0.60))
        case .ocean:
            adaptive(light: rgb(0.02, 0.31, 0.55), dark: rgb(0.36, 0.76, 1.00))
        case .amber:
            adaptive(light: rgb(0.49, 0.25, 0.01), dark: rgb(1.00, 0.73, 0.32))
        case .slate:
            adaptive(light: rgb(0.10, 0.14, 0.18), dark: rgb(0.94, 0.96, 0.98))
        }
    }

    var background: Color {
        switch self {
        case .forest:
            adaptive(light: rgb(0.955, 0.975, 0.958), dark: rgb(0.025, 0.075, 0.052))
        case .ocean:
            adaptive(light: rgb(0.95, 0.97, 0.99), dark: rgb(0.025, 0.055, 0.085))
        case .amber:
            adaptive(light: rgb(0.985, 0.97, 0.94), dark: rgb(0.09, 0.055, 0.025))
        case .slate:
            adaptive(light: rgb(0.97, 0.97, 0.97), dark: rgb(0.018, 0.022, 0.026))
        }
    }

    var surface: Color {
        switch self {
        case .forest:
            adaptive(light: rgb(1, 1, 1), dark: rgb(0.060, 0.135, 0.092))
        case .ocean:
            adaptive(light: rgb(1, 1, 1), dark: rgb(0.050, 0.105, 0.155))
        case .amber:
            adaptive(light: rgb(1, 1, 1), dark: rgb(0.145, 0.09, 0.035))
        case .slate:
            adaptive(light: rgb(1, 1, 1), dark: rgb(0.07, 0.08, 0.09))
        }
    }

    var raisedSurface: Color {
        switch self {
        case .forest:
            adaptive(light: rgb(0.90, 0.945, 0.913), dark: rgb(0.085, 0.185, 0.125))
        case .ocean:
            adaptive(light: rgb(0.89, 0.94, 0.98), dark: rgb(0.075, 0.15, 0.22))
        case .amber:
            adaptive(light: rgb(0.965, 0.91, 0.82), dark: rgb(0.20, 0.125, 0.045))
        case .slate:
            adaptive(light: rgb(0.90, 0.91, 0.92), dark: rgb(0.14, 0.16, 0.18))
        }
    }

    var border: Color {
        switch self {
        case .forest:
            adaptive(light: rgb(0.79, 0.86, 0.81), dark: rgb(0.20, 0.34, 0.25))
        case .ocean:
            adaptive(light: rgb(0.76, 0.84, 0.91), dark: rgb(0.18, 0.31, 0.42))
        case .amber:
            adaptive(light: rgb(0.88, 0.80, 0.68), dark: rgb(0.39, 0.27, 0.13))
        case .slate:
            adaptive(light: rgb(0.58, 0.61, 0.64), dark: rgb(0.55, 0.59, 0.63))
        }
    }

    private func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    private func rgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
}

private struct JudgeColourThemeKey: EnvironmentKey {
    static let defaultValue = JudgeColourTheme.forest
}

extension EnvironmentValues {
    var judgeColourTheme: JudgeColourTheme {
        get { self[JudgeColourThemeKey.self] }
        set { self[JudgeColourThemeKey.self] = newValue }
    }
}

private struct JudgeCardModifier: ViewModifier {
    @Environment(\.judgeColourTheme) private var theme
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(theme.surface, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(theme.border.opacity(0.7), lineWidth: 0.5)
            }
    }
}

private struct JudgeScrollBackgroundModifier: ViewModifier {
    @Environment(\.judgeColourTheme) private var theme

    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(theme.background)
    }
}

extension View {
    func judgeCard(cornerRadius: CGFloat = 18) -> some View {
        modifier(JudgeCardModifier(cornerRadius: cornerRadius))
    }

    func judgeScrollBackground() -> some View {
        modifier(JudgeScrollBackgroundModifier())
    }
}
