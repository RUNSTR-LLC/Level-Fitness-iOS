import UIKit

class OnboardingViewController: UIViewController {
    
    // MARK: - Properties
    private var currentStep = 0
    private let totalSteps = 3
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Progress indicator
    private let progressView = UIView()
    private let progressBar = UIProgressView(progressViewStyle: .default)
    private let progressLabel = UILabel()
    
    // Content container
    private let contentContainer = UIView()
    private let stepImageView = UIImageView()
    private let stepTitleLabel = UILabel()
    private let stepDescriptionLabel = UILabel()
    
    // Navigation buttons
    private let buttonContainer = UIView()
    private let nextButton = UIButton(type: .custom)
    private let skipButton = UIButton(type: .custom)
    
    // Completion handler
    var onCompletion: (() -> Void)?
    
    // Onboarding steps data
    private let onboardingSteps = [
        OnboardingStep(
            imageName: "person.3.fill",
            title: "Join Fitness Teams",
            description: "Subscribe to teams led by your favorite fitness creators. Compete with like-minded people and stay motivated together.",
            buttonTitle: "Next"
        ),
        OnboardingStep(
            imageName: "chart.bar.fill",
            title: "Sync Your Workouts",
            description: "Connect your existing fitness apps and Apple Health. Your workouts automatically count toward team competitions and personal goals.",
            buttonTitle: "Next"
        ),
        OnboardingStep(
            imageName: "bitcoinsign.circle.fill",
            title: "Earn Bitcoin Rewards",
            description: "Complete challenges, climb leaderboards, and win competitions to earn real Bitcoin rewards. The more you move, the more you earn.",
            buttonTitle: "Get Started"
        )
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🎯 Onboarding: Loading welcome flow")
        
        setupIndustrialBackground()
        setupScrollView()
        setupProgressView()
        setupContent()
        setupButtons()
        setupConstraints()
        
        updateStepContent()
        
        print("🎯 Onboarding: Welcome flow loaded successfully")
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
        
        // Add subtle gear in background
        let backgroundGear = RotatingGearView(size: 150)
        backgroundGear.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundGear)
        
