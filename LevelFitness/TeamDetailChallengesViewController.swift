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
        loadSampleChallenges()
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
    
    private func loadSampleChallenges() {
        let challenges = [
            ChallengeData(
                title: "January Distance Challenge",
                type: "Monthly • Running",
                prize: "₿0.05",
                progress: 0.65,
                progressText: "156km / 240km",
                timeLeft: "12 days left",
                subtitle: "Push your limits this month"
            ),
            ChallengeData(
                title: "Speed Demon Week",
                type: "Weekly • Running",
                prize: "₿0.02",
                progress: 0.40,
                progressText: "2 / 5 runs completed",
                timeLeft: "4 days left",
                subtitle: "5 runs under 5:00/km pace"
            ),
            ChallengeData(
                title: "Elevation Master",
                type: "Monthly • Running",
                prize: "₿0.03",
                progress: 0.80,
                progressText: "1,200m / 1,500m elevation",
                timeLeft: "8 days left",
                subtitle: "Conquer the hills"
            ),
            ChallengeData(
                title: "Consistency Streak",
                type: "Daily • All Activities",
                prize: "₿0.01",
                progress: 0.25,
                progressText: "7 / 30 days streak",
                timeLeft: "Ongoing",
                subtitle: "Daily activity goal"
            )
        ]
        
        var lastView: UIView? = nil
        
        for challengeData in challenges {
            let challengeCard = ChallengeCard(challengeData: challengeData)
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
}