import UIKit

class TeamDetailEventsViewController: UIViewController {
    
    // MARK: - Properties
    private let teamData: TeamData
    private var isCaptain = false
    
    // MARK: - UI Components
    private let eventsContainer = UIView()
    private let headerView = UIView()
    private let createEventButton = UIButton(type: .custom)
    private let emptyStateView = UIView()
    private let emptyStateLabel = UILabel()
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
        setupHeaderView()
        setupEventsContainer()
        setupEmptyState()
        loadRealEvents()
        checkCaptainStatus()
    }
    
    // MARK: - Setup Methods
    
    private func setupHeaderView() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        
        // Create event button
        createEventButton.translatesAutoresizingMaskIntoConstraints = false
        createEventButton.setTitle("Create Event", for: .normal)
        createEventButton.setTitleColor(.white, for: .normal)
        createEventButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        createEventButton.backgroundColor = IndustrialDesign.Colors.bitcoin
        createEventButton.layer.cornerRadius = 8
        createEventButton.layer.borderWidth = 1
        createEventButton.layer.borderColor = IndustrialDesign.Colors.bitcoin.cgColor
        createEventButton.isHidden = true // Hidden by default, shown for captains
        createEventButton.addTarget(self, action: #selector(createEventTapped), for: .touchUpInside)
        
        headerView.addSubview(createEventButton)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            createEventButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            createEventButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -24),
            createEventButton.widthAnchor.constraint(equalToConstant: 100),
            createEventButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    private func setupEventsContainer() {
        eventsContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(eventsContainer)
        
        NSLayoutConstraint.activate([
            eventsContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            eventsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            eventsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            eventsContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupEmptyState() {
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.isHidden = true
        
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.text = "No events yet"
        emptyStateLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        emptyStateLabel.textColor = IndustrialDesign.Colors.secondaryText
        emptyStateLabel.textAlignment = .center
        
        emptyStateView.addSubview(emptyStateLabel)
        eventsContainer.addSubview(emptyStateView)
        
        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: eventsContainer.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: eventsContainer.centerYAnchor),
            emptyStateView.widthAnchor.constraint(equalTo: eventsContainer.widthAnchor, multiplier: 0.8),
            emptyStateView.heightAnchor.constraint(equalToConstant: 100),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor)
        ])
    }
    
    private func checkCaptainStatus() {
        Task {
            guard let userSession = AuthenticationService.shared.loadSession() else {
                return
            }
            
            do {
                let members = try await SupabaseService.shared.fetchTeamMembers(teamId: teamData.id)
                print("🏗️ TeamDetailEvents: Fetched \(members.count) members for team \(teamData.id)")
                print("🏗️ TeamDetailEvents: User ID = \(userSession.id)")
                
                // Debug each member
                for member in members {
                    print("🏗️ TeamDetailEvents: Member: \(member.profile.id), Role: \(member.role)")
                }
                
                let isTeamCaptain = members.contains { $0.profile.id.lowercased() == userSession.id.lowercased() && $0.role == "captain" }
                
                await MainActor.run {
                    self.isCaptain = isTeamCaptain
                    self.createEventButton.isHidden = !isTeamCaptain
                    
                    if isTeamCaptain {
                        self.emptyStateLabel.text = "No events yet\nTap 'Create Event' to get started!"
                        print("🏗️ TeamDetailEvents: CREATE EVENT BUTTON SHOWN for captain")
                    } else {
                        self.emptyStateLabel.text = "No events yet"
                        print("🏗️ TeamDetailEvents: Create event button hidden for non-captain")
                    }
                    
                    print("🏗️ TeamDetailEvents: Captain status = \(isTeamCaptain), Button hidden = \(self.createEventButton.isHidden)")
                }
            } catch {
                print("🏗️ TeamDetailEvents: Error checking captain status: \(error)")
            }
        }
    }
    
    private func loadRealEvents() {
        Task {
            do {
                // Fetch team challenges (team-specific events)
                let challenges = try await SupabaseService.shared.fetchChallenges(teamId: teamData.id)
                
                // Convert challenges to EventCardData
                let challengeCards = challenges.map { challenge in
                    EventCardData(
                        title: challenge.name,
                        date: formatDate(challenge.startDate),
                        prize: "\(challenge.prizePool) sats",
                        participants: "Team Challenge",
                        entry: "Free", // Challenges are typically free to join for team members
                        description: challenge.description ?? "Team challenge",
                        eventId: challenge.id
                    )
                }
                
                // Also fetch general events (not team-specific)
                let generalEvents = try await SupabaseService.shared.fetchEvents(status: "active")
                let eventCards = generalEvents.map { event in
                    EventCardData(
                        title: event.name,
                        date: formatDate(event.startDate),
                        prize: "\(event.prizePool) sats",
                        participants: "\(event.participantCount) joined",
                        entry: event.entryFee > 0 ? "\(event.entryFee) sats" : "Free",
                        description: event.description ?? "Competition event",
                        eventId: event.id
                    )
                }
                
                // Combine both types of events
                let allEventCards = challengeCards + eventCards
                
                await MainActor.run {
                    displayEvents(allEventCards)
                }
                
                print("🏗️ TeamDetailEvents: ✅ Loaded \(challenges.count) challenges and \(generalEvents.count) events")
                
            } catch {
                print("❌ TeamDetailEvents: Failed to load events: \(error)")
                await MainActor.run {
                    displayEvents([])
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    @objc private func createEventTapped() {
        print("🏗️ TeamDetailEvents: Create event tapped")
        
        guard isCaptain else {
            print("🏗️ TeamDetailEvents: User is not captain, ignoring create event tap")
            return
        }
        
        let eventCreationWizard = EventCreationWizardViewController(teamData: teamData)
        eventCreationWizard.onCompletion = { [weak self] success, eventData in
            DispatchQueue.main.async {
                if success {
                    print("🏗️ TeamDetailEvents: Event created successfully")
                    self?.loadRealEvents() // Refresh events list
                } else {
                    print("🏗️ TeamDetailEvents: Event creation cancelled")
                }
                self?.dismiss(animated: true)
            }
        }
        
        let navigationController = UINavigationController(rootViewController: eventCreationWizard)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }
    
    private func displayEvents(_ events: [EventCardData]) {
        // Clear existing cards
        eventCards.forEach { $0.removeFromSuperview() }
        eventCards.removeAll()
        
        if events.isEmpty {
            emptyStateView.isHidden = false
            return
        } else {
            emptyStateView.isHidden = true
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