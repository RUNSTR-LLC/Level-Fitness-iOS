import UIKit

protocol TeamDetailEventsDelegate: AnyObject {
    func eventsDidRequestCreateEvent()
    func eventsDidRequestEventDetails(_ eventId: String)
}

class TeamDetailEventsController: UIViewController {
    
    // MARK: - Properties
    private let teamData: TeamData
    weak var delegate: TeamDetailEventsDelegate?
    private var isCaptain = false
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var eventsContainer: UIView?
    private var eventsEmptyLabel: UILabel?
    private var eventsTitleLabel: UILabel?
    private var eventsCreateButton: UIButton?
    
    // Data
    private var createdEvents: [EventCreationData] = []
    private static var sharedEvents: [String: [EventCreationData]] = [:]
    
    // MARK: - Initialization
    init(teamData: TeamData, isCaptain: Bool) {
        self.teamData = teamData
        self.isCaptain = isCaptain
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        loadPersistedEvents()
        setupNotificationListeners()
    }
    
    // MARK: - Setup Methods
    
    private func setupViews() {
        view.backgroundColor = .clear
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        setupEventsSection()
    }
    
    private func setupEventsSection() {
        let eventsContainer = UIView()
        eventsContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(eventsContainer)
        self.eventsContainer = eventsContainer
        
        // Events title
        let titleLabel = UILabel()
        titleLabel.text = "Team Events"
        titleLabel.font = IndustrialDesign.Fonts.sectionHeader
        titleLabel.textColor = IndustrialDesign.Colors.text
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        eventsContainer.addSubview(titleLabel)
        self.eventsTitleLabel = titleLabel
        
        // Create event button (captain only)
        if isCaptain {
            let createButton = UIButton(type: .system)
            createButton.setTitle("+ Create Event", for: .normal)
            createButton.backgroundColor = IndustrialDesign.Colors.accent
            createButton.setTitleColor(.white, for: .normal)
            createButton.layer.cornerRadius = 8
            createButton.titleLabel?.font = IndustrialDesign.Fonts.button
            createButton.translatesAutoresizingMaskIntoConstraints = false
            createButton.addTarget(self, action: #selector(createEventTapped), for: .touchUpInside)
            eventsContainer.addSubview(createButton)
            self.eventsCreateButton = createButton
        }
        
        // Empty state label
        let emptyLabel = UILabel()
        emptyLabel.text = "No events yet"
        emptyLabel.font = IndustrialDesign.Fonts.body
        emptyLabel.textColor = IndustrialDesign.Colors.textSecondary
        emptyLabel.textAlignment = .center
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        eventsContainer.addSubview(emptyLabel)
        self.eventsEmptyLabel = emptyLabel
        
        updateEventsDisplay()
    }
    
    private func setupConstraints() {
        guard let eventsContainer = eventsContainer,
              let eventsTitleLabel = eventsTitleLabel,
              let eventsEmptyLabel = eventsEmptyLabel else { return }
        
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Events container
            eventsContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            eventsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            eventsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            eventsContainer.bottomAnchor.constraint(greaterThanOrEqualTo: contentView.bottomAnchor, constant: -20),
            
            // Title
            eventsTitleLabel.topAnchor.constraint(equalTo: eventsContainer.topAnchor),
            eventsTitleLabel.leadingAnchor.constraint(equalTo: eventsContainer.leadingAnchor),
            eventsTitleLabel.trailingAnchor.constraint(equalTo: eventsContainer.trailingAnchor),
            
            // Empty label
            eventsEmptyLabel.centerXAnchor.constraint(equalTo: eventsContainer.centerXAnchor),
            eventsEmptyLabel.centerYAnchor.constraint(equalTo: eventsContainer.centerYAnchor)
        ])
        
        // Create button constraints (if captain)
        if let createButton = eventsCreateButton {
            NSLayoutConstraint.activate([
                createButton.topAnchor.constraint(equalTo: eventsTitleLabel.bottomAnchor, constant: 16),
                createButton.centerXAnchor.constraint(equalTo: eventsContainer.centerXAnchor),
                createButton.widthAnchor.constraint(equalToConstant: 200),
                createButton.heightAnchor.constraint(equalToConstant: 44)
            ])
            
            eventsEmptyLabel.topAnchor.constraint(equalTo: createButton.bottomAnchor, constant: 20).isActive = true
        } else {
            eventsEmptyLabel.topAnchor.constraint(equalTo: eventsTitleLabel.bottomAnchor, constant: 20).isActive = true
        }
    }
    
    // This controller focuses specifically on team events
    // Configuration is handled through loadPersistedEvents() in viewDidLoad
    
    private func loadPersistedEvents() {
        createdEvents = Self.sharedEvents[teamData.id] ?? []
        updateEventsDisplay()
    }
    
    private func updateEventsDisplay() {
        eventsEmptyLabel?.isHidden = !createdEvents.isEmpty
        
        // Update content view height
        let hasEvents = !createdEvents.isEmpty
        let minHeight: CGFloat = hasEvents ? 300 : 150
        contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: minHeight).isActive = true
    }
    
    private func setupNotificationListeners() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSubscriptionChange),
            name: .teamSubscriptionChanged,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEventCreated),
            name: .eventCreated,
            object: nil
        )
    }
    
    // MARK: - Actions
    
    @objc private func createEventTapped() {
        delegate?.eventsDidRequestCreateEvent()
    }
    
    @objc private func handleSubscriptionChange(_ notification: Notification) {
        guard let teamId = notification.userInfo?["teamId"] as? String,
              teamId == teamData.id else { return }
        
        // Subscription changes handled by parent view controller
    }
    
    @objc private func handleEventCreated(_ notification: Notification) {
        guard let eventData = notification.userInfo?["eventData"] as? EventCreationData,
              let teamId = notification.userInfo?["teamId"] as? String,
              teamId == teamData.id else { return }
        
        createdEvents.append(eventData)
        Self.sharedEvents[teamData.id] = createdEvents
        updateEventsDisplay()
    }
    
    // MARK: - Public Methods
    
    func updateCaptainStatus(_ isCaptain: Bool) {
        self.isCaptain = isCaptain
        if isCaptain && eventsCreateButton == nil {
            // Captain controls are set up during initial view setup
            setupViews()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// TeamDetailHeaderViewController delegate conformances are in TeamDetailHeaderViewController.swift

// MARK: - Notification Names

extension Notification.Name {
    static let eventCreated = Notification.Name("eventCreated")
}