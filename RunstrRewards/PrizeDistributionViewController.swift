import UIKit

class PrizeDistributionViewController: UIViewController {
    
    // MARK: - Properties
    private let teamData: TeamData
    private let eventData: EventData
    private var prizeDistribution: PrizeDistribution?
    private let distributionService = TeamPrizeDistributionService.shared
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header section
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let eventLabel = UILabel()
    private let prizeAmountLabel = UILabel()
    private let walletBalanceLabel = UILabel()
    
    // Distribution method section
    private let methodSection = UIView()
    private let methodTitleLabel = UILabel()
    private let methodSegmentedControl = UISegmentedControl(items: [
        "Equal", "Performance", "Top Performers", "Hybrid", "Custom"
    ])
    private let methodDescriptionLabel = UILabel()
    
    // Recipients preview section
    private let previewSection = UIView()
    private let previewTitleLabel = UILabel()
    private let recipientsTableView = UITableView()
    private let totalVerificationLabel = UILabel()
    
    // Action buttons
    private let actionContainer = UIView()
    private let calculateButton = UIButton(type: .custom)
    private let previewButton = UIButton(type: .custom)
    private let executeButton = UIButton(type: .custom)
    private let cancelButton = UIButton(type: .custom)
    
    // Custom amount input (for custom distribution)
    private let customAmountContainer = UIView()
    private var customAmountFields: [String: UITextField] = [:]
    
    // Status indicator
    private let statusView = UIView()
    private let statusLabel = UILabel()
    
    // MARK: - Initialization
    
    init(teamData: TeamData, eventData: EventData) {
        self.teamData = teamData
        self.eventData = eventData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("💰 PrizeDistribution: Loading distribution interface for team: \(teamData.name)")
        
        setupIndustrialBackground()
        setupScrollView()
        setupHeader()
        setupMethodSection()
        setupPreviewSection()
        setupActions()
        setupCustomAmountSection()
        setupStatusView()
        setupConstraints()
        
        loadTeamWalletInfo()
        updateMethodDescription()
        
        print("💰 PrizeDistribution: Interface loaded successfully")
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
        
        // Add decorative gear
        let gear = RotatingGearView(size: 80)
        gear.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gear)
        
        NSLayoutConstraint.activate([
            gear.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            gear.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 10),
            gear.widthAnchor.constraint(equalToConstant: 80),
            gear.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupHeader() {
        headerView.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.95)
        headerView.layer.cornerRadius = 12
        headerView.layer.borderWidth = 1
        headerView.layer.borderColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.text = "Prize Distribution"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        eventLabel.text = eventData.name
        eventLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        eventLabel.textColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        eventLabel.translatesAutoresizingMaskIntoConstraints = false
        
        prizeAmountLabel.text = "Prize: ₿\(Int(eventData.prizePool))"
        prizeAmountLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        prizeAmountLabel.textColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        prizeAmountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        walletBalanceLabel.font = UIFont.systemFont(ofSize: 14)
        walletBalanceLabel.textColor = IndustrialDesign.Colors.secondaryText
        walletBalanceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(titleLabel)
        headerView.addSubview(eventLabel)
        headerView.addSubview(prizeAmountLabel)
        headerView.addSubview(walletBalanceLabel)
        contentView.addSubview(headerView)
    }
    
    private func setupMethodSection() {
        methodSection.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.9)
        methodSection.layer.cornerRadius = 12
        methodSection.layer.borderWidth = 1
        methodSection.layer.borderColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        methodSection.translatesAutoresizingMaskIntoConstraints = false
        
        methodTitleLabel.text = "Distribution Method"
        methodTitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        methodTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        methodTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        methodSegmentedControl.selectedSegmentIndex = 0
        methodSegmentedControl.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        methodSegmentedControl.selectedSegmentTintColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        methodSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        methodSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
        methodSegmentedControl.addTarget(self, action: #selector(methodChanged), for: .valueChanged)
        methodSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        methodDescriptionLabel.font = UIFont.systemFont(ofSize: 14)
        methodDescriptionLabel.textColor = IndustrialDesign.Colors.secondaryText
        methodDescriptionLabel.numberOfLines = 0
        methodDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        methodSection.addSubview(methodTitleLabel)
        methodSection.addSubview(methodSegmentedControl)
        methodSection.addSubview(methodDescriptionLabel)
        contentView.addSubview(methodSection)
    }
    
