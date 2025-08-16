import UIKit
import HealthKit

class EventManagementDashboardViewController: UIViewController {
    
    // MARK: - Properties
    private let teamData: TeamData
    private var events: [EventData] = []
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header section
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let teamNameLabel = UILabel()
    private let createEventButton = UIButton(type: .custom)
    
    // Stats section
    private let statsContainer = UIView()
    private let activeEventsCard = EventStatCard()
    private let totalParticipantsCard = EventStatCard()
    private let totalEarningsCard = EventStatCard()
    
    // Events list section
    private let eventsSection = UIView()
    private let eventsSectionTitle = UILabel()
    private let eventsTableView = UITableView()
    private let emptyStateView = UIView()
    private let emptyStateLabel = UILabel()
    private let emptyStateButton = UIButton(type: .custom)
    
    // Filter section
    private let filterContainer = UIView()
    private let allEventsButton = UIButton(type: .custom)
    private let activeEventsButton = UIButton(type: .custom)
    private let completedEventsButton = UIButton(type: .custom)
    private var currentFilter: EventFilter = .all
    
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
        print("🎛️ EventDashboard: Loading event management dashboard for team: \(teamData.name)")
        
        setupIndustrialBackground()
        setupScrollView()
        setupHeader()
        setupStatsSection()
        setupFilterSection()
        setupEventsSection()
        setupConstraints()
        
        loadEvents()
        updateStats()
        
