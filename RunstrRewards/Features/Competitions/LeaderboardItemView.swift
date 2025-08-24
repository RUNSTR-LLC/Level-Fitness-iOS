import UIKit

protocol LeaderboardItemViewDelegate: AnyObject {
    func didTapLeaderboardItem(_ user: LeaderboardUser)
}

class LeaderboardItemView: UIView {
    
    // MARK: - Properties
    private let user: LeaderboardUser
    weak var delegate: LeaderboardItemViewDelegate?
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let rankBadge = UIView()
    private let rankLabel = UILabel()
    private let userInfoContainer = UIView()
    private let usernameLabel = UILabel()
    private let statsLabel = UILabel()
    private let scoreContainer = UIView()
    private let scoreLabel = UILabel()
    private let pointsLabel = UILabel()
    private let boltDecoration = UIView()
    
    // MARK: - Initialization
    
    init(user: LeaderboardUser) {
        self.user = user
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
        
        // Rank badge
        rankBadge.translatesAutoresizingMaskIntoConstraints = false
        rankBadge.backgroundColor = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0)
        rankBadge.layer.cornerRadius = 8
        rankBadge.layer.borderWidth = 1
        rankBadge.layer.borderColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        
        // Rank label
        rankLabel.translatesAutoresizingMaskIntoConstraints = false
        rankLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        rankLabel.textColor = IndustrialDesign.Colors.primaryText
        rankLabel.textAlignment = .center
        
        // User info container
        userInfoContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Username label
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        usernameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        usernameLabel.textColor = IndustrialDesign.Colors.primaryText
        usernameLabel.numberOfLines = 1
        
        // Stats label
        statsLabel.translatesAutoresizingMaskIntoConstraints = false
        statsLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        statsLabel.textColor = IndustrialDesign.Colors.secondaryText
        statsLabel.numberOfLines = 1
        
        // Score container
        scoreContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Score label
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        scoreLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        scoreLabel.textColor = IndustrialDesign.Colors.primaryText
        scoreLabel.textAlignment = .right
        scoreLabel.numberOfLines = 1
        
        // Points label
        pointsLabel.translatesAutoresizingMaskIntoConstraints = false
        pointsLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        pointsLabel.textColor = IndustrialDesign.Colors.secondaryText
        pointsLabel.textAlignment = .right
        pointsLabel.text = "POINTS"
        pointsLabel.letterSpacing = 0.5
        
        // Bolt decoration
        boltDecoration.translatesAutoresizingMaskIntoConstraints = false
        boltDecoration.backgroundColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0)
        boltDecoration.layer.cornerRadius = 3
        boltDecoration.layer.borderWidth = 1
        boltDecoration.layer.borderColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor
        
        // Add subviews
        addSubview(containerView)
        containerView.addSubview(rankBadge)
        containerView.addSubview(userInfoContainer)
        containerView.addSubview(scoreContainer)
        containerView.addSubview(boltDecoration)
        
        rankBadge.addSubview(rankLabel)
        userInfoContainer.addSubview(usernameLabel)
        userInfoContainer.addSubview(statsLabel)
        scoreContainer.addSubview(scoreLabel)
        scoreContainer.addSubview(pointsLabel)
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(itemTapped))
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
            containerView.heightAnchor.constraint(equalToConstant: 70),
            
            // Rank badge
            rankBadge.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            rankBadge.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            rankBadge.widthAnchor.constraint(equalToConstant: 40),
            rankBadge.heightAnchor.constraint(equalToConstant: 40),
            
            // Rank label
            rankLabel.centerXAnchor.constraint(equalTo: rankBadge.centerXAnchor),
            rankLabel.centerYAnchor.constraint(equalTo: rankBadge.centerYAnchor),
            
            // User info container
            userInfoContainer.leadingAnchor.constraint(equalTo: rankBadge.trailingAnchor, constant: 16),
            userInfoContainer.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            userInfoContainer.trailingAnchor.constraint(lessThanOrEqualTo: scoreContainer.leadingAnchor, constant: -16),
            
            // Username label
            usernameLabel.topAnchor.constraint(equalTo: userInfoContainer.topAnchor),
            usernameLabel.leadingAnchor.constraint(equalTo: userInfoContainer.leadingAnchor),
            usernameLabel.trailingAnchor.constraint(equalTo: userInfoContainer.trailingAnchor),
            
            // Stats label
            statsLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 4),
            statsLabel.leadingAnchor.constraint(equalTo: userInfoContainer.leadingAnchor),
            statsLabel.trailingAnchor.constraint(equalTo: userInfoContainer.trailingAnchor),
            statsLabel.bottomAnchor.constraint(equalTo: userInfoContainer.bottomAnchor),
            
            // Score container
            scoreContainer.trailingAnchor.constraint(equalTo: boltDecoration.leadingAnchor, constant: -16),
            scoreContainer.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            scoreContainer.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            // Score label
            scoreLabel.topAnchor.constraint(equalTo: scoreContainer.topAnchor),
            scoreLabel.leadingAnchor.constraint(equalTo: scoreContainer.leadingAnchor),
            scoreLabel.trailingAnchor.constraint(equalTo: scoreContainer.trailingAnchor),
            
            // Points label
            pointsLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 4),
            pointsLabel.leadingAnchor.constraint(equalTo: scoreContainer.leadingAnchor),
            pointsLabel.trailingAnchor.constraint(equalTo: scoreContainer.trailingAnchor),
            pointsLabel.bottomAnchor.constraint(equalTo: scoreContainer.bottomAnchor),
            
            // Bolt decoration
            boltDecoration.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            boltDecoration.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            boltDecoration.widthAnchor.constraint(equalToConstant: 6),
            boltDecoration.heightAnchor.constraint(equalToConstant: 6)
        ])
    }
    
    private func configureWithData() {
        rankLabel.text = "\(user.rank)"
        usernameLabel.text = user.username
        statsLabel.text = "\(user.formattedDistance) km • \(user.workouts) workouts"
        scoreLabel.text = user.formattedPoints
        
        // Special styling for top 3 positions
        switch user.rank {
        case 1:
            // Gold styling
            rankBadge.backgroundColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0) // Gold
            rankBadge.layer.borderColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0).cgColor
            rankLabel.textColor = UIColor.black
            
        case 2:
            // Silver styling
            rankBadge.backgroundColor = UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1.0) // Silver
            rankBadge.layer.borderColor = UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1.0).cgColor
            rankLabel.textColor = UIColor.black
            
        case 3:
            // Bronze styling
            rankBadge.backgroundColor = UIColor(red: 0.80, green: 0.50, blue: 0.20, alpha: 1.0) // Bronze
            rankBadge.layer.borderColor = UIColor(red: 0.80, green: 0.50, blue: 0.20, alpha: 1.0).cgColor
            rankLabel.textColor = UIColor.black
            
        default:
            // Default styling
            break
        }
    }
    
    private func setupHoverEffects() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(itemPressed(_:)))
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
    
    @objc private func itemTapped() {
        // Tap feedback animation
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = .identity
            }
        }
        
        delegate?.didTapLeaderboardItem(user)
        print("🏆 RunstrRewards: Leaderboard item tapped: \(user.username)")
    }
    
    @objc private func itemPressed(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            UIView.animate(withDuration: 0.2) { [self] in
                self.transform = CGAffineTransform(translationX: -4, y: 0)
                self.containerView.layer.borderColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0).cgColor
                self.layer.shadowColor = UIColor.black.cgColor
                self.layer.shadowOffset = CGSize(width: -6, height: 0)
                self.layer.shadowOpacity = 0.4
                self.layer.shadowRadius = 12
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