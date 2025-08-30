import UIKit

// MARK: - Challenge Constants

struct ChallengeConstants {
    struct Stakes {
        static let minimumAmount = 100 // satoshis
        static let maximumAmount = 100_000 // satoshis
        static let defaultAmount = 100 // satoshis
        static let presetAmounts = [100, 500, 1000, 5000] // satoshis
    }
    
    struct TeamFees {
        static let minimumPercentage = 5
        static let maximumPercentage = 20
        static let defaultPercentage = 10
    }
    
    struct UI {
        static let modalCornerRadius: CGFloat = 16
        static let cardCornerRadius: CGFloat = 12
        static let buttonCornerRadius: CGFloat = 8
        static let borderWidth: CGFloat = 1
        static let animationDuration: TimeInterval = 0.3
    }
}

// MARK: - Challenge Type Enum

enum ChallengeType: String, CaseIterable {
    case fiveK = "5k_race"
    case tenK = "10k_race"
    case weeklyMiles = "weekly_miles"
    case dailyStreak = "daily_streak"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .fiveK:
            return "5K Race"
        case .tenK:
            return "10K Race"
        case .weeklyMiles:
            return "Weekly Miles"
        case .dailyStreak:
            return "Daily Streak"
        case .custom:
            return "Custom Challenge"
        }
    }
    
    var description: String {
        switch self {
        case .fiveK:
            return "Fastest 5K time wins"
        case .tenK:
            return "Fastest 10K time wins"
        case .weeklyMiles:
            return "Most distance this week"
        case .dailyStreak:
            return "Most consecutive days"
        case .custom:
            return "Set your own rules"
        }
    }
    
    var defaultDuration: TimeInterval {
        switch self {
        case .fiveK, .tenK:
            return 24 * 60 * 60 // 24 hours
        case .weeklyMiles:
            return 7 * 24 * 60 * 60 // 1 week
        case .dailyStreak:
            return 30 * 24 * 60 * 60 // 30 days
        case .custom:
            return 7 * 24 * 60 * 60 // 1 week default
        }
    }
}

// MARK: - Challenge Creation Data

class ChallengeCreationData {
    var selectedOpponents: [TeamMemberWithProfile] = []
    var challengeType: ChallengeType = .fiveK
    var stakeAmount: Int = 0 // in satoshis
    var startDate: Date = Date()
    var endDate: Date = Date().addingTimeInterval(24 * 60 * 60) // Default 24 hours
    var challengeMessage: String = ""
    var teamArbitrationFee: Int = ChallengeConstants.TeamFees.defaultPercentage
    
    var totalStakePerPerson: Int {
        return stakeAmount
    }
    
    var teamFeeAmount: Int {
        let totalPot = stakeAmount * (selectedOpponents.count + 1) // +1 for challenger
        return (totalPot * teamArbitrationFee) / 100
    }
    
    var winnerPayout: Int {
        let totalPot = stakeAmount * (selectedOpponents.count + 1)
        return totalPot - teamFeeAmount
    }
    
    var isValid: Bool {
        // Basic validation: must have opponents selected
        guard !selectedOpponents.isEmpty else { return false }
        
        // Validate stake amount if set
        if stakeAmount > 0 {
            guard stakeAmount >= ChallengeConstants.Stakes.minimumAmount && 
                  stakeAmount <= ChallengeConstants.Stakes.maximumAmount else { return false }
        }
        
        // Validate dates
        guard endDate > startDate else { return false }
        
        // Challenge message is optional, no validation needed
        return true
    }
}

// MARK: - Challenge Creation Errors

enum ChallengeCreationError: Error, LocalizedError {
    case notAuthenticated
    case noOpponentsSelected
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to create a challenge"
        case .noOpponentsSelected:
            return "Please select at least one opponent"
        case .invalidData:
            return "Challenge data is invalid"
        }
    }
}

// MARK: - Challenge Creation Modal

class ChallengeCreationModal: UIViewController {
    
    // MARK: - Properties
    private let teamData: TeamData
    private let challengeData = ChallengeCreationData()
    private var currentStep = 0
    private let totalSteps = 4
    
    // Completion handler
    var onCompletion: ((Bool) -> Void)?
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header
    private let headerView = UIView()
    private let closeButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    private let stepLabel = UILabel()
    
    // Progress indicator
    private let progressView = UIProgressView()
    
    // Content container
    private let stepContainer = UIView()
    
    // Navigation
    private let navigationContainer = UIView()
    private let backButton = UIButton(type: .custom)
    private let nextButton = UIButton(type: .custom)
    
