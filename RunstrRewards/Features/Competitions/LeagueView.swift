import UIKit

// PayoutType enum is defined in LeagueCreationWizardViewController.swift
// and will be accessible throughout the module

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
    private var currentLeague: TeamLeague?
    private var teamWalletBalance: Int = 0
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Real prize pool banner components
    private let prizePoolContainer = UIView()
    private let prizePoolTitle = UILabel()
    private let prizePoolAmount = UILabel()
    private let payoutStructure = UILabel()
    private let daysRemaining = UILabel()
    
    private let leaderboardContainer = UIView()
    private let leaderboardTitle = UILabel()
    private let leaderboardStackView = UIStackView()
    
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
        
        // Prize pool container
        setupPrizePoolContainer()
        
        // Leaderboard container
        leaderboardContainer.translatesAutoresizingMaskIntoConstraints = false
        leaderboardContainer.backgroundColor = UIColor.clear
        
        // Leaderboard title
        leaderboardTitle.translatesAutoresizingMaskIntoConstraints = false
        leaderboardTitle.text = "MONTHLY LEAGUE"
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
        contentView.addSubview(prizePoolContainer)
        contentView.addSubview(leaderboardContainer)
        
        leaderboardContainer.addSubview(leaderboardTitle)
        leaderboardContainer.addSubview(leaderboardStackView)
    }
    
    private func setupPrizePoolContainer() {
        prizePoolContainer.translatesAutoresizingMaskIntoConstraints = false
        prizePoolContainer.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.95)
        prizePoolContainer.layer.cornerRadius = 16
        prizePoolContainer.layer.borderWidth = 1
        prizePoolContainer.layer.borderColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        
        // Add gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.12, green: 0.08, blue: 0.04, alpha: 0.8).cgColor,
            UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.95).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = 16
        prizePoolContainer.layer.insertSublayer(gradientLayer, at: 0)
        
        // Prize pool title
        prizePoolTitle.text = "PRIZE POOL"
        prizePoolTitle.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        prizePoolTitle.textColor = IndustrialDesign.Colors.accentText
        prizePoolTitle.textAlignment = .center
        prizePoolTitle.translatesAutoresizingMaskIntoConstraints = false
        
        // Prize pool amount
        prizePoolAmount.text = "₿0.000000"
        prizePoolAmount.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        prizePoolAmount.textColor = IndustrialDesign.Colors.bitcoin
        prizePoolAmount.textAlignment = .center
        prizePoolAmount.translatesAutoresizingMaskIntoConstraints = false
        
        // Payout structure
        payoutStructure.text = "Winner takes all"
        payoutStructure.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        payoutStructure.textColor = IndustrialDesign.Colors.secondaryText
        payoutStructure.textAlignment = .center
        payoutStructure.translatesAutoresizingMaskIntoConstraints = false
        
        // Days remaining
        daysRemaining.text = "30 days remaining"
        daysRemaining.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        daysRemaining.textColor = IndustrialDesign.Colors.accentText
        daysRemaining.textAlignment = .center
        daysRemaining.translatesAutoresizingMaskIntoConstraints = false
        
        // Add bolt decoration
        let boltView = UIImageView(image: UIImage(systemName: "bolt.fill"))
        boltView.tintColor = IndustrialDesign.Colors.bitcoin
        boltView.contentMode = .scaleAspectFit
        boltView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews to container
        prizePoolContainer.addSubview(prizePoolTitle)
        prizePoolContainer.addSubview(prizePoolAmount)
        prizePoolContainer.addSubview(payoutStructure)
        prizePoolContainer.addSubview(daysRemaining)
        prizePoolContainer.addSubview(boltView)
        
        // Set up constraints for prize pool elements
        NSLayoutConstraint.activate([
            // Bolt decoration
            boltView.topAnchor.constraint(equalTo: prizePoolContainer.topAnchor, constant: 12),
            boltView.trailingAnchor.constraint(equalTo: prizePoolContainer.trailingAnchor, constant: -12),
            boltView.widthAnchor.constraint(equalToConstant: 16),
            boltView.heightAnchor.constraint(equalToConstant: 16),
            
            // Title
            prizePoolTitle.topAnchor.constraint(equalTo: prizePoolContainer.topAnchor, constant: 20),
            prizePoolTitle.leadingAnchor.constraint(equalTo: prizePoolContainer.leadingAnchor, constant: 16),
            prizePoolTitle.trailingAnchor.constraint(equalTo: prizePoolContainer.trailingAnchor, constant: -16),
            
            // Amount
            prizePoolAmount.topAnchor.constraint(equalTo: prizePoolTitle.bottomAnchor, constant: 8),
            prizePoolAmount.leadingAnchor.constraint(equalTo: prizePoolContainer.leadingAnchor, constant: 16),
            prizePoolAmount.trailingAnchor.constraint(equalTo: prizePoolContainer.trailingAnchor, constant: -16),
            
            // Payout structure
            payoutStructure.topAnchor.constraint(equalTo: prizePoolAmount.bottomAnchor, constant: 8),
            payoutStructure.leadingAnchor.constraint(equalTo: prizePoolContainer.leadingAnchor, constant: 16),
            payoutStructure.trailingAnchor.constraint(equalTo: prizePoolContainer.trailingAnchor, constant: -16),
            
            // Days remaining
            daysRemaining.topAnchor.constraint(equalTo: payoutStructure.bottomAnchor, constant: 8),
            daysRemaining.leadingAnchor.constraint(equalTo: prizePoolContainer.leadingAnchor, constant: 16),
            daysRemaining.trailingAnchor.constraint(equalTo: prizePoolContainer.trailingAnchor, constant: -16),
            daysRemaining.bottomAnchor.constraint(lessThanOrEqualTo: prizePoolContainer.bottomAnchor, constant: -16)
        ])
        
        // Update gradient layer frame when layout changes
        DispatchQueue.main.async {
            gradientLayer.frame = self.prizePoolContainer.bounds
        }
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
            
            // Prize pool container
            prizePoolContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            prizePoolContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            prizePoolContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            prizePoolContainer.heightAnchor.constraint(equalToConstant: 140),
            
            // Leaderboard container
            leaderboardContainer.topAnchor.constraint(equalTo: prizePoolContainer.bottomAnchor, constant: 20),
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
        loadLeagueData()
        loadRealLeaderboard()
    }
    
    private func loadLeagueData() {
        Task {
            do {
                // Load active team league
                let league = try await CompetitionDataService.shared.fetchActiveTeamLeague(teamId: teamId)
                
                // Load team wallet balance (placeholder for now - will integrate with actual wallet service)
                let walletBalance = 500000 // 0.005 BTC = 500,000 sats - placeholder
                
                await MainActor.run {
                    self.currentLeague = league
                    self.teamWalletBalance = walletBalance
                    self.updatePrizePoolDisplay()
                }
                
                print("LeagueView: Loaded league data for team \(teamId)")
                
            } catch {
                print("LeagueView: Failed to load league data: \(error)")
                await MainActor.run {
                    self.currentLeague = nil
                    self.teamWalletBalance = 0
                    self.updatePrizePoolDisplay()
                }
            }
        }
    }
    
    private func loadRealLeaderboard() {
        Task {
            do {
                // Load team leaderboard from Supabase - changed to monthly
                let teamLeaderboardMembers = try await supabaseService.fetchTeamLeaderboard(teamId: teamId, type: "distance", period: "monthly")
                
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
    
    private func updatePrizePoolDisplay() {
        if let league = currentLeague {
            // Show real league data
            let btcAmount = Double(teamWalletBalance) / 100_000_000.0
            prizePoolAmount.text = "₿\(String(format: "%.6f", btcAmount))"
            
            // Update payout structure based on league settings
            let payoutType = PayoutType.allCases.first { $0.percentages == league.payoutPercentages } ?? .winnerTakesAll
            payoutStructure.text = payoutType.description
            
            // Update days remaining
            let daysLeft = league.daysRemaining
            daysRemaining.text = "\(daysLeft) days remaining"
            
            prizePoolTitle.text = "PRIZE POOL"
        } else {
            // Show no active league state
            prizePoolAmount.text = "No Active League"
            payoutStructure.text = "Create a monthly league to compete"
            daysRemaining.text = "Team captain can create league"
            prizePoolTitle.text = "MONTHLY LEAGUE"
        }
    }
    
    // Streak and chat loading removed from scope
    
    private func buildLeaderboard() {
        // Clear existing views
        leaderboardStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for user in leaderboardUsers {
            let potentialPrize = calculatePotentialPrize(for: user)
            let leaderboardItem = LeaderboardItemView(user: user, potentialPrize: potentialPrize)
            leaderboardItem.delegate = self
            leaderboardStackView.addArrangedSubview(leaderboardItem)
        }
    }
    
    private func calculatePotentialPrize(for user: LeaderboardUser) -> Int {
        guard let league = currentLeague, teamWalletBalance > 0 else {
            return 0
        }
        
        // Calculate what this user would earn based on current ranking
        let rank = user.rank
        let payoutPercentages = league.payoutPercentages
        
        // Check if this user's rank qualifies for a prize
        guard rank <= payoutPercentages.count else {
            return 0 // No prize for ranks beyond payout structure
        }
        
        // Calculate prize amount (rank is 1-indexed, array is 0-indexed)
        let percentage = payoutPercentages[rank - 1]
        let prizeAmount = Int(Double(teamWalletBalance) * Double(percentage) / 100.0)
        
        return prizeAmount
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
