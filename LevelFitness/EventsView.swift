import UIKit

struct CompetitionEvent {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let prizePool: Double // in Bitcoin
    let entryFee: Double? // in Bitcoin, nil for free
    let participants: Int
    let eventType: EventType
    let goalValue: String // "42.2 KM", "5x5K", etc.
    let isRegistered: Bool
    
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
        return "₿\(String(format: "%.2f", prizePool))"
    }
    
    var formattedEntryFee: String {
        guard let fee = entryFee, fee > 0 else { return "Free" }
        return "₿\(String(format: "%.4f", fee))"
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
        loadSampleEvents()
    }
    
    private func loadSampleEvents() {
        let calendar = Calendar.current
        let now = Date()
        
        events = [
            CompetitionEvent(
                id: "1",
                title: "Global Marathon Challenge",
                startDate: calendar.date(byAdding: .day, value: 20, to: now)!,
                endDate: calendar.date(byAdding: .day, value: 22, to: now)!,
                prizePool: 0.25,
                entryFee: 0.001,
                participants: 847,
                eventType: .marathon,
                goalValue: "42.2 KM Goal",
                isRegistered: false
            ),
            CompetitionEvent(
                id: "2",
                title: "Speed Week Challenge",
                startDate: calendar.date(byAdding: .day, value: 6, to: now)!,
                endDate: calendar.date(byAdding: .day, value: 12, to: now)!,
                prizePool: 0.10,
                entryFee: nil,
                participants: 324,
                eventType: .speed,
                goalValue: "5x5K Format",
                isRegistered: true
            ),
            CompetitionEvent(
                id: "3",
                title: "Elevation Masters",
                startDate: calendar.date(byAdding: .day, value: 11, to: now)!,
                endDate: calendar.date(byAdding: .day, value: 22, to: now)!,
                prizePool: 0.15,
                entryFee: 0.0005,
                participants: 156,
                eventType: .elevation,
                goalValue: "3000m Elevation",
                isRegistered: false
            ),
            CompetitionEvent(
                id: "4",
                title: "New Year Century",
                startDate: calendar.date(byAdding: .day, value: -8, to: now)!,
                endDate: calendar.date(byAdding: .day, value: 22, to: now)!,
                prizePool: 0.30,
                entryFee: 0.0002,
                participants: 512,
                eventType: .distance,
                goalValue: "100K Monthly Goal",
                isRegistered: false
            )
        ]
        
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