        print("🎛️ EventDashboard: Dashboard loaded successfully")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadEvents()
        updateStats()
    }
    
    // MARK: - Setup Methods
    
    private func setupIndustrialBackground() {
        view.backgroundColor = IndustrialDesign.Colors.background
        
        // Add grid pattern
        let gridView = GridPatternView()
        gridView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gridView)
        
        NSLayoutConstraint.activate([
            gridView.topAnchor.constraint(equalTo: view.topAnchor),
            gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Add gear decoration
        let gear = RotatingGearView(size: 100)
        gear.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gear)
        
        NSLayoutConstraint.activate([
            gear.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            gear.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 20),
            gear.widthAnchor.constraint(equalToConstant: 100),
            gear.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 0.95)
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        
        titleLabel.text = "Event Management"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        teamNameLabel.text = teamData.name
        teamNameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        teamNameLabel.textColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0) // Bitcoin orange
        teamNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        createEventButton.setTitle("+ Create Event", for: .normal)
        createEventButton.setTitleColor(.white, for: .normal)
        createEventButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        createEventButton.backgroundColor = UIColor.systemBlue
        createEventButton.layer.cornerRadius = 8
        createEventButton.translatesAutoresizingMaskIntoConstraints = false
        createEventButton.addTarget(self, action: #selector(createEventTapped), for: .touchUpInside)
        
        headerView.addSubview(titleLabel)
        headerView.addSubview(teamNameLabel)
        headerView.addSubview(createEventButton)
        contentView.addSubview(headerView)
    }
    
    private func setupStatsSection() {
        statsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure stat cards
        activeEventsCard.configure(
            title: "Active Events",
            value: "0",
            icon: "calendar.circle.fill",
            color: UIColor.systemGreen
        )
        
        totalParticipantsCard.configure(
            title: "Total Participants",
            value: "0",
            icon: "person.3.fill",
            color: UIColor.systemBlue
        )
        
        totalEarningsCard.configure(
            title: "Event Earnings",
            value: "₿ 0",
            icon: "bitcoinsign.circle.fill",
            color: UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        )
        
        activeEventsCard.translatesAutoresizingMaskIntoConstraints = false
        totalParticipantsCard.translatesAutoresizingMaskIntoConstraints = false
        totalEarningsCard.translatesAutoresizingMaskIntoConstraints = false
        
        statsContainer.addSubview(activeEventsCard)
        statsContainer.addSubview(totalParticipantsCard)
        statsContainer.addSubview(totalEarningsCard)
        contentView.addSubview(statsContainer)
    }
    
    private func setupFilterSection() {
        filterContainer.translatesAutoresizingMaskIntoConstraints = false
        filterContainer.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        filterContainer.layer.cornerRadius = 8
        
        // Configure filter buttons
        allEventsButton.setTitle("All", for: .normal)
        allEventsButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        allEventsButton.backgroundColor = UIColor.systemBlue
        allEventsButton.setTitleColor(.white, for: .normal)
        allEventsButton.layer.cornerRadius = 6
        allEventsButton.translatesAutoresizingMaskIntoConstraints = false
        allEventsButton.addTarget(self, action: #selector(allEventsFilterTapped), for: .touchUpInside)
        
        activeEventsButton.setTitle("Active", for: .normal)
        activeEventsButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        activeEventsButton.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0)
        activeEventsButton.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
        activeEventsButton.layer.cornerRadius = 6
        activeEventsButton.translatesAutoresizingMaskIntoConstraints = false
        activeEventsButton.addTarget(self, action: #selector(activeEventsFilterTapped), for: .touchUpInside)
        
        completedEventsButton.setTitle("Completed", for: .normal)
        completedEventsButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        completedEventsButton.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0)
        completedEventsButton.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
        completedEventsButton.layer.cornerRadius = 6
        completedEventsButton.translatesAutoresizingMaskIntoConstraints = false
        completedEventsButton.addTarget(self, action: #selector(completedEventsFilterTapped), for: .touchUpInside)
        
        filterContainer.addSubview(allEventsButton)
        filterContainer.addSubview(activeEventsButton)
        filterContainer.addSubview(completedEventsButton)
        contentView.addSubview(filterContainer)
    }
    
    private func setupEventsSection() {
        eventsSection.translatesAutoresizingMaskIntoConstraints = false
        
        eventsSectionTitle.text = "Your Events"
        eventsSectionTitle.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        eventsSectionTitle.textColor = IndustrialDesign.Colors.primaryText
        eventsSectionTitle.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup table view
        eventsTableView.translatesAutoresizingMaskIntoConstraints = false
        eventsTableView.backgroundColor = .clear
        eventsTableView.separatorStyle = .none
        eventsTableView.delegate = self
        eventsTableView.dataSource = self
        eventsTableView.register(EventManagementCell.self, forCellReuseIdentifier: "EventManagementCell")
        
        // Setup empty state
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        emptyStateView.layer.cornerRadius = 12
        emptyStateView.layer.borderWidth = 1
        emptyStateView.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        emptyStateLabel.text = "No events created yet\\n\\nStart engaging your team members by creating your first fitness event!"
        emptyStateLabel.font = UIFont.systemFont(ofSize: 16)
        emptyStateLabel.textColor = IndustrialDesign.Colors.secondaryText
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        emptyStateButton.setTitle("Create Your First Event", for: .normal)
        emptyStateButton.setTitleColor(.white, for: .normal)
        emptyStateButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        emptyStateButton.backgroundColor = UIColor.systemBlue
        emptyStateButton.layer.cornerRadius = 8
        emptyStateButton.translatesAutoresizingMaskIntoConstraints = false
        emptyStateButton.addTarget(self, action: #selector(createEventTapped), for: .touchUpInside)
        
        emptyStateView.addSubview(emptyStateLabel)
        emptyStateView.addSubview(emptyStateButton)
        
        eventsSection.addSubview(eventsSectionTitle)
        eventsSection.addSubview(eventsTableView)
        eventsSection.addSubview(emptyStateView)
        contentView.addSubview(eventsSection)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Header
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            headerView.heightAnchor.constraint(equalToConstant: 80),
            
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            
            teamNameLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            teamNameLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            
            createEventButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            createEventButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            createEventButton.widthAnchor.constraint(equalToConstant: 140),
            createEventButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Stats container
            statsContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            statsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            statsContainer.heightAnchor.constraint(equalToConstant: 100),
            
            activeEventsCard.topAnchor.constraint(equalTo: statsContainer.topAnchor),
            activeEventsCard.leadingAnchor.constraint(equalTo: statsContainer.leadingAnchor),
            activeEventsCard.widthAnchor.constraint(equalTo: statsContainer.widthAnchor, multiplier: 0.31),
            activeEventsCard.bottomAnchor.constraint(equalTo: statsContainer.bottomAnchor),
            
            totalParticipantsCard.topAnchor.constraint(equalTo: statsContainer.topAnchor),
            totalParticipantsCard.centerXAnchor.constraint(equalTo: statsContainer.centerXAnchor),
            totalParticipantsCard.widthAnchor.constraint(equalTo: statsContainer.widthAnchor, multiplier: 0.31),
            totalParticipantsCard.bottomAnchor.constraint(equalTo: statsContainer.bottomAnchor),
            
            totalEarningsCard.topAnchor.constraint(equalTo: statsContainer.topAnchor),
            totalEarningsCard.trailingAnchor.constraint(equalTo: statsContainer.trailingAnchor),
            totalEarningsCard.widthAnchor.constraint(equalTo: statsContainer.widthAnchor, multiplier: 0.31),
            totalEarningsCard.bottomAnchor.constraint(equalTo: statsContainer.bottomAnchor),
            
            // Filter container
            filterContainer.topAnchor.constraint(equalTo: statsContainer.bottomAnchor, constant: 20),
            filterContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            filterContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            filterContainer.heightAnchor.constraint(equalToConstant: 44),
            
            allEventsButton.leadingAnchor.constraint(equalTo: filterContainer.leadingAnchor, constant: 12),
            allEventsButton.centerYAnchor.constraint(equalTo: filterContainer.centerYAnchor),
            allEventsButton.widthAnchor.constraint(equalToConstant: 60),
            allEventsButton.heightAnchor.constraint(equalToConstant: 32),
            
            activeEventsButton.leadingAnchor.constraint(equalTo: allEventsButton.trailingAnchor, constant: 8),
            activeEventsButton.centerYAnchor.constraint(equalTo: filterContainer.centerYAnchor),
            activeEventsButton.widthAnchor.constraint(equalToConstant: 70),
            activeEventsButton.heightAnchor.constraint(equalToConstant: 32),
            
            completedEventsButton.leadingAnchor.constraint(equalTo: activeEventsButton.trailingAnchor, constant: 8),
            completedEventsButton.centerYAnchor.constraint(equalTo: filterContainer.centerYAnchor),
            completedEventsButton.widthAnchor.constraint(equalToConstant: 90),
            completedEventsButton.heightAnchor.constraint(equalToConstant: 32),
            
            // Events section
            eventsSection.topAnchor.constraint(equalTo: filterContainer.bottomAnchor, constant: 20),
            eventsSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            eventsSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            eventsSection.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            eventsSection.heightAnchor.constraint(equalToConstant: 400),
            
            eventsSectionTitle.topAnchor.constraint(equalTo: eventsSection.topAnchor),
            eventsSectionTitle.leadingAnchor.constraint(equalTo: eventsSection.leadingAnchor),
            
            eventsTableView.topAnchor.constraint(equalTo: eventsSectionTitle.bottomAnchor, constant: 12),
            eventsTableView.leadingAnchor.constraint(equalTo: eventsSection.leadingAnchor),
            eventsTableView.trailingAnchor.constraint(equalTo: eventsSection.trailingAnchor),
            eventsTableView.bottomAnchor.constraint(equalTo: eventsSection.bottomAnchor),
            
            // Empty state
            emptyStateView.topAnchor.constraint(equalTo: eventsSectionTitle.bottomAnchor, constant: 12),
            emptyStateView.leadingAnchor.constraint(equalTo: eventsSection.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: eventsSection.trailingAnchor),
            emptyStateView.heightAnchor.constraint(equalToConstant: 200),
            
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateView.topAnchor, constant: 40),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor, constant: 20),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor, constant: -20),
            
            emptyStateButton.topAnchor.constraint(equalTo: emptyStateLabel.bottomAnchor, constant: 20),
            emptyStateButton.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateButton.widthAnchor.constraint(equalToConstant: 200),
            emptyStateButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - Data Loading
    
    private func loadEvents() {
        // In a real implementation, this would load from Supabase
        // For now, create sample data
        events = createSampleEvents()
        updateEventsList()
    }
    
    private func createSampleEvents() -> [EventData] {
        return [
            EventData(
                id: "1",
                name: "December Distance Challenge",
                type: .challenge,
                status: .active,
                startDate: Date().addingTimeInterval(-7 * 24 * 3600), // 7 days ago
                endDate: Date().addingTimeInterval(23 * 24 * 3600), // 23 days from now
                participants: 47,
                prizePool: 5000,
                entryFee: 100
            ),
            EventData(
                id: "2",
                name: "Holiday Sprint Week",
                type: .sprint,
                status: .completed,
                startDate: Date().addingTimeInterval(-14 * 24 * 3600),
                endDate: Date().addingTimeInterval(-7 * 24 * 3600),
                participants: 32,
                prizePool: 2500,
                entryFee: 0
            ),
            EventData(
                id: "3",
                name: "New Year Marathon",
                type: .marathon,
                status: .upcoming,
                startDate: Date().addingTimeInterval(10 * 24 * 3600),
                endDate: Date().addingTimeInterval(40 * 24 * 3600),
                participants: 12,
                prizePool: 10000,
                entryFee: 200
            )
        ]
    }
    
    private func updateStats() {
        let activeEvents = events.filter { $0.status == .active }.count
        let totalParticipants = events.reduce(0) { $0 + $1.participants }
        let totalEarnings = events.reduce(0) { $0 + Int($1.prizePool) }
        
        activeEventsCard.updateValue("\(activeEvents)")
        totalParticipantsCard.updateValue("\(totalParticipants)")
        totalEarningsCard.updateValue("₿ \(totalEarnings)")
    }
    
    private func updateEventsList() {
        let filteredEvents = events.filter { event in
            switch currentFilter {
            case .all:
                return true
            case .active:
                return event.status == .active
            case .completed:
                return event.status == .completed
            }
        }
        
        if filteredEvents.isEmpty {
            eventsTableView.isHidden = true
            emptyStateView.isHidden = false
        } else {
            eventsTableView.isHidden = false
            emptyStateView.isHidden = true
            eventsTableView.reloadData()
        }
    }
    
    // MARK: - Actions
    
    @objc private func createEventTapped() {
        print("🎛️ EventDashboard: Create event button tapped")
        
        let eventWizard = EventCreationWizardViewController(teamData: teamData)
        eventWizard.onCompletion = { [weak self] success, eventData in
            if success {
                print("🎛️ EventDashboard: Event created successfully")
                self?.loadEvents()
                self?.updateStats()
            }
            eventWizard.dismiss(animated: true)
        }
        
        let navController = UINavigationController(rootViewController: eventWizard)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    @objc private func allEventsFilterTapped() {
        updateFilter(.all)
    }
    
    @objc private func activeEventsFilterTapped() {
        updateFilter(.active)
    }
    
    @objc private func completedEventsFilterTapped() {
        updateFilter(.completed)
    }
    
    private func updateFilter(_ filter: EventFilter) {
        currentFilter = filter
        
        // Update button appearances
        let buttons = [allEventsButton, activeEventsButton, completedEventsButton]
        for button in buttons {
            button.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0)
            button.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
        }
        
        let selectedButton: UIButton
        switch filter {
        case .all:
            selectedButton = allEventsButton
        case .active:
            selectedButton = activeEventsButton
        case .completed:
            selectedButton = completedEventsButton
        }
        
        selectedButton.backgroundColor = UIColor.systemBlue
        selectedButton.setTitleColor(.white, for: .normal)
        
        updateEventsList()
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension EventManagementDashboardViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let filteredEvents = events.filter { event in
            switch currentFilter {
            case .all:
                return true
            case .active:
                return event.status == .active
            case .completed:
                return event.status == .completed
            }
        }
        return filteredEvents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "EventManagementCell", for: indexPath) as? EventManagementCell else {
            return UITableViewCell()
        }
        
        let filteredEvents = events.filter { event in
            switch currentFilter {
            case .all:
                return true
            case .active:
                return event.status == .active
            case .completed:
                return event.status == .completed
            }
        }
        
        let event = filteredEvents[indexPath.row]
        cell.configure(with: event)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let filteredEvents = events.filter { event in
            switch currentFilter {
            case .all:
                return true
            case .active:
                return event.status == .active
            case .completed:
                return event.status == .completed
            }
        }
        
        let event = filteredEvents[indexPath.row]
        print("🎛️ EventDashboard: Selected event: \(event.name)")
        
        // TODO: Navigate to event detail view
        let alert = UIAlertController(
            title: "Event Details",
            message: "Event detail view will be implemented in the next phase.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Supporting Types

enum EventFilter {
    case all
    case active
    case completed
}

struct EventData {
    let id: String
    let name: String
    let type: EventType
    let status: EventStatus
    let startDate: Date
    let endDate: Date
    let participants: Int
    let prizePool: Double
    let entryFee: Double
}

enum EventStatus {
    case upcoming
    case active
    case completed
    
    var displayName: String {
        switch self {
        case .upcoming:
            return "Upcoming"
        case .active:
            return "Active"
        case .completed:
            return "Completed"
        }
    }
    
    var color: UIColor {
        switch self {
        case .upcoming:
            return UIColor.systemOrange
        case .active:
            return UIColor.systemGreen
        case .completed:
            return UIColor.systemGray
        }
    }
}