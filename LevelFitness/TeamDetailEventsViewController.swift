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
        loadRealEvents()
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
    
    private func loadRealEvents() {
        // TODO: Fetch real events from Supabase based on team ID
        Task {
            // For now, show empty state until Supabase team_events table is set up
            await MainActor.run {
                displayEvents([])
            }
        }
    }
    
    private func displayEvents(_ events: [EventData]) {
        // Clear existing cards
        eventCards.forEach { $0.removeFromSuperview() }
        eventCards.removeAll()
        
        if events.isEmpty {
            showEmptyState("No upcoming events")
            return
        }
        
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
    
    private func showEmptyState(_ message: String) {
        let emptyLabel = UILabel()
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.text = message
        emptyLabel.textColor = IndustrialDesign.Colors.secondaryText
        emptyLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        emptyLabel.textAlignment = .center
        
        eventsContainer.addSubview(emptyLabel)
        
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: eventsContainer.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: eventsContainer.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: eventsContainer.leadingAnchor, constant: 40),
            emptyLabel.trailingAnchor.constraint(equalTo: eventsContainer.trailingAnchor, constant: -40)
        ])
    }
}