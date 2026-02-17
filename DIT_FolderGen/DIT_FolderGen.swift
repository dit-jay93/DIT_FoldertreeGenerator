import SwiftUI

@main
struct DIT_FolderGenApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 700)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.appInfo) {
                Button("About DIT_FolderGen") {
                    NSApplication.shared.orderFrontStandardAboutPanel(nil)
                }
            }
        }
    }
}