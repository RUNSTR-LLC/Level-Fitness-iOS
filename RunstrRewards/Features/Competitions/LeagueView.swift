import UIKit

struct LeaderboardUser: Codable {
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

// General streak functionality removed from scope - only used for streak events

// Chat functionality removed from scope

protocol LeagueViewDelegate: AnyObject {
    func didTapLeaderboardUser(_ user: LeaderboardUser)
}

class LeagueView: UIView {
    
    // MARK: - Properties
    weak var delegate: LeagueViewDelegate?
    private var leaderboardUsers: [LeaderboardUser] = []
    private let teamId: String
    private let supabaseService = SupabaseService.shared
    // Removed streak and chat data - simplified to leaderboard only
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let prizePoolBanner = PrizePoolBannerView()
    private let leaderboardContainer = UIView()
    private let leaderboardTitle = UILabel()
    private let leaderboardStackView = UIStackView()
    // Removed streak and chat containers - simplified to leaderboard only
    
    init(frame: CGRect = .zero, teamId: String) {
        self.teamId = teamId
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
        
        // Streak and chat setup removed from scope
        
        // Add subviews
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(prizePoolBanner)
        contentView.addSubview(leaderboardContainer)
        
        leaderboardContainer.addSubview(leaderboardTitle)
        leaderboardContainer.addSubview(leaderboardStackView)
    }
    
    // Chat gradient setup removed
    
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
            
            // Content view bottom constraint (simplified - only leaderboard)
            leaderboardContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    // Layout subviews simplified - chat gradient removed
    
    // MARK: - Public Methods
    
    func loadRealData() {
        loadRealLeaderboard()
    }
    
    private func loadRealLeaderboard() {
        Task {
            do {
                // Load team leaderboard from Supabase
                let teamLeaderboardMembers = try await supabaseService.fetchTeamLeaderboard(teamId: teamId, type: "distance", period: "weekly")
                
                // Convert to LeaderboardUser format
                let leaderboardUsers = teamLeaderboardMembers.enumerated().map { index, member in
                    LeaderboardUser(
                        id: member.userId,
                        username: member.username ?? "Anonymous",
                        rank: index + 1,
                        distance: member.totalDistance,
                        workouts: member.workoutCount,
                        points: member.totalPoints
                    )
                }
                
                await MainActor.run {
                    self.leaderboardUsers = leaderboardUsers
                    self.buildLeaderboard()
                }
                
                print("LeagueView: Loaded \(leaderboardUsers.count) leaderboard entries for team \(teamId)")
                
            } catch {
                print("LeagueView: Failed to load team leaderboard: \(error)")
                await MainActor.run {
                    self.leaderboardUsers = []
                    self.buildLeaderboard()
                }
            }
        }
    }
    
    // Streak and chat loading removed from scope
    
    private func buildLeaderboard() {
        // Clear existing views
        leaderboardStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for user in leaderboardUsers {
            let leaderboardItem = LeaderboardItemView(user: user)
            leaderboardItem.delegate = self
            leaderboardStackView.addArrangedSubview(leaderboardItem)
        }
    }
    
    // Streak grid building removed from scope
    
    // Chat message building removed from scope
}

// MARK: - Delegate Implementations

extension LeagueView: LeaderboardItemViewDelegate {
    func didTapLeaderboardItem(_ user: LeaderboardUser) {
        print("🏆 RunstrRewards: Tapped leaderboard user: \(user.username)")
        // TODO: Show user profile or stats
    }
}

// Streak card delegate removed from scope
