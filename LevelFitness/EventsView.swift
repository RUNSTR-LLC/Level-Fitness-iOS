import UIKit

// Extension to add computed properties to SupabaseService's CompetitionEvent
extension CompetitionEvent {
    var title: String { return name }
    var participants: Int { return participantCount }
    var eventType: EventType { 
        return EventType.fromString(type)
    }
    var goalValue: String {
        return "\(targetValue) \(unit.uppercased())"
    }
    var isRegistered: Bool {
        // TODO: Check if current user is registered for this event
        return false
    }
    
    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        
        let calendar = Calendar.current
        if calendar.isDate(startDate, equalTo: endDate, toGranularity: .month) {
            let startDay = formatter.string(from: startDate)
            let endFormatter = DateFormatter()
            endFormatter.dateFormat = "d, yyyy"
            let endDay = endFormatter.string(from: endDate)
            return "\(startDay)-\(endDay)"
        } else {
            formatter.dateFormat = "MMM d"
            let start = formatter.string(from: startDate)
            let end = formatter.string(from: endDate)
            let year = DateFormatter()
            year.dateFormat = "yyyy"
            return "\(start)-\(end), \(year.string(from: endDate))"
        }
    }
    
    var formattedPrizePool: String {
        let btcAmount = Double(prizePool) / 100_000_000.0 // Convert satoshis to BTC
        return "₿\(String(format: "%.6f", btcAmount))"
    }
    
    var formattedEntryFee: String {
        guard entryFee > 0 else { return "Free" }
        let btcAmount = Double(entryFee) / 100_000_000.0 // Convert satoshis to BTC
        return "₿\(String(format: "%.6f", btcAmount))"
    }
    
    var formattedParticipants: String {
        return "\(participants)"
    }
}

enum EventType {
    case marathon
    case speed
    case elevation
    case distance
    case streak
    
    static func fromString(_ typeString: String) -> EventType {
        switch typeString.lowercased() {
        case "marathon": return .marathon
        case "speed_challenge": return .speed
        case "elevation_goal": return .elevation
        case "distance": return .distance
        case "streak", "frequency": return .streak
        default: return .distance
        }
    }
    
    var icon: String {
        switch self {
        case .marathon: return "🏁"
        case .speed: return "⚡"
        case .elevation: return "⛰️"
        case .distance: return "🏃"
        case .streak: return "🔥"
        }
    }
}

protocol EventsViewDelegate: AnyObject {
    func didTapEvent(_ event: CompetitionEvent)
    func didJoinEvent(_ event: CompetitionEvent)
}

class EventsView: UIView {
    
    // MARK: - Properties
    weak var delegate: EventsViewDelegate?
    private var events: [CompetitionEvent] = []
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let eventsStackView = UIStackView()
    
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
        
        // Events stack view
        eventsStackView.translatesAutoresizingMaskIntoConstraints = false
        eventsStackView.axis = .vertical
        eventsStackView.spacing = 16
        eventsStackView.alignment = .fill
        eventsStackView.isUserInteractionEnabled = true
        
        // Add subviews
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(eventsStackView)
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
            
            // Events stack view
            eventsStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            eventsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            eventsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            eventsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    // MARK: - Public Methods
    
    func loadSampleData() {
        // Legacy method name kept for compatibility - now loads real data
        loadRealEvents()
    }
    
    func loadRealEvents() {
        Task {
            do {
                let fetchedEvents = try await SupabaseService.shared.fetchEvents(status: "active")
                
                await MainActor.run {
                    displayEvents(fetchedEvents)
                    print("🏆 LevelFitness: Loaded \(fetchedEvents.count) events from Supabase")
                }
            } catch {
                print("🏆 LevelFitness: Error fetching events: \(error)")
                await MainActor.run {
                    displayEvents([]) // Show empty state on error
                }
            }
        }
    }
    
    private func displayEvents(_ eventList: [CompetitionEvent]) {
        events = eventList
        buildEventsList()
    }
    
    private func loadSampleEvents() {
        // Start with empty array - real data will be loaded from Supabase
        events = []
        
        buildEventsList()
    }
    
    private func buildEventsList() {
        // Clear existing views
        eventsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for event in events {
            let eventCard = EventCardView(event: event)
            eventCard.delegate = self
            eventsStackView.addArrangedSubview(eventCard)
        }
    }
}

// MARK: - EventCardViewDelegate

extension EventsView: EventCardViewDelegate {
    func didTapEventCard(_ event: CompetitionEvent) {
        delegate?.didTapEvent(event)
    }
    
    func didTapJoinButton(_ event: CompetitionEvent) {
        delegate?.didJoinEvent(event)
    }
}