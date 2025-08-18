import UIKit
import StoreKit

class PaymentSheetViewController: UIViewController {
    
    // MARK: - Properties
    private let teamData: TeamData
    private let subscriptionPrice: Double = 3.99
    
    // Completion handler
    var onCompletion: ((Bool) -> Void)?
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let handleView = UIView()
    
    // Header section
    private let headerView = UIView()
    private let teamImageView = UIImageView()
    private let teamNameLabel = UILabel()
    private let subscriptionLabel = UILabel()
    
    // Benefits section
    private let benefitsSection = UIView()
    private let benefitsTitle = UILabel()
    private var benefitItems: [BenefitRow] = []
    
    // Pricing section
    private let pricingSection = UIView()
    private let priceLabel = UILabel()
    private let billingLabel = UILabel()
    
    // Payment button
    private let paymentButton = UIButton(type: .custom)
    private let cancelButton = UIButton(type: .custom)
    
    // Loading indicator
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    init(teamData: TeamData) {
        self.teamData = teamData
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = .pageSheet
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.preferredCornerRadius = 20
            sheet.prefersGrabberVisible = true
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("💳 PaymentSheet: Loading payment sheet for team: \(teamData.name)")
        
        setupBackground()
        setupContainerView()
        setupHeader()
        setupBenefitsSection()
        setupPricingSection()
        setupButtons()
        setupConstraints()
        
        // Load real pricing from StoreKit
        loadProductPricing()
        
        print("💳 PaymentSheet: Payment sheet loaded successfully")
    }
    
    // MARK: - Setup Methods
    
