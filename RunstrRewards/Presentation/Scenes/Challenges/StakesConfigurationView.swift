import UIKit

protocol StakesConfigurationDelegate: AnyObject {
    func stakesConfigurationDidChange(amount: Int)
    func teamFeePercentageDidChange(percentage: Int)
}

class StakesConfigurationView: UIView {
    
    // MARK: - Properties
    weak var delegate: StakesConfigurationDelegate?
    private var challengeData: ChallengeCreationData?
    
    private var currentStakeAmount: Int = 0 {
        didSet {
            updateCalculations()
            delegate?.stakesConfigurationDidChange(amount: currentStakeAmount)
        }
    }
    
    private var teamFeePercentage: Int = 10 {
        didSet {
            updateCalculations()
            delegate?.teamFeePercentageDidChange(percentage: teamFeePercentage)
        }
    }
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // Stakes toggle
    private let stakesToggleContainer = UIView()
    private let stakesToggleLabel = UILabel()
    private let stakesToggleSwitch = UISwitch()
    
    // Stakes amount configuration (hidden by default)
    private let stakesAmountContainer = UIView()
    private let amountTitleLabel = UILabel()
    private let amountTextField = UITextField()
    private let satoshiLabel = UILabel()
    private let presetButtonsContainer = UIView()
    private let presetStackView = UIStackView()
    
    // Team fee configuration
    private let teamFeeContainer = UIView()
    private let teamFeeTitleLabel = UILabel()
    private let teamFeeDescriptionLabel = UILabel()
    private let teamFeeSlider = UISlider()
    private let teamFeeValueLabel = UILabel()
    
    // Calculation breakdown
    private let breakdownContainer = UIView()
    private let breakdownTitleLabel = UILabel()
    private let totalPotLabel = UILabel()
    private let teamFeeAmountLabel = UILabel()
    private let winnerPayoutLabel = UILabel()
    
    // Wallet balance info
    private let walletInfoContainer = UIView()
    private let walletBalanceLabel = UILabel()
    private let walletWarningLabel = UILabel()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        configureInitialState()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        backgroundColor = .clear
        
        // Scroll view
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Header
        titleLabel.text = "Stakes & Rewards"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        subtitleLabel.text = "Add Bitcoin stakes to make it interesting (optional)"
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = IndustrialDesign.Colors.secondaryText
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Stakes toggle
        setupStakesToggle()
        
        // Stakes amount configuration  
        setupStakesAmountConfiguration()
        
        // Team fee configuration
        setupTeamFeeConfiguration()
        
        // Calculation breakdown
        setupCalculationBreakdown()
        
        // Wallet info
        setupWalletInfo()
        
