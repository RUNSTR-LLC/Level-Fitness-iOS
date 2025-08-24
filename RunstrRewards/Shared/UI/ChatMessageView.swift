import UIKit

// MARK: - Chat Data Model (for team chat in specific contexts)

struct ChatMessage {
    let id: String
    let username: String
    let text: String
    let timestamp: Date
    let userInitials: String
    
    var formattedTime: String {
        let formatter = DateFormatter()
        let timeInterval = Date().timeIntervalSince(timestamp)
        
        if timeInterval < 60 {
            return "now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes) min ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: timestamp)
        }
    }
}

class ChatMessageView: UIView {
    
    // MARK: - Properties
    private let message: ChatMessage
    
    // MARK: - UI Components
    private let avatarView = UIView()
    private let avatarLabel = UILabel()
    private let contentContainer = UIView()
    private let headerContainer = UIView()
    private let usernameLabel = UILabel()
    private let timeLabel = UILabel()
    private let messageLabel = UILabel()
    
    // MARK: - Initialization
    
    init(message: ChatMessage) {
        self.message = message
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
        
        // Avatar view
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        avatarView.layer.cornerRadius = 14
        avatarView.layer.borderWidth = 1
        avatarView.layer.borderColor = UIColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1.0).cgColor
        
        // Add gradient to avatar
        DispatchQueue.main.async {
            self.setupAvatarGradient()
        }
        
        // Avatar label
        avatarLabel.translatesAutoresizingMaskIntoConstraints = false
        avatarLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        avatarLabel.textColor = IndustrialDesign.Colors.primaryText
        avatarLabel.textAlignment = .center
        avatarLabel.numberOfLines = 1
        
        // Content container
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Header container
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Username label
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        usernameLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        usernameLabel.textColor = IndustrialDesign.Colors.primaryText
        usernameLabel.numberOfLines = 1
        
        // Time label
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        timeLabel.textColor = IndustrialDesign.Colors.secondaryText
        timeLabel.numberOfLines = 1
        
        // Message label
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        messageLabel.textColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
        messageLabel.numberOfLines = 0
        messageLabel.lineBreakMode = .byWordWrapping
        
        // Add subviews
        addSubview(avatarView)
        addSubview(contentContainer)
        
        avatarView.addSubview(avatarLabel)
        contentContainer.addSubview(headerContainer)
        contentContainer.addSubview(messageLabel)
        
        headerContainer.addSubview(usernameLabel)
        headerContainer.addSubview(timeLabel)
    }
    
    private func setupAvatarGradient() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor,
            UIColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = avatarView.bounds
        gradientLayer.cornerRadius = 14
        
        avatarView.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Avatar view
            avatarView.topAnchor.constraint(equalTo: topAnchor),
            avatarView.leadingAnchor.constraint(equalTo: leadingAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 28),
            avatarView.heightAnchor.constraint(equalToConstant: 28),
            
            // Avatar label
            avatarLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            
            // Content container
            contentContainer.topAnchor.constraint(equalTo: topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 8),
            contentContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Header container
            headerContainer.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            
            // Username label
            usernameLabel.topAnchor.constraint(equalTo: headerContainer.topAnchor),
            usernameLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            usernameLabel.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            
            // Time label
            timeLabel.topAnchor.constraint(equalTo: headerContainer.topAnchor),
            timeLabel.leadingAnchor.constraint(equalTo: usernameLabel.trailingAnchor, constant: 8),
            timeLabel.trailingAnchor.constraint(lessThanOrEqualTo: headerContainer.trailingAnchor),
            timeLabel.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            
            // Message label
            messageLabel.topAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: 2),
            messageLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])
        
        // Set priority for username label to prevent compression
        usernameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        usernameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }
    
    private func configureWithData() {
        avatarLabel.text = message.userInitials
        usernameLabel.text = message.username
        timeLabel.text = message.formattedTime
        messageLabel.text = message.text
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update gradient frame
        if let gradientLayer = avatarView.layer.sublayers?.first(where: { $0 is CAGradientLayer }) as? CAGradientLayer {
            gradientLayer.frame = avatarView.bounds
        }
    }
}

// MARK: - PrizePoolBannerView

class PrizePoolBannerView: UIView {
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let prizeLabel = UILabel()
    private let amountContainer = UIView()
    private let bitcoinSymbolLabel = UILabel()
    private let amountLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let leftBolt = UIView()
    private let rightBolt = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
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
        
