import UIKit

class TeamLeaderboardSetupStepViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let stepTitleLabel = UILabel()
    private let stepDescriptionLabel = UILabel()
    
    // Leaderboard type selection
    private let typeSection = UIView()
    private let typeLabel = UILabel()
    private var typeButtons: [UIButton] = []
    
    // Leaderboard period selection
    private let periodSection = UIView()
    private let periodLabel = UILabel()
    private var periodButtons: [UIButton] = []
    
    // Speed ranking configuration (shown when speed rankings selected)
    private let speedConfigSection = UIView()
    private let speedConfigLabel = UILabel()
    private var speedDistanceButtons: [UIButton] = []
    private let customDistanceContainer = UIView()
    private let customDistanceField = UITextField()
    private let customDistanceLabel = UILabel()
    
    // Team data reference
    private let teamData: TeamCreationData
    
    init(teamData: TeamCreationData) {
        self.teamData = teamData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
        setupSelectionButtons()
        loadExistingData()
        
        print("📊 TeamLeaderboardSetup: Step view loaded")
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        view.backgroundColor = UIColor.clear
        
        // Step header
        stepTitleLabel.text = "Leaderboard Setup"
        stepTitleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        stepTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        stepTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        stepDescriptionLabel.text = "Configure how your team leaderboard will rank members. This will be the main competition view for your team."
        stepDescriptionLabel.font = UIFont.systemFont(ofSize: 16)
        stepDescriptionLabel.textColor = IndustrialDesign.Colors.secondaryText
        stepDescriptionLabel.numberOfLines = 0
        stepDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        setupSections()
        
        // Add to scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [stepTitleLabel, stepDescriptionLabel, typeSection, periodSection, speedConfigSection].forEach {
            contentView.addSubview($0)
        }
    }
    
    private func setupSections() {
        // Leaderboard type section
        typeSection.translatesAutoresizingMaskIntoConstraints = false
        typeSection.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        typeSection.layer.cornerRadius = 12
        typeSection.layer.borderWidth = 1
        typeSection.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        typeLabel.text = "Ranking Method"
        typeLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        typeLabel.textColor = IndustrialDesign.Colors.primaryText
        typeLabel.translatesAutoresizingMaskIntoConstraints = false
        typeSection.addSubview(typeLabel)
        
        // Period selection section
        periodSection.translatesAutoresizingMaskIntoConstraints = false
        periodSection.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        periodSection.layer.cornerRadius = 12
        periodSection.layer.borderWidth = 1
        periodSection.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        periodLabel.text = "Leaderboard Period"
        periodLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        periodLabel.textColor = IndustrialDesign.Colors.primaryText
        periodLabel.translatesAutoresizingMaskIntoConstraints = false
        periodSection.addSubview(periodLabel)
        
        // Speed ranking configuration section (initially hidden)
        speedConfigSection.translatesAutoresizingMaskIntoConstraints = false
        speedConfigSection.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        speedConfigSection.layer.cornerRadius = 12
        speedConfigSection.layer.borderWidth = 1
        speedConfigSection.layer.borderColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 0.5).cgColor
        speedConfigSection.isHidden = true
        
        speedConfigLabel.text = "Speed Distance Configuration"
        speedConfigLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        speedConfigLabel.textColor = IndustrialDesign.Colors.bitcoin
        speedConfigLabel.translatesAutoresizingMaskIntoConstraints = false
        speedConfigSection.addSubview(speedConfigLabel)
        
        // Custom distance input container
        customDistanceContainer.translatesAutoresizingMaskIntoConstraints = false
        customDistanceContainer.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)
        customDistanceContainer.layer.cornerRadius = 8
        customDistanceContainer.layer.borderWidth = 1
        customDistanceContainer.layer.borderColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0).cgColor
        customDistanceContainer.isHidden = true
        
        customDistanceLabel.text = "Distance (km):"
        customDistanceLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        customDistanceLabel.textColor = IndustrialDesign.Colors.secondaryText
        customDistanceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        customDistanceField.placeholder = "5.0"
        customDistanceField.text = "\(teamData.customSpeedDistance)"
        customDistanceField.keyboardType = .decimalPad
        customDistanceField.backgroundColor = UIColor.clear
        customDistanceField.textColor = IndustrialDesign.Colors.primaryText
        customDistanceField.font = UIFont.systemFont(ofSize: 16)
        customDistanceField.translatesAutoresizingMaskIntoConstraints = false
        
        customDistanceContainer.addSubview(customDistanceLabel)
        customDistanceContainer.addSubview(customDistanceField)
        speedConfigSection.addSubview(customDistanceContainer)
    }
    
    private func setupSelectionButtons() {
        print("📊 TeamLeaderboardSetup: Creating buttons for \(TeamLeaderboardType.allCases.count) leaderboard types")
        
        // Create leaderboard type buttons with better spacing
        var previousTypeButton: UIView? = nil
        for (index, leaderboardType) in TeamLeaderboardType.allCases.enumerated() {
            print("📊 TeamLeaderboardSetup: Creating type button \(index + 1): \(leaderboardType.displayName)")
            let button = createSelectionButton(
                title: leaderboardType.displayName,
                icon: leaderboardType.icon,
                tag: index
            )
            button.addTarget(self, action: #selector(leaderboardTypeSelected(_:)), for: .touchUpInside)
            typeButtons.append(button)
            typeSection.addSubview(button)
            
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: typeSection.leadingAnchor, constant: 16),
                button.trailingAnchor.constraint(equalTo: typeSection.trailingAnchor, constant: -16),
                button.heightAnchor.constraint(equalToConstant: 56) // Slightly taller for better touch
            ])
            
            if let previousButton = previousTypeButton {
                button.topAnchor.constraint(equalTo: previousButton.bottomAnchor, constant: 12).isActive = true
            } else {
                button.topAnchor.constraint(equalTo: typeLabel.bottomAnchor, constant: 20).isActive = true
            }
            
            previousTypeButton = button
        }
        
        // Create period selection buttons with better spacing
        print("📊 TeamLeaderboardSetup: Creating buttons for \(LeaderboardPeriod.allCases.count) leaderboard periods")
        var previousPeriodButton: UIView? = nil
        for (index, period) in LeaderboardPeriod.allCases.enumerated() {
            print("📊 TeamLeaderboardSetup: Creating period button \(index + 1): \(period.displayName)")
            let button = createSelectionButton(
                title: period.displayName,
                icon: "calendar",
                tag: index
            )
            button.addTarget(self, action: #selector(periodSelected(_:)), for: .touchUpInside)
            periodButtons.append(button)
            periodSection.addSubview(button)
            
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: periodSection.leadingAnchor, constant: 16),
                button.trailingAnchor.constraint(equalTo: periodSection.trailingAnchor, constant: -16),
                button.heightAnchor.constraint(equalToConstant: 56) // Slightly taller for better touch
            ])
            
            if let previousButton = previousPeriodButton {
                button.topAnchor.constraint(equalTo: previousButton.bottomAnchor, constant: 12).isActive = true
            } else {
                button.topAnchor.constraint(equalTo: periodLabel.bottomAnchor, constant: 20).isActive = true
            }
            
            previousPeriodButton = button
        }
        
        print("📊 TeamLeaderboardSetup: Setup complete - \(typeButtons.count) type buttons, \(periodButtons.count) period buttons")
    }
    
    private func createSelectionButton(title: String, icon: String, tag: Int) -> UIButton {
        let button = UIButton(type: .custom)
        button.tag = tag
        button.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Create icon and title layout
        let iconImageView = UIImageView(image: UIImage(systemName: icon))
        iconImageView.tintColor = IndustrialDesign.Colors.secondaryText
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        button.addSubview(iconImageView)
        button.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: button.trailingAnchor, constant: -16)
        ])
        
        return button
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Step header
            stepTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            stepTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stepTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            stepDescriptionLabel.topAnchor.constraint(equalTo: stepTitleLabel.bottomAnchor, constant: 8),
            stepDescriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stepDescriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            // Type section
            typeSection.topAnchor.constraint(equalTo: stepDescriptionLabel.bottomAnchor, constant: 32),
            typeSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            typeSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            typeLabel.topAnchor.constraint(equalTo: typeSection.topAnchor, constant: 16),
            typeLabel.leadingAnchor.constraint(equalTo: typeSection.leadingAnchor, constant: 16),
            typeLabel.trailingAnchor.constraint(equalTo: typeSection.trailingAnchor, constant: -16),
            
            // Period section
            periodSection.topAnchor.constraint(equalTo: typeSection.bottomAnchor, constant: 24),
            periodSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            periodSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            periodLabel.topAnchor.constraint(equalTo: periodSection.topAnchor, constant: 16),
            periodLabel.leadingAnchor.constraint(equalTo: periodSection.leadingAnchor, constant: 16),
            periodLabel.trailingAnchor.constraint(equalTo: periodSection.trailingAnchor, constant: -16)
        ])
        
        // Set up proper bottom constraints for sections after buttons are created
        DispatchQueue.main.async {
            if let lastTypeButton = self.typeButtons.last {
                self.typeSection.bottomAnchor.constraint(equalTo: lastTypeButton.bottomAnchor, constant: 16).isActive = true
            }
            
            if let lastPeriodButton = self.periodButtons.last {
                self.periodSection.bottomAnchor.constraint(equalTo: lastPeriodButton.bottomAnchor, constant: 16).isActive = true
                // Set content view bottom constraint to last period button
                self.contentView.bottomAnchor.constraint(equalTo: self.periodSection.bottomAnchor, constant: 24).isActive = true
            }
        }
    }
    
    private func loadExistingData() {
        // Select current leaderboard type
        if let typeIndex = TeamLeaderboardType.allCases.firstIndex(of: teamData.leaderboardType) {
            selectTypeButton(at: typeIndex)
        }
        
        // Select current period
        if let periodIndex = LeaderboardPeriod.allCases.firstIndex(of: teamData.leaderboardPeriod) {
            selectPeriodButton(at: periodIndex)
        }
    }
    
    // MARK: - Actions
    
    @objc private func leaderboardTypeSelected(_ sender: UIButton) {
        let selectedType = TeamLeaderboardType.allCases[sender.tag]
        teamData.leaderboardType = selectedType
        selectTypeButton(at: sender.tag)
        
        print("📊 TeamLeaderboardSetup: Selected leaderboard type: \(selectedType.displayName)")
    }
    
    @objc private func periodSelected(_ sender: UIButton) {
        let selectedPeriod = LeaderboardPeriod.allCases[sender.tag]
        teamData.leaderboardPeriod = selectedPeriod
        selectPeriodButton(at: sender.tag)
        
        print("📊 TeamLeaderboardSetup: Selected period: \(selectedPeriod.displayName)")
    }
    
    private func selectTypeButton(at index: Int) {
        for (i, button) in typeButtons.enumerated() {
            if i == index {
                button.backgroundColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 0.2)
                button.layer.borderColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0).cgColor
            } else {
                button.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
                button.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
            }
        }
    }
    
    private func selectPeriodButton(at index: Int) {
        for (i, button) in periodButtons.enumerated() {
            if i == index {
                button.backgroundColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 0.2)
                button.layer.borderColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0).cgColor
            } else {
                button.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
                button.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
            }
        }
    }
}