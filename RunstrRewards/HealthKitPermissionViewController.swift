import UIKit
import HealthKit

class HealthKitPermissionViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header
    private let headerView = UIView()
    private let backButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    
    // Main content
    private let iconView = UIView()
    private let iconImageView = UIImageView()
    
    private let titleSection = UIView()
    private let mainTitleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // Benefits section
    private let benefitsSection = UIView()
    private let benefitsTitle = UILabel()
    private var benefitItems: [BenefitItemView] = []
    
    // Permission button
    private let permissionButton = UIButton(type: .custom)
    private let skipButton = UIButton(type: .custom)
    
    // Loading state
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    // Completion handler
    var onCompletion: ((Bool) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🏥 HealthKitPermission: Loading permission request view")
        
        setupIndustrialBackground()
        setupScrollView()
        setupHeader()
        setupContent()
        setupBenefitsSection()
        setupButtons()
        setupConstraints()
        
        print("🏥 HealthKitPermission: Permission view loaded successfully")
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
        titleLabel.text = "Health Data"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(backButton)
        headerView.addSubview(titleLabel)
        contentView.addSubview(headerView)
    }
    
    private func setupContent() {
        // Health icon
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        iconView.layer.cornerRadius = 40
        iconView.layer.borderWidth = 1
        iconView.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        iconImageView.image = UIImage(systemName: "heart.fill")
        iconImageView.tintColor = UIColor.systemRed
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        iconView.addSubview(iconImageView)
        
        // Title section
        titleSection.translatesAutoresizingMaskIntoConstraints = false
        
        mainTitleLabel.text = "Sync Your Workouts"
        mainTitleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        mainTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        mainTitleLabel.textAlignment = .center
        mainTitleLabel.numberOfLines = 0
        mainTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        subtitleLabel.text = "Connect your fitness data to compete with teams and earn Bitcoin rewards automatically"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textColor = IndustrialDesign.Colors.secondaryText
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        titleSection.addSubview(mainTitleLabel)
        titleSection.addSubview(subtitleLabel)
        
        contentView.addSubview(iconView)
        contentView.addSubview(titleSection)
    }
    
    private func setupBenefitsSection() {
        benefitsSection.translatesAutoresizingMaskIntoConstraints = false
        benefitsSection.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        benefitsSection.layer.cornerRadius = 12
        benefitsSection.layer.borderWidth = 1
        benefitsSection.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        benefitsTitle.text = "What We Track"
        benefitsTitle.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        benefitsTitle.textColor = IndustrialDesign.Colors.primaryText
        benefitsTitle.translatesAutoresizingMaskIntoConstraints = false
        
        // Create benefit items
        let benefits = [
            ("figure.run", "Workouts & Activities", "Running, cycling, strength training, and more"),
            ("heart.fill", "Heart Rate Data", "Validate workout intensity for fair competition"),
            ("flame.fill", "Calories Burned", "Track energy expenditure and effort"),
            ("location.fill", "Distance & Routes", "Monitor progress and achievements"),
            ("lock.shield.fill", "Your Privacy", "Data stays on your device, only stats are shared")
        ]
        
        for (index, benefit) in benefits.enumerated() {
            let benefitItem = BenefitItemView(
                iconName: benefit.0,
                title: benefit.1,
                description: benefit.2,
                isPrivacy: index == benefits.count - 1
            )
            benefitItem.translatesAutoresizingMaskIntoConstraints = false
            benefitItems.append(benefitItem)
            benefitsSection.addSubview(benefitItem)
        }
        
        benefitsSection.addSubview(benefitsTitle)
        contentView.addSubview(benefitsSection)
    }
    
    private func setupButtons() {
        // Main permission button
        permissionButton.setTitle("Connect Health Data", for: .normal)
        permissionButton.setTitleColor(.white, for: .normal)
        permissionButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        permissionButton.backgroundColor = IndustrialDesign.Colors.cardBackground
        permissionButton.layer.cornerRadius = 12
        permissionButton.layer.borderWidth = 1
        permissionButton.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        permissionButton.translatesAutoresizingMaskIntoConstraints = false
        permissionButton.addTarget(self, action: #selector(requestHealthKitPermission), for: .touchUpInside)
        
        // Skip button
        skipButton.setTitle("Skip for Now", for: .normal)
        skipButton.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
        skipButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        skipButton.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.6)
        skipButton.layer.cornerRadius = 12
        skipButton.layer.borderWidth = 1
        skipButton.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.addTarget(self, action: #selector(skipButtonTapped), for: .touchUpInside)
        
        // Loading indicator
        loadingIndicator.color = .white
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(permissionButton)
        contentView.addSubview(skipButton)
        contentView.addSubview(loadingIndicator)
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
            
            // Icon
            iconView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 40),
            iconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 80),
            iconView.heightAnchor.constraint(equalToConstant: 80),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),
            
            // Title section
            titleSection.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 32),
            titleSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            titleSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            mainTitleLabel.topAnchor.constraint(equalTo: titleSection.topAnchor),
            mainTitleLabel.leadingAnchor.constraint(equalTo: titleSection.leadingAnchor),
            mainTitleLabel.trailingAnchor.constraint(equalTo: titleSection.trailingAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: mainTitleLabel.bottomAnchor, constant: 12),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleSection.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleSection.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: titleSection.bottomAnchor),
            
            // Benefits section
            benefitsSection.topAnchor.constraint(equalTo: titleSection.bottomAnchor, constant: 32),
            benefitsSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            benefitsSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            benefitsTitle.topAnchor.constraint(equalTo: benefitsSection.topAnchor, constant: 20),
            benefitsTitle.leadingAnchor.constraint(equalTo: benefitsSection.leadingAnchor, constant: 20),
            benefitsTitle.trailingAnchor.constraint(equalTo: benefitsSection.trailingAnchor, constant: -20),
            
            // Buttons
            permissionButton.topAnchor.constraint(equalTo: benefitsSection.bottomAnchor, constant: 32),
            permissionButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            permissionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            permissionButton.heightAnchor.constraint(equalToConstant: 56),
            
            skipButton.topAnchor.constraint(equalTo: permissionButton.bottomAnchor, constant: 16),
            skipButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            skipButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            skipButton.heightAnchor.constraint(equalToConstant: 48),
            skipButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
            
            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: permissionButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: permissionButton.centerYAnchor)
        ])
        
        // Benefits items constraints
        var previousItem: UIView = benefitsTitle
        for benefitItem in benefitItems {
            NSLayoutConstraint.activate([
                benefitItem.topAnchor.constraint(equalTo: previousItem.bottomAnchor, constant: 16),
                benefitItem.leadingAnchor.constraint(equalTo: benefitsSection.leadingAnchor, constant: 20),
                benefitItem.trailingAnchor.constraint(equalTo: benefitsSection.trailingAnchor, constant: -20),
                benefitItem.heightAnchor.constraint(equalToConstant: 60)
            ])
            previousItem = benefitItem
        }
        
        // Update benefits section bottom constraint
        if let lastItem = benefitItems.last {
            benefitsSection.bottomAnchor.constraint(equalTo: lastItem.bottomAnchor, constant: 20).isActive = true
        }
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        print("🏥 HealthKitPermission: Back button tapped")
        dismiss(animated: true)
    }
    
    @objc private func requestHealthKitPermission() {
        print("🏥 HealthKitPermission: Requesting HealthKit permission")
        
        setLoadingState(true)
        
        Task {
            do {
                let authorized = try await HealthKitService.shared.requestAuthorization()
                
                await MainActor.run {
                    self.setLoadingState(false)
                    
                    if authorized {
                        print("🏥 HealthKitPermission: Permission granted successfully")
                        self.showSuccessAndContinue()
                    } else {
                        print("🏥 HealthKitPermission: Permission denied")
                        self.showPermissionDeniedAlert()
                    }
                }
            } catch {
                await MainActor.run {
                    self.setLoadingState(false)
                    print("🏥 HealthKitPermission: Error requesting permission: \(error)")
                    self.showErrorAlert(error)
                }
            }
        }
    }
    
    @objc private func skipButtonTapped() {
        print("🏥 HealthKitPermission: Skip button tapped")
        onCompletion?(false)
    }
    
    // MARK: - Helper Methods
    
    private func setLoadingState(_ loading: Bool) {
        permissionButton.isEnabled = !loading
        skipButton.isEnabled = !loading
        
        if loading {
            loadingIndicator.startAnimating()
            permissionButton.setTitle("", for: .normal)
        } else {
            loadingIndicator.stopAnimating()
            permissionButton.setTitle("Connect Health Data", for: .normal)
        }
    }
    
    private func showSuccessAndContinue() {
        let alert = UIAlertController(
            title: "Health Data Connected!",
            message: "Your workouts will now sync automatically and you can start competing with teams to earn Bitcoin rewards.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Continue", style: .default) { _ in
            self.onCompletion?(true)
        })
        
        present(alert, animated: true)
    }
    
    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Health Data Access Needed",
            message: "To compete with teams and earn rewards, RunstrRewards needs access to your workout data. You can enable this later in Settings.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Skip for Now", style: .cancel) { _ in
            self.onCompletion?(false)
        })
        
        present(alert, animated: true)
    }
    
    private func showErrorAlert(_ error: Error) {
        let alert = UIAlertController(
            title: "Connection Error",
            message: "Failed to connect to Health app: \(error.localizedDescription)",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Try Again", style: .default) { _ in
            self.requestHealthKitPermission()
        })
        
        alert.addAction(UIAlertAction(title: "Skip for Now", style: .cancel) { _ in
            self.onCompletion?(false)
        })
        
        present(alert, animated: true)
    }
}

// MARK: - BenefitItemView

class BenefitItemView: UIView {
    
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    
    init(iconName: String, title: String, description: String, isPrivacy: Bool = false) {
        super.init(frame: .zero)
        
        setupViews(iconName: iconName, title: title, description: description, isPrivacy: isPrivacy)
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews(iconName: String, title: String, description: String, isPrivacy: Bool) {
        iconImageView.image = UIImage(systemName: iconName)
        iconImageView.tintColor = IndustrialDesign.Colors.primaryText
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        descriptionLabel.text = description
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = IndustrialDesign.Colors.secondaryText
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(descriptionLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -2)
        ])
    }
}