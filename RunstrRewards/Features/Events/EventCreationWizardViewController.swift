import UIKit
import HealthKit

class EventCreationWizardViewController: UIViewController {
    
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
    private let totalSteps = 4
    
    // Event data being collected
    private var eventData = EventCreationData()
    
    // Team context for event creation
    private let teamData: TeamData
    
    // Step view controllers
    private var stepViewControllers: [UIViewController] = []
    private var currentStepViewController: UIViewController?
    
    // Completion handler
    var onCompletion: ((Bool, EventCreationData?) -> Void)?
    
    // MARK: - Initialization
    
    init(teamData: TeamData) {
        self.teamData = teamData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("📅 EventCreationWizard: Starting event creation wizard for team: \(teamData.name)")
        
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
        
        print("📅 EventCreationWizard: Wizard initialized successfully")
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
        
        // Cancel button
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        
        // Title
        titleLabel.text = "Create Event"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Step label
        stepLabel.text = "Step 1 of \(totalSteps)"
        stepLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        stepLabel.textColor = IndustrialDesign.Colors.secondaryText
        stepLabel.textAlignment = .center
        stepLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(cancelButton)
        headerView.addSubview(titleLabel)
        headerView.addSubview(stepLabel)
        contentView.addSubview(headerView)
    }
    
    private func setupProgressView() {
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = IndustrialDesign.Colors.bitcoin
        progressView.trackTintColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0)
        progressView.layer.cornerRadius = 2
        progressView.layer.masksToBounds = true
        
