import UIKit

struct MessageData {
    let author: String
    let avatar: String
    let message: String
    let time: String
}

class MessageView: UIView {
    
    // MARK: - UI Components
    private let avatarView = UIView()
    private let avatarLabel = UILabel()
    private let contentContainer = UIView()
    private let headerContainer = UIView()
    private let authorLabel = UILabel()
    private let timeLabel = UILabel()
    private let messageLabel = UILabel()
    
    private let messageData: MessageData
    
    // MARK: - Initialization
    init(messageData: MessageData) {
        self.messageData = messageData
        super.init(frame: .zero)
        
        setupMessage()
        setupConstraints()
        updateContent()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    private func setupMessage() {
        // Avatar setup
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        avatarView.layer.cornerRadius = 18
        avatarView.layer.borderWidth = 1
        avatarView.layer.borderColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor
        
        // Avatar label
        avatarLabel.translatesAutoresizingMaskIntoConstraints = false
        avatarLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        avatarLabel.textColor = IndustrialDesign.Colors.primaryText
        avatarLabel.textAlignment = .center
        
        // Content container
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Header container
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Author label
        authorLabel.translatesAutoresizingMaskIntoConstraints = false
        authorLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        authorLabel.textColor = IndustrialDesign.Colors.primaryText
        
        // Time label
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        timeLabel.textColor = IndustrialDesign.Colors.secondaryText
        
        // Message label
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        messageLabel.textColor = IndustrialDesign.Colors.primaryText
        messageLabel.numberOfLines = 0
        messageLabel.lineBreakMode = .byWordWrapping
        
        // Add subviews
        avatarView.addSubview(avatarLabel)
        headerContainer.addSubview(authorLabel)
        headerContainer.addSubview(timeLabel)
        contentContainer.addSubview(headerContainer)
        contentContainer.addSubview(messageLabel)
        
        addSubview(avatarView)
        addSubview(contentContainer)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Avatar
            avatarView.topAnchor.constraint(equalTo: topAnchor),
            avatarView.leadingAnchor.constraint(equalTo: leadingAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 36),
            avatarView.heightAnchor.constraint(equalToConstant: 36),
            
            // Avatar label
            avatarLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            
            // Content container
            contentContainer.topAnchor.constraint(equalTo: topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            contentContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Header container
            headerContainer.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            headerContainer.heightAnchor.constraint(equalToConstant: 20),
            
            // Author label
            authorLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            authorLabel.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),
            
            // Time label
            timeLabel.leadingAnchor.constraint(equalTo: authorLabel.trailingAnchor, constant: 8),
            timeLabel.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),
            timeLabel.trailingAnchor.constraint(lessThanOrEqualTo: headerContainer.trailingAnchor),
            
            // Message label
            messageLabel.topAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: 4),
            messageLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])
    }
    
    private func updateContent() {
        avatarLabel.text = messageData.avatar
        authorLabel.text = messageData.author
        timeLabel.text = messageData.time
        messageLabel.text = messageData.message
    }
}