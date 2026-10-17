import Foundation

/// ذكر واحد كما يُولَّد في Web/data.js بواسطة tools/build.py
struct Dhikr: Decodable {
    let t: String      // النص
    let c: Int         // العدد
    let h: String?     // عنوان
    let n: String?     // المصدر أو الملاحظة
}

/// يقرأ الأذكار من Web/data.js (نفس مصدر الواجهة) ليستعملها كود Swift، مثل التنبيهات.
final class AthkarData {
    static let shared = AthkarData()
    private(set) var sections: [String: [Dhikr]] = [:]

    private init() { load() }

    private func load() {
        guard let url = Bundle.main.url(forResource: "data", withExtension: "js", subdirectory: "Web"),
              var s = try? String(contentsOf: url, encoding: .utf8) else { return }
        s = s.replacingOccurrences(of: "const AZ=", with: "")
        if s.hasSuffix(";") { s.removeLast() }
        guard let data = s.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String: [Dhikr]].self, from: data) else { return }
        sections = decoded
    }

    /// أذكار قصيرة مناسبة لنص التنبيه (بدون المراجع وأرقام الآيات)
    func shortTexts() -> [String] {
        ["sabah", "masa", "after", "wake", "sleep", "rasul", "quran", "hamd"]
            .flatMap { sections[$0] ?? [] }
            .map { clean($0.t) }
            .filter { $0.count > 14 && $0.count < 150 }
    }

    /// نصوص تتغير يوميًا لتنبيهات اليوم
    func notificationTexts(count: Int = 60) -> [String] {
        let pool = shortTexts()
        guard !pool.isEmpty else { return [] }
        let day = Int(Date().timeIntervalSince1970 / 86_400)
        return (0..<count).map { pool[(day + $0 * 7) % pool.count] }
    }

    private func clean(_ s: String) -> String {
        s.replacingOccurrences(of: #"\s*[\[(].*?[\])]"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"﴿.*?﴾"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
