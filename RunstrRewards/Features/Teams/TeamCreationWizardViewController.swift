import UIKit
import HealthKit

class TeamCreationWizardViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header
    private let headerView = UIView()
    private let cancelButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    private let stepLabel = UILabel()
    
    // Progress indicator
    private let progressView = UIProgressView()
    
    // Step content container
    private let stepContainer = UIView()
    
    // Navigation buttons
    private let navigationContainer = UIView()
    private let backButton = UIButton(type: .custom)
    private let nextButton = UIButton(type: .custom)
    
    // MARK: - Wizard State
    private var currentStep = 0
    private let totalSteps = 4 // TODO: Change to 5 after adding wallet step via Xcode
    
    // Team data being collected
    private var teamData = TeamCreationData()
    
    // Step view controllers
    private var stepViewControllers: [UIViewController] = []
    private var currentStepViewController: UIViewController?
    
    // Completion handler
    var onCompletion: ((Bool) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🧙‍♂️ TeamCreationWizard: Starting team creation wizard")
        
        // Configure modal presentation for better text input compatibility
        configureModalPresentation()
        
        setupIndustrialBackground()
        setupScrollView()
        setupHeader()
        setupProgressView()
        setupStepContainer()
        setupNavigationButtons()
        setupConstraints()
        
        // Initialize step view controllers
        setupStepViewControllers()
        
        // Show first step
        showStep(0)
        
        print("🧙‍♂️ TeamCreationWizard: Wizard initialized successfully")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Ensure proper input session establishment after view is fully presented
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.configureWizardInputSessions()
        }
        
        print("🧙‍♂️ TeamCreationWizard: Wizard appeared, configuring input system")
    }
    
    // MARK: - Setup Methods
    
    private func configureModalPresentation() {
        // Ensure proper modal presentation configuration for text input compatibility
        modalPresentationCapturesStatusBarAppearance = true
        
        // Configure for full screen to avoid input session conflicts
        if let navigationController = navigationController {
            navigationController.modalPresentationStyle = .fullScreen
            navigationController.modalTransitionStyle = .coverVertical
        }
        
        print("🧙‍♂️ TeamCreationWizard: Modal presentation configured for text input compatibility")
    }
    
    private func configureWizardInputSessions() {
        print("🧙‍♂️ TeamCreationWizard: Configuring wizard-level input sessions")
        
        // Ensure the current step's input sessions are properly configured
        if currentStepViewController is TeamBasicInfoStepViewController {
            // The step view controller will handle its own input session configuration
            print("🧙‍♂️ TeamCreationWizard: Current step is basic info - input sessions will be configured by step")
        }
        
        print("🧙‍♂️ TeamCreationWizard: Wizard input sessions configured")
    }
    
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
        
        // Add gear decoration
        let gear = RotatingGearView(size: 120)
        gear.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gear)
        
        NSLayoutConstraint.activate([
            gear.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            gear.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 30),
            gear.widthAnchor.constraint(equalToConstant: 120),
            gear.heightAnchor.constraint(equalToConstant: 120)
        ])
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 0.95)
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false // Allow other touches to work
        scrollView.addGestureRecognizer(tapGesture)
        
        // Set up keyboard observers for better scrolling
        setupKeyboardObservers()
    }
    
    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        
        // Cancel button
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        // Title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Create Your Team"
        titleLabel.font = IndustrialDesign.Typography.navTitleFont
        titleLabel.textAlignment = .center
        
        // Step indicator
        stepLabel.translatesAutoresizingMaskIntoConstraints = false
        stepLabel.text = "Step 1 of \(totalSteps)"
        stepLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        stepLabel.textColor = IndustrialDesign.Colors.secondaryText
        stepLabel.textAlignment = .center
        
        headerView.addSubview(cancelButton)
        headerView.addSubview(titleLabel)
        headerView.addSubview(stepLabel)
        contentView.addSubview(headerView)
        
        // Add gradient to title
        DispatchQueue.main.async {
            self.applyGradientToLabel(self.titleLabel)
        }
    }
    
    private func setupProgressView() {
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0) // Bitcoin orange
        progressView.trackTintColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        progressView.layer.cornerRadius = 2
        progressView.clipsToBounds = true
        
        contentView.addSubview(progressView)
    }
    
    private func setupStepContainer() {
        stepContainer.translatesAutoresizingMaskIntoConstraints = false
        stepContainer.backgroundColor = UIColor.clear
        
        contentView.addSubview(stepContainer)
    }
    
    private func setupNavigationButtons() {
        navigationContainer.translatesAutoresizingMaskIntoConstraints = false
        navigationContainer.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        
        // Back button
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setTitle("Back", for: .normal)
        backButton.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        backButton.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        backButton.layer.cornerRadius = 8
        backButton.layer.borderWidth = 1
        backButton.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backButton.isEnabled = false
        
        // Next button
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.setTitle("Next", for: .normal)
        nextButton.setTitleColor(UIColor.white, for: .normal)
        nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        nextButton.backgroundColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        nextButton.layer.cornerRadius = 8
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        
        navigationContainer.addSubview(backButton)
        navigationContainer.addSubview(nextButton)
        contentView.addSubview(navigationContainer)
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
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 100),
            
            // Header elements
            cancelButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: IndustrialDesign.Spacing.xLarge),
            cancelButton.topAnchor.constraint(equalTo: headerView.topAnchor, constant: IndustrialDesign.Spacing.medium),
            
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: IndustrialDesign.Spacing.medium),
            
            stepLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            stepLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            
            // Progress view
            progressView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: IndustrialDesign.Spacing.medium),
            progressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: IndustrialDesign.Spacing.xLarge),
            progressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -IndustrialDesign.Spacing.xLarge),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            
            // Step container
            stepContainer.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: IndustrialDesign.Spacing.xLarge),
            stepContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stepContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stepContainer.bottomAnchor.constraint(equalTo: navigationContainer.topAnchor),
            stepContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 400),
            
            // Navigation container
            navigationContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            navigationContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            navigationContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            navigationContainer.heightAnchor.constraint(equalToConstant: 100),
            
            // Navigation buttons
            backButton.leadingAnchor.constraint(equalTo: navigationContainer.leadingAnchor, constant: IndustrialDesign.Spacing.xLarge),
            backButton.centerYAnchor.constraint(equalTo: navigationContainer.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 100),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            nextButton.trailingAnchor.constraint(equalTo: navigationContainer.trailingAnchor, constant: -IndustrialDesign.Spacing.xLarge),
            nextButton.centerYAnchor.constraint(equalTo: navigationContainer.centerYAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 100),
            nextButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupStepViewControllers() {
        stepViewControllers = [
            TeamBasicInfoStepViewController(teamData: teamData),
            TeamMetricSelectionStepViewController(teamData: teamData),
            TeamLeaderboardSetupStepViewController(teamData: teamData),
            TeamWalletSetupStepViewController(teamData: teamData),
            TeamReviewStepViewController(teamData: teamData)
        ]
    }
    
    // MARK: - Step Navigation
    
    private func showStep(_ step: Int) {
        guard step >= 0 && step < stepViewControllers.count else { 
            print("🧙‍♂️ TeamCreationWizard: ERROR - Invalid step: \(step), total steps: \(stepViewControllers.count)")
            return 
        }
        
        print("🧙‍♂️ TeamCreationWizard: Transitioning to step \(step + 1) of \(totalSteps)")
        
        // Remove current step view controller
        if let currentVC = currentStepViewController {
            print("🧙‍♂️ TeamCreationWizard: Removing current step: \(type(of: currentVC))")
            currentVC.willMove(toParent: nil)
            currentVC.view.removeFromSuperview()
            currentVC.removeFromParent()
        }
        
        // Add new step view controller
        let newVC = stepViewControllers[step]
        print("🧙‍♂️ TeamCreationWizard: Adding new step: \(type(of: newVC))")
        
        addChild(newVC)
        stepContainer.addSubview(newVC.view)
        newVC.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            newVC.view.topAnchor.constraint(equalTo: stepContainer.topAnchor),
            newVC.view.leadingAnchor.constraint(equalTo: stepContainer.leadingAnchor),
            newVC.view.trailingAnchor.constraint(equalTo: stepContainer.trailingAnchor),
            newVC.view.bottomAnchor.constraint(equalTo: stepContainer.bottomAnchor)
        ])
        
        newVC.didMove(toParent: self)
        currentStepViewController = newVC
        currentStep = step
        
        // Update UI
        updateProgressAndLabels()
        updateNavigationButtons()
        
        print("🧙‍♂️ TeamCreationWizard: Successfully showing step \(step + 1) - \(type(of: newVC))")
        
        // Force layout update to ensure UI is visible
        DispatchQueue.main.async {
            self.stepContainer.setNeedsLayout()
            self.stepContainer.layoutIfNeeded()
            newVC.view.setNeedsLayout()
            newVC.view.layoutIfNeeded()
            print("🧙‍♂️ TeamCreationWizard: Forced layout update for step \(step + 1)")
            print("🧙‍♂️ TeamCreationWizard: StepContainer frame: \(self.stepContainer.frame)")
            print("🧙‍♂️ TeamCreationWizard: ChildView frame: \(newVC.view.frame)")
        }
    }
    
    private func updateProgressAndLabels() {
        let progress = Float(currentStep + 1) / Float(totalSteps)
        progressView.setProgress(progress, animated: true)
        stepLabel.text = "Step \(currentStep + 1) of \(totalSteps)"
    }
    
    private func updateNavigationButtons() {
        backButton.isEnabled = currentStep > 0
        
        if currentStep == totalSteps - 1 {
            nextButton.setTitle("Create Team", for: .normal)
            nextButton.backgroundColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0) // Bitcoin orange for consistency
        } else {
            nextButton.setTitle("Next", for: .normal)
            nextButton.backgroundColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0) // Bitcoin orange
        }
    }
    
    // MARK: - Actions
    
    @objc private func cancelTapped() {
        print("🧙‍♂️ TeamCreationWizard: User cancelled team creation")
        
        let alert = UIAlertController(
            title: "Cancel Team Creation?",
            message: "Your progress will be lost. Are you sure you want to cancel?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Keep Editing", style: .cancel))
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive) { _ in
            self.onCompletion?(false)
            self.dismiss(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    @objc private func backTapped() {
        guard currentStep > 0 else { return }
        showStep(currentStep - 1)
    }
    
    @objc private func nextTapped() {
        if currentStep == totalSteps - 1 {
            // Final step - create the team
            createTeam()
        } else {
            // Validate current step and move to next
            if validateCurrentStep() {
                showStep(currentStep + 1)
            }
        }
    }
    
    private func validateCurrentStep() -> Bool {
        switch currentStep {
        case 0: // Basic Info Step
            let name = teamData.teamName.trimmingCharacters(in: .whitespacesAndNewlines)
            if name.isEmpty {
                showValidationError("Please enter a team name")
                return false
            }
            if name.count < 3 {
                showValidationError("Team name must be at least 3 characters")
                return false
            }
            return true
            
        case 1: // Metrics Step
            if teamData.selectedMetrics.isEmpty {
                showValidationError("Please select at least one fitness metric to track")
                return false
            }
            return true
            
        case 2: // Leaderboard Step
            // Leaderboard type and period have default values, so always valid
            return true
            
        case 3: // Wallet Setup Step
            if !teamData.isWalletReady {
                showValidationError("Please wait for the Bitcoin wallet to be ready before proceeding")
                return false
            }
            return true
            
        case 4: // Review Step
            return true
            
        default:
            return true
        }
    }
    
    private func showValidationError(_ message: String) {
        let alert = UIAlertController(
            title: "Please Complete This Step",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func createTeam() {
        print("🧙‍♂️ TeamCreationWizard: Creating team with data: \(teamData.teamName)")
        
        Task {
            do {
                // Check captain subscription status
                let subscriptionStatus = await SubscriptionService.shared.checkSubscriptionStatus()
                
                // Only enforce subscription in production mode
                if !SubscriptionService.DEVELOPMENT_MODE {
                    guard subscriptionStatus == .captain else {
                        throw NSError(domain: "TeamCreation", code: 1004, userInfo: [
                            NSLocalizedDescriptionKey: "Captain subscription required to create teams"
                        ])
                    }
                    
                    // Check if captain already has a team
                    let hasExistingTeam = try await SubscriptionService.shared.hasExistingTeamAsync()
                    if hasExistingTeam {
                        throw NSError(domain: "TeamCreation", code: 1005, userInfo: [
                            NSLocalizedDescriptionKey: "You can only create one team per captain subscription"
                        ])
                    }
                } else {
                    print("🧙‍♂️ TeamCreationWizard: DEVELOPMENT MODE - Bypassing subscription checks")
                }
                
                // Show loading state
                await MainActor.run {
                    nextButton.isEnabled = false
                    nextButton.setTitle("Creating...", for: .normal)
                }
                
                // Clear any temporary token sessions first
                AuthenticationService.shared.clearTemporaryTokenSessions()
                
                // Get current user ID and ensure Supabase authentication
                guard let userSession = AuthenticationService.shared.loadSession() else {
                    print("TeamCreation: No user session found")
                    throw NSError(domain: "TeamCreation", code: 1001, userInfo: [NSLocalizedDescriptionKey: "You must be logged in to create a team"])
                }
                
                print("TeamCreation: Found user session with tokens - access: \(userSession.accessToken.prefix(10))..., refresh: \(userSession.refreshToken.prefix(10))...")
                
                // Explicitly restore Supabase session if we have real tokens
                if userSession.accessToken != "temp_token" && userSession.refreshToken != "temp_refresh_token" {
                    do {
                        try await SupabaseService.shared.restoreSession(accessToken: userSession.accessToken, refreshToken: userSession.refreshToken)
                        print("TeamCreation: Successfully restored Supabase session")
                    } catch {
                        print("TeamCreation: Failed to restore Supabase session: \(error)")
                        throw NSError(domain: "TeamCreation", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Session expired. Please sign in again to create a team."])
                    }
                }
                
                // Ensure Supabase has a valid session - critical for row-level security
                let currentSupabaseUser = try await SupabaseService.shared.getCurrentUser()
                if currentSupabaseUser == nil {
                    throw NSError(domain: "TeamCreation", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Session expired. Please sign in again to create a team."])
                }
                
                // Validate required fields
                guard !teamData.teamName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw NSError(domain: "TeamCreation", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Team name is required"])
                }
                
                // Validate wallet readiness - CRITICAL requirement
                guard teamData.isWalletReady else {
                    throw NSError(domain: "TeamCreation", code: 1006, userInfo: [NSLocalizedDescriptionKey: "Bitcoin wallet setup is required. Please wait for wallet to be ready before creating team."])
                }
                
                // Generate team ID first (needed for wallet creation)
                let teamId = UUID().uuidString
                
                // Create team wallet FIRST (this is the critical step that can fail)
                print("🧙‍♂️ TeamCreationWizard: Creating team wallet first...")
                let teamWallet = try await TeamWalletManager.shared.createTeamWallet(
                    for: teamId,
                    captainId: userSession.id
                )
                print("🧙‍♂️ TeamCreationWizard: Team wallet created successfully with ID: \(teamWallet.id)")
                
                // Only create team in database AFTER wallet succeeds
                let newTeam = Team(
                    id: teamId,
                    name: teamData.teamName.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: teamData.description.isEmpty ? nil : teamData.description,
                    captainId: userSession.id,
                    memberCount: 1, // Start with 1 member (the creator)
                    maxMembers: 50, // Default team size limit
                    totalEarnings: 0.0,
                    imageUrl: nil,
                    selectedMetrics: teamData.selectedMetrics,
                    createdAt: Date()
                )
                let team = try await SupabaseService.shared.createTeam(newTeam)
                
                print("🧙‍♂️ TeamCreationWizard: Team created successfully with ID: \(team.id)")
                
                await MainActor.run {
                    // Show success and dismiss
                    let successAlert = UIAlertController(
                        title: "Team Created Successfully! 🎉",
                        message: "Your team '\(teamData.teamName)' is now live with a Bitcoin wallet! Start sharing your QR code to get members and fund your team's prize pool.",
                        preferredStyle: .alert
                    )
                    
                    successAlert.addAction(UIAlertAction(title: "Done", style: .default) { _ in
                        self.onCompletion?(true)
                        self.dismiss(animated: true)
                    })
                    
                    self.present(successAlert, animated: true)
                }
                
            } catch {
                await MainActor.run {
                    nextButton.isEnabled = true
                    nextButton.setTitle("Create Team", for: .normal)
                    
                    let errorAlert = UIAlertController(
                        title: "Team Creation Failed",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(errorAlert, animated: true)
                }
            }
        }
    }
    
    private func applyGradientToLabel(_ label: UILabel) {
        let gradient = CAGradientLayer.logo()
        gradient.frame = label.bounds
        
        let gradientColor = UIColor { _ in
            return UIColor.white
        }
        label.textColor = gradientColor
        
        let maskLayer = CATextLayer()
        maskLayer.string = label.text
        maskLayer.font = label.font
        maskLayer.fontSize = label.font.pointSize
        maskLayer.frame = label.bounds
        maskLayer.alignmentMode = .center
        maskLayer.foregroundColor = UIColor.black.cgColor
        
        gradient.mask = maskLayer
        label.layer.addSublayer(gradient)
    }
    
    // MARK: - Keyboard Management
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        // Adjust scroll view bottom inset to keep navigation buttons accessible
        let keyboardHeight = keyboardFrame.height
        
        UIView.animate(withDuration: animationDuration) {
            self.scrollView.contentInset.bottom = keyboardHeight
            self.scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        UIView.animate(withDuration: animationDuration) {
            self.scrollView.contentInset.bottom = 0
            self.scrollView.verticalScrollIndicatorInsets.bottom = 0
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Team Creation Data Model

class TeamCreationData: ObservableObject {
    @Published var teamName: String = ""
    @Published var description: String = ""
    @Published var selectedMetrics: [String] = ["running"] // Pre-select running to ensure UI has content
    @Published var leaderboardType: TeamLeaderboardType = .distance
    @Published var leaderboardPeriod: LeaderboardPeriod = .weekly
    @Published var speedRankingDistance: SpeedRankingDistance = .fiveK
    @Published var customSpeedDistance: Double = 5.0 // kilometers
    @Published var isWalletReady: Bool = false
    
    init() {
        print("🧙‍♂️ TeamCreationData: Initialized with defaults - metrics: \(selectedMetrics)")
    }
}

enum TeamLeaderboardType: String, CaseIterable {
    case distance = "distance"
    case workoutCount = "workout_count"
    case streaks = "streaks"
    case speedRankings = "speed_rankings"
    
    var displayName: String {
        switch self {
        case .distance: return "Total Distance"
        case .workoutCount: return "Workout Count"
        case .streaks: return "Workout Streaks"
        case .speedRankings: return "Speed Rankings"
        }
    }
    
    var icon: String {
        switch self {
        case .distance: return "location.fill"
        case .workoutCount: return "figure.run"
        case .streaks: return "flame.fill"
        case .speedRankings: return "stopwatch.fill"
        }
    }
    
    var description: String {
        switch self {
        case .distance: return "Rank by total distance covered across all workouts"
        case .workoutCount: return "Rank by number of completed workouts"
        case .streaks: return "Rank by longest consecutive workout streaks"
        case .speedRankings: return "Rank by fastest single effort (5K, 10K, custom distance)"
        }
    }
}

enum LeaderboardPeriod: String, CaseIterable {
    case daily = "daily"
    case weekly = "weekly" 
    case monthly = "monthly"
    case allTime = "all_time"
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .allTime: return "All-Time"
        }
    }
}

enum SpeedRankingDistance: String, CaseIterable {
    case fiveK = "5K"
    case tenK = "10K"
    case halfMarathon = "half_marathon"
    case marathon = "marathon"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .fiveK: return "5K"
        case .tenK: return "10K"
        case .halfMarathon: return "Half Marathon"
        case .marathon: return "Marathon"
        case .custom: return "Custom Distance"
        }
    }
    
    var distanceInKm: Double {
        switch self {
        case .fiveK: return 5.0
        case .tenK: return 10.0
        case .halfMarathon: return 21.1
        case .marathon: return 42.2
        case .custom: return 0.0 // Will use customSpeedDistance
        }
    }
}