import SwiftUI

enum MRColor {
    static let background = Color(red: 0.965, green: 0.955, blue: 0.925)
    static let surface = Color(red: 0.995, green: 0.99, blue: 0.975)
    static let ink = Color(red: 0.09, green: 0.13, blue: 0.115)
    static let secondaryText = Color(red: 0.38, green: 0.41, blue: 0.38)
    static let accent = Color(red: 0.055, green: 0.31, blue: 0.225)
    static let accentSoft = Color(red: 0.85, green: 0.91, blue: 0.87)
    static let divider = Color.black.opacity(0.09)
    static let success = Color(red: 0.12, green: 0.46, blue: 0.29)
    static let amber = Color(red: 0.72, green: 0.43, blue: 0.08)
    static let red = Color(red: 0.72, green: 0.18, blue: 0.14)
}

enum MRSpacing {
    static let xs: CGFloat = 6
    static let sm: CGFloat = 10
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

extension View {
    func relocationPage() -> some View {
        self
            .padding(.horizontal, MRSpacing.lg)
            .padding(.vertical, MRSpacing.md)
            .frame(maxWidth: 820, alignment: .leading)
    }
}