        contentView.addSubview(progressView)
    }
    
    private func setupStepContainer() {
        stepContainer.translatesAutoresizingMaskIntoConstraints = false
        stepContainer.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        stepContainer.layer.cornerRadius = 12
        stepContainer.layer.borderWidth = 1
        stepContainer.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        contentView.addSubview(stepContainer)
        
        // Add bolt decoration to step container
        DispatchQueue.main.async {
            self.addBoltDecoration()
        }
    }
    
    private func addBoltDecoration() {
        // Add bolt decoration to match app theme
        let boltView = UIImageView(image: UIImage(systemName: "bolt.fill"))
        boltView.tintColor = IndustrialDesign.Colors.bitcoin
        boltView.contentMode = .scaleAspectFit
        boltView.translatesAutoresizingMaskIntoConstraints = false
        stepContainer.addSubview(boltView)
        
        NSLayoutConstraint.activate([
            boltView.topAnchor.constraint(equalTo: stepContainer.topAnchor, constant: 8),
            boltView.trailingAnchor.constraint(equalTo: stepContainer.trailingAnchor, constant: -8),
            boltView.widthAnchor.constraint(equalToConstant: 16),
            boltView.heightAnchor.constraint(equalToConstant: 16)
        ])
    }
    
    private func setupNavigationButtons() {
        navigationContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Back button
        backButton.setTitle("Back", for: .normal)
        backButton.setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        backButton.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        backButton.layer.cornerRadius = 12
        backButton.layer.borderWidth = 1
        backButton.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.isEnabled = false
        backButton.alpha = 0.6
        
        // Next button
        nextButton.setTitle("Next", for: .normal)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        nextButton.backgroundColor = IndustrialDesign.Colors.bitcoin
        nextButton.layer.cornerRadius = 12
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        
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
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            cancelButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            cancelButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor),
            
            stepLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            stepLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            
            // Progress view
            progressView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            progressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            progressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            
            // Step container
            stepContainer.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 24),
            stepContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stepContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            stepContainer.heightAnchor.constraint(equalToConstant: 400),
            
            // Navigation container
            navigationContainer.topAnchor.constraint(equalTo: stepContainer.bottomAnchor, constant: 24),
            navigationContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            navigationContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            navigationContainer.heightAnchor.constraint(equalToConstant: 56),
            navigationContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            
            // Navigation buttons
            backButton.leadingAnchor.constraint(equalTo: navigationContainer.leadingAnchor),
            backButton.topAnchor.constraint(equalTo: navigationContainer.topAnchor),
            backButton.bottomAnchor.constraint(equalTo: navigationContainer.bottomAnchor),
            backButton.widthAnchor.constraint(equalTo: navigationContainer.widthAnchor, multiplier: 0.45),
            
            nextButton.trailingAnchor.constraint(equalTo: navigationContainer.trailingAnchor),
            nextButton.topAnchor.constraint(equalTo: navigationContainer.topAnchor),
            nextButton.bottomAnchor.constraint(equalTo: navigationContainer.bottomAnchor),
            nextButton.widthAnchor.constraint(equalTo: navigationContainer.widthAnchor, multiplier: 0.45)
        ])
    }
    
    private func setupStepViewControllers() {
        stepViewControllers = [
            EventBasicInfoStepViewController(eventData: eventData, teamData: teamData),
            EventMetricsStepViewController(eventData: eventData),
            EventScheduleStepViewController(eventData: eventData),
            EventReviewStepViewController(eventData: eventData, teamData: teamData)
        ]
    }
    
    // MARK: - Step Navigation
    
    private func showStep(_ step: Int) {
        guard step >= 0 && step < stepViewControllers.count else { return }
        
        // Remove current step view controller
        if let currentVC = currentStepViewController {
            currentVC.willMove(toParent: nil)
            currentVC.view.removeFromSuperview()
            currentVC.removeFromParent()
        }
        
        // Add new step view controller
        let stepVC = stepViewControllers[step]
        addChild(stepVC)
        stepVC.view.translatesAutoresizingMaskIntoConstraints = false
        stepContainer.addSubview(stepVC.view)
        
        NSLayoutConstraint.activate([
            stepVC.view.topAnchor.constraint(equalTo: stepContainer.topAnchor, constant: 20),
            stepVC.view.leadingAnchor.constraint(equalTo: stepContainer.leadingAnchor, constant: 20),
            stepVC.view.trailingAnchor.constraint(equalTo: stepContainer.trailingAnchor, constant: -20),
            stepVC.view.bottomAnchor.constraint(equalTo: stepContainer.bottomAnchor, constant: -20)
        ])
        
        stepVC.didMove(toParent: self)
        currentStepViewController = stepVC
        
        // Update UI for current step
        updateUIForStep(step)
        
        print("📅 EventCreationWizard: Showing step \(step + 1)")
    }
    
    private func updateUIForStep(_ step: Int) {
        currentStep = step
        
        // Update step label
        stepLabel.text = "Step \(step + 1) of \(totalSteps)"
        
        // Update progress
        let progress = Float(step) / Float(totalSteps - 1)
        progressView.setProgress(progress, animated: true)
        
        // Update navigation buttons
        backButton.isEnabled = step > 0
        backButton.alpha = step > 0 ? 1.0 : 0.6
        
        // Update next button text for last step
        if step == totalSteps - 1 {
            nextButton.setTitle("Create Event", for: .normal)
            nextButton.backgroundColor = IndustrialDesign.Colors.bitcoin // Bitcoin orange for all actions
        } else {
            nextButton.setTitle("Next", for: .normal)
            nextButton.backgroundColor = IndustrialDesign.Colors.bitcoin
        }
    }
    
    // MARK: - Actions
    
    @objc private func cancelButtonTapped() {
        print("📅 EventCreationWizard: Cancel button tapped")
        
        let alert = UIAlertController(
            title: "Cancel Event Creation?",
            message: "Your progress will be lost if you cancel now.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Keep Editing", style: .cancel))
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive) { _ in
            self.onCompletion?(false, nil)
        })
        
        present(alert, animated: true)
    }
    
    @objc private func backButtonTapped() {
        guard currentStep > 0 else { return }
        
        print("📅 EventCreationWizard: Back button tapped - going to step \(currentStep - 1)")
        showStep(currentStep - 1)
    }
    
    @objc private func nextButtonTapped() {
        print("📅 EventCreationWizard: Next button tapped from step \(currentStep)")
        
        // Validate current step
        if validateCurrentStep() {
            if currentStep < totalSteps - 1 {
                // Go to next step
                showStep(currentStep + 1)
            } else {
                // Final step - create the event
                createEvent()
            }
        }
    }
    
    private func validateCurrentStep() -> Bool {
        // Validation logic for each step
        switch currentStep {
        case 0: // Basic info
            return !eventData.eventName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 1: // Metrics
            return !eventData.selectedMetrics.isEmpty
        case 2: // Schedule
            return eventData.startDate != nil && eventData.endDate != nil
        case 3: // Review
            return true
        default:
            return false
        }
    }
    
    private func createEvent() {
        print("📅 EventCreationWizard: Creating event with data: \(eventData.eventName)")
        
        Task {
            do {
                // Create CompetitionEvent from wizard data
                let event = CompetitionEvent(
                    id: UUID().uuidString,
                    name: eventData.eventName,
                    description: eventData.description.isEmpty ? nil : eventData.description,
                    type: eventData.eventType.rawValue,
                    targetValue: eventData.targetValue ?? 0.0,
                    unit: eventData.targetUnit.isEmpty ? "distance" : eventData.targetUnit,
                    entryFee: Int(eventData.entryFee * 100), // Convert to satoshis
                    prizePool: Int(eventData.prizePool * 100), // Convert to satoshis
                    startDate: eventData.startDate ?? Date(),
                    endDate: eventData.endDate ?? Date().addingTimeInterval(86400 * 7), // 1 week default
                    maxParticipants: eventData.maxParticipants,
                    participantCount: 0,
                    status: "active",
                    imageUrl: nil,
                    createdAt: Date()
                )
                
                // Create event in Supabase
                let createdEvent = try await SupabaseService.shared.createEvent(event)
                
                DispatchQueue.main.async {
                    let alert = UIAlertController(
                        title: "Event Created! 🎉",
                        message: "Your event '\(createdEvent.name)' has been created successfully and is now live.",
                        preferredStyle: .alert
                    )
                    
                    alert.addAction(UIAlertAction(title: "Done", style: .default) { _ in
                        self.onCompletion?(true, self.eventData)
                    })
                    
                    self.present(alert, animated: true)
                }
                
            } catch {
                print("📅 EventCreationWizard: Failed to create event: \(error)")
                
                DispatchQueue.main.async {
                    let alert = UIAlertController(
                        title: "Event Creation Failed",
                        message: "Sorry, we couldn't create your event. Please try again.",
                        preferredStyle: .alert
                    )
                    
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
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

// MARK: - Event Creation Data Model

class EventCreationData: ObservableObject {
    @Published var eventName: String = ""
    @Published var description: String = ""
    @Published var eventType: EventType = .challenge
    @Published var selectedMetrics: [String] = []
    @Published var startDate: Date?
    @Published var endDate: Date?
    @Published var entryFee: Double = 0.0
    @Published var prizePool: Double = 0.0
    @Published var maxParticipants: Int?
    @Published var isPublic: Bool = true
    
    // Event-specific settings
    @Published var targetValue: Double?
    @Published var targetUnit: String = ""
    @Published var requiresRegistration: Bool = true
}

// MARK: - Event Types

enum EventType: String, CaseIterable {
    case challenge = "challenge"
    case competition = "competition"
    case marathon = "marathon"
    case sprint = "sprint"
    
    var displayName: String {
        switch self {
        case .challenge:
            return "Challenge"
        case .competition:
            return "Competition"
        case .marathon:
            return "Marathon"
        case .sprint:
            return "Sprint"
        }
    }
    
    var description: String {
        switch self {
        case .challenge:
            return "Long-term fitness challenge with flexible goals"
        case .competition:
            return "Head-to-head competition with rankings"
        case .marathon:
            return "Endurance-focused event over extended period"
        case .sprint:
            return "Short, intense burst of activity"
        }
    }
}