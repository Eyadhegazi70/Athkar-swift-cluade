import SwiftUI
import WebKit

/// الجسر بين واجهة HTML/CSS/JS وبين iOS: الحفظ الدائم، الاهتزاز، التنبيهات، الموقع، النسخ.
final class WebBridge: NSObject, ObservableObject, WKScriptMessageHandler {
    @Published var tab = "home"
    @Published var scheme: ColorScheme? = nil
    let web: WKWebView
    private let location = LocationManager()

    override init() {
        let ucc = WKUserContentController()
        // الحالة المحفوظة تُحقن قبل تحميل الصفحة، فيرجع كل شيء كما تركه المستخدم.
        let saved = UserDefaults.standard.string(forKey: "state") ?? "null"
        ucc.addUserScript(WKUserScript(source: "window.__NATIVE__=true;window.__STATE__=\(saved);",
                                       injectionTime: .atDocumentStart, forMainFrameOnly: true))
        let cfg = WKWebViewConfiguration()
        cfg.userContentController = ucc
        web = WKWebView(frame: .zero, configuration: cfg)
        super.init()
        // وسيط ضعيف: يمنع الدورة WebBridge ← WKWebView ← UserContentController ← WebBridge
        ucc.add(WeakScriptHandler(self), name: "native")

        web.isOpaque = false
        web.backgroundColor = .clear
        web.scrollView.backgroundColor = .clear
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.scrollView.bounces = false
        web.scrollView.showsVerticalScrollIndicator = false
        if #available(iOS 16.4, *) { web.isInspectable = true }

        location.onLocation = { [weak self] la, lo in self?.js("window.onLoc&&onLoc(\(la),\(lo))") }
        location.onHeading = { [weak self] h in self?.js("window.onHead&&onHead(\(h))") }

        if let dir = Bundle.main.url(forResource: "Web", withExtension: nil) {
            web.loadFileURL(dir.appendingPathComponent("index.html"), allowingReadAccessTo: dir)
        }
    }

    func js(_ s: String) { web.evaluateJavaScript(s, completionHandler: nil) }
    func go(_ page: String) { js("go('\(page)')") }

    func userContentController(_ c: WKUserContentController, didReceive m: WKScriptMessage) {
        guard let d = m.body as? [String: Any], let k = d["k"] as? String else { return }
        switch k {
        case "save":
            UserDefaults.standard.set(d["v"] as? String ?? "null", forKey: "state")
        case "haptic":
            haptic(d["s"] as? String ?? "light")
        case "notif":
            NotificationManager.shared.schedule(
                on: (d["on"] as? NSNumber)?.boolValue ?? false,
                everyMinutes: (d["m"] as? NSNumber)?.intValue ?? 30,
                texts: d["texts"] as? [String] ?? [])
        case "loc":
            location.requestLocation()
        case "head":
            location.setHeading((d["on"] as? NSNumber)?.boolValue ?? false)
        case "tab":
            let t = d["v"] as? String ?? "home"
            DispatchQueue.main.async { [weak self] in self?.tab = t }
        case "theme":
            let t = d["v"] as? String ?? "auto"
            DispatchQueue.main.async { [weak self] in self?.scheme = t == "light" ? .light : (t == "dark" ? .dark : nil) }
        case "copy":
            UIPasteboard.general.string = d["v"] as? String
        default: break
        }
    }

    private func haptic(_ style: String) {
        switch style {
        case "ok": UINotificationFeedbackGenerator().notificationOccurred(.success)
        case "heavy": UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        default: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

/// يمرّر رسائل JavaScript للـ WebBridge بدون الإمساك به بقوة
private final class WeakScriptHandler: NSObject, WKScriptMessageHandler {
    private weak var target: WKScriptMessageHandler?
    init(_ target: WKScriptMessageHandler) { self.target = target }
    func userContentController(_ c: WKUserContentController, didReceive m: WKScriptMessage) {
        target?.userContentController(c, didReceive: m)
    }
}
