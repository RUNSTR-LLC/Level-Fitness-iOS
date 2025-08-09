import UIKit

class TeamDetailEventsViewController: UIViewController {
    
    // MARK: - Properties
    private let teamData: TeamData
    
    // MARK: - UI Components
    private let eventsContainer = UIView()
    private var eventCards: [EventCard] = []
    
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
        setupEventsContainer()
        loadSampleEvents()
    }
    
    // MARK: - Setup Methods
    
    private func setupEventsContainer() {
        eventsContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(eventsContainer)
        
        NSLayoutConstraint.activate([
            eventsContainer.topAnchor.constraint(equalTo: view.topAnchor),
            eventsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            eventsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            eventsContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadSampleEvents() {
        let events = [
            EventData(
                title: "Virtual Steel City Marathon",
                date: "February 15, 2025",
                prize: "₿0.10",
                participants: "89 registered",
                entry: "Entry: ₿0.001",
                description: "26.2 miles through virtual steel cityscapes"
            ),
            EventData(
                title: "Weekend Warrior 10K",
                date: "This Saturday • 8:00 AM",
                prize: "₿0.02",
                participants: "34 registered",
                entry: "Free Entry",
                description: "Start your weekend strong with 10K"
            ),
            EventData(
                title: "Night Run Challenge",
                date: "January 30, 2025 • 7:00 PM",
                prize: "₿0.03",
                participants: "56 registered",
                entry: "Entry: ₿0.0005",
                description: "5K under the stars, bring a headlamp"
            ),
            EventData(
                title: "Team Relay Race",
                date: "February 8, 2025",
                prize: "₿0.05",
                participants: "12 teams registered",
                entry: "Entry: ₿0.002/team",
                description: "4x5K relay, build your team strategy"
            )
        ]
        
        var lastView: UIView? = nil
        
        for eventData in events {
            let eventCard = EventCard(eventData: eventData)
            eventCard.translatesAutoresizingMaskIntoConstraints = false
            eventsContainer.addSubview(eventCard)
            eventCards.append(eventCard)
            
            NSLayoutConstraint.activate([
                eventCard.leadingAnchor.constraint(equalTo: eventsContainer.leadingAnchor, constant: IndustrialDesign.Spacing.large),
                eventCard.trailingAnchor.constraint(equalTo: eventsContainer.trailingAnchor, constant: -IndustrialDesign.Spacing.large)
            ])
            
            if let lastView = lastView {
                eventCard.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: IndustrialDesign.Spacing.medium).isActive = true
            } else {
                eventCard.topAnchor.constraint(equalTo: eventsContainer.topAnchor, constant: IndustrialDesign.Spacing.large).isActive = true
            }
            
            lastView = eventCard
        }
        
        if let lastView = lastView {
            eventsContainer.bottomAnchor.constraint(greaterThanOrEqualTo: lastView.bottomAnchor, constant: IndustrialDesign.Spacing.large).isActive = true
        }
    }
}