import SwiftUI
import UIKit

extension Color {
    static let judgeAccent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.39, green: 0.84, blue: 0.60, alpha: 1)
            : UIColor(red: 0.08, green: 0.38, blue: 0.23, alpha: 1)
    })

    static let judgeBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.025, green: 0.075, blue: 0.052, alpha: 1)
            : UIColor(red: 0.955, green: 0.975, blue: 0.958, alpha: 1)
    })

    static let judgeSurface = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.060, green: 0.135, blue: 0.092, alpha: 1)
            : UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    })

    static let judgeRaisedSurface = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.085, green: 0.185, blue: 0.125, alpha: 1)
            : UIColor(red: 0.900, green: 0.945, blue: 0.913, alpha: 1)
    })

    static let judgeBorder = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.20, green: 0.34, blue: 0.25, alpha: 1)
            : UIColor(red: 0.79, green: 0.86, blue: 0.81, alpha: 1)
    })
}

private struct JudgeCardModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(Color.judgeSurface, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.judgeBorder.opacity(0.7), lineWidth: 0.5)
            }
    }
}

extension View {
    func judgeCard(cornerRadius: CGFloat = 18) -> some View {
        modifier(JudgeCardModifier(cornerRadius: cornerRadius))
    }

    func judgeScrollBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(Color.judgeBackground)
    }
}
