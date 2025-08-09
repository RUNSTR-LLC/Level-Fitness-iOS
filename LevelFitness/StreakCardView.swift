import UIKit

protocol StreakCardViewDelegate: AnyObject {
    func didTapStreakCard(_ type: StreakType)
}

class StreakCardView: UIView {
    
    // MARK: - Properties
    private let streakData: StreakData
    weak var delegate: StreakCardViewDelegate?
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let emojiLabel = UILabel()
    private let valueLabel = UILabel()
    private let titleLabel = UILabel()
    private let boltDecoration = UIView()
    
    // MARK: - Initialization
    
    init(data: StreakData) {
        self.streakData = data
        super.init(frame: .zero)
        setupView()
        setupConstraints()
        configureWithData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    private func setupView() {
        backgroundColor = UIColor.clear
        
        // Container view
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        containerView.layer.cornerRadius = 10
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0).cgColor
        
        // Add gradient background
        DispatchQueue.main.async {
            self.setupContainerGradient()
        }
        
        // Emoji label
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        emojiLabel.font = UIFont.systemFont(ofSize: 32, weight: .regular)
        emojiLabel.textAlignment = .center
        
        // Value label
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        valueLabel.textColor = IndustrialDesign.Colors.primaryText
        valueLabel.textAlignment = .center
        valueLabel.numberOfLines = 1
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.8
        
        // Title label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        titleLabel.textColor = IndustrialDesign.Colors.secondaryText
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.letterSpacing = 0.5
        
        // Bolt decoration
        boltDecoration.translatesAutoresizingMaskIntoConstraints = false
        boltDecoration.backgroundColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0)
        boltDecoration.layer.cornerRadius = 3
        boltDecoration.layer.borderWidth = 1
        boltDecoration.layer.borderColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor
        
        // Add subviews
        addSubview(containerView)
        containerView.addSubview(emojiLabel)
        containerView.addSubview(valueLabel)
        containerView.addSubview(titleLabel)
        containerView.addSubview(boltDecoration)
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        addGestureRecognizer(tapGesture)
        
        setupHoverEffects()
    }
    
    private func setupContainerGradient() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor,
            UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = containerView.bounds
        gradientLayer.cornerRadius = 10
        
        containerView.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Emoji label
            emojiLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            emojiLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            // Value label
            valueLabel.topAnchor.constraint(equalTo: emojiLabel.bottomAnchor, constant: 0),
            valueLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            valueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            // Title label
            titleLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -8),
            
            // Bolt decoration
            boltDecoration.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            boltDecoration.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            boltDecoration.widthAnchor.constraint(equalToConstant: 6),
            boltDecoration.heightAnchor.constraint(equalToConstant: 6)
        ])
    }
    
    private func configureWithData() {
        emojiLabel.text = streakData.emoji
        titleLabel.text = streakData.label.uppercased()
        
        // Format value based on streak type
        switch streakData.type {
        case .rank:
            let suffix = getOrdinalSuffix(for: streakData.value)
            valueLabel.text = "\(streakData.value)\(suffix)"
        default:
            valueLabel.text = "\(streakData.value)"
        }
    }
    
    private func getOrdinalSuffix(for number: Int) -> String {
        switch number % 100 {
        case 11, 12, 13:
            return "th"
        default:
            switch number % 10 {
            case 1: return "st"
            case 2: return "nd"
            case 3: return "rd"
            default: return "th"
            }
        }
    }
    
    private func setupHoverEffects() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(cardPressed(_:)))
        longPressGesture.minimumPressDuration = 0
        addGestureRecognizer(longPressGesture)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update gradient frame
        if let gradientLayer = containerView.layer.sublayers?.first(where: { $0 is CAGradientLayer }) as? CAGradientLayer {
            gradientLayer.frame = containerView.bounds
        }
    }
    
    // MARK: - Actions
    
    @objc private func cardTapped() {
        // Tap feedback animation
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = .identity
            }
        }
        
        delegate?.didTapStreakCard(streakData.type)
        print("🏆 LevelFitness: Streak card tapped: \(streakData.type.title)")
    }
    
    @objc private func cardPressed(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            UIView.animate(withDuration: 0.2) { [self] in
                self.transform = CGAffineTransform(translationX: 0, y: -4)
                self.containerView.layer.borderColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0).cgColor
                self.layer.shadowColor = UIColor.black.cgColor
                self.layer.shadowOffset = CGSize(width: 0, height: 8)
                self.layer.shadowOpacity = 0.4
                self.layer.shadowRadius = 16
            }
        case .ended, .cancelled:
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) { [self] in
                self.transform = .identity
                self.containerView.layer.borderColor = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0).cgColor
                self.layer.shadowOpacity = 0
            }
        default:
            break
        }
    }
}