import UIKit

protocol EarningsHeaderViewDelegate: AnyObject {
    func didTapBackButton()
    func didTapSettingsButton()
}

class EarningsHeaderView: UIView {
    
    // MARK: - Properties
    weak var delegate: EarningsHeaderViewDelegate?
    
    // MARK: - UI Components
    private let backButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
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
        
        // Title label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Earnings"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        
        // Settings button
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.setImage(UIImage(systemName: "gearshape"), for: .normal)
        settingsButton.tintColor = IndustrialDesign.Colors.secondaryText
        settingsButton.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        
        addSubview(backButton)
        addSubview(titleLabel)
        addSubview(settingsButton)
        
        // Add gradient to title
        DispatchQueue.main.async {
            self.applyGradientToLabel(self.titleLabel)
        }
        
        // Add button animations
        setupButtonAnimations()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: IndustrialDesign.Spacing.large),
            backButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            settingsButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -IndustrialDesign.Spacing.large),
            settingsButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 40),
            settingsButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupButtonAnimations() {
        [backButton, settingsButton].forEach { button in
            button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchDown)
            button.addTarget(self, action: #selector(buttonReleased(_:)), for: .touchUpInside)
            button.addTarget(self, action: #selector(buttonReleased(_:)), for: .touchUpOutside)
            button.addTarget(self, action: #selector(buttonReleased(_:)), for: .touchCancel)
        }
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
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        print("💰 LevelFitness: Earnings back button tapped")
        delegate?.didTapBackButton()
    }
    
    @objc private func settingsButtonTapped() {
        print("💰 LevelFitness: Earnings settings button tapped")
        delegate?.didTapSettingsButton()
    }
    
    @objc private func buttonPressed(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            sender.alpha = 0.7
        }
    }
    
    @objc private func buttonReleased(_ sender: UIButton) {
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.5,
            options: .allowUserInteraction
        ) {
            sender.transform = .identity
            sender.alpha = 1.0
        }
    }
}