import UIKit

protocol TeamDetailHeaderViewDelegate: AnyObject {
    func didTapBackButton()
    func didTapSettingsButton()
}

class TeamDetailHeaderView: UIView {
    
    // MARK: - Properties
    weak var delegate: TeamDetailHeaderViewDelegate?
    
    // MARK: - UI Components
    private let backButton = UIButton(type: .custom)
    private let teamNameLabel = UILabel()
    private let memberCountLabel = UILabel()
    private let settingsButton = UIButton(type: .custom)
    
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
        backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        
        // Add bottom border
        let borderLayer = CALayer()
        borderLayer.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
        borderLayer.frame = CGRect(x: 0, y: 79, width: UIScreen.main.bounds.width, height: 1)
        layer.addSublayer(borderLayer)
        
        // Back button
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = IndustrialDesign.Colors.secondaryText
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        // Team name
        teamNameLabel.translatesAutoresizingMaskIntoConstraints = false
        teamNameLabel.font = IndustrialDesign.Typography.navTitleFont
        teamNameLabel.textAlignment = .center
        
        // Member count
        memberCountLabel.translatesAutoresizingMaskIntoConstraints = false
        memberCountLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        memberCountLabel.textColor = IndustrialDesign.Colors.secondaryText
        memberCountLabel.textAlignment = .center
        
        // Settings button
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        settingsButton.tintColor = IndustrialDesign.Colors.secondaryText
        settingsButton.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        
        addSubview(backButton)
        addSubview(teamNameLabel)
        addSubview(memberCountLabel)
        addSubview(settingsButton)
        
        // Add gradient to team name
        DispatchQueue.main.async {
            self.applyGradientToLabel(self.teamNameLabel)
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: IndustrialDesign.Spacing.large),
            backButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            
            teamNameLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            teamNameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            
            memberCountLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            memberCountLabel.topAnchor.constraint(equalTo: teamNameLabel.bottomAnchor, constant: 4),
            
            settingsButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -IndustrialDesign.Spacing.large),
            settingsButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 40),
            settingsButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(teamName: String, memberCount: Int) {
        teamNameLabel.text = teamName
        memberCountLabel.text = "\(memberCount) MEMBERS"
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        delegate?.didTapBackButton()
    }
    
    @objc private func settingsButtonTapped() {
        delegate?.didTapSettingsButton()
    }
    
    private func applyGradientToLabel(_ label: UILabel) {
        let gradient = CAGradientLayer.logo()
        gradient.frame = label.bounds
        
        let gradientColor = UIColor { _ in
            return UIColor.white
        }
        label.textColor = gradientColor
        
        let maskLayer = CATextLayer()
        maskLayer.string = label.text
        maskLayer.font = label.font
        maskLayer.fontSize = label.font.pointSize
        maskLayer.frame = label.bounds
        maskLayer.alignmentMode = .center
        maskLayer.foregroundColor = UIColor.black.cgColor
        
        gradient.mask = maskLayer
        label.layer.addSublayer(gradient)
    }
}