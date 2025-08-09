import UIKit

class TeamDetailAboutSection: UIView {
    
    // MARK: - UI Components
    private let aboutTitleLabel = UILabel()
    private let aboutDescriptionLabel = UILabel()
    private let statsRow = UIView()
    private let prizePoolStat = StatItem(value: "₿0.00", label: "Prize Pool", isBitcoin: true)
    private let avgKmStat = StatItem(value: "0", label: "Avg Weekly KM")
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
        aboutDescriptionLabel.text = "Community of runners pushing each other to new heights. Join us for daily runs and weekly challenges."
        aboutDescriptionLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        aboutDescriptionLabel.textColor = IndustrialDesign.Colors.primaryText
        aboutDescriptionLabel.numberOfLines = 2
        aboutDescriptionLabel.lineBreakMode = .byWordWrapping
        
        // Stats row
        statsRow.translatesAutoresizingMaskIntoConstraints = false
        
        prizePoolStat.translatesAutoresizingMaskIntoConstraints = false
        avgKmStat.translatesAutoresizingMaskIntoConstraints = false
        
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
        statsRow.addSubview(avgKmStat)
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
            
            // Stats items
            prizePoolStat.leadingAnchor.constraint(equalTo: statsRow.leadingAnchor),
            prizePoolStat.centerYAnchor.constraint(equalTo: statsRow.centerYAnchor),
            
            avgKmStat.trailingAnchor.constraint(equalTo: statsRow.trailingAnchor),
            avgKmStat.centerYAnchor.constraint(equalTo: statsRow.centerYAnchor)
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
    
    func configure(prizePool: String, avgKm: Int) {
        prizePoolStat.updateValue(prizePool)
        avgKmStat.updateValue("\(avgKm)")
    }
}