    // Step content views
    private var opponentSelectionView: OpponentSelectionView?
    private var challengeTypeView: ChallengeTypeSelector?
    private var stakesConfigView: StakesConfigurationView?
    private var reviewView: ChallengeReviewView?
    
    // Loading state
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    // MARK: - Initialization
    
    init(teamData: TeamData) {
        self.teamData = teamData
        super.init(nibName: nil, bundle: nil)
        
        // Set modal presentation style
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🏆 ChallengeCreation: Starting challenge creation for team: \(teamData.name)")
        
        setupIndustrialBackground()
        setupScrollView()
        setupHeader()
        setupProgressView()
        setupStepContainer()
        setupNavigationButtons()
        setupLoadingIndicator()
        setupConstraints()
        
        // Show first step
        showStep(0)
        
        print("🏆 ChallengeCreation: Modal initialized successfully")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Animate in
        view.alpha = 0
        view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.view.alpha = 1
            self.view.transform = .identity
        }
    }
    
    // MARK: - Setup Methods
    
    private func setupIndustrialBackground() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        // Main container with industrial theme
        let containerView = UIView()
        containerView.backgroundColor = IndustrialDesign.Colors.background
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 2
        containerView.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(containerView)
        containerView.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            containerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.8),
            
            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
    }
    
    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.9)
        
        // Close button
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = IndustrialDesign.Colors.secondaryText
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        // Title
        titleLabel.text = "Create Challenge"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Step indicator
        stepLabel.text = "Step 1 of \(totalSteps)"
        stepLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        stepLabel.textColor = IndustrialDesign.Colors.secondaryText
        stepLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(closeButton)
        headerView.addSubview(titleLabel)
        headerView.addSubview(stepLabel)
        contentView.addSubview(headerView)
    }
    
    private func setupProgressView() {
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = IndustrialDesign.Colors.bitcoin
        progressView.trackTintColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        progressView.progress = 0.25 // First step
        
        contentView.addSubview(progressView)
    }
    
    private func setupStepContainer() {
        stepContainer.translatesAutoresizingMaskIntoConstraints = false
        stepContainer.backgroundColor = .clear
        contentView.addSubview(stepContainer)
    }
    
    private func setupNavigationButtons() {
        navigationContainer.translatesAutoresizingMaskIntoConstraints = false
        navigationContainer.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.9)
        
        // Back button
        backButton.setTitle("Back", for: .normal)
        backButton.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
        backButton.backgroundColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.6)
        backButton.layer.cornerRadius = 8
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.isHidden = true // Hidden on first step
        
        // Next button
        nextButton.setTitle("Next", for: .normal)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.backgroundColor = IndustrialDesign.Colors.bitcoin
        nextButton.layer.cornerRadius = 8
        nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        nextButton.isEnabled = false
        nextButton.alpha = 0.6
        
        navigationContainer.addSubview(backButton)
        navigationContainer.addSubview(nextButton)
        contentView.addSubview(navigationContainer)
    }
    
    private func setupLoadingIndicator() {
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.color = IndustrialDesign.Colors.bitcoin
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Header
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 80),
            
            closeButton.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),
            
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -16),
            
            stepLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            stepLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            stepLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            // Progress view
            progressView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            progressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            progressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            
            // Step container
            stepContainer.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 20),
            stepContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stepContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Navigation container
            navigationContainer.topAnchor.constraint(equalTo: stepContainer.bottomAnchor, constant: 20),
            navigationContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            navigationContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            navigationContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            navigationContainer.heightAnchor.constraint(equalToConstant: 80),
            
            backButton.leadingAnchor.constraint(equalTo: navigationContainer.leadingAnchor, constant: 20),
            backButton.centerYAnchor.constraint(equalTo: navigationContainer.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 80),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            nextButton.trailingAnchor.constraint(equalTo: navigationContainer.trailingAnchor, constant: -20),
            nextButton.centerYAnchor.constraint(equalTo: navigationContainer.centerYAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 100),
            nextButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Step Management
    
    private func showStep(_ step: Int) {
        currentStep = step
        updateProgressIndicator()
        updateNavigationButtons()
        updateStepContent()
        
        print("🏆 ChallengeCreation: Showing step \(step + 1) of \(totalSteps)")
    }
    
    private func updateProgressIndicator() {
        let progress = Float(currentStep + 1) / Float(totalSteps)
        progressView.setProgress(progress, animated: true)
        stepLabel.text = "Step \(currentStep + 1) of \(totalSteps)"
    }
    
    private func updateNavigationButtons() {
        // Back button visibility
        backButton.isHidden = currentStep == 0
        
        // Next button text and state
        switch currentStep {
        case totalSteps - 1: // Last step
            nextButton.setTitle("Create Challenge", for: .normal)
        default:
            nextButton.setTitle("Next", for: .normal)
        }
        
        // Enable/disable next button based on step validation
        validateCurrentStep()
    }
    
    private func validateCurrentStep() {
        var isValid = false
        
        switch currentStep {
        case 0: // Opponent selection
            isValid = !challengeData.selectedOpponents.isEmpty
        case 1: // Challenge type
            isValid = true // Always valid once type is selected
        case 2: // Stakes configuration
            isValid = true // Optional step
        case 3: // Review
            isValid = challengeData.isValid
        default:
            isValid = false
        }
        
        nextButton.isEnabled = isValid
        nextButton.alpha = isValid ? 1.0 : 0.6
    }
    
    private func updateStepContent() {
        // Clear current step content
        stepContainer.subviews.forEach { $0.removeFromSuperview() }
        
        switch currentStep {
        case 0:
            showOpponentSelection()
        case 1:
            showChallengeTypeSelection()
        case 2:
            showStakesConfiguration()
        case 3:
            showReview()
        default:
            break
        }
    }
    
    // MARK: - Step Content Views
    
    private func showOpponentSelection() {
        let view = OpponentSelectionView(teamData: teamData)
        view.delegate = self
        view.selectedOpponents = challengeData.selectedOpponents
        
        view.translatesAutoresizingMaskIntoConstraints = false
        stepContainer.addSubview(view)
        
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: stepContainer.topAnchor),
            view.leadingAnchor.constraint(equalTo: stepContainer.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: stepContainer.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: stepContainer.bottomAnchor),
            view.heightAnchor.constraint(equalToConstant: 400)
        ])
        
        opponentSelectionView = view
    }
    
    private func showChallengeTypeSelection() {
        let view = ChallengeTypeSelector()
        view.delegate = self
        view.selectedType = challengeData.challengeType
        
        view.translatesAutoresizingMaskIntoConstraints = false
        stepContainer.addSubview(view)
        
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: stepContainer.topAnchor),
            view.leadingAnchor.constraint(equalTo: stepContainer.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: stepContainer.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: stepContainer.bottomAnchor),
            view.heightAnchor.constraint(equalToConstant: 350)
        ])
        
        challengeTypeView = view
    }
    
    private func showStakesConfiguration() {
        let view = StakesConfigurationView()
        view.delegate = self
        view.configure(with: challengeData)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        stepContainer.addSubview(view)
        
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: stepContainer.topAnchor),
            view.leadingAnchor.constraint(equalTo: stepContainer.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: stepContainer.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: stepContainer.bottomAnchor),
            view.heightAnchor.constraint(equalToConstant: 300)
        ])
        
        stakesConfigView = view
    }
    
    private func showReview() {
        let view = ChallengeReviewView()
        view.delegate = self
        view.configure(with: challengeData, teamData: teamData)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        stepContainer.addSubview(view)
        
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: stepContainer.topAnchor),
            view.leadingAnchor.constraint(equalTo: stepContainer.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: stepContainer.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: stepContainer.bottomAnchor),
            view.heightAnchor.constraint(equalToConstant: 450)
        ])
        
        reviewView = view
    }
    
    // MARK: - Actions
    
    @objc private func closeButtonTapped() {
        print("🏆 ChallengeCreation: Close button tapped")
        dismissModal(success: false)
    }
    
    @objc private func backButtonTapped() {
        print("🏆 ChallengeCreation: Back button tapped")
        if currentStep > 0 {
            showStep(currentStep - 1)
        }
    }
    
    @objc private func nextButtonTapped() {
        print("🏆 ChallengeCreation: Next button tapped")
        
        if currentStep < totalSteps - 1 {
            showStep(currentStep + 1)
        } else {
            // Last step - create challenge
            createChallenge()
        }
    }
    
    // MARK: - Challenge Creation
    
    private func createChallenge() {
        print("🏆 ChallengeCreation: Creating challenge...")
        
        loadingIndicator.startAnimating()
        nextButton.isEnabled = false
        
        Task {
            do {
                // Create challenge as a special event type
                let challengeId = try await createChallengeEvent()
                
                // Send notifications to challenged opponents
                try await sendChallengeNotifications(challengeId: challengeId)
                
                await MainActor.run {
                    print("🏆 ChallengeCreation: Challenge created successfully!")
                    loadingIndicator.stopAnimating()
                    dismissModal(success: true)
                }
            } catch {
                print("❌ ChallengeCreation: Failed to create challenge: \(error)")
                await MainActor.run {
                    loadingIndicator.stopAnimating()
                    nextButton.isEnabled = true
                    showAlert(title: "Error", message: "Failed to create challenge. Please try again.")
                }
            }
        }
    }
    
    private func createChallengeEvent() async throws -> String {
        guard let currentUserId = AuthenticationService.shared.currentUserId else {
            throw ChallengeCreationError.notAuthenticated
        }
        
        // Get the first selected opponent (for simplicity in MVP)
        guard let opponent = challengeData.selectedOpponents.first else {
            throw ChallengeCreationError.noOpponentsSelected
        }
        
        // Create the challenge using P2PChallengeService
        let challenge = try await P2PChallengeService.shared.createChallenge(
            from: currentUserId,
            to: opponent.userId,
            type: challengeData.challengeType,
            stakeAmount: challengeData.stakeAmount,
            startDate: challengeData.startDate,
            endDate: challengeData.endDate,
            message: challengeData.challengeMessage.isEmpty ? nil : challengeData.challengeMessage
        )
        
        print("🏆 ChallengeCreation: P2P Challenge created with ID: \(challenge.id)")
        return challenge.id
    }
    
    private func sendChallengeNotifications(challengeId: String) async throws {
        guard let currentUserId = AuthenticationService.shared.currentUserId else {
            print("❌ ChallengeCreation: No current user ID found")
            return
        }
        
        // Use a default username if we can't get the current user's name
        let challengerName = "A team member"
        
        for opponent in challengeData.selectedOpponents {
            let stakeText = challengeData.stakeAmount > 0 ? " for \(challengeData.stakeAmount) sats" : ""
            
            try await NotificationInboxService.shared.storeNotification(
                userId: opponent.userId,
                type: "challenge_request",
                title: "🎯 Challenge Request!",
                body: "\(challengerName) challenged you to a \(challengeData.challengeType.displayName)\(stakeText)",
                teamId: teamData.id,
                fromUserId: currentUserId,
                eventId: challengeId,
                actionData: [
                    "challenge_id": challengeId,
                    "challenger_name": challengerName,
                    "challenge_type": challengeData.challengeType.rawValue,
                    "stake_amount": String(challengeData.stakeAmount),
                    "message": challengeData.challengeMessage,
                    "action": "view_challenge"
                ]
            )
        }
        
        print("🏆 ChallengeCreation: Sent challenge notifications to \(challengeData.selectedOpponents.count) opponents")
    }
    
    // MARK: - Helper Methods
    
    private func dismissModal(success: Bool) {
        UIView.animate(withDuration: 0.3, animations: {
            self.view.alpha = 0
            self.view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            self.dismiss(animated: false) {
                self.onCompletion?(success)
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - OpponentSelectionDelegate

extension ChallengeCreationModal: OpponentSelectionDelegate {
    
    func opponentSelectionDidChange(_ opponents: [TeamMemberWithProfile]) {
        challengeData.selectedOpponents = opponents
        validateCurrentStep()
        
        print("🏆 ChallengeCreation: Selected \(opponents.count) opponents")
    }
}

// MARK: - ChallengeTypeSelectionDelegate

extension ChallengeCreationModal: ChallengeTypeSelectionDelegate {
    
    func challengeTypeDidChange(_ type: ChallengeType) {
        challengeData.challengeType = type
        validateCurrentStep()
        
        print("🏆 ChallengeCreation: Selected challenge type: \(type.displayName)")
    }
    
    func challengeDurationDidChange(startDate: Date, endDate: Date) {
        challengeData.startDate = startDate
        challengeData.endDate = endDate
        validateCurrentStep()
        
        print("🏆 ChallengeCreation: Duration changed: \(startDate) to \(endDate)")
    }
    
    func challengeMessageDidChange(_ message: String) {
        challengeData.challengeMessage = message
        validateCurrentStep()
        
        print("🏆 ChallengeCreation: Message changed: \(message)")
    }
}

// MARK: - StakesConfigurationDelegate

extension ChallengeCreationModal: StakesConfigurationDelegate {
    
    func stakesConfigurationDidChange(amount: Int) {
        challengeData.stakeAmount = amount
        validateCurrentStep()
        
        print("🏆 ChallengeCreation: Stake amount changed: \(amount) sats")
    }
    
    func teamFeePercentageDidChange(percentage: Int) {
        challengeData.teamArbitrationFee = percentage
        validateCurrentStep()
        
        print("🏆 ChallengeCreation: Team fee changed: \(percentage)%")
    }
}

// MARK: - ChallengeReviewDelegate

extension ChallengeCreationModal: ChallengeReviewDelegate {
    
    func challengeReviewDidTapEdit(step: Int) {
        print("🏆 ChallengeCreation: Edit requested for step \(step)")
        showStep(step)
    }
}

