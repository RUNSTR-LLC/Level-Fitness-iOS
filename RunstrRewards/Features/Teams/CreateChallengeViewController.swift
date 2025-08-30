import UIKit

protocol CreateChallengeDelegate: AnyObject {
    func didCreateChallenge(_ challenge: P2PChallenge)
    func didCancelChallenge()
}

class CreateChallengeViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: CreateChallengeDelegate?
    private let teamId: String
    private let teamMembers: [TeamMemberWithProfile]
    private let currentUserId: String
    
    // UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let headerView = UIView()
    private let backButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // Form sections
    private let opponentSection = UIView()
    private let challengeTypeSection = UIView()
    private let stakeSection = UIView()
    private let durationSection = UIView()
    private let conditionsSection = UIView()
    
    // Selection states
    private var selectedOpponent: TeamMemberWithProfile?
    private var selectedChallengeType: P2PChallengeType = .distanceRace
    private var selectedStake: P2PChallengeStake = .small
    private var selectedDuration: Int = 7 // days
    private var challengeConditions: P2PChallengeConditions?
    
    // Action buttons
    private let createButton = UIButton(type: .custom)
    private let cancelButton = UIButton(type: .custom)
    
    // MARK: - Initialization
    
    init(teamId: String, teamMembers: [TeamMemberWithProfile], currentUserId: String) {
        self.teamId = teamId
        self.teamMembers = teamMembers.filter { $0.userId != currentUserId } // Exclude current user
        self.currentUserId = currentUserId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("🥊 CreateChallengeViewController: Loading challenge creation for team \(teamId)")
        
        setupIndustrialBackground()
        setupScrollView()
        setupHeader()
        setupFormSections()
        setupActionButtons()
        setupConstraints()
        
        // Set default conditions
        updateConditionsForType(.distanceRace)
    }
    
    // MARK: - Setup Methods
    
    private func setupIndustrialBackground() {
        view.backgroundColor = IndustrialDesign.Colors.background
        
        // Add grid pattern
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
        contentView.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 0.95)
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Back button
        backButton.setTitle("← Back", for: .normal)
        backButton.setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        // Title
        titleLabel.text = "Create Challenge"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Subtitle
        subtitleLabel.text = "Challenge a teammate to a fitness competition"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textColor = IndustrialDesign.Colors.secondaryText
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(backButton)
        headerView.addSubview(titleLabel)
        headerView.addSubview(subtitleLabel)
        contentView.addSubview(headerView)
    }
    
    private func setupFormSections() {
        setupOpponentSelection()
        setupChallengeTypeSelection()
        setupStakeSelection()
        setupDurationSelection()
        setupConditionsSection()
        
        [opponentSection, challengeTypeSection, stakeSection, durationSection, conditionsSection].forEach {
            contentView.addSubview($0)
        }
    }
    
    private func setupOpponentSelection() {
        opponentSection.translatesAutoresizingMaskIntoConstraints = false
        opponentSection.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        opponentSection.layer.cornerRadius = 12
        opponentSection.layer.borderWidth = 1
        opponentSection.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        
        let titleLabel = createSectionTitle("Select Opponent")
        opponentSection.addSubview(titleLabel)
        
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorColor = IndustrialDesign.Colors.cardBorder
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TeamMemberCell.self, forCellReuseIdentifier: "TeamMemberCell")
        tableView.layer.cornerRadius = 8
        tableView.isScrollEnabled = false
        
        opponentSection.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: opponentSection.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: opponentSection.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: opponentSection.trailingAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: opponentSection.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: opponentSection.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: opponentSection.bottomAnchor, constant: -16),
            tableView.heightAnchor.constraint(equalToConstant: min(CGFloat(teamMembers.count * 60), 240))
        ])
    }
    
    private func setupChallengeTypeSelection() {
        challengeTypeSection.translatesAutoresizingMaskIntoConstraints = false
        challengeTypeSection.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        challengeTypeSection.layer.cornerRadius = 12
        challengeTypeSection.layer.borderWidth = 1
        challengeTypeSection.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        
        let titleLabel = createSectionTitle("Challenge Type")
        challengeTypeSection.addSubview(titleLabel)
        
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 8
        
        for challengeType in P2PChallengeType.allCases {
            let button = createTypeButton(for: challengeType)
            stackView.addArrangedSubview(button)
        }
        
        challengeTypeSection.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: challengeTypeSection.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: challengeTypeSection.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: challengeTypeSection.trailingAnchor, constant: -16),
            
            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: challengeTypeSection.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: challengeTypeSection.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: challengeTypeSection.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupStakeSelection() {
        stakeSection.translatesAutoresizingMaskIntoConstraints = false
        stakeSection.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        stakeSection.layer.cornerRadius = 12
        stakeSection.layer.borderWidth = 1
        stakeSection.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        
        let titleLabel = createSectionTitle("Stake Amount")
        stakeSection.addSubview(titleLabel)
        
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        
        for stake in P2PChallengeStake.allCases {
            let button = createStakeButton(for: stake)
            stackView.addArrangedSubview(button)
        }
        
        stakeSection.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: stakeSection.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: stakeSection.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: stakeSection.trailingAnchor, constant: -16),
            
            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: stakeSection.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: stakeSection.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: stakeSection.bottomAnchor, constant: -16),
            stackView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupDurationSelection() {
        durationSection.translatesAutoresizingMaskIntoConstraints = false
        durationSection.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        durationSection.layer.cornerRadius = 12
        durationSection.layer.borderWidth = 1
        durationSection.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        
        let titleLabel = createSectionTitle("Duration")
        durationSection.addSubview(titleLabel)
        
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumValue = 1
        slider.maximumValue = 30
        slider.value = Float(selectedDuration)
        slider.tintColor = IndustrialDesign.Colors.bitcoin
        slider.addTarget(self, action: #selector(durationChanged(_:)), for: .valueChanged)
        
        let durationLabel = UILabel()
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.text = "\(selectedDuration) days"
        durationLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        durationLabel.textColor = IndustrialDesign.Colors.primaryText
        durationLabel.textAlignment = .center
        durationLabel.tag = 999 // For easy reference
        
        durationSection.addSubview(slider)
        durationSection.addSubview(durationLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: durationSection.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: durationSection.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: durationSection.trailingAnchor, constant: -16),
            
            slider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            slider.leadingAnchor.constraint(equalTo: durationSection.leadingAnchor, constant: 16),
            slider.trailingAnchor.constraint(equalTo: durationSection.trailingAnchor, constant: -16),
            
            durationLabel.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 8),
            durationLabel.centerXAnchor.constraint(equalTo: durationSection.centerXAnchor),
            durationLabel.bottomAnchor.constraint(equalTo: durationSection.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupConditionsSection() {
        conditionsSection.translatesAutoresizingMaskIntoConstraints = false
        conditionsSection.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        conditionsSection.layer.cornerRadius = 12
        conditionsSection.layer.borderWidth = 1
        conditionsSection.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        
        let titleLabel = createSectionTitle("Challenge Goal")
        conditionsSection.addSubview(titleLabel)
        
        let descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        descriptionLabel.textColor = IndustrialDesign.Colors.secondaryText
        descriptionLabel.numberOfLines = 0
        descriptionLabel.tag = 998 // For easy reference
        
        conditionsSection.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: conditionsSection.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: conditionsSection.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: conditionsSection.trailingAnchor, constant: -16),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            descriptionLabel.leadingAnchor.constraint(equalTo: conditionsSection.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: conditionsSection.trailingAnchor, constant: -16),
            descriptionLabel.bottomAnchor.constraint(equalTo: conditionsSection.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupActionButtons() {
        createButton.translatesAutoresizingMaskIntoConstraints = false
        createButton.setTitle("Create Challenge", for: .normal)
        createButton.setTitleColor(.black, for: .normal)
        createButton.backgroundColor = IndustrialDesign.Colors.bitcoin
        createButton.layer.cornerRadius = 8
        createButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        createButton.addTarget(self, action: #selector(createButtonTapped), for: .touchUpInside)
        
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
        cancelButton.backgroundColor = .clear
        cancelButton.layer.cornerRadius = 8
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        
        contentView.addSubview(createButton)
        contentView.addSubview(cancelButton)
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
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            backButton.topAnchor.constraint(equalTo: headerView.topAnchor),
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            
            // Form sections
            opponentSection.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 32),
            opponentSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            opponentSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            challengeTypeSection.topAnchor.constraint(equalTo: opponentSection.bottomAnchor, constant: 20),
            challengeTypeSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            challengeTypeSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            stakeSection.topAnchor.constraint(equalTo: challengeTypeSection.bottomAnchor, constant: 20),
            stakeSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stakeSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            durationSection.topAnchor.constraint(equalTo: stakeSection.bottomAnchor, constant: 20),
            durationSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            durationSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            conditionsSection.topAnchor.constraint(equalTo: durationSection.bottomAnchor, constant: 20),
            conditionsSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            conditionsSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            // Action buttons
            createButton.topAnchor.constraint(equalTo: conditionsSection.bottomAnchor, constant: 32),
            createButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            createButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            createButton.heightAnchor.constraint(equalToConstant: 50),
            
            cancelButton.topAnchor.constraint(equalTo: createButton.bottomAnchor, constant: 12),
            cancelButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            cancelButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            cancelButton.heightAnchor.constraint(equalToConstant: 50),
            cancelButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }
    
    // MARK: - Helper Methods
    
    private func createSectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textColor = IndustrialDesign.Colors.primaryText
        return label
    }
    
    private func createTypeButton(for type: P2PChallengeType) -> UIButton {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        
        let isSelected = type == selectedChallengeType
        
        button.setTitle(type.displayName, for: .normal)
        button.setTitleColor(isSelected ? .black : IndustrialDesign.Colors.primaryText, for: .normal)
        button.backgroundColor = isSelected ? IndustrialDesign.Colors.bitcoin : UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = isSelected ? IndustrialDesign.Colors.bitcoin.cgColor : IndustrialDesign.Colors.cardBorder.cgColor
        
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.tag = type.hashValue
        button.addTarget(self, action: #selector(challengeTypeSelected(_:)), for: .touchUpInside)
        
        return button
    }
    
    private func createStakeButton(for stake: P2PChallengeStake) -> UIButton {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let isSelected = stake == selectedStake
        
        button.setTitle(stake.displayName, for: .normal)
        button.setTitleColor(isSelected ? .black : IndustrialDesign.Colors.primaryText, for: .normal)
        button.backgroundColor = isSelected ? IndustrialDesign.Colors.bitcoin : UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = isSelected ? IndustrialDesign.Colors.bitcoin.cgColor : IndustrialDesign.Colors.cardBorder.cgColor
        
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        button.tag = stake.rawValue
        button.addTarget(self, action: #selector(stakeSelected(_:)), for: .touchUpInside)
        
        return button
    }
    
    private func updateConditionsForType(_ type: P2PChallengeType) {
        guard let descriptionLabel = conditionsSection.viewWithTag(998) as? UILabel else { return }
        
        switch type {
        case .distanceRace:
            challengeConditions = P2PChallengeConditions(
                targetValue: 42195, // Marathon distance in meters
                unit: "meters",
                description: "First to complete a marathon distance (42.2km) wins"
            )
            descriptionLabel.text = "🏃‍♂️ First to complete a marathon distance (42.2km) wins"
            
        case .durationGoal:
            challengeConditions = P2PChallengeConditions(
                targetValue: 300 * 60, // 5 hours in seconds
                unit: "seconds",
                description: "Most total workout time over the challenge duration wins"
            )
            descriptionLabel.text = "⏱️ Most total workout time over the challenge duration wins"
            
        case .streakDays:
            challengeConditions = P2PChallengeConditions(
                targetValue: Double(selectedDuration),
                unit: "days",
                description: "Longest consecutive daily workout streak wins"
            )
            descriptionLabel.text = "🔥 Longest consecutive daily workout streak wins"
            
        case .fastestTime:
            challengeConditions = P2PChallengeConditions(
                targetValue: 1800, // 30 minutes in seconds
                unit: "seconds",
                description: "Fastest to complete a 5K run wins"
            )
            descriptionLabel.text = "🏎️ Fastest to complete a 5K run wins"
        }
    }
    
    private func validateForm() -> Bool {
        guard selectedOpponent != nil else {
            showAlert(title: "No Opponent", message: "Please select an opponent to challenge.")
            return false
        }
        
        guard challengeConditions != nil else {
            showAlert(title: "Invalid Conditions", message: "Challenge conditions are not properly set.")
            return false
        }
        
        return true
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        print("🥊 CreateChallengeViewController: Back button tapped")
        delegate?.didCancelChallenge()
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func challengeTypeSelected(_ sender: UIButton) {
        if let type = P2PChallengeType.allCases.first(where: { $0.hashValue == sender.tag }) {
            selectedChallengeType = type
            updateConditionsForType(type)
            
            // Refresh challenge type section
            setupChallengeTypeSelection()
            
            print("🥊 CreateChallengeViewController: Challenge type selected - \(type.displayName)")
        }
    }
    
    @objc private func stakeSelected(_ sender: UIButton) {
        if let stake = P2PChallengeStake.allCases.first(where: { $0.rawValue == sender.tag }) {
            selectedStake = stake
            
            // Refresh stake section
            setupStakeSelection()
            
            print("🥊 CreateChallengeViewController: Stake selected - \(stake.displayName)")
        }
    }
    
    @objc private func durationChanged(_ sender: UISlider) {
        selectedDuration = Int(sender.value)
        
        if let durationLabel = durationSection.viewWithTag(999) as? UILabel {
            durationLabel.text = "\(selectedDuration) days"
        }
        
        // Update conditions if it's a streak challenge
        if selectedChallengeType == .streakDays {
            updateConditionsForType(.streakDays)
        }
    }
    
    @objc private func createButtonTapped() {
        print("🥊 CreateChallengeViewController: Create challenge button tapped")
        
        guard validateForm() else { return }
        guard let opponent = selectedOpponent,
              let conditions = challengeConditions else { return }
        
        createButton.isEnabled = false
        createButton.setTitle("Creating...", for: .normal)
        
        Task {
            do {
                let challenge = try await P2PChallengeService.shared.createChallenge(
                    challengerId: currentUserId,
                    challengedId: opponent.userId,
                    teamId: teamId,
                    type: selectedChallengeType,
                    stake: selectedStake,
                    duration: selectedDuration,
                    conditions: conditions
                )
                
                print("✅ CreateChallengeViewController: Challenge created successfully")
                
                await MainActor.run {
                    delegate?.didCreateChallenge(challenge)
                    navigationController?.popViewController(animated: true)
                }
                
            } catch {
                print("❌ CreateChallengeViewController: Failed to create challenge - \(error)")
                
                await MainActor.run {
                    createButton.isEnabled = true
                    createButton.setTitle("Create Challenge", for: .normal)
                    
                    showAlert(title: "Error", message: "Failed to create challenge: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc private func cancelButtonTapped() {
        print("🥊 CreateChallengeViewController: Cancel button tapped")
        delegate?.didCancelChallenge()
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension CreateChallengeViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return teamMembers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TeamMemberCell", for: indexPath) as! TeamMemberCell
        let member = teamMembers[indexPath.row]
        
        cell.configure(with: member, isSelected: selectedOpponent?.userId == member.userId)
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedOpponent = teamMembers[indexPath.row]
        tableView.reloadData()
        
        print("🥊 CreateChallengeViewController: Opponent selected - \(selectedOpponent?.profile.username ?? "Unknown")")
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

// MARK: - Team Member Cell

class TeamMemberCell: UITableViewCell {
    
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let usernameLabel = UILabel()
    private let selectionIndicator = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        contentView.backgroundColor = .clear
        
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.layer.masksToBounds = true
        avatarImageView.backgroundColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = IndustrialDesign.Colors.primaryText
        
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        usernameLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        usernameLabel.textColor = IndustrialDesign.Colors.secondaryText
        
        selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        selectionIndicator.layer.cornerRadius = 10
        selectionIndicator.backgroundColor = IndustrialDesign.Colors.bitcoin
        selectionIndicator.isHidden = true
        
        [avatarImageView, nameLabel, usernameLabel, selectionIndicator].forEach {
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: selectionIndicator.leadingAnchor, constant: -8),
            
            usernameLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            usernameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            usernameLabel.trailingAnchor.constraint(lessThanOrEqualTo: selectionIndicator.leadingAnchor, constant: -8),
            usernameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            selectionIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            selectionIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            selectionIndicator.widthAnchor.constraint(equalToConstant: 20),
            selectionIndicator.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func configure(with member: TeamMemberWithProfile, isSelected: Bool) {
        nameLabel.text = member.profile.fullName ?? "Unknown"
        usernameLabel.text = "@\(member.profile.username ?? "user")"
        selectionIndicator.isHidden = !isSelected
        
        // Load avatar if available
        if let avatarUrl = member.profile.avatarUrl, let url = URL(string: avatarUrl) {
            // Load image asynchronously
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    await MainActor.run {
                        avatarImageView.image = UIImage(data: data)
                    }
                } catch {
                    print("Failed to load avatar: \(error)")
                }
            }
        } else {
            // Use initials as fallback
            avatarImageView.image = nil
            avatarImageView.backgroundColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        }
    }
}