import SwiftUI

enum AppTheme {
    static let cream = Color("WarmCream")
    static let paper = Color("Paper")
    static let honey = Color("Honey")
    static let honeySoft = Color("HoneySoft")
    static let caramel = Color("Caramel")
    static let ink = Color("WarmInk")
    static let berrySoft = Color("BerrySoft")
    static let sageSoft = Color("SageSoft")
    static let secondaryText = Color(red: 0.53, green: 0.48, blue: 0.42)
}

enum AppLayout {
    static func isExpanded(_ horizontalSizeClass: UserInterfaceSizeClass?) -> Bool {
        horizontalSizeClass == .regular
    }

    static func contentMaxWidth(_ horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        isExpanded(horizontalSizeClass) ? 1040 : 720
    }

    static func horizontalPadding(_ horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        isExpanded(horizontalSizeClass) ? 30 : 16
    }

    static func sectionSpacing(_ horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        isExpanded(horizontalSizeClass) ? 28 : 22
    }
}

struct RoundedCard: ViewModifier {
    var radius: CGFloat = 22
    var padding: CGFloat = 14

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            }
            .shadow(color: AppTheme.caramel.opacity(0.07), radius: 12, y: 6)
    }
}

struct AdaptivePage: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    var bottomPadding: CGFloat = 30

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: AppLayout.contentMaxWidth(horizontalSizeClass))
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppLayout.horizontalPadding(horizontalSizeClass))
            .padding(.bottom, bottomPadding)
    }
}

extension View {
    func roundedCard(radius: CGFloat = 22, padding: CGFloat = 14) -> some View {
        modifier(RoundedCard(radius: radius, padding: padding))
    }

    func adaptivePage(bottomPadding: CGFloat = 30) -> some View {
        modifier(AdaptivePage(bottomPadding: bottomPadding))
    }
}