        // Add to hierarchy
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(stakesToggleContainer)
        contentView.addSubview(stakesAmountContainer)
        contentView.addSubview(teamFeeContainer)
        contentView.addSubview(breakdownContainer)
        contentView.addSubview(walletInfoContainer)
    }
    
    private func setupStakesToggle() {
        stakesToggleContainer.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.8)
        stakesToggleContainer.layer.cornerRadius = 12
        stakesToggleContainer.layer.borderWidth = 1
        stakesToggleContainer.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        stakesToggleContainer.translatesAutoresizingMaskIntoConstraints = false
        
        stakesToggleLabel.text = "Add Bitcoin Stakes"
        stakesToggleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        stakesToggleLabel.textColor = IndustrialDesign.Colors.primaryText
        stakesToggleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        stakesToggleSwitch.onTintColor = IndustrialDesign.Colors.bitcoin
        stakesToggleSwitch.translatesAutoresizingMaskIntoConstraints = false
        stakesToggleSwitch.addTarget(self, action: #selector(stakesToggled(_:)), for: .valueChanged)
        
        stakesToggleContainer.addSubview(stakesToggleLabel)
        stakesToggleContainer.addSubview(stakesToggleSwitch)
    }
    
    private func setupStakesAmountConfiguration() {
        stakesAmountContainer.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.8)
        stakesAmountContainer.layer.cornerRadius = 12
        stakesAmountContainer.layer.borderWidth = 1
        stakesAmountContainer.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        stakesAmountContainer.translatesAutoresizingMaskIntoConstraints = false
        stakesAmountContainer.isHidden = true
        
        // Amount title
        amountTitleLabel.text = "Stake Amount (per person)"
        amountTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        amountTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        amountTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Amount input
        amountTextField.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
        amountTextField.textColor = IndustrialDesign.Colors.primaryText
        amountTextField.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        amountTextField.layer.cornerRadius = 8
        amountTextField.layer.borderWidth = 1
        amountTextField.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        amountTextField.textAlignment = .center
        amountTextField.keyboardType = .numberPad
        amountTextField.placeholder = "0"
        amountTextField.translatesAutoresizingMaskIntoConstraints = false
        amountTextField.addTarget(self, action: #selector(amountChanged(_:)), for: .editingChanged)
        
        // Satoshi label
        satoshiLabel.text = "satoshis"
        satoshiLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        satoshiLabel.textColor = IndustrialDesign.Colors.bitcoin
        satoshiLabel.textAlignment = .center
        satoshiLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Preset buttons
        setupPresetButtons()
        
        stakesAmountContainer.addSubview(amountTitleLabel)
        stakesAmountContainer.addSubview(amountTextField)
        stakesAmountContainer.addSubview(satoshiLabel)
        stakesAmountContainer.addSubview(presetButtonsContainer)
    }
    
    private func setupPresetButtons() {
        presetButtonsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        presetStackView.axis = .horizontal
        presetStackView.distribution = .fillEqually
        presetStackView.spacing = 12
        presetStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let presetAmounts = ChallengeConstants.Stakes.presetAmounts
        for amount in presetAmounts {
            let button = createPresetButton(amount: amount)
            presetStackView.addArrangedSubview(button)
        }
        
        presetButtonsContainer.addSubview(presetStackView)
    }
    
    private func createPresetButton(amount: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("\(amount)", for: .normal)
        button.setTitleColor(IndustrialDesign.Colors.bitcoin, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = IndustrialDesign.Colors.bitcoin.withAlphaComponent(0.3).cgColor
        button.tag = amount
        button.addTarget(self, action: #selector(presetButtonTapped(_:)), for: .touchUpInside)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 36).isActive = true
        
        return button
    }
    
    private func setupTeamFeeConfiguration() {
        teamFeeContainer.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.8)
        teamFeeContainer.layer.cornerRadius = 12
        teamFeeContainer.layer.borderWidth = 1
        teamFeeContainer.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        teamFeeContainer.translatesAutoresizingMaskIntoConstraints = false
        teamFeeContainer.isHidden = true
        
        teamFeeTitleLabel.text = "Team Arbitration Fee"
        teamFeeTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        teamFeeTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        teamFeeTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        teamFeeDescriptionLabel.text = "The team keeps this percentage to handle disputes and distribute prizes"
        teamFeeDescriptionLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        teamFeeDescriptionLabel.textColor = IndustrialDesign.Colors.secondaryText
        teamFeeDescriptionLabel.numberOfLines = 0
        teamFeeDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        teamFeeSlider.minimumValue = Float(ChallengeConstants.TeamFees.minimumPercentage)
        teamFeeSlider.maximumValue = Float(ChallengeConstants.TeamFees.maximumPercentage)
        teamFeeSlider.value = Float(ChallengeConstants.TeamFees.defaultPercentage)
        teamFeeSlider.tintColor = IndustrialDesign.Colors.bitcoin
        teamFeeSlider.translatesAutoresizingMaskIntoConstraints = false
        teamFeeSlider.addTarget(self, action: #selector(teamFeeSliderChanged(_:)), for: .valueChanged)
        
        teamFeeValueLabel.text = "10%"
        teamFeeValueLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        teamFeeValueLabel.textColor = IndustrialDesign.Colors.bitcoin
        teamFeeValueLabel.textAlignment = .center
        teamFeeValueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        teamFeeContainer.addSubview(teamFeeTitleLabel)
        teamFeeContainer.addSubview(teamFeeDescriptionLabel)
        teamFeeContainer.addSubview(teamFeeSlider)
        teamFeeContainer.addSubview(teamFeeValueLabel)
    }
    
    private func setupCalculationBreakdown() {
        breakdownContainer.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.9)
        breakdownContainer.layer.cornerRadius = 12
        breakdownContainer.layer.borderWidth = 1
        breakdownContainer.layer.borderColor = IndustrialDesign.Colors.bitcoin.withAlphaComponent(0.5).cgColor
        breakdownContainer.translatesAutoresizingMaskIntoConstraints = false
        breakdownContainer.isHidden = true
        
        breakdownTitleLabel.text = "Prize Breakdown"
        breakdownTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        breakdownTitleLabel.textColor = IndustrialDesign.Colors.bitcoin
        breakdownTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        totalPotLabel.text = "Total Pot: 0 sats"
        totalPotLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        totalPotLabel.textColor = IndustrialDesign.Colors.primaryText
        totalPotLabel.translatesAutoresizingMaskIntoConstraints = false
        
        teamFeeAmountLabel.text = "Team Fee: 0 sats"
        teamFeeAmountLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        teamFeeAmountLabel.textColor = IndustrialDesign.Colors.secondaryText
        teamFeeAmountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        winnerPayoutLabel.text = "Winner Gets: 0 sats"
        winnerPayoutLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        winnerPayoutLabel.textColor = IndustrialDesign.Colors.bitcoin
        winnerPayoutLabel.translatesAutoresizingMaskIntoConstraints = false
        
        breakdownContainer.addSubview(breakdownTitleLabel)
        breakdownContainer.addSubview(totalPotLabel)
        breakdownContainer.addSubview(teamFeeAmountLabel)
        breakdownContainer.addSubview(winnerPayoutLabel)
    }
    
    private func setupWalletInfo() {
        walletInfoContainer.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.8)
        walletInfoContainer.layer.cornerRadius = 12
        walletInfoContainer.layer.borderWidth = 1
        walletInfoContainer.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        walletInfoContainer.translatesAutoresizingMaskIntoConstraints = false
        walletInfoContainer.isHidden = true
        
        walletBalanceLabel.text = "Wallet Balance: Loading..."
        walletBalanceLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        walletBalanceLabel.textColor = IndustrialDesign.Colors.primaryText
        walletBalanceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        walletWarningLabel.text = ""
        walletWarningLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        walletWarningLabel.textColor = UIColor.systemOrange
        walletWarningLabel.numberOfLines = 0
        walletWarningLabel.translatesAutoresizingMaskIntoConstraints = false
        walletWarningLabel.isHidden = true
        
        walletInfoContainer.addSubview(walletBalanceLabel)
        walletInfoContainer.addSubview(walletWarningLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Header
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            // Stakes toggle
            stakesToggleContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            stakesToggleContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stakesToggleContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stakesToggleContainer.heightAnchor.constraint(equalToConstant: 60),
            
            stakesToggleLabel.leadingAnchor.constraint(equalTo: stakesToggleContainer.leadingAnchor, constant: 16),
            stakesToggleLabel.centerYAnchor.constraint(equalTo: stakesToggleContainer.centerYAnchor),
            
            stakesToggleSwitch.trailingAnchor.constraint(equalTo: stakesToggleContainer.trailingAnchor, constant: -16),
            stakesToggleSwitch.centerYAnchor.constraint(equalTo: stakesToggleContainer.centerYAnchor),
            
            // Stakes amount container
            stakesAmountContainer.topAnchor.constraint(equalTo: stakesToggleContainer.bottomAnchor, constant: 12),
            stakesAmountContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stakesAmountContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            amountTitleLabel.topAnchor.constraint(equalTo: stakesAmountContainer.topAnchor, constant: 16),
            amountTitleLabel.leadingAnchor.constraint(equalTo: stakesAmountContainer.leadingAnchor, constant: 16),
            amountTitleLabel.trailingAnchor.constraint(equalTo: stakesAmountContainer.trailingAnchor, constant: -16),
            
            amountTextField.topAnchor.constraint(equalTo: amountTitleLabel.bottomAnchor, constant: 12),
            amountTextField.centerXAnchor.constraint(equalTo: stakesAmountContainer.centerXAnchor),
            amountTextField.widthAnchor.constraint(equalToConstant: 120),
            amountTextField.heightAnchor.constraint(equalToConstant: 50),
            
            satoshiLabel.topAnchor.constraint(equalTo: amountTextField.bottomAnchor, constant: 4),
            satoshiLabel.centerXAnchor.constraint(equalTo: amountTextField.centerXAnchor),
            
            presetButtonsContainer.topAnchor.constraint(equalTo: satoshiLabel.bottomAnchor, constant: 16),
            presetButtonsContainer.leadingAnchor.constraint(equalTo: stakesAmountContainer.leadingAnchor, constant: 16),
            presetButtonsContainer.trailingAnchor.constraint(equalTo: stakesAmountContainer.trailingAnchor, constant: -16),
            presetButtonsContainer.bottomAnchor.constraint(equalTo: stakesAmountContainer.bottomAnchor, constant: -16),
            
            presetStackView.topAnchor.constraint(equalTo: presetButtonsContainer.topAnchor),
            presetStackView.leadingAnchor.constraint(equalTo: presetButtonsContainer.leadingAnchor),
            presetStackView.trailingAnchor.constraint(equalTo: presetButtonsContainer.trailingAnchor),
            presetStackView.bottomAnchor.constraint(equalTo: presetButtonsContainer.bottomAnchor),
            
            // Team fee container
            teamFeeContainer.topAnchor.constraint(equalTo: stakesAmountContainer.bottomAnchor, constant: 12),
            teamFeeContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            teamFeeContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            teamFeeTitleLabel.topAnchor.constraint(equalTo: teamFeeContainer.topAnchor, constant: 16),
            teamFeeTitleLabel.leadingAnchor.constraint(equalTo: teamFeeContainer.leadingAnchor, constant: 16),
            teamFeeTitleLabel.trailingAnchor.constraint(equalTo: teamFeeValueLabel.leadingAnchor, constant: -8),
            
            teamFeeValueLabel.topAnchor.constraint(equalTo: teamFeeContainer.topAnchor, constant: 16),
            teamFeeValueLabel.trailingAnchor.constraint(equalTo: teamFeeContainer.trailingAnchor, constant: -16),
            teamFeeValueLabel.widthAnchor.constraint(equalToConstant: 60),
            
            teamFeeDescriptionLabel.topAnchor.constraint(equalTo: teamFeeTitleLabel.bottomAnchor, constant: 4),
            teamFeeDescriptionLabel.leadingAnchor.constraint(equalTo: teamFeeContainer.leadingAnchor, constant: 16),
            teamFeeDescriptionLabel.trailingAnchor.constraint(equalTo: teamFeeContainer.trailingAnchor, constant: -16),
            
            teamFeeSlider.topAnchor.constraint(equalTo: teamFeeDescriptionLabel.bottomAnchor, constant: 12),
            teamFeeSlider.leadingAnchor.constraint(equalTo: teamFeeContainer.leadingAnchor, constant: 16),
            teamFeeSlider.trailingAnchor.constraint(equalTo: teamFeeContainer.trailingAnchor, constant: -16),
            teamFeeSlider.bottomAnchor.constraint(equalTo: teamFeeContainer.bottomAnchor, constant: -16),
            
            // Breakdown container
            breakdownContainer.topAnchor.constraint(equalTo: teamFeeContainer.bottomAnchor, constant: 12),
            breakdownContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            breakdownContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            breakdownTitleLabel.topAnchor.constraint(equalTo: breakdownContainer.topAnchor, constant: 16),
            breakdownTitleLabel.leadingAnchor.constraint(equalTo: breakdownContainer.leadingAnchor, constant: 16),
            breakdownTitleLabel.trailingAnchor.constraint(equalTo: breakdownContainer.trailingAnchor, constant: -16),
            
            totalPotLabel.topAnchor.constraint(equalTo: breakdownTitleLabel.bottomAnchor, constant: 8),
            totalPotLabel.leadingAnchor.constraint(equalTo: breakdownContainer.leadingAnchor, constant: 16),
            totalPotLabel.trailingAnchor.constraint(equalTo: breakdownContainer.trailingAnchor, constant: -16),
            
            teamFeeAmountLabel.topAnchor.constraint(equalTo: totalPotLabel.bottomAnchor, constant: 4),
            teamFeeAmountLabel.leadingAnchor.constraint(equalTo: breakdownContainer.leadingAnchor, constant: 16),
            teamFeeAmountLabel.trailingAnchor.constraint(equalTo: breakdownContainer.trailingAnchor, constant: -16),
            
            winnerPayoutLabel.topAnchor.constraint(equalTo: teamFeeAmountLabel.bottomAnchor, constant: 8),
            winnerPayoutLabel.leadingAnchor.constraint(equalTo: breakdownContainer.leadingAnchor, constant: 16),
            winnerPayoutLabel.trailingAnchor.constraint(equalTo: breakdownContainer.trailingAnchor, constant: -16),
            winnerPayoutLabel.bottomAnchor.constraint(equalTo: breakdownContainer.bottomAnchor, constant: -16),
            
            // Wallet info container
            walletInfoContainer.topAnchor.constraint(equalTo: breakdownContainer.bottomAnchor, constant: 12),
            walletInfoContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            walletInfoContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            walletInfoContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            walletBalanceLabel.topAnchor.constraint(equalTo: walletInfoContainer.topAnchor, constant: 16),
            walletBalanceLabel.leadingAnchor.constraint(equalTo: walletInfoContainer.leadingAnchor, constant: 16),
            walletBalanceLabel.trailingAnchor.constraint(equalTo: walletInfoContainer.trailingAnchor, constant: -16),
            
            walletWarningLabel.topAnchor.constraint(equalTo: walletBalanceLabel.bottomAnchor, constant: 8),
            walletWarningLabel.leadingAnchor.constraint(equalTo: walletInfoContainer.leadingAnchor, constant: 16),
            walletWarningLabel.trailingAnchor.constraint(equalTo: walletInfoContainer.trailingAnchor, constant: -16),
            walletWarningLabel.bottomAnchor.constraint(equalTo: walletInfoContainer.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with data: ChallengeCreationData) {
        self.challengeData = data
        
        // Set initial values
        currentStakeAmount = data.stakeAmount
        teamFeePercentage = data.teamArbitrationFee
        
        // Update UI
        amountTextField.text = currentStakeAmount > 0 ? String(currentStakeAmount) : ""
        stakesToggleSwitch.isOn = currentStakeAmount > 0
        teamFeeSlider.value = Float(teamFeePercentage)
        teamFeeValueLabel.text = "\(teamFeePercentage)%"
        
        // Show/hide stakes containers
        updateStakesVisibility()
        
        // Update calculations
        updateCalculations()
        
        // Load wallet balance
        loadWalletBalance()
    }
    
    private func configureInitialState() {
        updateStakesVisibility()
        updateCalculations()
    }
    
    // MARK: - Actions
    
    @objc private func stakesToggled(_ sender: UISwitch) {
        if !sender.isOn {
            currentStakeAmount = 0
            amountTextField.text = ""
        } else if currentStakeAmount == 0 {
            currentStakeAmount = ChallengeConstants.Stakes.defaultAmount
            amountTextField.text = String(ChallengeConstants.Stakes.defaultAmount)
        }
        
        updateStakesVisibility()
    }
    
    @objc private func amountChanged(_ textField: UITextField) {
        currentStakeAmount = Int(textField.text ?? "0") ?? 0
        validateStakeAmount()
    }
    
    @objc private func presetButtonTapped(_ sender: UIButton) {
        currentStakeAmount = sender.tag
        amountTextField.text = String(currentStakeAmount)
        stakesToggleSwitch.isOn = true
        updateStakesVisibility()
    }
    
    @objc private func teamFeeSliderChanged(_ sender: UISlider) {
        teamFeePercentage = Int(sender.value)
        teamFeeValueLabel.text = "\(teamFeePercentage)%"
    }
    
    // MARK: - Private Methods
    
    private func updateStakesVisibility() {
        let hasStakes = stakesToggleSwitch.isOn && currentStakeAmount > 0
        
        stakesAmountContainer.isHidden = !stakesToggleSwitch.isOn
        teamFeeContainer.isHidden = !hasStakes
        breakdownContainer.isHidden = !hasStakes
        walletInfoContainer.isHidden = !hasStakes
    }
    
    private func updateCalculations() {
        guard let challengeData = challengeData else { return }
        
        let participantCount = challengeData.selectedOpponents.count + 1 // +1 for challenger
        let totalPot = currentStakeAmount * participantCount
        let teamFeeAmount = (totalPot * teamFeePercentage) / 100
        let winnerPayout = totalPot - teamFeeAmount
        
        totalPotLabel.text = "Total Pot: \(totalPot.formatted()) sats"
        teamFeeAmountLabel.text = "Team Fee (\(teamFeePercentage)%): \(teamFeeAmount.formatted()) sats"
        winnerPayoutLabel.text = "Winner Gets: \(winnerPayout.formatted()) sats"
        
        // Update challenge data
        challengeData.stakeAmount = currentStakeAmount
        challengeData.teamArbitrationFee = teamFeePercentage
    }
    
    private func validateStakeAmount() {
        guard currentStakeAmount > 0 else {
            walletWarningLabel.isHidden = true
            return
        }
        
        // Check minimum amount
        if currentStakeAmount < ChallengeConstants.Stakes.minimumAmount {
            showWarning("Minimum stake is \(ChallengeConstants.Stakes.minimumAmount.formatted()) satoshis")
            return
        }
        
        // Check maximum amount
        if currentStakeAmount > ChallengeConstants.Stakes.maximumAmount {
            showWarning("Maximum stake is \(ChallengeConstants.Stakes.maximumAmount.formatted()) satoshis")
            return
        }
        
        walletWarningLabel.isHidden = true
        updateCalculations()
    }
    
    private func showWarning(_ message: String) {
        walletWarningLabel.text = message
        walletWarningLabel.isHidden = false
    }
    
    private func loadWalletBalance() {
        // TODO: Load actual wallet balance
        // For now, show placeholder
        walletBalanceLabel.text = "Wallet Balance: 50,000 sats"
    }
}

// MARK: - Int Extension for Formatting

private extension Int {
    func formatted() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? String(self)
    }
}