    private func setupBackground() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        // Add tap gesture to dismiss
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupContainerView() {
        containerView.backgroundColor = IndustrialDesign.Colors.background
        containerView.layer.cornerRadius = 20
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Handle view for sheet
        handleView.backgroundColor = UIColor(white: 0.5, alpha: 0.5)
        handleView.layer.cornerRadius = 2
        handleView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(containerView)
        containerView.addSubview(handleView)
    }
    
    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Team image placeholder
        teamImageView.image = UIImage(systemName: "person.3.fill")
        teamImageView.tintColor = UIColor.systemBlue
        teamImageView.contentMode = .scaleAspectFit
        teamImageView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        teamImageView.layer.cornerRadius = 30
        teamImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Team name
        teamNameLabel.text = teamData.name
        teamNameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        teamNameLabel.textColor = IndustrialDesign.Colors.primaryText
        teamNameLabel.textAlignment = .center
        teamNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Subscription label
        subscriptionLabel.text = "Team Subscription"
        subscriptionLabel.font = UIFont.systemFont(ofSize: 16)
        subscriptionLabel.textColor = IndustrialDesign.Colors.secondaryText
        subscriptionLabel.textAlignment = .center
        subscriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(teamImageView)
        headerView.addSubview(teamNameLabel)
        headerView.addSubview(subscriptionLabel)
        containerView.addSubview(headerView)
    }
    
    private func setupBenefitsSection() {
        benefitsSection.translatesAutoresizingMaskIntoConstraints = false
        
        benefitsTitle.text = "What's Included"
        benefitsTitle.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        benefitsTitle.textColor = IndustrialDesign.Colors.primaryText
        benefitsTitle.translatesAutoresizingMaskIntoConstraints = false
        
        // Create benefit items
        let benefits = [
            ("checkmark.circle.fill", "Compete in team leaderboards"),
            ("trophy.fill", "Participate in team events"),
            ("bitcoinsign.circle.fill", "Earn Bitcoin rewards"),
            ("message.fill", "Access team chat"),
            ("chart.bar.fill", "Track your progress")
        ]
        
        for benefit in benefits {
            let benefitRow = BenefitRow(iconName: benefit.0, text: benefit.1)
            benefitRow.translatesAutoresizingMaskIntoConstraints = false
            benefitItems.append(benefitRow)
            benefitsSection.addSubview(benefitRow)
        }
        
        benefitsSection.addSubview(benefitsTitle)
        containerView.addSubview(benefitsSection)
    }
    
    private func setupPricingSection() {
        pricingSection.translatesAutoresizingMaskIntoConstraints = false
        pricingSection.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        pricingSection.layer.cornerRadius = 12
        pricingSection.layer.borderWidth = 1
        pricingSection.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        priceLabel.text = "$\(String(format: "%.2f", subscriptionPrice))"
        priceLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        priceLabel.textColor = IndustrialDesign.Colors.primaryText
        priceLabel.textAlignment = .center
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        billingLabel.text = "per month • Cancel anytime"
        billingLabel.font = UIFont.systemFont(ofSize: 14)
        billingLabel.textColor = IndustrialDesign.Colors.secondaryText
        billingLabel.textAlignment = .center
        billingLabel.translatesAutoresizingMaskIntoConstraints = false
        
        pricingSection.addSubview(priceLabel)
        pricingSection.addSubview(billingLabel)
        containerView.addSubview(pricingSection)
    }
    
    private func setupButtons() {
        // Payment button
        paymentButton.setTitle("Subscribe Now", for: .normal)
        paymentButton.setTitleColor(.white, for: .normal)
        paymentButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        paymentButton.backgroundColor = UIColor.systemBlue
        paymentButton.layer.cornerRadius = 12
        paymentButton.layer.borderWidth = 1
        paymentButton.layer.borderColor = UIColor.systemBlue.cgColor
        paymentButton.translatesAutoresizingMaskIntoConstraints = false
        paymentButton.addTarget(self, action: #selector(paymentButtonTapped), for: .touchUpInside)
        
        // Cancel button
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cancelButton.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.6)
        cancelButton.layer.cornerRadius = 12
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        
        // Loading indicator
        loadingIndicator.color = .white
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(paymentButton)
        containerView.addSubview(cancelButton)
        containerView.addSubview(loadingIndicator)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 600),
            
            // Handle view
            handleView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            handleView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            handleView.widthAnchor.constraint(equalToConstant: 40),
            handleView.heightAnchor.constraint(equalToConstant: 4),
            
            // Header
            headerView.topAnchor.constraint(equalTo: handleView.bottomAnchor, constant: 24),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            
            teamImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            teamImageView.topAnchor.constraint(equalTo: headerView.topAnchor),
            teamImageView.widthAnchor.constraint(equalToConstant: 60),
            teamImageView.heightAnchor.constraint(equalToConstant: 60),
            
            teamNameLabel.topAnchor.constraint(equalTo: teamImageView.bottomAnchor, constant: 16),
            teamNameLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            teamNameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            
            subscriptionLabel.topAnchor.constraint(equalTo: teamNameLabel.bottomAnchor, constant: 4),
            subscriptionLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            subscriptionLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            subscriptionLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            
            // Benefits section
            benefitsSection.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 32),
            benefitsSection.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            benefitsSection.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            
            benefitsTitle.topAnchor.constraint(equalTo: benefitsSection.topAnchor),
            benefitsTitle.leadingAnchor.constraint(equalTo: benefitsSection.leadingAnchor),
            benefitsTitle.trailingAnchor.constraint(equalTo: benefitsSection.trailingAnchor),
            
            // Pricing section
            pricingSection.topAnchor.constraint(equalTo: benefitsSection.bottomAnchor, constant: 24),
            pricingSection.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            pricingSection.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            pricingSection.heightAnchor.constraint(equalToConstant: 80),
            
            priceLabel.centerXAnchor.constraint(equalTo: pricingSection.centerXAnchor),
            priceLabel.topAnchor.constraint(equalTo: pricingSection.topAnchor, constant: 12),
            
            billingLabel.centerXAnchor.constraint(equalTo: pricingSection.centerXAnchor),
            billingLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 4),
            
            // Buttons
            paymentButton.topAnchor.constraint(equalTo: pricingSection.bottomAnchor, constant: 24),
            paymentButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            paymentButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            paymentButton.heightAnchor.constraint(equalToConstant: 56),
            
            cancelButton.topAnchor.constraint(equalTo: paymentButton.bottomAnchor, constant: 12),
            cancelButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            cancelButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            cancelButton.heightAnchor.constraint(equalToConstant: 48),
            
            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: paymentButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: paymentButton.centerYAnchor)
        ])
        
        // Layout benefit items
        layoutBenefitItems()
    }
    
    private func layoutBenefitItems() {
        guard !benefitItems.isEmpty else { return }
        
        var previousItem: UIView = benefitsTitle
        for benefitItem in benefitItems {
            NSLayoutConstraint.activate([
                benefitItem.topAnchor.constraint(equalTo: previousItem.bottomAnchor, constant: 12),
                benefitItem.leadingAnchor.constraint(equalTo: benefitsSection.leadingAnchor),
                benefitItem.trailingAnchor.constraint(equalTo: benefitsSection.trailingAnchor),
                benefitItem.heightAnchor.constraint(equalToConstant: 24)
            ])
            previousItem = benefitItem
        }
        
        if let lastItem = benefitItems.last {
            benefitsSection.bottomAnchor.constraint(equalTo: lastItem.bottomAnchor).isActive = true
        }
    }
    
    // MARK: - Actions
    
    @objc private func backgroundTapped() {
        dismiss(animated: true) {
            self.onCompletion?(false)
        }
    }
    
    @objc private func cancelButtonTapped() {
        print("💳 PaymentSheet: Cancel button tapped")
        dismiss(animated: true) {
            self.onCompletion?(false)
        }
    }
    
    @objc private func paymentButtonTapped() {
        print("💳 PaymentSheet: Payment button tapped")
        processPayment()
    }
    
    // MARK: - Payment Processing
    
    private func processPayment() {
        setLoadingState(true)
        
        Task {
            do {
                let success = try await SubscriptionService.shared.subscribeToTeam(teamData.id)
                
                await MainActor.run {
                    self.setLoadingState(false)
                    
                    if success {
                        print("💳 PaymentSheet: Payment successful for team: \(self.teamData.name)")
                        self.showPaymentSuccess()
                    } else {
                        print("💳 PaymentSheet: Payment cancelled by user")
                        self.dismiss(animated: true) {
                            self.onCompletion?(false)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.setLoadingState(false)
                    print("💳 PaymentSheet: Payment failed: \(error)")
                    self.showPaymentError(error)
                }
            }
        }
    }
    
    private func setLoadingState(_ loading: Bool) {
        paymentButton.isEnabled = !loading
        cancelButton.isEnabled = !loading
        
        if loading {
            loadingIndicator.startAnimating()
            paymentButton.setTitle("", for: .normal)
        } else {
            loadingIndicator.stopAnimating()
            paymentButton.setTitle("Subscribe Now", for: .normal)
        }
    }
    
    private func showPaymentSuccess() {
        // Animate success state
        UIView.animate(withDuration: 0.3, animations: {
            self.paymentButton.backgroundColor = UIColor.systemGreen
            self.paymentButton.layer.borderColor = UIColor.systemGreen.cgColor
            self.paymentButton.setTitle("Success! ✓", for: .normal)
        }) { _ in
            // Dismiss after brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.dismiss(animated: true) {
                    self.onCompletion?(true)
                }
            }
        }
    }
    
    private func showPaymentError(_ error: Error) {
        let alert = UIAlertController(
            title: "Payment Failed",
            message: "Could not complete subscription: \(error.localizedDescription)",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Try Again", style: .default) { _ in
            self.processPayment()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.dismiss(animated: true) {
                self.onCompletion?(false)
            }
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Product Pricing
    
    private func loadProductPricing() {
        let realPrice = SubscriptionService.shared.getTeamSubscriptionPrice()
        priceLabel.text = realPrice.replacingOccurrences(of: "/month", with: "")
        billingLabel.text = "per month • Cancel anytime"
    }
}

// MARK: - BenefitRow Component

class BenefitRow: UIView {
    
    private let iconImageView = UIImageView()
    private let textLabel = UILabel()
    
    init(iconName: String, text: String) {
        super.init(frame: .zero)
        
        setupViews(iconName: iconName, text: text)
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews(iconName: String, text: String) {
        iconImageView.image = UIImage(systemName: iconName)
        iconImageView.tintColor = UIColor.systemBlue
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        textLabel.text = text
        textLabel.font = UIFont.systemFont(ofSize: 16)
        textLabel.textColor = IndustrialDesign.Colors.primaryText
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(iconImageView)
        addSubview(textLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            textLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            textLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}