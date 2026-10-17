import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var bridge = WebBridge()

    var body: some View {
        ZStack(alignment: .bottom) {
            WebHost(web: bridge.web).ignoresSafeArea()
            GlassTabBar(bridge: bridge)
        }
        .tint(.teal)
        .preferredColorScheme(bridge.scheme)
    }
}

/// يعرض WKWebView الذي يحمل واجهة HTML/CSS/JS
struct WebHost: UIViewRepresentable {
    let web: WKWebView
    func makeUIView(context: Context) -> WKWebView { web }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

// MARK: - شريط التنقل: Fluid Liquid Glass (iOS 17+)
struct GlassTabBar: View {
    @ObservedObject var bridge: WebBridge
    @Namespace private var ns
    /// مقدار تمدد الكبسولة أثناء الحركة (١ = شكلها الطبيعي)
    @State private var stretch: CGFloat = 1

    private let liquid = Animation.interpolatingSpring(stiffness: 170, damping: 15)

    private let items: [(id: String, icon: String, title: String)] = [
        ("home", "house.fill", "الرئيسية"),
        ("mushaf", "book.fill", "المصحف"),
        ("prayer", "clock.fill", "الصلاة"),
        ("tasbeeh", "circle.grid.3x3.fill", "السبحة"),
        ("settings", "slider.horizontal.3", "الإعدادات"),
    ]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(items, id: \.id) { item in
                let selected = bridge.tab == item.id
                Button { select(item.id) } label: {
                    VStack(spacing: 3) {
                        Image(systemName: item.icon)
                            .font(.system(size: 19, weight: .semibold))
                            .scaleEffect(selected ? 1.12 : 1)
                            .symbolEffect(.bounce, value: selected)
                        Text(item.title).font(.system(size: 10.5, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .foregroundStyle(selected ? Color.accentColor : Color.secondary)
                    .background {
                        if selected {
                            SelectedGlassCapsule()
                                .matchedGeometryEffect(id: "selection", in: ns)
                                // تمدد أفقي مع انضغاط رأسي بسيط = إحساس القطرة السائلة
                                .scaleEffect(x: stretch, y: 1 - (stretch - 1) * 0.22)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(6)
        .animation(liquid, value: bridge.tab) // أي تغيير للتبويب (من اللمس أو من الواجهة) يتحرك بنفس الحركة
        .glassBar()
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
        .environment(\.layoutDirection, .rightToLeft)
    }

    private func select(_ id: String) {
        let from = items.firstIndex { $0.id == bridge.tab } ?? 0
        let to = items.firstIndex { $0.id == id } ?? 0

        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.6)

        // ١) تمدد سريع في بداية الحركة، كلما زادت المسافة زاد التمدد
        let target = min(1 + 0.3 * CGFloat(max(abs(to - from), 1)), 1.9)
        withAnimation(.easeOut(duration: 0.14), completionCriteria: .logicallyComplete) {
            stretch = target
        } completion: {
            // ٢) ارتداد نابضي يرجّعها لشكلها الطبيعي عند الوصول
            withAnimation(liquid) { stretch = 1 }
        }

        // ٣) انزلاق الكبسولة بين التبويبات
        withAnimation(liquid) { bridge.tab = id }
        bridge.go(id)
    }
}

/// الكبسولة المحددة: زجاج شفاف متدرج بحدود مضيئة وتوهج خفيف
struct SelectedGlassCapsule: View {
    var body: some View {
        Capsule()
            .fill(LinearGradient(
                colors: [.white.opacity(0.34), Color.accentColor.opacity(0.18), .white.opacity(0.06)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(
                Capsule().strokeBorder(LinearGradient(
                    colors: [.white.opacity(0.9), .white.opacity(0.12), .white.opacity(0.5)],
                    startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
            .shadow(color: Color.accentColor.opacity(0.35), radius: 10, y: 3)
    }
}

extension View {
    /// زجاج كلاسيكي ناعم: Material + حد مضيء + لمعة علوية + ظل وتوهج (iOS 17+)
    func glassBar() -> some View {
        self
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule().strokeBorder(LinearGradient(
                    colors: [.white.opacity(0.65), .white.opacity(0.08), .white.opacity(0.3)],
                    startPoint: .top, endPoint: .bottom), lineWidth: 1))
            .overlay(alignment: .top) {
                Capsule()
                    .fill(LinearGradient(colors: [.white.opacity(0.35), .clear], startPoint: .top, endPoint: .bottom))
                    .frame(height: 20)
                    .padding(.horizontal, 22)
                    .padding(.top, 2)
                    .blur(radius: 5)
                    .allowsHitTesting(false)
            }
            .shadow(color: .black.opacity(0.16), radius: 20, y: 8)
            .shadow(color: Color.accentColor.opacity(0.18), radius: 14)
    }
}
