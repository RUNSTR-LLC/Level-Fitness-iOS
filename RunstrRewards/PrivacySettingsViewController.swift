import UIKit

class PrivacySettingsViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header
    private let headerView = UIView()
    private let backButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    
    // Privacy sections
    private let dataCollectionSection = UIView()
    private let dataUsageSection = UIView()
    private let sharingSection = UIView()
    
    private var privacySettingViews: [PrivacySettingView] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🔒 Privacy Settings: Loading view")
        
        setupIndustrialBackground()
        setupScrollView()
        setupHeader()
        setupPrivacySections()
        setupConstraints()
        loadPrivacySettings()
        
        print("🔒 Privacy Settings: View loaded successfully")
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
        titleLabel.text = "Privacy Settings"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(backButton)
        headerView.addSubview(titleLabel)
        contentView.addSubview(headerView)
    }
    
    private func setupPrivacySections() {
        // Data Collection Section
        dataCollectionSection.translatesAutoresizingMaskIntoConstraints = false
        let dataCollectionSettings = [
            PrivacySettingData(
                title: "HealthKit Data Collection",
                description: "Allow app to read workout and health data",
                isEnabled: true,
                type: .healthKit
            ),
            PrivacySettingData(
                title: "Location Data",
                description: "Allow app to access location for workout tracking",
                isEnabled: false,
                type: .location
            ),
            PrivacySettingData(
                title: "Usage Analytics",
                description: "Help improve the app with anonymous usage data",
                isEnabled: true,
                type: .analytics
            )
        ]
        
        let dataCollectionSectionView = PrivacySectionView(title: "Data Collection", settings: dataCollectionSettings)
        dataCollectionSectionView.delegate = self
        dataCollectionSection.addSubview(dataCollectionSectionView)
        privacySettingViews.append(contentsOf: dataCollectionSectionView.settingViews)
        contentView.addSubview(dataCollectionSection)
        
        // Data Usage Section
        dataUsageSection.translatesAutoresizingMaskIntoConstraints = false
        let dataUsageSettings = [
            PrivacySettingData(
                title: "Workout Verification",
                description: "Allow cross-platform verification to prevent fraud",
                isEnabled: true,
                type: .verification
            ),
            PrivacySettingData(
                title: "Performance Analytics",
                description: "Use your data to improve reward calculations",
                isEnabled: true,
                type: .performance
            )
        ]
        
        let dataUsageSectionView = PrivacySectionView(title: "Data Usage", settings: dataUsageSettings)
        dataUsageSectionView.delegate = self
        dataUsageSection.addSubview(dataUsageSectionView)
        privacySettingViews.append(contentsOf: dataUsageSectionView.settingViews)
        contentView.addSubview(dataUsageSection)
        
        // Sharing Section
        sharingSection.translatesAutoresizingMaskIntoConstraints = false
        let sharingSettings = [
            PrivacySettingData(
                title: "Team Leaderboards",
                description: "Show your workout stats in team rankings",
                isEnabled: true,
                type: .teamSharing
            ),
            PrivacySettingData(
                title: "Achievement Sharing",
                description: "Allow teams to see your achievement progress",
                isEnabled: true,
                type: .achievements
            ),
            PrivacySettingData(
                title: "Profile Visibility",
                description: "Make your profile visible to other team members",
                isEnabled: true,
                type: .profile
            )
        ]
        
        let sharingSectionView = PrivacySectionView(title: "Data Sharing", settings: sharingSettings)
        sharingSectionView.delegate = self
        sharingSection.addSubview(sharingSectionView)
        privacySettingViews.append(contentsOf: sharingSectionView.settingViews)
        contentView.addSubview(sharingSection)
        
        // Setup section constraints
        NSLayoutConstraint.activate([
            dataCollectionSectionView.topAnchor.constraint(equalTo: dataCollectionSection.topAnchor),
            dataCollectionSectionView.leadingAnchor.constraint(equalTo: dataCollectionSection.leadingAnchor),
            dataCollectionSectionView.trailingAnchor.constraint(equalTo: dataCollectionSection.trailingAnchor),
            dataCollectionSectionView.bottomAnchor.constraint(equalTo: dataCollectionSection.bottomAnchor),
            
            dataUsageSectionView.topAnchor.constraint(equalTo: dataUsageSection.topAnchor),
            dataUsageSectionView.leadingAnchor.constraint(equalTo: dataUsageSection.leadingAnchor),
            dataUsageSectionView.trailingAnchor.constraint(equalTo: dataUsageSection.trailingAnchor),
            dataUsageSectionView.bottomAnchor.constraint(equalTo: dataUsageSection.bottomAnchor),
            
            sharingSectionView.topAnchor.constraint(equalTo: sharingSection.topAnchor),
            sharingSectionView.leadingAnchor.constraint(equalTo: sharingSection.leadingAnchor),
            sharingSectionView.trailingAnchor.constraint(equalTo: sharingSection.trailingAnchor),
            sharingSectionView.bottomAnchor.constraint(equalTo: sharingSection.bottomAnchor)
        ])
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
            
            // Privacy sections
            dataCollectionSection.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 32),
            dataCollectionSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            dataCollectionSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            dataUsageSection.topAnchor.constraint(equalTo: dataCollectionSection.bottomAnchor, constant: 32),
            dataUsageSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            dataUsageSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            sharingSection.topAnchor.constraint(equalTo: dataUsageSection.bottomAnchor, constant: 32),
            sharingSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            sharingSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            sharingSection.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }
    
    private func loadPrivacySettings() {
        // Load saved privacy preferences
        for settingView in privacySettingViews {
            let key = "privacy_\(settingView.settingData.type.rawValue)"
            let isEnabled = UserDefaults.standard.bool(forKey: key)
            settingView.updateSetting(isEnabled: isEnabled)
        }
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        print("🔒 Privacy Settings: Back button tapped")
        navigationController?.popViewController(animated: true)
    }
    
    private func savePrivacySetting(_ type: PrivacySettingType, isEnabled: Bool) {
        let key = "privacy_\(type.rawValue)"
        UserDefaults.standard.set(isEnabled, forKey: key)
        print("🔒 Privacy Settings: Saved \(type.rawValue) = \(isEnabled)")
    }
}

