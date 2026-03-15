import SwiftUI

@main
struct OfflinePasswordManagerApp: App {
    #if os(macOS)
    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        DispatchQueue.main.async {
            NSApplication.shared.activate(ignoringOtherApps: true)
            NSApplication.shared.windows.first?.makeKeyAndOrderFront(nil)
        }
    }
    #endif

    @AppStorage("displayMode") private var displayMode: DisplayMode = .system
    @AppStorage("appFontSize") private var appFontSize: AppFontSize = .standard
    @AppStorage("appLanguage") private var appLanguage: AppLanguage = .system

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(displayMode.colorScheme)
                .dynamicTypeSize(appFontSize.dynamicTypeSize)
                .environment(\.locale, appLanguage.locale ?? Locale.current)
        }
    }
}
