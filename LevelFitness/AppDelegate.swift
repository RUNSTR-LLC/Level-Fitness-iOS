import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize core services
        setupCoreServices()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Check if user is already authenticated
        let rootViewController: UIViewController
        if let existingSession = AuthenticationService.shared.loadSession() {
            print("AppDelegate: Found existing session for user: \(existingSession.email ?? "Unknown")")
            // User is already authenticated, go straight to main app
            rootViewController = ViewController()
        } else {
            print("AppDelegate: No existing session, showing login")
            // User needs to authenticate
            rootViewController = LoginViewController()
        }
        
        let navigationController = UINavigationController(rootViewController: rootViewController)
        
        // Configure navigation bar appearance for industrial theme
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = IndustrialDesign.Colors.background
        appearance.titleTextAttributes = [
            .foregroundColor: IndustrialDesign.Colors.primaryText,
            .font: IndustrialDesign.Typography.navTitleFont
        ]
        appearance.shadowColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        navigationController.navigationBar.tintColor = IndustrialDesign.Colors.primaryText
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        return true
    }
    
    // MARK: - Core Services Setup
    
    private func setupCoreServices() {
        // Start network monitoring
        let _ = NetworkMonitorService.shared
        print("AppDelegate: Network monitoring initialized")
        
        // Initialize offline data service
        let _ = OfflineDataService.shared
        print("AppDelegate: Offline data service initialized")
        
        // Initialize error handling service
        let _ = ErrorHandlingService.shared
        print("AppDelegate: Error handling service initialized")
        
        // Setup network change notifications
        setupNetworkNotifications()
    }
    
    private func setupNetworkNotifications() {
        NotificationCenter.default.addObserver(
            forName: .connectionRestored,
            object: nil,
            queue: .main
        ) { notification in
            print("AppDelegate: Network connection restored")
            // Could show a brief success message to user
        }
        
        NotificationCenter.default.addObserver(
            forName: .connectionLost,
            object: nil,
            queue: .main
        ) { notification in
            print("AppDelegate: Network connection lost - app in offline mode")
            // Could show offline indicator in UI
        }
    }
}