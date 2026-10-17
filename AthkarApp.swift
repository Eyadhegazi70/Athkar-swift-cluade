import SwiftUI

@main
struct AthkarApp: App {
    init() {
        // نجهّز مدير التنبيهات مبكرًا ليظهر التنبيه حتى والتطبيق مفتوح
        _ = NotificationManager.shared
    }

    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
