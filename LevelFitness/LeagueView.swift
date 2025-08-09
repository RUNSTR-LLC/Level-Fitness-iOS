import UIKit

struct LeaderboardUser {
    let id: String
    let username: String
    let rank: Int
    let distance: Double // in km
    let workouts: Int
    let points: Int
    
    var formattedDistance: String {
        return String(format: "%.1f", distance)
    }
    
    var formattedPoints: String {
        return NumberFormatter().string(from: NSNumber(value: points)) ?? "0"
    }
}

struct StreakData {
    let type: StreakType
    let value: Int
    let label: String
    let emoji: String
}

enum StreakType {
    case daily
    case weekly
    case total
    case rank
    
    var title: String {
        switch self {
        case .daily: return "Daily Streak"
        case .weekly: return "Weekly Goals"
        case .total: return "Total Activities"
        case .rank: return "League Rank"
        }
    }
}

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

protocol LeagueViewDelegate: AnyObject {
    func didTapLeaderboardUser(_ user: LeaderboardUser)
    func didTapStreakCard(_ type: StreakType)
}

class LeagueView: UIView {
    
    // MARK: - Properties
    weak var delegate: LeagueViewDelegate?
    private var leaderboardUsers: [LeaderboardUser] = []
    private var streakData: [StreakData] = []
    private var chatMessages: [ChatMessage] = []
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let prizePoolBanner = PrizePoolBannerView()
    private let leaderboardContainer = UIView()
    private let leaderboardTitle = UILabel()
    private let leaderboardStackView = UIStackView()
    private let streakContainer = UIView()
    private let streakTitle = UILabel()
    private let streakGridContainer = UIView()
    private let chatContainer = UIView()
    private let chatTitle = UILabel()
    private let chatMessagesContainer = UIView()
    
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
        backgroundColor = UIColor.clear
        clipsToBounds = true // Prevent content from extending beyond bounds
        
        // Scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.indicatorStyle = .white
        scrollView.backgroundColor = UIColor.clear
        scrollView.delaysContentTouches = false // Improve touch responsiveness
        scrollView.canCancelContentTouches = true
        scrollView.bounces = true
        scrollView.alwaysBounceVertical = true
        
        // Content view
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = UIColor.clear
        contentView.isUserInteractionEnabled = true
        
        // Prize pool banner
        prizePoolBanner.translatesAutoresizingMaskIntoConstraints = false
        
        // Leaderboard container
        leaderboardContainer.translatesAutoresizingMaskIntoConstraints = false
        leaderboardContainer.backgroundColor = UIColor.clear
        
        // Leaderboard title
        leaderboardTitle.translatesAutoresizingMaskIntoConstraints = false
        leaderboardTitle.text = "WEEKLY LEADERBOARD"
        leaderboardTitle.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        leaderboardTitle.textColor = IndustrialDesign.Colors.accentText
        leaderboardTitle.letterSpacing = 1
        
        // Leaderboard stack view
        leaderboardStackView.translatesAutoresizingMaskIntoConstraints = false
        leaderboardStackView.axis = .vertical
        leaderboardStackView.spacing = 12
        leaderboardStackView.alignment = .fill
        
        // Streak container
        streakContainer.translatesAutoresizingMaskIntoConstraints = false
        streakContainer.backgroundColor = UIColor.clear
        
        // Streak title
        streakTitle.translatesAutoresizingMaskIntoConstraints = false
        streakTitle.text = "STREAK COMPETITIONS"
        streakTitle.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        streakTitle.textColor = IndustrialDesign.Colors.accentText
        streakTitle.letterSpacing = 1
        
        // Streak grid container
        streakGridContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Chat container
        chatContainer.translatesAutoresizingMaskIntoConstraints = false
        chatContainer.backgroundColor = UIColor.clear
        
        // Chat title
        chatTitle.translatesAutoresizingMaskIntoConstraints = false
        chatTitle.text = "LEAGUE CHAT"
        chatTitle.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        chatTitle.textColor = IndustrialDesign.Colors.accentText
        chatTitle.letterSpacing = 1
        