        NSLayoutConstraint.activate([
            backgroundGear.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 75),
            backgroundGear.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 75),
            backgroundGear.widthAnchor.constraint(equalToConstant: 150),
            backgroundGear.heightAnchor.constraint(equalToConstant: 150)
        ])
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isScrollEnabled = false // Disable scrolling for step-by-step flow
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupProgressView() {
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        // Progress bar
        progressBar.progressTintColor = IndustrialDesign.Colors.primaryText
        progressBar.trackTintColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        progressBar.layer.cornerRadius = 2
        progressBar.clipsToBounds = true
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        
        // Progress label
        progressLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        progressLabel.textColor = IndustrialDesign.Colors.secondaryText
        progressLabel.textAlignment = .center
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        
        progressView.addSubview(progressBar)
        progressView.addSubview(progressLabel)
        contentView.addSubview(progressView)
    }
    
    private func setupContent() {
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Step image
        stepImageView.contentMode = .scaleAspectFit
        stepImageView.tintColor = IndustrialDesign.Colors.primaryText
        stepImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Step title
        stepTitleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        stepTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        stepTitleLabel.textAlignment = .center
        stepTitleLabel.numberOfLines = 0
        stepTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Step description
        stepDescriptionLabel.font = UIFont.systemFont(ofSize: 17)
        stepDescriptionLabel.textColor = IndustrialDesign.Colors.secondaryText
        stepDescriptionLabel.textAlignment = .center
        stepDescriptionLabel.numberOfLines = 0
        stepDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentContainer.addSubview(stepImageView)
        contentContainer.addSubview(stepTitleLabel)
        contentContainer.addSubview(stepDescriptionLabel)
        contentView.addSubview(contentContainer)
    }
    
    private func setupButtons() {
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Next/Continue button
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        nextButton.backgroundColor = IndustrialDesign.Colors.cardBackground
        nextButton.layer.cornerRadius = 12
        nextButton.layer.borderWidth = 1
        nextButton.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        
        // Skip button
        skipButton.setTitle("Skip", for: .normal)
        skipButton.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
        skipButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        skipButton.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.6)
        skipButton.layer.cornerRadius = 12
        skipButton.layer.borderWidth = 1
        skipButton.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.addTarget(self, action: #selector(skipButtonTapped), for: .touchUpInside)
        
        buttonContainer.addSubview(nextButton)
        buttonContainer.addSubview(skipButton)
        contentView.addSubview(buttonContainer)
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
            contentView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            
            // Progress view
            progressView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 32),
            progressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            progressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            progressView.heightAnchor.constraint(equalToConstant: 40),
            
            progressBar.topAnchor.constraint(equalTo: progressView.topAnchor),
            progressBar.leadingAnchor.constraint(equalTo: progressView.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: progressView.trailingAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: 4),
            
            progressLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 8),
            progressLabel.centerXAnchor.constraint(equalTo: progressView.centerXAnchor),
            progressLabel.bottomAnchor.constraint(equalTo: progressView.bottomAnchor),
            
            // Content container
            contentContainer.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 60),
            contentContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            contentContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            contentContainer.bottomAnchor.constraint(equalTo: buttonContainer.topAnchor, constant: -60),
            
            // Step image
            stepImageView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            stepImageView.centerXAnchor.constraint(equalTo: contentContainer.centerXAnchor),
            stepImageView.widthAnchor.constraint(equalToConstant: 80),
            stepImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Step title
            stepTitleLabel.topAnchor.constraint(equalTo: stepImageView.bottomAnchor, constant: 32),
            stepTitleLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            stepTitleLabel.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            
            // Step description
            stepDescriptionLabel.topAnchor.constraint(equalTo: stepTitleLabel.bottomAnchor, constant: 16),
            stepDescriptionLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            stepDescriptionLabel.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            
            // Button container
            buttonContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            buttonContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            buttonContainer.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            buttonContainer.heightAnchor.constraint(equalToConstant: 120),
            
            // Next button
            nextButton.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
            nextButton.leadingAnchor.constraint(equalTo: buttonContainer.leadingAnchor),
            nextButton.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor),
            nextButton.heightAnchor.constraint(equalToConstant: 56),
            
            // Skip button
            skipButton.topAnchor.constraint(equalTo: nextButton.bottomAnchor, constant: 12),
            skipButton.leadingAnchor.constraint(equalTo: buttonContainer.leadingAnchor),
            skipButton.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor),
            skipButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    // MARK: - Content Updates
    
    private func updateStepContent() {
        let step = onboardingSteps[currentStep]
        
        // Update progress
        let progress = Float(currentStep + 1) / Float(totalSteps)
        progressBar.setProgress(progress, animated: true)
        progressLabel.text = "Step \(currentStep + 1) of \(totalSteps)"
        
        // Update content with animation
        UIView.transition(with: contentContainer, duration: 0.3, options: .transitionCrossDissolve) {
            self.stepImageView.image = UIImage(systemName: step.imageName)
            self.stepTitleLabel.text = step.title
            self.stepDescriptionLabel.text = step.description
            self.nextButton.setTitle(step.buttonTitle, for: .normal)
        }
        
        // Update button colors for final step
        if currentStep == totalSteps - 1 {
            UIView.animate(withDuration: 0.3) {
                self.nextButton.backgroundColor = IndustrialDesign.Colors.cardBorderHover
                self.nextButton.layer.borderColor = IndustrialDesign.Colors.cardBorderHover.cgColor
            }
        }
        
        print("🎯 Onboarding: Updated to step \(currentStep + 1)/\(totalSteps): \(step.title)")
    }
    
    // MARK: - Actions
    
    @objc private func nextButtonTapped() {
        print("🎯 Onboarding: Next button tapped for step \(currentStep + 1)")
        
        if currentStep < totalSteps - 1 {
            // Move to next step
            currentStep += 1
            updateStepContent()
        } else {
            // Complete onboarding
            completeOnboarding()
        }
    }
    
    @objc private func skipButtonTapped() {
        print("🎯 Onboarding: Skip button tapped")
        completeOnboarding()
    }
    
    private func completeOnboarding() {
        print("🎯 Onboarding: Completing onboarding flow")
        
        // Mark onboarding as completed
        UserDefaults.standard.set(true, forKey: "onboarding_completed")
        
        // Animate completion
        UIView.animate(withDuration: 0.3, animations: {
            self.view.alpha = 0
        }) { _ in
            self.onCompletion?()
        }
    }
    
    // MARK: - Public Methods
    
    static func shouldShowOnboarding() -> Bool {
        return !UserDefaults.standard.bool(forKey: "onboarding_completed")
    }
    
    static func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: "onboarding_completed")
        print("🎯 Onboarding: Reset onboarding status")
    }
}

// MARK: - OnboardingStep Data Model

private struct OnboardingStep {
    let imageName: String
    let title: String
    let description: String
    let buttonTitle: String
}