import UIKit

class TeamDetailChallengesViewController: UIViewController {
    
    // MARK: - Properties
    private let teamData: TeamData
    
    // MARK: - UI Components
    private let challengesContainer = UIView()
    private var challengeCards: [ChallengeCard] = []
    
    // MARK: - Initialization
    init(teamData: TeamData) {
        self.teamData = teamData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupChallengesContainer()
        loadRealChallenges()
    }
    
    // MARK: - Setup Methods
    
    private func setupChallengesContainer() {
        challengesContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(challengesContainer)
        
        NSLayoutConstraint.activate([
            challengesContainer.topAnchor.constraint(equalTo: view.topAnchor),
            challengesContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            challengesContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            challengesContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadRealChallenges() {
        // TODO: Fetch real challenges from Supabase based on team ID
        Task {
            // For now, show empty state until Supabase team_challenges table is set up
            await MainActor.run {
                displayChallenges([])
            }
        }
    }
    
    private func displayChallenges(_ challenges: [ChallengeData]) {
        // Clear existing cards
        challengeCards.forEach { $0.removeFromSuperview() }
        challengeCards.removeAll()
        
        if challenges.isEmpty {
            showEmptyState("No active challenges")
            return
        }
        
        var lastView: UIView? = nil
        
        for challengeData in challenges {
            let challengeCard = ChallengeCard(challengeData: challengeData)
            challengeCard.delegate = self
            challengeCard.translatesAutoresizingMaskIntoConstraints = false
            challengesContainer.addSubview(challengeCard)
            challengeCards.append(challengeCard)
            
            NSLayoutConstraint.activate([
                challengeCard.leadingAnchor.constraint(equalTo: challengesContainer.leadingAnchor, constant: IndustrialDesign.Spacing.large),
                challengeCard.trailingAnchor.constraint(equalTo: challengesContainer.trailingAnchor, constant: -IndustrialDesign.Spacing.large)
            ])
            
            if let lastView = lastView {
                challengeCard.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: IndustrialDesign.Spacing.medium).isActive = true
            } else {
                challengeCard.topAnchor.constraint(equalTo: challengesContainer.topAnchor, constant: IndustrialDesign.Spacing.large).isActive = true
            }
            
            lastView = challengeCard
        }
        
        if let lastView = lastView {
            challengesContainer.bottomAnchor.constraint(greaterThanOrEqualTo: lastView.bottomAnchor, constant: IndustrialDesign.Spacing.large).isActive = true
        }
    }
    
    private func showEmptyState(_ message: String) {
        let emptyLabel = UILabel()
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.text = message
        emptyLabel.textColor = IndustrialDesign.Colors.secondaryText
        emptyLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        emptyLabel.textAlignment = .center
        
        challengesContainer.addSubview(emptyLabel)
        
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: challengesContainer.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: challengesContainer.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: challengesContainer.leadingAnchor, constant: 40),
            emptyLabel.trailingAnchor.constraint(equalTo: challengesContainer.trailingAnchor, constant: -40)
        ])
    }
}

// MARK: - ChallengeCardDelegate

extension TeamDetailChallengesViewController: ChallengeCardDelegate {
    func didTapChallengeCard(_ challengeData: ChallengeData) {
        print("🏆 TeamDetailChallenges: Challenge card tapped: \(challengeData.title)")
        
        let challengeDetailVC = ChallengeDetailViewController(challengeData: challengeData)
        navigationController?.pushViewController(challengeDetailVC, animated: true)
    }
}