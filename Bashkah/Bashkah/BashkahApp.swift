import SwiftUI
import FirebaseCore

// MARK: - App Delegate (Firebase Setup)
class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        print("🚀 App did finish launching")
        print("🔥 Starting Firebase configuration...")
        
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("✅ Firebase configured successfully")
        } else {
            print("⚠️ Firebase already configured")
        }
        
        // Extra check
        if let app = FirebaseApp.app() {
            print("📡 Firebase App Name: \(app.name)")
            print("📡 Firebase Options Project ID: \(app.options.projectID ?? "No Project ID")")
        } else {
            print("❌ Firebase NOT initialized")
        }
        
        return true
    }
}

// MARK: - Main App Entry

@main
struct BashkahApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                SplashPageView()
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
    }
}
