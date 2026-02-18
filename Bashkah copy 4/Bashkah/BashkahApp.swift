import SwiftUI
import FirebaseCore

// MARK: - App Delegate (Logs Only)
class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

        print("🚀 App did finish launching")

        if let app = FirebaseApp.app() {
            print("✅ Firebase already configured (from BashkahApp.init)")
            print("📡 Firebase App Name: \(app.name)")
            print("📡 Firebase Options Project ID: \(app.options.projectID ?? "No Project ID")")
        } else {
            print("❌ Firebase NOT initialized yet (this should NOT happen now)")
        }

        return true
    }
}

// MARK: - Main App Entry
@main
struct BashkahApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        // ✅ Configure Firebase as early as possible (before any Firestore usage)
        if FirebaseApp.app() == nil {
            print("🔥 Starting Firebase configuration (BashkahApp.init)...")
            FirebaseApp.configure()
            print("✅ Firebase configured successfully (BashkahApp.init)")
        } else {
            print("⚠️ Firebase already configured (BashkahApp.init)")
        }
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                SplashPageView()
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
    }
}
