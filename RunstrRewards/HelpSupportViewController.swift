import UIKit
import MessageUI

class HelpSupportViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header
    private let headerView = UIView()
    private let backButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    
    // Support sections
    private let quickHelpSection = UIView()
    private let contactSection = UIView()
    private let resourcesSection = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("❓ Help & Support: Loading view")
        
        setupIndustrialBackground()
        setupScrollView()
        setupHeader()
        setupSupportSections()
        setupConstraints()
        
        print("❓ Help & Support: View loaded successfully")
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
        titleLabel.text = "Help & Support"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(backButton)
        headerView.addSubview(titleLabel)
        contentView.addSubview(headerView)
    }
    
    private func setupSupportSections() {
        // Quick Help Section
        quickHelpSection.translatesAutoresizingMaskIntoConstraints = false
        let quickHelpItems = [
            SupportItem(title: "Getting Started", subtitle: "How to sync workouts and earn rewards", icon: "play.circle.fill", action: { [weak self] in
                self?.showGettingStarted()
            }),
            SupportItem(title: "Troubleshooting", subtitle: "Fix common sync and reward issues", icon: "wrench.fill", action: { [weak self] in
                self?.showTroubleshooting()
            }),
            SupportItem(title: "Account & Billing", subtitle: "Manage subscriptions and payments", icon: "creditcard.fill", action: { [weak self] in
                self?.showAccountHelp()
            }),
            SupportItem(title: "Bitcoin Wallet", subtitle: "Understanding rewards and withdrawals", icon: "bitcoinsign.circle.fill", action: { [weak self] in
                self?.showWalletHelp()
            })
        ]
        
        let quickHelpSectionView = SupportSectionView(title: "Quick Help", items: quickHelpItems)
        quickHelpSection.addSubview(quickHelpSectionView)
        contentView.addSubview(quickHelpSection)
        
        // Contact Section
        contactSection.translatesAutoresizingMaskIntoConstraints = false
        let contactItems = [
            SupportItem(title: "Email Support", subtitle: "If you need help with something in the app or have a suggestion send an email", icon: "envelope.fill", action: { [weak self] in
                self?.openEmailSupport()
            }),
            SupportItem(title: "Report a Bug", subtitle: "Help us improve the app", icon: "ladybug.fill", action: { [weak self] in
                self?.reportBug()
            }),
            SupportItem(title: "Feature Request", subtitle: "Suggest new features", icon: "lightbulb.fill", action: { [weak self] in
                self?.submitFeatureRequest()
            })
        ]
        
        let contactSectionView = SupportSectionView(title: "Contact Us", items: contactItems)
        contactSection.addSubview(contactSectionView)
        contentView.addSubview(contactSection)
        
        // Resources Section
        resourcesSection.translatesAutoresizingMaskIntoConstraints = false
        let resourceItems = [
            SupportItem(title: "Community Guidelines", subtitle: "Rules for teams and competitions", icon: "person.3.fill", action: { [weak self] in
                self?.showCommunityGuidelines()
            }),
            SupportItem(title: "Security & Safety", subtitle: "How we protect your data", icon: "shield.fill", action: { [weak self] in
                self?.showSecurityInfo()
            }),
            SupportItem(title: "Bitcoin Basics", subtitle: "Learn about Lightning Network", icon: "book.fill", action: { [weak self] in
                self?.showBitcoinBasics()
            }),
            SupportItem(title: "System Status", subtitle: "Check service availability", icon: "checkmark.circle.fill", action: { [weak self] in
                self?.checkSystemStatus()
            })
        ]
        
        let resourcesSectionView = SupportSectionView(title: "Resources", items: resourceItems)
        resourcesSection.addSubview(resourcesSectionView)
        contentView.addSubview(resourcesSection)
        
        // Setup section constraints
        NSLayoutConstraint.activate([
            quickHelpSectionView.topAnchor.constraint(equalTo: quickHelpSection.topAnchor),
            quickHelpSectionView.leadingAnchor.constraint(equalTo: quickHelpSection.leadingAnchor),
            quickHelpSectionView.trailingAnchor.constraint(equalTo: quickHelpSection.trailingAnchor),
            quickHelpSectionView.bottomAnchor.constraint(equalTo: quickHelpSection.bottomAnchor),
            
            contactSectionView.topAnchor.constraint(equalTo: contactSection.topAnchor),
            contactSectionView.leadingAnchor.constraint(equalTo: contactSection.leadingAnchor),
            contactSectionView.trailingAnchor.constraint(equalTo: contactSection.trailingAnchor),
            contactSectionView.bottomAnchor.constraint(equalTo: contactSection.bottomAnchor),
            
            resourcesSectionView.topAnchor.constraint(equalTo: resourcesSection.topAnchor),
            resourcesSectionView.leadingAnchor.constraint(equalTo: resourcesSection.leadingAnchor),
            resourcesSectionView.trailingAnchor.constraint(equalTo: resourcesSection.trailingAnchor),
            resourcesSectionView.bottomAnchor.constraint(equalTo: resourcesSection.bottomAnchor)
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
            
            // Support sections
            quickHelpSection.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 32),
            quickHelpSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            quickHelpSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            contactSection.topAnchor.constraint(equalTo: quickHelpSection.bottomAnchor, constant: 32),
            contactSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            contactSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            resourcesSection.topAnchor.constraint(equalTo: contactSection.bottomAnchor, constant: 32),
            resourcesSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            resourcesSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            resourcesSection.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        print("❓ Help & Support: Back button tapped")
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Support Actions
    
    private func showGettingStarted() {
        let message = """
        Welcome to RunstrRewards! Here's how to get started:
        
        1. Connect HealthKit to sync your workouts automatically
        2. Join or create a team to compete with others
        3. Complete workouts and earn Bitcoin rewards
        4. Track your progress on team leaderboards
        
        Your workouts from Apple Health, Strava, Garmin, and other platforms will automatically sync and earn you rewards!
        """
        
        showInfoAlert(title: "Getting Started", message: message)
    }
    
    private func showTroubleshooting() {
        let message = """
        Common issues and solutions:
        
        • Workouts not syncing: Check HealthKit permissions in Settings > Privacy & Security > Health
        
        • Missing rewards: Rewards are calculated weekly and distributed on Sundays
        
        • Team not showing: Make sure you have an active internet connection
        
        • Bitcoin wallet issues: Contact support for wallet-related problems
        
        If issues persist, please contact support with your device model and iOS version.
        """
        
        showInfoAlert(title: "Troubleshooting", message: message)
    }
    
    private func showAccountHelp() {
        let message = """
        Account & Billing Help:
        
        • Subscriptions are managed through the App Store
        • To cancel: Settings > Apple ID > Subscriptions > RunstrRewards
        • Refunds must be requested through Apple Support
        • Your account data is synced across devices with the same Apple ID
        
        For billing questions, contact Apple Support or email us at dakota.brown@runstr.club
        """
        
        showInfoAlert(title: "Account & Billing", message: message)
    }
    
    private func showWalletHelp() {
        let message = """
        Bitcoin Wallet Guide:
        
        • Rewards are paid in Bitcoin via Lightning Network
        • Weekly payouts happen every Sunday
        • Minimum payout: 1,000 satoshis (sats)
        • Transaction fees are covered by RunstrRewards
        
        Your wallet is managed securely by CoinOS. You can withdraw to external wallets anytime.
        
        For wallet issues, please contact support.
        """
        
        showInfoAlert(title: "Bitcoin Wallet", message: message)
    }
    
    private func openEmailSupport() {
        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setToRecipients(["dakota.brown@runstr.club"])
            mailComposer.setSubject("RunstrRewards Support Request")
            
            // Add device info
            let deviceInfo = """
            
            
            ---
            Device Information:
            iOS Version: \(UIDevice.current.systemVersion)
            Device Model: \(UIDevice.current.model)
            App Version: 1.0.0
            """
            
            mailComposer.setMessageBody("Please describe your issue or question:\n\n\(deviceInfo)", isHTML: false)
            present(mailComposer, animated: true)
        } else {
            // Fallback to opening mail app
            if let url = URL(string: "mailto:dakota.brown@runstr.club?subject=Level%20Fitness%20Support") {
                UIApplication.shared.open(url)
            }
        }
    }
    
    private func reportBug() {
        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setToRecipients(["dakota.brown@runstr.club"])
            mailComposer.setSubject("Bug Report - RunstrRewards")
            
            let bugTemplate = """
            Bug Description:
            [Describe what happened]
            
            Steps to Reproduce:
            1. 
            2. 
            3. 
            
            Expected Behavior:
            [What should have happened]
            
            Actual Behavior:
            [What actually happened]
            
            ---
            Device Information:
            iOS Version: \(UIDevice.current.systemVersion)
            Device Model: \(UIDevice.current.model)
            App Version: 1.0.0
            """
            
            mailComposer.setMessageBody(bugTemplate, isHTML: false)
            present(mailComposer, animated: true)
        } else {
            showInfoAlert(title: "Report Bug", message: "Please email bug reports to dakota.brown@runstr.club with details about the issue and steps to reproduce it.")
        }
    }
    
    private func submitFeatureRequest() {
        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setToRecipients(["dakota.brown@runstr.club"])
            mailComposer.setSubject("Feature Request - RunstrRewards")
            
            let featureTemplate = """
            Feature Request:
            [Describe the feature you'd like to see]
            
            Use Case:
            [How would this feature help you?]
            
            Additional Details:
            [Any other relevant information]
            
            ---
            Submitted from RunstrRewards iOS App v1.0.0
            """
            
            mailComposer.setMessageBody(featureTemplate, isHTML: false)
            present(mailComposer, animated: true)
        } else {
            showInfoAlert(title: "Feature Request", message: "Please email feature requests to dakota.brown@runstr.club with details about what you'd like to see in the app.")
        }
    }
    
    private func showCommunityGuidelines() {
        let message = """
        RunstrRewards Community Guidelines:
        
        • Be respectful to all team members
        • No harassment, spam, or inappropriate content
        • Play fair - cheating results in account suspension
        • Keep team chat relevant to fitness and challenges
        • Report suspicious activity to moderators
        
        Violations may result in removal from teams or account suspension.
        """
        
        showInfoAlert(title: "Community Guidelines", message: message)
    }
    
    private func showSecurityInfo() {
        let message = """
        Your Security & Privacy:
        
        • Health data is encrypted and never shared without permission
        • Bitcoin transactions use secure Lightning Network protocol
        • Account data is protected with industry-standard encryption
        • We never sell your personal information
        
        For detailed privacy information, see our Privacy Policy in Settings.
        """
        
        showInfoAlert(title: "Security & Privacy", message: message)
    }
    
    private func showBitcoinBasics() {
        let message = """
        Bitcoin & Lightning Network Basics:
        
        • Bitcoin is a digital currency with real value
        • Lightning Network enables instant, low-cost transactions
        • 1 Bitcoin = 100,000,000 satoshis (sats)
        • Your rewards are real Bitcoin you can withdraw anytime
        
        RunstrRewards uses CoinOS for secure wallet management and Lightning Network transactions.
        """
        
        showInfoAlert(title: "Bitcoin Basics", message: message)
    }
    
    private func checkSystemStatus() {
        let message = """
        Current System Status: ✅ All Systems Operational
        
        Services:
        • HealthKit Sync: ✅ Online
        • Push Notifications: ✅ Online  
        • Bitcoin Payments: ✅ Online
        • Team Features: ✅ Online
        
        For real-time status updates, follow @levelfitness on social media.
        """
        
        showInfoAlert(title: "System Status", message: message)
    }
    
    private func showInfoAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - MFMailComposeViewControllerDelegate

