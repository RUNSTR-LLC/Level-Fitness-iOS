import UIKit

class LeagueSettingsStepViewController: UIViewController {
    
    // MARK: - Properties
    private let leagueData: LeagueCreationData
    private let teamData: TeamData
    private let teamWalletBalance: Int
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // League Name Section
    private let nameLabel = UILabel()
    private let nameTextField = UITextField()
    private let nameContainer = UIView()
    
    // Prize Distribution Section
    private let prizeLabel = UILabel()
    private let currentBalanceLabel = UILabel()
    private let payoutOptionsContainer = UIView()
    private var payoutButtons: [UIButton] = []
    
    // Description Section
    private let descriptionLabel = UILabel()
    private let descriptionTextView = UITextView()
    
    // MARK: - Initialization
    
    init(leagueData: LeagueCreationData, teamData: TeamData, teamWalletBalance: Int) {
        self.leagueData = leagueData
        self.teamData = teamData
        self.teamWalletBalance = teamWalletBalance
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupConstraints()
        populateDefaults()
    }
    
    // MARK: - Setup Methods
    
    private func setupView() {
        view.backgroundColor = UIColor.clear
        
        // Scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // League name section
        nameLabel.text = "LEAGUE NAME"
        nameLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        nameLabel.textColor = IndustrialDesign.Colors.accentText
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        nameContainer.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        nameContainer.layer.cornerRadius = 12
        nameContainer.layer.borderWidth = 1
        nameContainer.layer.borderColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        nameContainer.translatesAutoresizingMaskIntoConstraints = false
        
        nameTextField.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        nameTextField.textColor = IndustrialDesign.Colors.primaryText
        nameTextField.backgroundColor = UIColor.clear
        nameTextField.borderStyle = .none
        nameTextField.placeholder = "Enter league name..."
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        nameTextField.delegate = self
        nameTextField.addTarget(self, action: #selector(nameTextFieldChanged), for: .editingChanged)
        
        // Prize distribution section
        prizeLabel.text = "PRIZE DISTRIBUTION"
        prizeLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        prizeLabel.textColor = IndustrialDesign.Colors.accentText
        prizeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        currentBalanceLabel.text = formatTeamWalletBalance()
        currentBalanceLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        currentBalanceLabel.textColor = IndustrialDesign.Colors.bitcoin
        currentBalanceLabel.textAlignment = .center
        currentBalanceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        payoutOptionsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Description section
        descriptionLabel.text = "DESCRIPTION (OPTIONAL)"
        descriptionLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        descriptionLabel.textColor = IndustrialDesign.Colors.accentText
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        descriptionTextView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        descriptionTextView.layer.cornerRadius = 12
        descriptionTextView.layer.borderWidth = 1
        descriptionTextView.layer.borderColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        descriptionTextView.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        descriptionTextView.textColor = IndustrialDesign.Colors.primaryText
        descriptionTextView.text = "Compete for distance this month and earn Bitcoin rewards!"
        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup payout option buttons
        setupPayoutOptions()
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(nameLabel)
        contentView.addSubview(nameContainer)
        nameContainer.addSubview(nameTextField)
        
        contentView.addSubview(prizeLabel)
        contentView.addSubview(currentBalanceLabel)
        contentView.addSubview(payoutOptionsContainer)
        
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(descriptionTextView)
    }
    
    private func setupPayoutOptions() {
        payoutButtons.removeAll()
        
        for payoutType in PayoutType.allCases {
            let button = createPayoutButton(for: payoutType)
            payoutButtons.append(button)
            payoutOptionsContainer.addSubview(button)
        }
        
        // Select default option
        selectPayoutType(.winnerTakesAll)
    }
    
    private func createPayoutButton(for payoutType: PayoutType) -> UIButton {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Button styling
        button.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        
        // Button content
        let titleLabel = UILabel()
        titleLabel.text = payoutType.displayName
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let descLabel = UILabel()
        descLabel.text = payoutType.description
        descLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        descLabel.textColor = IndustrialDesign.Colors.secondaryText
        descLabel.numberOfLines = 0
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        
        button.addSubview(titleLabel)
        button.addSubview(descLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: button.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descLabel.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            descLabel.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            descLabel.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -12)
        ])
        
