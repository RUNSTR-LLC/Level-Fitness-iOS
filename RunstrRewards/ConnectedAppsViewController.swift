import UIKit

class ConnectedAppsViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header
    private let headerView = UIView()
    private let backButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    
    // Connected apps section
    private let connectedAppsSection = UIView()
    private var appConnectionViews: [AppConnectionView] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🔗 Connected Apps: Loading view")
        
        setupIndustrialBackground()
        setupScrollView()
        setupHeader()
        setupConnectedAppsSection()
        setupConstraints()
        
        print("🔗 Connected Apps: View loaded successfully")
    }
    
    // MARK: - Setup Methods
    
    private func setupIndustrialBackground() {
        view.backgroundColor = IndustrialDesign.Colors.background
        
        // Add grid pattern background
        let gridView = GridPatternView()
        gridView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gridView)
        
        NSLayoutConstraint.activate([
            gridView.topAnchor.constraint(equalTo: view.topAnchor),
            gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Back button
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = IndustrialDesign.Colors.primaryText
        backButton.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        backButton.layer.cornerRadius = 20
        backButton.layer.borderWidth = 1
        backButton.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        // Title
        titleLabel.text = "Connected Apps"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(backButton)
        headerView.addSubview(titleLabel)
        contentView.addSubview(headerView)
    }
    
    private func setupConnectedAppsSection() {
        connectedAppsSection.translatesAutoresizingMaskIntoConstraints = false
        
        // Create app connection views
        let apps = [
            AppConnectionData(name: "Apple Health", icon: "heart.fill", isConnected: true, description: "Syncing workouts automatically"),
            AppConnectionData(name: "Strava", icon: "figure.run", isConnected: false, description: "Connect to sync running and cycling data"),
            AppConnectionData(name: "Garmin Connect", icon: "watch", isConnected: false, description: "Sync from Garmin devices"),
            AppConnectionData(name: "Fitbit", icon: "figure.walk", isConnected: false, description: "Connect Fitbit tracking data"),
            AppConnectionData(name: "Google Fit", icon: "figure.strengthtraining.traditional", isConnected: false, description: "Sync Google Fit activities"),
            AppConnectionData(name: "MyFitnessPal", icon: "fork.knife", isConnected: false, description: "Nutrition and calorie tracking")
        ]
        
        for (index, appData) in apps.enumerated() {
            let appView = AppConnectionView(appData: appData)
            appView.delegate = self
            appView.translatesAutoresizingMaskIntoConstraints = false
            connectedAppsSection.addSubview(appView)
            appConnectionViews.append(appView)
            
            // Position constraints
            NSLayoutConstraint.activate([
                appView.leadingAnchor.constraint(equalTo: connectedAppsSection.leadingAnchor),
                appView.trailingAnchor.constraint(equalTo: connectedAppsSection.trailingAnchor),
                appView.topAnchor.constraint(equalTo: index == 0 ? connectedAppsSection.topAnchor : appConnectionViews[index-1].bottomAnchor, constant: index == 0 ? 0 : 16)
            ])
            
            if index == apps.count - 1 {
                appView.bottomAnchor.constraint(equalTo: connectedAppsSection.bottomAnchor).isActive = true
            }
        }
        
        contentView.addSubview(connectedAppsSection)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Header
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            headerView.heightAnchor.constraint(equalToConstant: 44),
            
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            // Connected apps section
            connectedAppsSection.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 32),
            connectedAppsSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            connectedAppsSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            connectedAppsSection.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        print("🔗 Connected Apps: Back button tapped")
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - AppConnectionViewDelegate

extension ConnectedAppsViewController: AppConnectionViewDelegate {
    func appConnectionToggled(_ appData: AppConnectionData, isConnected: Bool) {
        print("🔗 Connected Apps: \(appData.name) connection toggled to \(isConnected)")
        
        if isConnected {
            connectApp(appData)
        } else {
            disconnectApp(appData)
        }
    }
    
    private func connectApp(_ appData: AppConnectionData) {
        let alert = UIAlertController(
            title: "Connect \(appData.name)",
            message: "To connect \(appData.name), you'll be redirected to their authentication page. Your data will be synced securely.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Connect", style: .default) { _ in
            // TODO: Implement actual OAuth flow for each platform
            self.showAlert(title: "Connection Initiated", message: "\(appData.name) connection will be available in a future update with full OAuth integration.")
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func disconnectApp(_ appData: AppConnectionData) {
        let alert = UIAlertController(
            title: "Disconnect \(appData.name)",
            message: "This will stop syncing data from \(appData.name). You can reconnect anytime.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Disconnect", style: .destructive) { _ in
            // TODO: Implement actual disconnection logic
            self.showAlert(title: "Disconnected", message: "\(appData.name) has been disconnected successfully.")
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Supporting Classes

struct AppConnectionData {
    let name: String
    let icon: String
    let isConnected: Bool
    let description: String
}

protocol AppConnectionViewDelegate: AnyObject {
    func appConnectionToggled(_ appData: AppConnectionData, isConnected: Bool)
}

class AppConnectionView: UIView {
    
    weak var delegate: AppConnectionViewDelegate?
    private let appData: AppConnectionData
    
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let nameLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let connectionSwitch = UISwitch()
    private let statusLabel = UILabel()
    
    init(appData: AppConnectionData) {
        self.appData = appData
        super.init(frame: .zero)
        
        setupViews()
        setupConstraints()
        updateConnectionStatus()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        // Container
        containerView.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Icon
        iconImageView.image = UIImage(systemName: appData.icon)
        iconImageView.tintColor = appData.isConnected ? IndustrialDesign.Colors.primaryText : IndustrialDesign.Colors.secondaryText
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Name
        nameLabel.text = appData.name
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = IndustrialDesign.Colors.primaryText
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Description
        descriptionLabel.text = appData.description
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = IndustrialDesign.Colors.secondaryText
        descriptionLabel.numberOfLines = 2
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Switch
        connectionSwitch.isOn = appData.isConnected
        connectionSwitch.onTintColor = IndustrialDesign.Colors.primaryText
        connectionSwitch.translatesAutoresizingMaskIntoConstraints = false
        connectionSwitch.addTarget(self, action: #selector(switchToggled), for: .valueChanged)
        
        // Status
        statusLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(iconImageView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(connectionSwitch)
        containerView.addSubview(statusLabel)
        addSubview(containerView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 80),
            
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 30),
            iconImageView.heightAnchor.constraint(equalToConstant: 30),
            
            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            
            descriptionLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            descriptionLabel.trailingAnchor.constraint(equalTo: connectionSwitch.leadingAnchor, constant: -16),
            
            connectionSwitch.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            connectionSwitch.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            statusLabel.topAnchor.constraint(equalTo: connectionSwitch.bottomAnchor, constant: 4)
        ])
    }
    
    private func updateConnectionStatus() {
        if appData.isConnected {
            statusLabel.text = "Connected"
            statusLabel.textColor = IndustrialDesign.Colors.primaryText
            iconImageView.tintColor = IndustrialDesign.Colors.primaryText
        } else {
            statusLabel.text = "Not Connected"
            statusLabel.textColor = IndustrialDesign.Colors.secondaryText
            iconImageView.tintColor = IndustrialDesign.Colors.secondaryText
        }
    }
    
    @objc private func switchToggled() {
        delegate?.appConnectionToggled(appData, isConnected: connectionSwitch.isOn)
    }
}