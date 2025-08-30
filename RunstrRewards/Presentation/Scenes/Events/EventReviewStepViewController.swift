import UIKit
import HealthKit

class EventReviewStepViewController: UIViewController {
    
    // MARK: - Properties
    private let eventData: EventCreationData
    private let teamData: TeamData
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Title section
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // Event preview card
    private let previewCard = UIView()
    private let eventNameLabel = UILabel()
    private let eventTypeLabel = UILabel()
    private let eventDescLabel = UILabel()
    
    // Details sections
    private let detailsContainer = UIView()
    
    // Schedule section
    private let scheduleSection = UIView()
    private let scheduleTitleLabel = UILabel()
    private let startDateLabel = UILabel()
    private let endDateLabel = UILabel()
    private let durationLabel = UILabel()
    
    // Metrics section
    private let metricsSection = UIView()
    private let metricsTitleLabel = UILabel()
    private let metricsListLabel = UILabel()
    private let targetLabel = UILabel()
    
    // Entry section
    private let entrySection = UIView()
    private let entryTitleLabel = UILabel()
    private let entryFeeLabel = UILabel()
    private let prizePoolLabel = UILabel()
    private let maxParticipantsLabel = UILabel()
    private let visibilityLabel = UILabel()
    
    // Terms section
    private let termsSection = UIView()
    private let termsTitleLabel = UILabel()
    private let termsTextLabel = UILabel()
    private let agreeSwitch = UISwitch()
    private let agreeLabel = UILabel()
    
    // MARK: - Initialization
    
    init(eventData: EventCreationData, teamData: TeamData) {
        self.eventData = eventData
        self.teamData = teamData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("✅ EventReview: Loading review step")
        
        setupScrollView()
        setupContent()
        setupConstraints()
        populateEventData()
        
        print("✅ EventReview: Review step loaded")
    }
    
    // MARK: - Setup Methods
    
    private func setupScrollView() {
        view.backgroundColor = .clear
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupContent() {
        setupTitleSection()
        setupPreviewCard()
        setupDetailsContainer()
        setupScheduleSection()
        setupMetricsSection()
        setupEntrySection()
        setupTermsSection()
    }
    
    private func setupTitleSection() {
        titleLabel.text = "Review Event"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        subtitleLabel.text = "Review your event details before creating"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textColor = IndustrialDesign.Colors.secondaryText
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
    }
    
    private func setupPreviewCard() {
        previewCard.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.9)
        previewCard.layer.cornerRadius = 12
        previewCard.layer.borderWidth = 1
        previewCard.layer.borderColor = IndustrialDesign.Colors.bitcoin.cgColor
        previewCard.translatesAutoresizingMaskIntoConstraints = false
        
        // Add gradient background
        DispatchQueue.main.async {
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = [
                IndustrialDesign.Colors.bitcoin.withAlphaComponent(0.1).cgColor,
                UIColor.clear.cgColor
            ]
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 1, y: 1)
            gradientLayer.frame = self.previewCard.bounds
            gradientLayer.cornerRadius = 12
            self.previewCard.layer.insertSublayer(gradientLayer, at: 0)
        }
        
        eventNameLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        eventNameLabel.textColor = IndustrialDesign.Colors.primaryText
        eventNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        eventTypeLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        eventTypeLabel.textColor = IndustrialDesign.Colors.bitcoin
        eventTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        eventDescLabel.font = UIFont.systemFont(ofSize: 14)
        eventDescLabel.textColor = IndustrialDesign.Colors.secondaryText
        eventDescLabel.numberOfLines = 3
        eventDescLabel.translatesAutoresizingMaskIntoConstraints = false
        