        // Add gradient background
        DispatchQueue.main.async {
            self.setupContainerGradient()
        }
        
        // Add bottom border
        let borderView = UIView()
        borderView.translatesAutoresizingMaskIntoConstraints = false
        borderView.backgroundColor = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0)
        containerView.addSubview(borderView)
        
        NSLayoutConstraint.activate([
            borderView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            borderView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            borderView.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        // Prize label
        prizeLabel.translatesAutoresizingMaskIntoConstraints = false
        prizeLabel.text = "CURRENT PRIZE POOL"
        prizeLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        prizeLabel.textColor = IndustrialDesign.Colors.secondaryText
        prizeLabel.textAlignment = .center
        prizeLabel.letterSpacing = 1
        
        // Amount container
        amountContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Bitcoin symbol
        bitcoinSymbolLabel.translatesAutoresizingMaskIntoConstraints = false
        bitcoinSymbolLabel.text = "₿"
        bitcoinSymbolLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        bitcoinSymbolLabel.textColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0) // Bitcoin orange
        bitcoinSymbolLabel.textAlignment = .center
        
        // Amount label
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        amountLabel.text = "0.5000"
        amountLabel.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        amountLabel.textColor = IndustrialDesign.Colors.primaryText
        amountLabel.textAlignment = .center
        
        // Subtitle label
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Distributed weekly to top performers"
        subtitleLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        subtitleLabel.textColor = IndustrialDesign.Colors.accentText
        subtitleLabel.textAlignment = .center
        
        // Bolt decorations
        leftBolt.translatesAutoresizingMaskIntoConstraints = false
        leftBolt.backgroundColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0)
        leftBolt.layer.cornerRadius = 4
        leftBolt.layer.borderWidth = 1
        leftBolt.layer.borderColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor
        
        rightBolt.translatesAutoresizingMaskIntoConstraints = false
        rightBolt.backgroundColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0)
        rightBolt.layer.cornerRadius = 4
        rightBolt.layer.borderWidth = 1
        rightBolt.layer.borderColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor
        
        // Add subviews
        addSubview(containerView)
        containerView.addSubview(prizeLabel)
        containerView.addSubview(amountContainer)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(leftBolt)
        containerView.addSubview(rightBolt)
        
        amountContainer.addSubview(bitcoinSymbolLabel)
        amountContainer.addSubview(amountLabel)
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
        
        containerView.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Prize label
            prizeLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            prizeLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            // Amount container
            amountContainer.topAnchor.constraint(equalTo: prizeLabel.bottomAnchor, constant: 8),
            amountContainer.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            // Bitcoin symbol
            bitcoinSymbolLabel.topAnchor.constraint(equalTo: amountContainer.topAnchor),
            bitcoinSymbolLabel.leadingAnchor.constraint(equalTo: amountContainer.leadingAnchor),
            bitcoinSymbolLabel.bottomAnchor.constraint(equalTo: amountContainer.bottomAnchor),
            
            // Amount label
            amountLabel.topAnchor.constraint(equalTo: amountContainer.topAnchor),
            amountLabel.leadingAnchor.constraint(equalTo: bitcoinSymbolLabel.trailingAnchor, constant: 6),
            amountLabel.trailingAnchor.constraint(equalTo: amountContainer.trailingAnchor),
            amountLabel.bottomAnchor.constraint(equalTo: amountContainer.bottomAnchor),
            
            // Subtitle label
            subtitleLabel.topAnchor.constraint(equalTo: amountContainer.bottomAnchor, constant: 4),
            subtitleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -20),
            
            // Left bolt
            leftBolt.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            leftBolt.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            leftBolt.widthAnchor.constraint(equalToConstant: 8),
            leftBolt.heightAnchor.constraint(equalToConstant: 8),
            
            // Right bolt
            rightBolt.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            rightBolt.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            rightBolt.widthAnchor.constraint(equalToConstant: 8),
            rightBolt.heightAnchor.constraint(equalToConstant: 8)
        ])
    }
    
    private func configureWithData() {
        // Data is already set in setupView, but this method can be used
        // to update with dynamic data in the future
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update gradient frame
        if let gradientLayer = containerView.layer.sublayers?.first(where: { $0 is CAGradientLayer }) as? CAGradientLayer {
            gradientLayer.frame = containerView.bounds
        }
    }
}