        // Chat messages container
        chatMessagesContainer.translatesAutoresizingMaskIntoConstraints = false
        chatMessagesContainer.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        chatMessagesContainer.layer.cornerRadius = 10
        chatMessagesContainer.layer.borderWidth = 1
        chatMessagesContainer.layer.borderColor = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0).cgColor
        
        // Add gradient to chat container
        DispatchQueue.main.async {
            self.setupChatGradient()
        }
        
        // Add subviews
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(prizePoolBanner)
        contentView.addSubview(leaderboardContainer)
        contentView.addSubview(streakContainer)
        contentView.addSubview(chatContainer)
        
        leaderboardContainer.addSubview(leaderboardTitle)
        leaderboardContainer.addSubview(leaderboardStackView)
        
        streakContainer.addSubview(streakTitle)
        streakContainer.addSubview(streakGridContainer)
        
        chatContainer.addSubview(chatTitle)
        chatContainer.addSubview(chatMessagesContainer)
    }
    
    private func setupChatGradient() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor,
            UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = chatMessagesContainer.bounds
        gradientLayer.cornerRadius = 10
        
        chatMessagesContainer.layer.insertSublayer(gradientLayer, at: 0)
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
            
            // Prize pool banner
            prizePoolBanner.topAnchor.constraint(equalTo: contentView.topAnchor),
            prizePoolBanner.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            prizePoolBanner.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            prizePoolBanner.heightAnchor.constraint(equalToConstant: 120),
            
            // Leaderboard container
            leaderboardContainer.topAnchor.constraint(equalTo: prizePoolBanner.bottomAnchor, constant: 20),
            leaderboardContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            leaderboardContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            // Leaderboard title
            leaderboardTitle.topAnchor.constraint(equalTo: leaderboardContainer.topAnchor),
            leaderboardTitle.leadingAnchor.constraint(equalTo: leaderboardContainer.leadingAnchor),
            leaderboardTitle.trailingAnchor.constraint(equalTo: leaderboardContainer.trailingAnchor),
            
            // Leaderboard stack view
            leaderboardStackView.topAnchor.constraint(equalTo: leaderboardTitle.bottomAnchor, constant: 16),
            leaderboardStackView.leadingAnchor.constraint(equalTo: leaderboardContainer.leadingAnchor),
            leaderboardStackView.trailingAnchor.constraint(equalTo: leaderboardContainer.trailingAnchor),
            leaderboardStackView.bottomAnchor.constraint(equalTo: leaderboardContainer.bottomAnchor),
            
            // Streak container
            streakContainer.topAnchor.constraint(equalTo: leaderboardContainer.bottomAnchor, constant: 32),
            streakContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            streakContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            // Streak title
            streakTitle.topAnchor.constraint(equalTo: streakContainer.topAnchor),
            streakTitle.leadingAnchor.constraint(equalTo: streakContainer.leadingAnchor),
            streakTitle.trailingAnchor.constraint(equalTo: streakContainer.trailingAnchor),
            
            // Streak grid container
            streakGridContainer.topAnchor.constraint(equalTo: streakTitle.bottomAnchor, constant: 16),
            streakGridContainer.leadingAnchor.constraint(equalTo: streakContainer.leadingAnchor),
            streakGridContainer.trailingAnchor.constraint(equalTo: streakContainer.trailingAnchor),
            streakGridContainer.bottomAnchor.constraint(equalTo: streakContainer.bottomAnchor),
            streakGridContainer.heightAnchor.constraint(equalToConstant: 160),
            
            // Chat container
            chatContainer.topAnchor.constraint(equalTo: streakContainer.bottomAnchor, constant: 32),
            chatContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            chatContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            chatContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
            
            // Chat title
            chatTitle.topAnchor.constraint(equalTo: chatContainer.topAnchor),
            chatTitle.leadingAnchor.constraint(equalTo: chatContainer.leadingAnchor),
            chatTitle.trailingAnchor.constraint(equalTo: chatContainer.trailingAnchor),
            
            // Chat messages container
            chatMessagesContainer.topAnchor.constraint(equalTo: chatTitle.bottomAnchor, constant: 16),
            chatMessagesContainer.leadingAnchor.constraint(equalTo: chatContainer.leadingAnchor),
            chatMessagesContainer.trailingAnchor.constraint(equalTo: chatContainer.trailingAnchor),
            chatMessagesContainer.bottomAnchor.constraint(equalTo: chatContainer.bottomAnchor),
            chatMessagesContainer.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update gradient frame
        if let gradientLayer = chatMessagesContainer.layer.sublayers?.first(where: { $0 is CAGradientLayer }) as? CAGradientLayer {
            gradientLayer.frame = chatMessagesContainer.bounds
        }
    }
    
    // MARK: - Public Methods
    
    func loadSampleData() {
        loadSampleLeaderboard()
        loadSampleStreaks()
        loadSampleChatMessages()
    }
    
    private func loadSampleLeaderboard() {
        leaderboardUsers = [
            LeaderboardUser(id: "1", username: "@lightningbolt", rank: 1, distance: 156.2, workouts: 12, points: 2847),
            LeaderboardUser(id: "2", username: "@speedracer", rank: 2, distance: 143.5, workouts: 15, points: 2655),
            LeaderboardUser(id: "3", username: "@marathonmike", rank: 3, distance: 138.8, workouts: 10, points: 2492),
            LeaderboardUser(id: "4", username: "@steelrunner", rank: 4, distance: 125.3, workouts: 14, points: 2341),
            LeaderboardUser(id: "5", username: "@cryptorunner", rank: 5, distance: 118.7, workouts: 11, points: 2156)
        ]
        
        buildLeaderboard()
    }
    
    private func loadSampleStreaks() {
        streakData = [
            StreakData(type: .daily, value: 42, label: "Daily Streak", emoji: "🔥"),
            StreakData(type: .weekly, value: 8, label: "Weekly Goals", emoji: "⚡"),
            StreakData(type: .total, value: 156, label: "Total Activities", emoji: "🏃"),
            StreakData(type: .rank, value: 3, label: "League Rank", emoji: "🏆")
        ]
        
        buildStreakGrid()
    }
    
    private func loadSampleChatMessages() {
        let now = Date()
        
        chatMessages = [
            ChatMessage(id: "1", username: "@lightningbolt", text: "Just crushed a 10K PR! Feeling good about this week's competition 💪", timestamp: Calendar.current.date(byAdding: .minute, value: -2, to: now)!, userInitials: "LB"),
            ChatMessage(id: "2", username: "@speedracer", text: "Nice work! The competition is heating up this week", timestamp: Calendar.current.date(byAdding: .minute, value: -5, to: now)!, userInitials: "SR"),
            ChatMessage(id: "3", username: "@marathonmike", text: "Don't forget the bonus points for consistency! Daily streaks matter 🔥", timestamp: Calendar.current.date(byAdding: .minute, value: -12, to: now)!, userInitials: "MM")
        ]
        
        buildChatMessages()
    }
    
    private func buildLeaderboard() {
        // Clear existing views
        leaderboardStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for user in leaderboardUsers {
            let leaderboardItem = LeaderboardItemView(user: user)
            leaderboardItem.delegate = self
            leaderboardStackView.addArrangedSubview(leaderboardItem)
        }
    }
    
    private func buildStreakGrid() {
        // Clear existing views
        streakGridContainer.subviews.forEach { $0.removeFromSuperview() }
        
        let cards = streakData.map { data in
            let card = StreakCardView(data: data)
            card.translatesAutoresizingMaskIntoConstraints = false
            card.delegate = self
            streakGridContainer.addSubview(card)
            return card
        }
        
        // Layout cards in 2x2 grid
        if cards.count >= 4 {
            let spacing: CGFloat = 12
            
            NSLayoutConstraint.activate([
                // Row 1: Daily (cards[0]) and Weekly (cards[1])
                cards[0].topAnchor.constraint(equalTo: streakGridContainer.topAnchor),
                cards[0].leadingAnchor.constraint(equalTo: streakGridContainer.leadingAnchor),
                cards[0].trailingAnchor.constraint(equalTo: streakGridContainer.centerXAnchor, constant: -spacing/2),
                cards[0].heightAnchor.constraint(equalToConstant: 74),
                
                cards[1].topAnchor.constraint(equalTo: streakGridContainer.topAnchor),
                cards[1].leadingAnchor.constraint(equalTo: streakGridContainer.centerXAnchor, constant: spacing/2),
                cards[1].trailingAnchor.constraint(equalTo: streakGridContainer.trailingAnchor),
                cards[1].heightAnchor.constraint(equalToConstant: 74),
                
                // Row 2: Total (cards[2]) and Rank (cards[3])
                cards[2].topAnchor.constraint(equalTo: cards[0].bottomAnchor, constant: spacing),
                cards[2].leadingAnchor.constraint(equalTo: streakGridContainer.leadingAnchor),
                cards[2].trailingAnchor.constraint(equalTo: streakGridContainer.centerXAnchor, constant: -spacing/2),
                cards[2].heightAnchor.constraint(equalToConstant: 74),
                
                cards[3].topAnchor.constraint(equalTo: cards[1].bottomAnchor, constant: spacing),
                cards[3].leadingAnchor.constraint(equalTo: streakGridContainer.centerXAnchor, constant: spacing/2),
                cards[3].trailingAnchor.constraint(equalTo: streakGridContainer.trailingAnchor),
                cards[3].heightAnchor.constraint(equalToConstant: 74)
            ])
        }
    }
    
    private func buildChatMessages() {
        // Clear existing views
        chatMessagesContainer.subviews.forEach { $0.removeFromSuperview() }
        
        var lastView: UIView?
        
        for message in chatMessages {
            let messageView = ChatMessageView(message: message)
            messageView.translatesAutoresizingMaskIntoConstraints = false
            chatMessagesContainer.addSubview(messageView)
            
            NSLayoutConstraint.activate([
                messageView.leadingAnchor.constraint(equalTo: chatMessagesContainer.leadingAnchor, constant: 16),
                messageView.trailingAnchor.constraint(equalTo: chatMessagesContainer.trailingAnchor, constant: -16)
            ])
            
            if let lastView = lastView {
                messageView.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 12).isActive = true
            } else {
                messageView.topAnchor.constraint(equalTo: chatMessagesContainer.topAnchor, constant: 16).isActive = true
            }
            
            lastView = messageView
        }
    }
}

// MARK: - LeaderboardItemViewDelegate

extension LeagueView: LeaderboardItemViewDelegate {
    func didTapLeaderboardItem(_ user: LeaderboardUser) {
        delegate?.didTapLeaderboardUser(user)
    }
}

// MARK: - StreakCardViewDelegate

extension LeagueView: StreakCardViewDelegate {
    func didTapStreakCard(_ type: StreakType) {
        delegate?.didTapStreakCard(type)
    }
}