        previewCard.addSubview(eventNameLabel)
        previewCard.addSubview(eventTypeLabel)
        previewCard.addSubview(eventDescLabel)
        contentView.addSubview(previewCard)
    }
    
    private func setupDetailsContainer() {
        detailsContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(detailsContainer)
    }
    
    private func setupScheduleSection() {
        scheduleSection.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        scheduleSection.layer.cornerRadius = 8
        scheduleSection.layer.borderWidth = 1
        scheduleSection.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        scheduleSection.translatesAutoresizingMaskIntoConstraints = false
        
        scheduleTitleLabel.text = "⏰ Schedule"
        scheduleTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        scheduleTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        scheduleTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        startDateLabel.font = UIFont.systemFont(ofSize: 14)
        startDateLabel.textColor = IndustrialDesign.Colors.primaryText
        startDateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        endDateLabel.font = UIFont.systemFont(ofSize: 14)
        endDateLabel.textColor = IndustrialDesign.Colors.primaryText
        endDateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        durationLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        durationLabel.textColor = IndustrialDesign.Colors.bitcoin
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        scheduleSection.addSubview(scheduleTitleLabel)
        scheduleSection.addSubview(startDateLabel)
        scheduleSection.addSubview(endDateLabel)
        scheduleSection.addSubview(durationLabel)
        detailsContainer.addSubview(scheduleSection)
    }
    
    private func setupMetricsSection() {
        metricsSection.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        metricsSection.layer.cornerRadius = 8
        metricsSection.layer.borderWidth = 1
        metricsSection.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        metricsSection.translatesAutoresizingMaskIntoConstraints = false
        
        metricsTitleLabel.text = "📊 Competition Metrics"
        metricsTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        metricsTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        metricsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        metricsListLabel.font = UIFont.systemFont(ofSize: 14)
        metricsListLabel.textColor = IndustrialDesign.Colors.primaryText
        metricsListLabel.numberOfLines = 0
        metricsListLabel.translatesAutoresizingMaskIntoConstraints = false
        
        targetLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        targetLabel.textColor = IndustrialDesign.Colors.bitcoin
        targetLabel.translatesAutoresizingMaskIntoConstraints = false
        
        metricsSection.addSubview(metricsTitleLabel)
        metricsSection.addSubview(metricsListLabel)
        metricsSection.addSubview(targetLabel)
        detailsContainer.addSubview(metricsSection)
    }
    
    private func setupEntrySection() {
        entrySection.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        entrySection.layer.cornerRadius = 8
        entrySection.layer.borderWidth = 1
        entrySection.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        entrySection.translatesAutoresizingMaskIntoConstraints = false
        
        entryTitleLabel.text = "🎟️ Entry & Rewards"
        entryTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        entryTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        entryTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        entryFeeLabel.font = UIFont.systemFont(ofSize: 14)
        entryFeeLabel.textColor = IndustrialDesign.Colors.primaryText
        entryFeeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        prizePoolLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        prizePoolLabel.textColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0) // Bitcoin orange
        prizePoolLabel.translatesAutoresizingMaskIntoConstraints = false
        
        maxParticipantsLabel.font = UIFont.systemFont(ofSize: 14)
        maxParticipantsLabel.textColor = IndustrialDesign.Colors.primaryText
        maxParticipantsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        visibilityLabel.font = UIFont.systemFont(ofSize: 14)
        visibilityLabel.textColor = IndustrialDesign.Colors.primaryText
        visibilityLabel.translatesAutoresizingMaskIntoConstraints = false
        
        entrySection.addSubview(entryTitleLabel)
        entrySection.addSubview(entryFeeLabel)
        entrySection.addSubview(prizePoolLabel)
        entrySection.addSubview(maxParticipantsLabel)
        entrySection.addSubview(visibilityLabel)
        detailsContainer.addSubview(entrySection)
    }
    
    private func setupTermsSection() {
        termsSection.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        termsSection.layer.cornerRadius = 8
        termsSection.layer.borderWidth = 1
        termsSection.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        termsSection.translatesAutoresizingMaskIntoConstraints = false
        
        termsTitleLabel.text = "📝 Event Terms"
        termsTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        termsTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        termsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        termsTextLabel.text = "• Participants must sync HealthKit data during event period\n• Fair play rules apply - suspicious activity will be investigated\n• Prize distribution occurs within 24 hours after event ends\n• Event creator reserves right to modify rules if needed"
        termsTextLabel.font = UIFont.systemFont(ofSize: 12)
        termsTextLabel.textColor = IndustrialDesign.Colors.secondaryText
        termsTextLabel.numberOfLines = 0
        termsTextLabel.translatesAutoresizingMaskIntoConstraints = false
        
        agreeLabel.text = "I agree to the event terms and conditions"
        agreeLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        agreeLabel.textColor = IndustrialDesign.Colors.primaryText
        agreeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        agreeSwitch.translatesAutoresizingMaskIntoConstraints = false
        agreeSwitch.addTarget(self, action: #selector(agreeSwitchChanged), for: .valueChanged)
        
        termsSection.addSubview(termsTitleLabel)
        termsSection.addSubview(termsTextLabel)
        termsSection.addSubview(agreeLabel)
        termsSection.addSubview(agreeSwitch)
        detailsContainer.addSubview(termsSection)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title section
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            // Preview card
            previewCard.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            previewCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            previewCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            previewCard.heightAnchor.constraint(equalToConstant: 100),
            
            eventNameLabel.topAnchor.constraint(equalTo: previewCard.topAnchor, constant: 16),
            eventNameLabel.leadingAnchor.constraint(equalTo: previewCard.leadingAnchor, constant: 16),
            eventNameLabel.trailingAnchor.constraint(equalTo: previewCard.trailingAnchor, constant: -16),
            
            eventTypeLabel.topAnchor.constraint(equalTo: eventNameLabel.bottomAnchor, constant: 4),
            eventTypeLabel.leadingAnchor.constraint(equalTo: previewCard.leadingAnchor, constant: 16),
            
            eventDescLabel.topAnchor.constraint(equalTo: eventTypeLabel.bottomAnchor, constant: 8),
            eventDescLabel.leadingAnchor.constraint(equalTo: previewCard.leadingAnchor, constant: 16),
            eventDescLabel.trailingAnchor.constraint(equalTo: previewCard.trailingAnchor, constant: -16),
            eventDescLabel.bottomAnchor.constraint(lessThanOrEqualTo: previewCard.bottomAnchor, constant: -16),
            
            // Details container
            detailsContainer.topAnchor.constraint(equalTo: previewCard.bottomAnchor, constant: 20),
            detailsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            detailsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            detailsContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // Schedule section
            scheduleSection.topAnchor.constraint(equalTo: detailsContainer.topAnchor),
            scheduleSection.leadingAnchor.constraint(equalTo: detailsContainer.leadingAnchor),
            scheduleSection.trailingAnchor.constraint(equalTo: detailsContainer.trailingAnchor),
            scheduleSection.heightAnchor.constraint(equalToConstant: 100),
            
            scheduleTitleLabel.topAnchor.constraint(equalTo: scheduleSection.topAnchor, constant: 12),
            scheduleTitleLabel.leadingAnchor.constraint(equalTo: scheduleSection.leadingAnchor, constant: 16),
            
            startDateLabel.topAnchor.constraint(equalTo: scheduleTitleLabel.bottomAnchor, constant: 8),
            startDateLabel.leadingAnchor.constraint(equalTo: scheduleSection.leadingAnchor, constant: 16),
            
            endDateLabel.topAnchor.constraint(equalTo: startDateLabel.bottomAnchor, constant: 4),
            endDateLabel.leadingAnchor.constraint(equalTo: scheduleSection.leadingAnchor, constant: 16),
            
            durationLabel.topAnchor.constraint(equalTo: endDateLabel.bottomAnchor, constant: 4),
            durationLabel.leadingAnchor.constraint(equalTo: scheduleSection.leadingAnchor, constant: 16),
            
            // Metrics section
            metricsSection.topAnchor.constraint(equalTo: scheduleSection.bottomAnchor, constant: 12),
            metricsSection.leadingAnchor.constraint(equalTo: detailsContainer.leadingAnchor),
            metricsSection.trailingAnchor.constraint(equalTo: detailsContainer.trailingAnchor),
            metricsSection.heightAnchor.constraint(equalToConstant: 80),
            
            metricsTitleLabel.topAnchor.constraint(equalTo: metricsSection.topAnchor, constant: 12),
            metricsTitleLabel.leadingAnchor.constraint(equalTo: metricsSection.leadingAnchor, constant: 16),
            
            metricsListLabel.topAnchor.constraint(equalTo: metricsTitleLabel.bottomAnchor, constant: 8),
            metricsListLabel.leadingAnchor.constraint(equalTo: metricsSection.leadingAnchor, constant: 16),
            metricsListLabel.trailingAnchor.constraint(equalTo: metricsSection.trailingAnchor, constant: -16),
            
            targetLabel.topAnchor.constraint(equalTo: metricsListLabel.bottomAnchor, constant: 4),
            targetLabel.leadingAnchor.constraint(equalTo: metricsSection.leadingAnchor, constant: 16),
            
            // Entry section
            entrySection.topAnchor.constraint(equalTo: metricsSection.bottomAnchor, constant: 12),
            entrySection.leadingAnchor.constraint(equalTo: detailsContainer.leadingAnchor),
            entrySection.trailingAnchor.constraint(equalTo: detailsContainer.trailingAnchor),
            entrySection.heightAnchor.constraint(equalToConstant: 120),
            
            entryTitleLabel.topAnchor.constraint(equalTo: entrySection.topAnchor, constant: 12),
            entryTitleLabel.leadingAnchor.constraint(equalTo: entrySection.leadingAnchor, constant: 16),
            
            entryFeeLabel.topAnchor.constraint(equalTo: entryTitleLabel.bottomAnchor, constant: 8),
            entryFeeLabel.leadingAnchor.constraint(equalTo: entrySection.leadingAnchor, constant: 16),
            
            prizePoolLabel.topAnchor.constraint(equalTo: entryFeeLabel.bottomAnchor, constant: 4),
            prizePoolLabel.leadingAnchor.constraint(equalTo: entrySection.leadingAnchor, constant: 16),
            
            maxParticipantsLabel.topAnchor.constraint(equalTo: prizePoolLabel.bottomAnchor, constant: 4),
            maxParticipantsLabel.leadingAnchor.constraint(equalTo: entrySection.leadingAnchor, constant: 16),
            
            visibilityLabel.topAnchor.constraint(equalTo: maxParticipantsLabel.bottomAnchor, constant: 4),
            visibilityLabel.leadingAnchor.constraint(equalTo: entrySection.leadingAnchor, constant: 16),
            
            // Terms section
            termsSection.topAnchor.constraint(equalTo: entrySection.bottomAnchor, constant: 12),
            termsSection.leadingAnchor.constraint(equalTo: detailsContainer.leadingAnchor),
            termsSection.trailingAnchor.constraint(equalTo: detailsContainer.trailingAnchor),
            termsSection.heightAnchor.constraint(equalToConstant: 180),
            termsSection.bottomAnchor.constraint(equalTo: detailsContainer.bottomAnchor, constant: -50),
            
            termsTitleLabel.topAnchor.constraint(equalTo: termsSection.topAnchor, constant: 12),
            termsTitleLabel.leadingAnchor.constraint(equalTo: termsSection.leadingAnchor, constant: 16),
            
            termsTextLabel.topAnchor.constraint(equalTo: termsTitleLabel.bottomAnchor, constant: 8),
            termsTextLabel.leadingAnchor.constraint(equalTo: termsSection.leadingAnchor, constant: 16),
            termsTextLabel.trailingAnchor.constraint(equalTo: termsSection.trailingAnchor, constant: -16),
            
            agreeLabel.topAnchor.constraint(equalTo: termsTextLabel.bottomAnchor, constant: 12),
            agreeLabel.leadingAnchor.constraint(equalTo: termsSection.leadingAnchor, constant: 16),
            
            agreeSwitch.centerYAnchor.constraint(equalTo: agreeLabel.centerYAnchor),
            agreeSwitch.leadingAnchor.constraint(greaterThanOrEqualTo: agreeLabel.trailingAnchor, constant: 8),
            agreeSwitch.trailingAnchor.constraint(equalTo: termsSection.trailingAnchor, constant: -16)
        ])
    }
    
    private func populateEventData() {
        // Event preview
        eventNameLabel.text = eventData.eventName.isEmpty ? "Untitled Event" : eventData.eventName
        eventTypeLabel.text = eventData.eventType.displayName.uppercased()
        eventDescLabel.text = eventData.description.isEmpty ? "No description provided" : eventData.description
        
        // Schedule
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        if let startDate = eventData.startDate {
            startDateLabel.text = "Starts: \(dateFormatter.string(from: startDate))"
        }
        
        if let endDate = eventData.endDate {
            endDateLabel.text = "Ends: \(dateFormatter.string(from: endDate))"
        }
        
        if let startDate = eventData.startDate, let endDate = eventData.endDate {
            let duration = endDate.timeIntervalSince(startDate)
            let days = Int(duration) / (24 * 3600)
            if days > 0 {
                durationLabel.text = "Duration: \(days) day\(days == 1 ? "" : "s")"
            } else {
                let hours = Int(duration) / 3600
                durationLabel.text = "Duration: \(hours) hour\(hours == 1 ? "" : "s")"
            }
        }
        
        // Metrics
        if eventData.selectedMetrics.isEmpty {
            metricsListLabel.text = "No metrics selected"
        } else {
            let metricNames = eventData.selectedMetrics.compactMap { metricId in
                return getMetricDisplayName(for: metricId)
            }
            metricsListLabel.text = metricNames.joined(separator: ", ")
        }
        
        if let targetValue = eventData.targetValue, targetValue > 0 {
            targetLabel.text = "Target: \(Int(targetValue)) \(eventData.targetUnit)"
        } else {
            targetLabel.text = "No target goal set"
        }
        
        // Entry & Rewards
        if eventData.entryFee > 0 {
            entryFeeLabel.text = "Entry Fee: \(Int(eventData.entryFee)) sats"
        } else {
            entryFeeLabel.text = "Entry Fee: Free"
        }
        
        if eventData.prizePool > 0 {
            prizePoolLabel.text = "Prize Pool: ₿ \(Int(eventData.prizePool)) sats"
        } else {
            prizePoolLabel.text = "Prize Pool: No prize set"
        }
        
        if let maxParticipants = eventData.maxParticipants {
            maxParticipantsLabel.text = "Max Participants: \(maxParticipants)"
        } else {
            maxParticipantsLabel.text = "Max Participants: Unlimited"
        }
        
        visibilityLabel.text = eventData.isPublic ? "Visibility: Public event" : "Visibility: Team members only"
    }
    
    private func getMetricDisplayName(for identifier: String) -> String? {
        let metrics = [
            ("distance", "Distance"),
            ("steps", "Steps"),
            ("calories", "Calories"),
            ("duration", "Duration"),
            ("heartRate", "Heart Rate"),
            ("elevation", "Elevation")
        ]
        
        return metrics.first { $0.0 == identifier }?.1
    }
    
    // MARK: - Public Methods
    
    func isValid() -> Bool {
        return agreeSwitch.isOn && !eventData.eventName.isEmpty && !eventData.selectedMetrics.isEmpty
    }
    
    // MARK: - Actions
    
    @objc private func agreeSwitchChanged() {
        print("✅ EventReview: Terms agreement changed to: \(agreeSwitch.isOn)")
        
        // Notify parent that validation status changed
        NotificationCenter.default.post(
            name: .eventReviewValidationChanged,
            object: nil,
            userInfo: ["isValid": isValid()]
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let eventReviewValidationChanged = Notification.Name("eventReviewValidationChanged")
}