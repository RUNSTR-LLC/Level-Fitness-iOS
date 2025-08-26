import UIKit

protocol TeamDetailAboutSectionDelegate: AnyObject {
    func didTapManageWallet()
}

class TeamDetailAboutSection: UIView {
    
    // MARK: - Properties
    weak var delegate: TeamDetailAboutSectionDelegate?
    
    // MARK: - UI Components
    private let aboutTitleLabel = UILabel()
    private let aboutDescriptionLabel = UILabel()
    private let statsRow = UIView()
    private let prizePoolStat = StatItem(value: "0 sats", label: "Prize Pool", isBitcoin: true)
    private let walletStatusIndicator = UIView()
    private let walletStatusLabel = UILabel()
    private let manageWalletButton = UIButton(type: .custom)
    private let boltDecoration = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    private func setupView() {
        backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        clipsToBounds = false // Allow button to be visible and interactive outside bounds
        
        // Add bottom border
        let borderLayer = CALayer()
        borderLayer.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        borderLayer.frame = CGRect(x: 0, y: 139, width: UIScreen.main.bounds.width, height: 1)
        layer.addSublayer(borderLayer)
        
        // About title
        aboutTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        aboutTitleLabel.text = "ABOUT"
        aboutTitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        aboutTitleLabel.textColor = IndustrialDesign.Colors.secondaryText
        
        // About description
        aboutDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        aboutDescriptionLabel.text = "Loading team information..."
        aboutDescriptionLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        aboutDescriptionLabel.textColor = IndustrialDesign.Colors.primaryText
        aboutDescriptionLabel.numberOfLines = 3
        aboutDescriptionLabel.lineBreakMode = .byWordWrapping
        
        // Stats row
        statsRow.translatesAutoresizingMaskIntoConstraints = false
        
        prizePoolStat.translatesAutoresizingMaskIntoConstraints = false
        
        // Wallet status indicator
        walletStatusIndicator.translatesAutoresizingMaskIntoConstraints = false
        walletStatusIndicator.backgroundColor = UIColor.systemOrange
        walletStatusIndicator.layer.cornerRadius = 4
        walletStatusIndicator.layer.borderWidth = 1
        walletStatusIndicator.layer.borderColor = UIColor.systemOrange.withAlphaComponent(0.3).cgColor
        
        // Wallet status label
        walletStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        walletStatusLabel.text = "Wallet not configured"
        walletStatusLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        walletStatusLabel.textColor = UIColor.systemOrange
        
        // Manage wallet button (only visible to captains)
        manageWalletButton.setTitle("Manage Wallet", for: .normal)
        manageWalletButton.setTitleColor(IndustrialDesign.Colors.bitcoin, for: .normal)
        manageWalletButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        manageWalletButton.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)
        manageWalletButton.layer.cornerRadius = 6
        manageWalletButton.layer.borderWidth = 1
        manageWalletButton.layer.borderColor = IndustrialDesign.Colors.bitcoin.cgColor
        manageWalletButton.translatesAutoresizingMaskIntoConstraints = false
        manageWalletButton.addTarget(self, action: #selector(manageWalletTapped), for: .touchUpInside)
        manageWalletButton.isHidden = true // Hidden by default, shown only for captains
        
        // Bolt decoration
        boltDecoration.backgroundColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0)
        boltDecoration.layer.cornerRadius = IndustrialDesign.Sizing.boltSize / 2
        boltDecoration.layer.borderWidth = 1
        boltDecoration.layer.borderColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor
        
        addSubview(aboutTitleLabel)
        addSubview(aboutDescriptionLabel)
        addSubview(statsRow)
        addSubview(boltDecoration)
        
        statsRow.addSubview(prizePoolStat)
        statsRow.addSubview(walletStatusIndicator)
        statsRow.addSubview(walletStatusLabel)
        statsRow.addSubview(manageWalletButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            aboutTitleLabel.topAnchor.constraint(equalTo: topAnchor, constant: IndustrialDesign.Spacing.large),
            aboutTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: IndustrialDesign.Spacing.large),
            
