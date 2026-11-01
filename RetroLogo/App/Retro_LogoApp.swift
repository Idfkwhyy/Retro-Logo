import SwiftUI

@main
struct Retro_LogoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
                .hidden()
        }
    }
}