    private func setupPreviewSection() {
        previewSection.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.9)
        previewSection.layer.cornerRadius = 12
        previewSection.layer.borderWidth = 1
        previewSection.layer.borderColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        previewSection.translatesAutoresizingMaskIntoConstraints = false
        
        previewTitleLabel.text = "Distribution Preview"
        previewTitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        previewTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        previewTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        recipientsTableView.backgroundColor = .clear
        recipientsTableView.separatorStyle = .none
        recipientsTableView.delegate = self
        recipientsTableView.dataSource = self
        recipientsTableView.register(RecipientCell.self, forCellReuseIdentifier: "RecipientCell")
        recipientsTableView.isScrollEnabled = false
        recipientsTableView.translatesAutoresizingMaskIntoConstraints = false
        
        totalVerificationLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        totalVerificationLabel.textColor = UIColor.systemGreen
        totalVerificationLabel.textAlignment = .center
        totalVerificationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        previewSection.addSubview(previewTitleLabel)
        previewSection.addSubview(recipientsTableView)
        previewSection.addSubview(totalVerificationLabel)
        contentView.addSubview(previewSection)
    }
    
    private func setupActions() {
        actionContainer.translatesAutoresizingMaskIntoConstraints = false
        
        calculateButton.setTitle("Calculate Distribution", for: .normal)
        calculateButton.setTitleColor(.white, for: .normal)
        calculateButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        calculateButton.backgroundColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        calculateButton.layer.cornerRadius = 8
        calculateButton.addTarget(self, action: #selector(calculateDistribution), for: .touchUpInside)
        calculateButton.translatesAutoresizingMaskIntoConstraints = false
        
        previewButton.setTitle("Preview Changes", for: .normal)
        previewButton.setTitleColor(.white, for: .normal)
        previewButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        previewButton.backgroundColor = IndustrialDesign.Colors.cardBackground
        previewButton.layer.cornerRadius = 8
        previewButton.addTarget(self, action: #selector(previewDistribution), for: .touchUpInside)
        previewButton.isHidden = true
        previewButton.translatesAutoresizingMaskIntoConstraints = false
        
        executeButton.setTitle("Execute Distribution", for: .normal)
        executeButton.setTitleColor(.white, for: .normal)
        executeButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        executeButton.backgroundColor = UIColor.systemGreen
        executeButton.layer.cornerRadius = 8
        executeButton.addTarget(self, action: #selector(executeDistribution), for: .touchUpInside)
        executeButton.isEnabled = false
        executeButton.alpha = 0.5
        executeButton.translatesAutoresizingMaskIntoConstraints = false
        
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cancelButton.backgroundColor = .clear
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = IndustrialDesign.Colors.secondaryText.cgColor
        cancelButton.layer.cornerRadius = 8
        cancelButton.addTarget(self, action: #selector(cancelDistribution), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        actionContainer.addSubview(calculateButton)
        actionContainer.addSubview(previewButton)
        actionContainer.addSubview(executeButton)
        actionContainer.addSubview(cancelButton)
        contentView.addSubview(actionContainer)
    }
    
    private func setupCustomAmountSection() {
        customAmountContainer.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.9)
        customAmountContainer.layer.cornerRadius = 12
        customAmountContainer.layer.borderWidth = 1
        customAmountContainer.layer.borderColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        customAmountContainer.isHidden = true
        customAmountContainer.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(customAmountContainer)
    }
    
    private func setupStatusView() {
        statusView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.9)
        statusView.layer.cornerRadius = 8
        statusView.isHidden = true
        statusView.translatesAutoresizingMaskIntoConstraints = false
        
        statusLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        statusView.addSubview(statusLabel)
        contentView.addSubview(statusView)
    }
    
    private func setupConstraints() {
        let spacing: CGFloat = 20
        
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
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: spacing),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: spacing),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -spacing),
            headerView.heightAnchor.constraint(equalToConstant: 120),
            
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            
            eventLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            eventLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            
            prizeAmountLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            prizeAmountLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            walletBalanceLabel.topAnchor.constraint(equalTo: prizeAmountLabel.bottomAnchor, constant: 4),
            walletBalanceLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            // Method section
            methodSection.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: spacing),
            methodSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: spacing),
            methodSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -spacing),
            methodSection.heightAnchor.constraint(equalToConstant: 140),
            
            methodTitleLabel.topAnchor.constraint(equalTo: methodSection.topAnchor, constant: 16),
            methodTitleLabel.leadingAnchor.constraint(equalTo: methodSection.leadingAnchor, constant: 16),
            
            methodSegmentedControl.topAnchor.constraint(equalTo: methodTitleLabel.bottomAnchor, constant: 12),
            methodSegmentedControl.leadingAnchor.constraint(equalTo: methodSection.leadingAnchor, constant: 16),
            methodSegmentedControl.trailingAnchor.constraint(equalTo: methodSection.trailingAnchor, constant: -16),
            methodSegmentedControl.heightAnchor.constraint(equalToConstant: 32),
            
            methodDescriptionLabel.topAnchor.constraint(equalTo: methodSegmentedControl.bottomAnchor, constant: 12),
            methodDescriptionLabel.leadingAnchor.constraint(equalTo: methodSection.leadingAnchor, constant: 16),
            methodDescriptionLabel.trailingAnchor.constraint(equalTo: methodSection.trailingAnchor, constant: -16),
            
            // Custom amount section
            customAmountContainer.topAnchor.constraint(equalTo: methodSection.bottomAnchor, constant: spacing),
            customAmountContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: spacing),
            customAmountContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -spacing),
            customAmountContainer.heightAnchor.constraint(equalToConstant: 200),
            
            // Preview section
            previewSection.topAnchor.constraint(equalTo: customAmountContainer.bottomAnchor, constant: spacing),
            previewSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: spacing),
            previewSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -spacing),
            previewSection.heightAnchor.constraint(equalToConstant: 300),
            
            previewTitleLabel.topAnchor.constraint(equalTo: previewSection.topAnchor, constant: 16),
            previewTitleLabel.leadingAnchor.constraint(equalTo: previewSection.leadingAnchor, constant: 16),
            
            recipientsTableView.topAnchor.constraint(equalTo: previewTitleLabel.bottomAnchor, constant: 12),
            recipientsTableView.leadingAnchor.constraint(equalTo: previewSection.leadingAnchor, constant: 16),
            recipientsTableView.trailingAnchor.constraint(equalTo: previewSection.trailingAnchor, constant: -16),
            recipientsTableView.bottomAnchor.constraint(equalTo: totalVerificationLabel.topAnchor, constant: -8),
            
            totalVerificationLabel.leadingAnchor.constraint(equalTo: previewSection.leadingAnchor, constant: 16),
            totalVerificationLabel.trailingAnchor.constraint(equalTo: previewSection.trailingAnchor, constant: -16),
            totalVerificationLabel.bottomAnchor.constraint(equalTo: previewSection.bottomAnchor, constant: -16),
            
            // Status view
            statusView.topAnchor.constraint(equalTo: previewSection.bottomAnchor, constant: spacing),
            statusView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: spacing),
            statusView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -spacing),
            statusView.heightAnchor.constraint(equalToConstant: 40),
            
            statusLabel.centerXAnchor.constraint(equalTo: statusView.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: statusView.centerYAnchor),
            
            // Action buttons
            actionContainer.topAnchor.constraint(equalTo: statusView.bottomAnchor, constant: spacing),
            actionContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: spacing),
            actionContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -spacing),
            actionContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -spacing),
            actionContainer.heightAnchor.constraint(equalToConstant: 100),
            
            calculateButton.topAnchor.constraint(equalTo: actionContainer.topAnchor),
            calculateButton.leadingAnchor.constraint(equalTo: actionContainer.leadingAnchor),
            calculateButton.widthAnchor.constraint(equalTo: actionContainer.widthAnchor, multiplier: 0.48),
            calculateButton.heightAnchor.constraint(equalToConstant: 44),
            
            previewButton.topAnchor.constraint(equalTo: actionContainer.topAnchor),
            previewButton.trailingAnchor.constraint(equalTo: actionContainer.trailingAnchor),
            previewButton.widthAnchor.constraint(equalTo: actionContainer.widthAnchor, multiplier: 0.48),
            previewButton.heightAnchor.constraint(equalToConstant: 44),
            
            executeButton.topAnchor.constraint(equalTo: calculateButton.bottomAnchor, constant: 12),
            executeButton.leadingAnchor.constraint(equalTo: actionContainer.leadingAnchor),
            executeButton.widthAnchor.constraint(equalTo: actionContainer.widthAnchor, multiplier: 0.48),
            executeButton.heightAnchor.constraint(equalToConstant: 44),
            
            cancelButton.topAnchor.constraint(equalTo: previewButton.bottomAnchor, constant: 12),
            cancelButton.trailingAnchor.constraint(equalTo: actionContainer.trailingAnchor),
            cancelButton.widthAnchor.constraint(equalTo: actionContainer.widthAnchor, multiplier: 0.48),
            cancelButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - Data Loading
    
    private func loadTeamWalletInfo() {
        if let wallet = distributionService.getTeamWallet(teamId: teamData.id) {
            walletBalanceLabel.text = "Team Wallet: ₿\(Int(wallet.availableBalance)) available"
            
            // Validate prize amount against available balance
            if wallet.availableBalance < eventData.prizePool {
                showInsufficientBalanceWarning()
            }
        } else {
            walletBalanceLabel.text = "Team wallet not found"
        }
    }
    
    private func showInsufficientBalanceWarning() {
        statusView.isHidden = false
        statusView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.2)
        statusLabel.textColor = UIColor.systemRed
        statusLabel.text = "⚠️ Insufficient team wallet balance for this distribution"
        
        executeButton.isEnabled = false
        executeButton.alpha = 0.5
    }
    
    // MARK: - Actions
    
    @objc private func methodChanged() {
        updateMethodDescription()
        
        // Show/hide custom amount section
        let isCustomMethod = methodSegmentedControl.selectedSegmentIndex == 4
        customAmountContainer.isHidden = !isCustomMethod
        
        if isCustomMethod {
            setupCustomAmountInputs()
        }
        
        // Clear existing distribution
        prizeDistribution = nil
        recipientsTableView.reloadData()
        updateExecuteButtonState()
    }
    
    private func updateMethodDescription() {
        let descriptions = [
            "Split the prize equally among all team members regardless of performance.",
            "Distribute based on individual performance metrics like distance, workouts, and points.",
            "Only reward the top 50% of performers based on their contribution to the team.",
            "Combine equal distribution (50%) with performance-based rewards (50%).",
            "Set custom amounts for each team member manually."
        ]
        
        methodDescriptionLabel.text = descriptions[methodSegmentedControl.selectedSegmentIndex]
    }
    
    private func setupCustomAmountInputs() {
        // Clear existing fields
        customAmountFields.forEach { $0.value.removeFromSuperview() }
        customAmountFields.removeAll()
        
        // In a real implementation, get actual team members
        let teamMembers = ["Alice", "Bob", "Charlie", "Diana", "Eve"]
        
        var previousField: UIView = customAmountContainer
        
        for (index, member) in teamMembers.enumerated() {
            let fieldContainer = UIView()
            fieldContainer.translatesAutoresizingMaskIntoConstraints = false
            
            let nameLabel = UILabel()
            nameLabel.text = member
            nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            nameLabel.textColor = IndustrialDesign.Colors.primaryText
            nameLabel.translatesAutoresizingMaskIntoConstraints = false
            
            let amountField = UITextField()
            amountField.placeholder = "0"
            amountField.keyboardType = .numberPad
            amountField.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
            amountField.textColor = IndustrialDesign.Colors.primaryText
            amountField.layer.cornerRadius = 6
            amountField.layer.borderWidth = 1
            amountField.layer.borderColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0).cgColor
            amountField.translatesAutoresizingMaskIntoConstraints = false
            
            // Add padding to text field
            amountField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
            amountField.leftViewMode = .always
            
            customAmountFields[member] = amountField
            
            fieldContainer.addSubview(nameLabel)
            fieldContainer.addSubview(amountField)
            customAmountContainer.addSubview(fieldContainer)
            
            NSLayoutConstraint.activate([
                fieldContainer.topAnchor.constraint(equalTo: index == 0 ? customAmountContainer.topAnchor : previousField.bottomAnchor, constant: 8),
                fieldContainer.leadingAnchor.constraint(equalTo: customAmountContainer.leadingAnchor, constant: 16),
                fieldContainer.trailingAnchor.constraint(equalTo: customAmountContainer.trailingAnchor, constant: -16),
                fieldContainer.heightAnchor.constraint(equalToConstant: 30),
                
                nameLabel.leadingAnchor.constraint(equalTo: fieldContainer.leadingAnchor),
                nameLabel.centerYAnchor.constraint(equalTo: fieldContainer.centerYAnchor),
                nameLabel.widthAnchor.constraint(equalToConstant: 80),
                
                amountField.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 12),
                amountField.trailingAnchor.constraint(equalTo: fieldContainer.trailingAnchor),
                amountField.centerYAnchor.constraint(equalTo: fieldContainer.centerYAnchor),
                amountField.heightAnchor.constraint(equalToConstant: 30)
            ])
            
            previousField = fieldContainer
        }
    }
    
    @objc private func calculateDistribution() {
        let selectedMethod = getSelectedDistributionMethod()
        
        showStatus("Calculating distribution...", color: UIColor.systemOrange)
        
        let result = distributionService.createDistribution(
            eventId: eventData.id,
            teamId: teamData.id,
            method: selectedMethod,
            totalPrize: eventData.prizePool,
            captainUserId: getCurrentCaptainId(),
            notes: "Distribution for \(eventData.name)"
        )
        
        switch result {
        case .success(let distribution):
            self.prizeDistribution = distribution
            recipientsTableView.reloadData()
            updateTotalVerification()
            updateExecuteButtonState()
            showStatus("Distribution calculated successfully", color: UIColor.systemGreen)
            
        case .failure(let error):
            showError("Failed to calculate distribution: \(error.localizedDescription)")
        }
    }
    
    @objc private func previewDistribution() {
        // Show detailed preview modal
        guard let distribution = prizeDistribution else { return }
        
        let previewAlert = createDistributionPreviewAlert(distribution: distribution)
        present(previewAlert, animated: true)
    }
    
    @objc private func executeDistribution() {
        guard let distribution = prizeDistribution else { return }
        
        let confirmAlert = UIAlertController(
            title: "Execute Distribution",
            message: "Are you sure you want to execute this prize distribution? This action cannot be undone.",
            preferredStyle: .alert
        )
        
        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        confirmAlert.addAction(UIAlertAction(title: "Execute", style: .destructive) { _ in
            self.performDistributionExecution(distribution: distribution)
        })
        
        present(confirmAlert, animated: true)
    }
    
    @objc private func cancelDistribution() {
        dismiss(animated: true)
    }
    
    // MARK: - Distribution Execution
    
    private func performDistributionExecution(distribution: PrizeDistribution) {
        showStatus("Executing distribution...", color: UIColor.systemOrange)
        
        // Disable all buttons during execution
        setButtonsEnabled(false)
        
        let result = distributionService.executeDistribution(distributionId: distribution.distributionId)
        
        switch result {
        case .success:
            showStatus("Distribution executed successfully! 🎉", color: UIColor.systemGreen)
            
            // Show success modal with results
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showExecutionSuccessModal()
            }
            
        case .failure(let error):
            showError("Distribution execution failed: \(error.localizedDescription)")
            setButtonsEnabled(true)
        }
    }
    
    private func showExecutionSuccessModal() {
        let successAlert = UIAlertController(
            title: "Distribution Complete! 🏆",
            message: "Prize distribution has been executed successfully. All team members have been notified and Bitcoin has been sent to their wallets.",
            preferredStyle: .alert
        )
        
        successAlert.addAction(UIAlertAction(title: "View Details", style: .default) { _ in
            // In a real implementation, show detailed results
            self.dismiss(animated: true)
        })
        
        successAlert.addAction(UIAlertAction(title: "Done", style: .default) { _ in
            self.dismiss(animated: true)
        })
        
        present(successAlert, animated: true)
    }
    
    // MARK: - Helper Methods
    
    private func getSelectedDistributionMethod() -> DistributionMethod {
        switch methodSegmentedControl.selectedSegmentIndex {
        case 0: return .equal
        case 1: return .performance
        case 2: return .topPerformers
        case 3: return .hybrid
        case 4: return .custom
        default: return .equal
        }
    }
    
    private func getCurrentCaptainId() -> String {
        // In a real implementation, get from authentication
        return "captain_user"
    }
    
    private func updateTotalVerification() {
        guard let distribution = prizeDistribution else {
            totalVerificationLabel.text = ""
            return
        }
        
        let totalAllocated = distribution.recipients.reduce(0) { $0 + $1.allocation }
        let isValid = abs(totalAllocated - distribution.totalPrize) < 1.0 // Allow 1 sat tolerance
        
        if isValid {
            totalVerificationLabel.text = "✓ Total: ₿\(Int(totalAllocated)) (Valid)"
            totalVerificationLabel.textColor = UIColor.systemGreen
        } else {
            totalVerificationLabel.text = "⚠️ Total: ₿\(Int(totalAllocated)) (Invalid - should be ₿\(Int(distribution.totalPrize)))"
            totalVerificationLabel.textColor = UIColor.systemRed
        }
    }
    
    private func updateExecuteButtonState() {
        let hasValidDistribution = prizeDistribution != nil
        
        executeButton.isEnabled = hasValidDistribution
        executeButton.alpha = hasValidDistribution ? 1.0 : 0.5
        previewButton.isHidden = !hasValidDistribution
    }
    
    private func setButtonsEnabled(_ enabled: Bool) {
        calculateButton.isEnabled = enabled
        previewButton.isEnabled = enabled
        executeButton.isEnabled = enabled && prizeDistribution != nil
        cancelButton.isEnabled = enabled
    }
    
    private func showStatus(_ message: String, color: UIColor) {
        statusView.isHidden = false
        statusView.backgroundColor = color.withAlphaComponent(0.2)
        statusLabel.textColor = color
        statusLabel.text = message
    }
    
    private func showError(_ message: String) {
        showStatus(message, color: UIColor.systemRed)
    }
    
    private func createDistributionPreviewAlert(distribution: PrizeDistribution) -> UIAlertController {
        let alert = UIAlertController(
            title: "Distribution Preview",
            message: "Method: \(distribution.distributionMethod)\nTotal Prize: ₿\(Int(distribution.totalPrize))\nRecipients: \(distribution.recipients.count)",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        alert.addAction(UIAlertAction(title: "Execute", style: .default) { _ in
            self.performDistributionExecution(distribution: distribution)
        })
        
        return alert
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension PrizeDistributionViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return prizeDistribution?.recipients.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "RecipientCell", for: indexPath) as? RecipientCell else {
            return UITableViewCell()
        }
        
        if let recipient = prizeDistribution?.recipients[indexPath.row] {
            cell.configure(with: recipient)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

// MARK: - RecipientCell

class RecipientCell: UITableViewCell {
    
    private let nameLabel = UILabel()
    private let allocationLabel = UILabel()
    private let percentageLabel = UILabel()
    private let reasonLabel = UILabel()
    private let performanceLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }
    
    private func setupCell() {
        backgroundColor = .clear
        selectionStyle = .none
        
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = IndustrialDesign.Colors.primaryText
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        allocationLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        allocationLabel.textColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        allocationLabel.textAlignment = .right
        allocationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        percentageLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        percentageLabel.textColor = IndustrialDesign.Colors.secondaryText
        percentageLabel.textAlignment = .right
        percentageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        reasonLabel.font = UIFont.systemFont(ofSize: 12)
        reasonLabel.textColor = IndustrialDesign.Colors.secondaryText
        reasonLabel.numberOfLines = 2
        reasonLabel.translatesAutoresizingMaskIntoConstraints = false
        
        performanceLabel.font = UIFont.systemFont(ofSize: 10)
        performanceLabel.textColor = IndustrialDesign.Colors.secondaryText
        performanceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(nameLabel)
        contentView.addSubview(allocationLabel)
        contentView.addSubview(percentageLabel)
        contentView.addSubview(reasonLabel)
        contentView.addSubview(performanceLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.widthAnchor.constraint(equalToConstant: 100),
            
            allocationLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            allocationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            allocationLabel.widthAnchor.constraint(equalToConstant: 80),
            
            percentageLabel.topAnchor.constraint(equalTo: allocationLabel.bottomAnchor, constant: 2),
            percentageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            percentageLabel.widthAnchor.constraint(equalToConstant: 80),
            
            reasonLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            reasonLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            reasonLabel.trailingAnchor.constraint(equalTo: allocationLabel.leadingAnchor, constant: -8),
            
            performanceLabel.topAnchor.constraint(equalTo: reasonLabel.bottomAnchor, constant: 2),
            performanceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
        ])
    }
    
    func configure(with recipient: PrizeRecipient) {
        nameLabel.text = recipient.username
        allocationLabel.text = "₿\(Int(recipient.allocation))"
        percentageLabel.text = "\(String(format: "%.1f", recipient.percentage))%"
        reasonLabel.text = recipient.reason
        
        if let performance = recipient.performance {
            performanceLabel.text = "Rank #\(performance.rank) • \(performance.points) pts • \(performance.totalWorkouts) workouts"
        } else {
            performanceLabel.text = ""
        }
    }
}