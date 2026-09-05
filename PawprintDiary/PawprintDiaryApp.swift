import SwiftUI

@main
struct PawprintDiaryApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var store = AppStore(
        resetLocalData: ProcessInfo.processInfo.arguments.contains("--reset-local-data")
    )

    var body: some Scene {
        WindowGroup {
            Group {
                if store.accountEmail == nil {
                    AccountView(allowsDismiss: false)
                } else {
                    RootTabView()
                }
            }
                .environment(store)
                .tint(AppTheme.honey)
                .preferredColorScheme(.light)
                .onAppear {
                    store.startCloudSessionRestore()
                }
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    Task { await store.syncSilently() }
                }
        }
    }
}