        button.addTarget(self, action: #selector(payoutButtonTapped(_:)), for: .touchUpInside)
        button.tag = PayoutType.allCases.firstIndex(of: payoutType) ?? 0
        
        return button
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // League name
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            nameContainer.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            nameContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            nameContainer.heightAnchor.constraint(equalToConstant: 50),
            
            nameTextField.centerYAnchor.constraint(equalTo: nameContainer.centerYAnchor),
            nameTextField.leadingAnchor.constraint(equalTo: nameContainer.leadingAnchor, constant: 16),
            nameTextField.trailingAnchor.constraint(equalTo: nameContainer.trailingAnchor, constant: -16),
            
            // Prize distribution
            prizeLabel.topAnchor.constraint(equalTo: nameContainer.bottomAnchor, constant: 24),
            prizeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            prizeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            currentBalanceLabel.topAnchor.constraint(equalTo: prizeLabel.bottomAnchor, constant: 8),
            currentBalanceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            currentBalanceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            payoutOptionsContainer.topAnchor.constraint(equalTo: currentBalanceLabel.bottomAnchor, constant: 16),
            payoutOptionsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            payoutOptionsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            payoutOptionsContainer.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        // Payout button constraints
        if payoutButtons.count >= 3 {
            NSLayoutConstraint.activate([
                payoutButtons[0].topAnchor.constraint(equalTo: payoutOptionsContainer.topAnchor),
                payoutButtons[0].leadingAnchor.constraint(equalTo: payoutOptionsContainer.leadingAnchor),
                payoutButtons[0].trailingAnchor.constraint(equalTo: payoutOptionsContainer.trailingAnchor),
                payoutButtons[0].heightAnchor.constraint(equalToConstant: 60),
                
                payoutButtons[1].topAnchor.constraint(equalTo: payoutButtons[0].bottomAnchor, constant: 10),
                payoutButtons[1].leadingAnchor.constraint(equalTo: payoutOptionsContainer.leadingAnchor),
                payoutButtons[1].trailingAnchor.constraint(equalTo: payoutOptionsContainer.trailingAnchor),
                payoutButtons[1].heightAnchor.constraint(equalToConstant: 60),
                
                payoutButtons[2].topAnchor.constraint(equalTo: payoutButtons[1].bottomAnchor, constant: 10),
                payoutButtons[2].leadingAnchor.constraint(equalTo: payoutOptionsContainer.leadingAnchor),
                payoutButtons[2].trailingAnchor.constraint(equalTo: payoutOptionsContainer.trailingAnchor),
                payoutButtons[2].heightAnchor.constraint(equalToConstant: 60)
            ])
        }
    }
    
    // MARK: - Helper Methods
    
    private func populateDefaults() {
        nameTextField.text = leagueData.generateDefaultLeagueName()
        leagueData.leagueName = nameTextField.text ?? ""
    }
    
    private func formatTeamWalletBalance() -> String {
        let btcAmount = Double(teamWalletBalance) / 100_000_000.0
        return "Prize Pool: ₿\(String(format: "%.6f", btcAmount))"
    }
    
    private func selectPayoutType(_ payoutType: PayoutType) {
        leagueData.payoutType = payoutType
        leagueData.payoutPercentages = payoutType.percentages
        
        // Update button appearances
        for (index, button) in payoutButtons.enumerated() {
            let isSelected = index == PayoutType.allCases.firstIndex(of: payoutType)
            
            if isSelected {
                button.layer.borderColor = IndustrialDesign.Colors.bitcoin.cgColor
                button.backgroundColor = UIColor(red: 0.15, green: 0.1, blue: 0.05, alpha: 0.9)
            } else {
                button.layer.borderColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
                button.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func nameTextFieldChanged() {
        leagueData.leagueName = nameTextField.text ?? ""
    }
    
    @objc private func payoutButtonTapped(_ sender: UIButton) {
        let payoutType = PayoutType.allCases[sender.tag]
        selectPayoutType(payoutType)
        
        print("🏆 LeagueSettings: Selected payout type: \(payoutType.displayName)")
    }
}

// MARK: - UITextFieldDelegate

extension LeagueSettingsStepViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}