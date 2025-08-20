import UIKit

class TeamDetailAboutSection: UIView {
    
    // MARK: - UI Components
    private let aboutTitleLabel = UILabel()
    private let aboutDescriptionLabel = UILabel()
    private let statsRow = UIView()
    private let prizePoolStat = StatItem(value: "₿0.00", label: "Prize Pool", isBitcoin: true)
    private let walletStatusIndicator = UIView()
    private let walletStatusLabel = UILabel()
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
            walletStatusLabel.centerYAnchor.constraint(equalTo: statsRow.centerYAnchor)
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
    
    func configure(description: String?, prizePool: String, walletConfigured: Bool = false) {
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
    }
    
    func showLoading() {
        aboutDescriptionLabel.text = "Loading team information..."
        prizePoolStat.updateValue("₿0")
        walletStatusLabel.text = "Checking wallet..."
        walletStatusLabel.textColor = IndustrialDesign.Colors.secondaryText
        walletStatusIndicator.backgroundColor = IndustrialDesign.Colors.secondaryText
    }
}