extension HelpSupportViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true) {
            switch result {
            case .sent:
                self.showInfoAlert(title: "Email Sent", message: "Thank you for contacting us! We'll respond within 24 hours.")
            case .failed:
                self.showInfoAlert(title: "Email Failed", message: "Unable to send email. Please try again or contact us directly at dakota.brown@runstr.club")
            default:
                break
            }
        }
    }
}

// MARK: - Supporting Classes

struct SupportItem {
    let title: String
    let subtitle: String
    let icon: String
    let action: (() -> Void)?
}

class SupportSectionView: UIView {
    
    private let titleLabel = UILabel()
    private let stackView = UIStackView()
    private let items: [SupportItem]
    
    init(title: String, items: [SupportItem]) {
        self.items = items
        super.init(frame: .zero)
        
        setupViews(title: title)
        setupConstraints()
        createItemViews()
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
    
    private func createItemViews() {
        for (index, item) in items.enumerated() {
            let itemView = SupportItemView(item: item)
            stackView.addArrangedSubview(itemView)
            
            // Add separator (except for last item)
            if index < items.count - 1 {
                let separator = UIView()
                separator.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0)
                separator.translatesAutoresizingMaskIntoConstraints = false
                separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
                stackView.addArrangedSubview(separator)
            }
        }
    }
}

class SupportItemView: UIView {
    
    private let item: SupportItem
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let chevronImageView = UIImageView()
    
    init(item: SupportItem) {
        self.item = item
        super.init(frame: .zero)
        
        setupViews()
        setupConstraints()
        setupTapGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        iconImageView.image = UIImage(systemName: item.icon)
        iconImageView.tintColor = UIColor.systemBlue
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.text = item.title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        subtitleLabel.text = item.subtitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 14)
        subtitleLabel.textColor = IndustrialDesign.Colors.secondaryText
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = IndustrialDesign.Colors.secondaryText
        chevronImageView.contentMode = .scaleAspectFit
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(chevronImageView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 60),
            
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -16),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            
            chevronImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            chevronImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 12)
        ])
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(itemTapped))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
        
        // Add hover effect
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPress.minimumPressDuration = 0
        addGestureRecognizer(longPress)
    }
    
    @objc private func itemTapped() {
        item.action?()
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            UIView.animate(withDuration: 0.1) {
                self.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
            }
        case .ended, .cancelled:
            UIView.animate(withDuration: 0.1) {
                self.backgroundColor = .clear
            }
        default:
            break
        }
    }
}