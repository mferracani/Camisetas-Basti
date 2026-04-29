import SwiftUI

@main
struct CamisetasBastiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showSplash = false
                        }
                    }
                } else {
                    HomeView()
                }
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Configure audio session early
        SoundManager.shared.playTap() // Trigger initialization
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Ensure any pending progress is saved
        ProgressStore.shared.save()
    }
}