            aboutDescriptionLabel.topAnchor.constraint(equalTo: aboutTitleLabel.bottomAnchor, constant: IndustrialDesign.Spacing.small),
            aboutDescriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: IndustrialDesign.Spacing.large),
            aboutDescriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),
            
            statsRow.topAnchor.constraint(equalTo: aboutDescriptionLabel.bottomAnchor, constant: IndustrialDesign.Spacing.large),
            statsRow.leadingAnchor.constraint(equalTo: leadingAnchor, constant: IndustrialDesign.Spacing.large),
            statsRow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -IndustrialDesign.Spacing.large),
            statsRow.heightAnchor.constraint(equalToConstant: 40),
            
            // Stats items - Prize pool centered
            prizePoolStat.leadingAnchor.constraint(equalTo: statsRow.leadingAnchor),
            prizePoolStat.centerYAnchor.constraint(equalTo: statsRow.centerYAnchor),
            
            // Wallet status on the right
            walletStatusIndicator.trailingAnchor.constraint(equalTo: walletStatusLabel.leadingAnchor, constant: -6),
            walletStatusIndicator.centerYAnchor.constraint(equalTo: statsRow.centerYAnchor),
            walletStatusIndicator.widthAnchor.constraint(equalToConstant: 8),
            walletStatusIndicator.heightAnchor.constraint(equalToConstant: 8),
            
            walletStatusLabel.trailingAnchor.constraint(equalTo: statsRow.trailingAnchor),
            walletStatusLabel.centerYAnchor.constraint(equalTo: statsRow.centerYAnchor),
            
            // Manage wallet button (positioned below prize pool when visible)
            manageWalletButton.topAnchor.constraint(equalTo: prizePoolStat.bottomAnchor, constant: 8),
            manageWalletButton.leadingAnchor.constraint(equalTo: statsRow.leadingAnchor),
            manageWalletButton.widthAnchor.constraint(equalToConstant: 120),
            manageWalletButton.heightAnchor.constraint(equalToConstant: 28)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Position bolt decoration
        boltDecoration.frame = CGRect(
            x: frame.width - 24,
            y: 12,
            width: IndustrialDesign.Sizing.boltSize,
            height: IndustrialDesign.Sizing.boltSize
        )
    }
    
    // MARK: - Configuration
    
    func configure(description: String?, prizePool: String, walletConfigured: Bool = false, isCaptain: Bool = false) {
        let displayDescription = description?.isEmpty == false ? description! : "This team doesn't have a description yet."
        aboutDescriptionLabel.text = displayDescription
        
        prizePoolStat.updateValue(prizePool)
        
        // Update wallet status
        if walletConfigured {
            walletStatusIndicator.backgroundColor = IndustrialDesign.Colors.primaryText
            walletStatusIndicator.layer.borderColor = IndustrialDesign.Colors.primaryText.withAlphaComponent(0.3).cgColor
            walletStatusLabel.text = "Wallet active"
            walletStatusLabel.textColor = IndustrialDesign.Colors.primaryText
        } else {
            walletStatusIndicator.backgroundColor = UIColor.systemOrange
            walletStatusIndicator.layer.borderColor = UIColor.systemOrange.withAlphaComponent(0.3).cgColor
            walletStatusLabel.text = "Wallet not configured"
            walletStatusLabel.textColor = UIColor.systemOrange
        }
        
        // Show/hide manage wallet button based on captain status
        manageWalletButton.isHidden = !isCaptain
        
        print("🏗️ TeamDetailAboutSection: Configure - isCaptain: \(isCaptain), manageWalletButton.isHidden: \(manageWalletButton.isHidden)")
    }
    
    func showLoading() {
        aboutDescriptionLabel.text = "Loading team information..."
        prizePoolStat.updateValue("0 sats")
        walletStatusLabel.text = "Checking wallet..."
        walletStatusLabel.textColor = IndustrialDesign.Colors.secondaryText
        walletStatusIndicator.backgroundColor = IndustrialDesign.Colors.secondaryText
        manageWalletButton.isHidden = true // Hide during loading
    }
    
    // MARK: - Actions
    
    @objc private func manageWalletTapped() {
        print("🏗️ TeamDetailAboutSection: Manage wallet button tapped")
        delegate?.didTapManageWallet()
    }
}