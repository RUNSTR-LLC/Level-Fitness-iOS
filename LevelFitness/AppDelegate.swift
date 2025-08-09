import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let loginViewController = LoginViewController()
        let navigationController = UINavigationController(rootViewController: loginViewController)
        
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
}