// MARK: - PrivacySectionViewDelegate

extension PrivacySettingsViewController: PrivacySectionViewDelegate {
    func privacySettingChanged(_ type: PrivacySettingType, isEnabled: Bool) {
        print("🔒 Privacy Settings: \(type.rawValue) changed to \(isEnabled)")
        
        // Handle special cases
        switch type {
        case .healthKit:
            if !isEnabled {
                showHealthKitDisableWarning()
            }
        case .location:
            if isEnabled {
                requestLocationPermission()
            }
        default:
            break
        }
        
        savePrivacySetting(type, isEnabled: isEnabled)
    }
    
    private func showHealthKitDisableWarning() {
        let alert = UIAlertController(
            title: "Disable HealthKit?",
            message: "Disabling HealthKit will stop workout tracking and Bitcoin rewards. You can re-enable this anytime in Settings.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Keep Enabled", style: .cancel) { _ in
            // Find and reset the HealthKit setting
            for settingView in self.privacySettingViews {
                if settingView.settingData.type == .healthKit {
                    settingView.updateSetting(isEnabled: true)
                    break
                }
            }
        })
        
        alert.addAction(UIAlertAction(title: "Disable", style: .destructive) { _ in
            self.savePrivacySetting(.healthKit, isEnabled: false)
        })
        
        present(alert, animated: true)
    }
    
    private func requestLocationPermission() {
        let alert = UIAlertController(
            title: "Location Access",
            message: "Location data helps verify outdoor workouts and prevent fraud. This will redirect you to Settings to enable location access.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            // Reset location setting
            for settingView in self.privacySettingViews {
                if settingView.settingData.type == .location {
                    settingView.updateSetting(isEnabled: false)
                    break
                }
            }
        })
        
        present(alert, animated: true)
    }
}

// MARK: - Supporting Classes

enum PrivacySettingType: String, CaseIterable {
    case healthKit = "healthkit"
    case location = "location"
    case analytics = "analytics"
    case verification = "verification"
    case performance = "performance"
    case teamSharing = "team_sharing"
    case achievements = "achievements"
    case profile = "profile"
}

struct PrivacySettingData {
    let title: String
    let description: String
    let isEnabled: Bool
    let type: PrivacySettingType
}

protocol PrivacySectionViewDelegate: AnyObject {
    func privacySettingChanged(_ type: PrivacySettingType, isEnabled: Bool)
}

class PrivacySectionView: UIView {
    
    weak var delegate: PrivacySectionViewDelegate?
    let settingViews: [PrivacySettingView]
    
    private let titleLabel = UILabel()
    private let stackView = UIStackView()
    
    init(title: String, settings: [PrivacySettingData]) {
        self.settingViews = settings.map { PrivacySettingView(settingData: $0) }
        super.init(frame: .zero)
        
        setupViews(title: title)
        setupConstraints()
        
        // Set delegates
        for settingView in settingViews {
            settingView.delegate = self
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews(title: String) {
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        stackView.layer.cornerRadius = 12
        stackView.layer.borderWidth = 1
        stackView.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        for (index, settingView) in settingViews.enumerated() {
            stackView.addArrangedSubview(settingView)
            
            // Add separator (except for last item)
            if index < settingViews.count - 1 {
                let separator = UIView()
                separator.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0)
                separator.translatesAutoresizingMaskIntoConstraints = false
                separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
                stackView.addArrangedSubview(separator)
            }
        }
        
        addSubview(titleLabel)
        addSubview(stackView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

extension PrivacySectionView: PrivacySettingViewDelegate {
    func privacySettingToggled(_ settingData: PrivacySettingData, isEnabled: Bool) {
        delegate?.privacySettingChanged(settingData.type, isEnabled: isEnabled)
    }
}

protocol PrivacySettingViewDelegate: AnyObject {
    func privacySettingToggled(_ settingData: PrivacySettingData, isEnabled: Bool)
}

class PrivacySettingView: UIView {
    
    weak var delegate: PrivacySettingViewDelegate?
    let settingData: PrivacySettingData
    
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let settingSwitch = UISwitch()
    
    init(settingData: PrivacySettingData) {
        self.settingData = settingData
        super.init(frame: .zero)
        
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        titleLabel.text = settingData.title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        descriptionLabel.text = settingData.description
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = IndustrialDesign.Colors.secondaryText
        descriptionLabel.numberOfLines = 2
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        settingSwitch.isOn = settingData.isEnabled
        settingSwitch.onTintColor = UIColor.systemGreen
        settingSwitch.translatesAutoresizingMaskIntoConstraints = false
        settingSwitch.addTarget(self, action: #selector(switchToggled), for: .valueChanged)
        
        addSubview(titleLabel)
        addSubview(descriptionLabel)
        addSubview(settingSwitch)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 70),
            
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: settingSwitch.leadingAnchor, constant: -16),
            
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            descriptionLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            
            settingSwitch.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            settingSwitch.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    func updateSetting(isEnabled: Bool) {
        settingSwitch.isOn = isEnabled
    }
    
    @objc private func switchToggled() {
        delegate?.privacySettingToggled(settingData, isEnabled: settingSwitch.isOn)
    }
}