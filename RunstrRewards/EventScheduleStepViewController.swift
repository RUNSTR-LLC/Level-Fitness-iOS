import UIKit
import HealthKit

class EventScheduleStepViewController: UIViewController {
    
    // MARK: - Properties
    private let eventData: EventCreationData
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Title section
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // Start date section
    private let startDateLabel = UILabel()
    private let startDateContainer = UIView()
    private let startDatePicker = UIDatePicker()
    
    // End date section
    private let endDateLabel = UILabel()
    private let endDateContainer = UIView()
    private let endDatePicker = UIDatePicker()
    
    // Entry settings section
    private let entryLabel = UILabel()
    private let entryContainer = UIView()
    
    // Entry fee
    private let entryFeeLabel = UILabel()
    private let entryFeeField = UITextField()
    private let entryFeeSwitch = UISwitch()
    private let entryFeeRow = UIView()
    
    // Prize pool
    private let prizePoolLabel = UILabel()
    private let prizePoolField = UITextField()
    private let prizePoolRow = UIView()
    
    // Max participants
    private let maxParticipantsLabel = UILabel()
    private let maxParticipantsField = UITextField()
    private let maxParticipantsSwitch = UISwitch()
    private let maxParticipantsRow = UIView()
    
    // Public/Private toggle
    private let visibilityLabel = UILabel()
    private let visibilitySwitch = UISwitch()
    private let visibilityRow = UIView()
    private let visibilityDescLabel = UILabel()
    
    // MARK: - Initialization
    
    init(eventData: EventCreationData) {
        self.eventData = eventData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🗓️ EventSchedule: Loading schedule step")
        
        setupScrollView()
        setupContent()
        setupConstraints()
        loadExistingData()
        
        print("🗓️ EventSchedule: Schedule step loaded")
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
        setupDatePickers()
        setupEntrySettings()
    }
    
    private func setupTitleSection() {
        titleLabel.text = "Event Schedule"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        subtitleLabel.text = "Set when your event runs and configure entry requirements"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textColor = IndustrialDesign.Colors.secondaryText
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
    }
    
    private func setupDatePickers() {
        // Start date section
        startDateLabel.text = "Start Date & Time"
        startDateLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        startDateLabel.textColor = IndustrialDesign.Colors.primaryText
        startDateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        startDateContainer.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        startDateContainer.layer.cornerRadius = 8
        startDateContainer.layer.borderWidth = 1
        startDateContainer.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        startDateContainer.translatesAutoresizingMaskIntoConstraints = false
        
        startDatePicker.datePickerMode = .dateAndTime
        startDatePicker.preferredDatePickerStyle = .compact
        startDatePicker.minimumDate = Date()
        startDatePicker.translatesAutoresizingMaskIntoConstraints = false
        startDatePicker.addTarget(self, action: #selector(startDateChanged), for: .valueChanged)
        
        // End date section
        endDateLabel.text = "End Date & Time"
        endDateLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        endDateLabel.textColor = IndustrialDesign.Colors.primaryText
        endDateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        endDateContainer.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        endDateContainer.layer.cornerRadius = 8
        endDateContainer.layer.borderWidth = 1
        endDateContainer.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        endDateContainer.translatesAutoresizingMaskIntoConstraints = false
        
        endDatePicker.datePickerMode = .dateAndTime
        endDatePicker.preferredDatePickerStyle = .compact
        endDatePicker.translatesAutoresizingMaskIntoConstraints = false
        endDatePicker.addTarget(self, action: #selector(endDateChanged), for: .valueChanged)
        
        startDateContainer.addSubview(startDatePicker)
        endDateContainer.addSubview(endDatePicker)
        
        contentView.addSubview(startDateLabel)
        contentView.addSubview(startDateContainer)
        contentView.addSubview(endDateLabel)
        contentView.addSubview(endDateContainer)
    }
    
    private func setupEntrySettings() {
        entryLabel.text = "Entry Settings"
        entryLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        entryLabel.textColor = IndustrialDesign.Colors.primaryText
        entryLabel.translatesAutoresizingMaskIntoConstraints = false
        
        entryContainer.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        entryContainer.layer.cornerRadius = 8
        entryContainer.layer.borderWidth = 1
        entryContainer.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        entryContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Entry fee row
        setupEntryFeeRow()
        
        // Prize pool row
        setupPrizePoolRow()
        
        // Max participants row
        setupMaxParticipantsRow()
        
        // Visibility row
        setupVisibilityRow()
        
        contentView.addSubview(entryLabel)
        contentView.addSubview(entryContainer)
    }
    
    private func setupEntryFeeRow() {
        entryFeeRow.translatesAutoresizingMaskIntoConstraints = false
        
        entryFeeLabel.text = "Entry Fee (sats)"
        entryFeeLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        entryFeeLabel.textColor = IndustrialDesign.Colors.primaryText
        entryFeeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        entryFeeSwitch.translatesAutoresizingMaskIntoConstraints = false
        entryFeeSwitch.addTarget(self, action: #selector(entryFeeSwitchChanged), for: .valueChanged)
        
        entryFeeField.font = UIFont.systemFont(ofSize: 14)
        entryFeeField.textColor = IndustrialDesign.Colors.primaryText
        entryFeeField.backgroundColor = .clear
        entryFeeField.placeholder = "0"
        entryFeeField.keyboardType = .numberPad
        entryFeeField.textAlignment = .right
        entryFeeField.translatesAutoresizingMaskIntoConstraints = false
        entryFeeField.addTarget(self, action: #selector(entryFeeChanged), for: .editingChanged)
        entryFeeField.isHidden = true
        
        entryFeeRow.addSubview(entryFeeLabel)
        entryFeeRow.addSubview(entryFeeSwitch)
        entryFeeRow.addSubview(entryFeeField)
        entryContainer.addSubview(entryFeeRow)
    }
    
    private func setupPrizePoolRow() {
        prizePoolRow.translatesAutoresizingMaskIntoConstraints = false
        
        prizePoolLabel.text = "Prize Pool (sats)"
        prizePoolLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        prizePoolLabel.textColor = IndustrialDesign.Colors.primaryText
        prizePoolLabel.translatesAutoresizingMaskIntoConstraints = false
        
        prizePoolField.font = UIFont.systemFont(ofSize: 14)
        prizePoolField.textColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0) // Bitcoin orange
        prizePoolField.backgroundColor = .clear
        prizePoolField.placeholder = "1000"
        prizePoolField.keyboardType = .numberPad
        prizePoolField.textAlignment = .right
        prizePoolField.translatesAutoresizingMaskIntoConstraints = false
        prizePoolField.addTarget(self, action: #selector(prizePoolChanged), for: .editingChanged)
        
        prizePoolRow.addSubview(prizePoolLabel)
        prizePoolRow.addSubview(prizePoolField)
        entryContainer.addSubview(prizePoolRow)
    }
    
    private func setupMaxParticipantsRow() {
        maxParticipantsRow.translatesAutoresizingMaskIntoConstraints = false
        
        maxParticipantsLabel.text = "Max Participants"
        maxParticipantsLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        maxParticipantsLabel.textColor = IndustrialDesign.Colors.primaryText
        maxParticipantsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        maxParticipantsSwitch.translatesAutoresizingMaskIntoConstraints = false
        maxParticipantsSwitch.addTarget(self, action: #selector(maxParticipantsSwitchChanged), for: .valueChanged)
        
        maxParticipantsField.font = UIFont.systemFont(ofSize: 14)
        maxParticipantsField.textColor = IndustrialDesign.Colors.primaryText
        maxParticipantsField.backgroundColor = .clear
        maxParticipantsField.placeholder = "50"
        maxParticipantsField.keyboardType = .numberPad
        maxParticipantsField.textAlignment = .right
        maxParticipantsField.translatesAutoresizingMaskIntoConstraints = false
        maxParticipantsField.addTarget(self, action: #selector(maxParticipantsChanged), for: .editingChanged)
        maxParticipantsField.isHidden = true
        
        maxParticipantsRow.addSubview(maxParticipantsLabel)
        maxParticipantsRow.addSubview(maxParticipantsSwitch)
        maxParticipantsRow.addSubview(maxParticipantsField)
        entryContainer.addSubview(maxParticipantsRow)
    }
    
    private func setupVisibilityRow() {
        visibilityRow.translatesAutoresizingMaskIntoConstraints = false
        
        visibilityLabel.text = "Public Event"
        visibilityLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        visibilityLabel.textColor = IndustrialDesign.Colors.primaryText
        visibilityLabel.translatesAutoresizingMaskIntoConstraints = false
        
        visibilitySwitch.isOn = true
        visibilitySwitch.translatesAutoresizingMaskIntoConstraints = false
        visibilitySwitch.addTarget(self, action: #selector(visibilitySwitchChanged), for: .valueChanged)
        
        visibilityDescLabel.text = "Anyone can discover and join this event"
        visibilityDescLabel.font = UIFont.systemFont(ofSize: 12)
        visibilityDescLabel.textColor = IndustrialDesign.Colors.secondaryText
        visibilityDescLabel.numberOfLines = 0
        visibilityDescLabel.translatesAutoresizingMaskIntoConstraints = false
        
        visibilityRow.addSubview(visibilityLabel)
        visibilityRow.addSubview(visibilitySwitch)
        entryContainer.addSubview(visibilityRow)
        entryContainer.addSubview(visibilityDescLabel)
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
            
            // Start date
            startDateLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            startDateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            startDateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            startDateContainer.topAnchor.constraint(equalTo: startDateLabel.bottomAnchor, constant: 8),
            startDateContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            startDateContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            startDateContainer.heightAnchor.constraint(equalToConstant: 48),
            
            startDatePicker.centerXAnchor.constraint(equalTo: startDateContainer.centerXAnchor),
            startDatePicker.centerYAnchor.constraint(equalTo: startDateContainer.centerYAnchor),
            
            // End date
            endDateLabel.topAnchor.constraint(equalTo: startDateContainer.bottomAnchor, constant: 16),
            endDateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            endDateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            endDateContainer.topAnchor.constraint(equalTo: endDateLabel.bottomAnchor, constant: 8),
            endDateContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            endDateContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            endDateContainer.heightAnchor.constraint(equalToConstant: 48),
            
            endDatePicker.centerXAnchor.constraint(equalTo: endDateContainer.centerXAnchor),
            endDatePicker.centerYAnchor.constraint(equalTo: endDateContainer.centerYAnchor),
            
            // Entry settings
            entryLabel.topAnchor.constraint(equalTo: endDateContainer.bottomAnchor, constant: 24),
            entryLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            entryLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            entryContainer.topAnchor.constraint(equalTo: entryLabel.bottomAnchor, constant: 8),
            entryContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            entryContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            entryContainer.heightAnchor.constraint(equalToConstant: 200),
            entryContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // Entry fee row
            entryFeeRow.topAnchor.constraint(equalTo: entryContainer.topAnchor, constant: 12),
            entryFeeRow.leadingAnchor.constraint(equalTo: entryContainer.leadingAnchor, constant: 16),
            entryFeeRow.trailingAnchor.constraint(equalTo: entryContainer.trailingAnchor, constant: -16),
            entryFeeRow.heightAnchor.constraint(equalToConstant: 32),
            
            entryFeeLabel.leadingAnchor.constraint(equalTo: entryFeeRow.leadingAnchor),
            entryFeeLabel.centerYAnchor.constraint(equalTo: entryFeeRow.centerYAnchor),
            
            entryFeeSwitch.trailingAnchor.constraint(equalTo: entryFeeRow.trailingAnchor),
            entryFeeSwitch.centerYAnchor.constraint(equalTo: entryFeeRow.centerYAnchor),
            
            entryFeeField.trailingAnchor.constraint(equalTo: entryFeeRow.trailingAnchor),
            entryFeeField.centerYAnchor.constraint(equalTo: entryFeeRow.centerYAnchor),
            entryFeeField.widthAnchor.constraint(equalToConstant: 80),
            
            // Prize pool row
            prizePoolRow.topAnchor.constraint(equalTo: entryFeeRow.bottomAnchor, constant: 12),
            prizePoolRow.leadingAnchor.constraint(equalTo: entryContainer.leadingAnchor, constant: 16),
            prizePoolRow.trailingAnchor.constraint(equalTo: entryContainer.trailingAnchor, constant: -16),
            prizePoolRow.heightAnchor.constraint(equalToConstant: 32),
            
            prizePoolLabel.leadingAnchor.constraint(equalTo: prizePoolRow.leadingAnchor),
            prizePoolLabel.centerYAnchor.constraint(equalTo: prizePoolRow.centerYAnchor),
            
            prizePoolField.trailingAnchor.constraint(equalTo: prizePoolRow.trailingAnchor),
            prizePoolField.centerYAnchor.constraint(equalTo: prizePoolRow.centerYAnchor),
            prizePoolField.widthAnchor.constraint(equalToConstant: 80),
            
            // Max participants row
            maxParticipantsRow.topAnchor.constraint(equalTo: prizePoolRow.bottomAnchor, constant: 12),
            maxParticipantsRow.leadingAnchor.constraint(equalTo: entryContainer.leadingAnchor, constant: 16),
            maxParticipantsRow.trailingAnchor.constraint(equalTo: entryContainer.trailingAnchor, constant: -16),
            maxParticipantsRow.heightAnchor.constraint(equalToConstant: 32),
            
            maxParticipantsLabel.leadingAnchor.constraint(equalTo: maxParticipantsRow.leadingAnchor),
            maxParticipantsLabel.centerYAnchor.constraint(equalTo: maxParticipantsRow.centerYAnchor),
            
            maxParticipantsSwitch.trailingAnchor.constraint(equalTo: maxParticipantsRow.trailingAnchor),
            maxParticipantsSwitch.centerYAnchor.constraint(equalTo: maxParticipantsRow.centerYAnchor),
            
            maxParticipantsField.trailingAnchor.constraint(equalTo: maxParticipantsRow.trailingAnchor),
            maxParticipantsField.centerYAnchor.constraint(equalTo: maxParticipantsRow.centerYAnchor),
            maxParticipantsField.widthAnchor.constraint(equalToConstant: 80),
            
            // Visibility row
            visibilityRow.topAnchor.constraint(equalTo: maxParticipantsRow.bottomAnchor, constant: 12),
            visibilityRow.leadingAnchor.constraint(equalTo: entryContainer.leadingAnchor, constant: 16),
            visibilityRow.trailingAnchor.constraint(equalTo: entryContainer.trailingAnchor, constant: -16),
            visibilityRow.heightAnchor.constraint(equalToConstant: 32),
            
            visibilityLabel.leadingAnchor.constraint(equalTo: visibilityRow.leadingAnchor),
            visibilityLabel.centerYAnchor.constraint(equalTo: visibilityRow.centerYAnchor),
            
            visibilitySwitch.trailingAnchor.constraint(equalTo: visibilityRow.trailingAnchor),
            visibilitySwitch.centerYAnchor.constraint(equalTo: visibilityRow.centerYAnchor),
            
            visibilityDescLabel.topAnchor.constraint(equalTo: visibilityRow.bottomAnchor, constant: 4),
            visibilityDescLabel.leadingAnchor.constraint(equalTo: entryContainer.leadingAnchor, constant: 16),
            visibilityDescLabel.trailingAnchor.constraint(equalTo: entryContainer.trailingAnchor, constant: -16)
        ])
    }
    
    private func loadExistingData() {
        if let startDate = eventData.startDate {
            startDatePicker.date = startDate
        } else {
            // Default to tomorrow at 9 AM
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            let defaultStart = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? Date()
            startDatePicker.date = defaultStart
            eventData.startDate = defaultStart
        }
        
        if let endDate = eventData.endDate {
            endDatePicker.date = endDate
        } else {
            // Default to 7 days after start date
            let defaultEnd = Calendar.current.date(byAdding: .day, value: 7, to: startDatePicker.date) ?? Date()
            endDatePicker.date = defaultEnd
            eventData.endDate = defaultEnd
        }
        
        // Update minimum date for end picker
        endDatePicker.minimumDate = startDatePicker.date
        
        // Load other settings
        if eventData.entryFee > 0 {
            entryFeeSwitch.isOn = true
            entryFeeField.isHidden = false
            entryFeeField.text = String(Int(eventData.entryFee))
        }
        
        prizePoolField.text = String(Int(eventData.prizePool))
        
        if let maxParticipants = eventData.maxParticipants {
            maxParticipantsSwitch.isOn = true
            maxParticipantsField.isHidden = false
            maxParticipantsField.text = String(maxParticipants)
        }
        
        visibilitySwitch.isOn = eventData.isPublic
        updateVisibilityDescription()
    }
    
    // MARK: - Actions
    
    @objc private func startDateChanged() {
        eventData.startDate = startDatePicker.date
        
        // Update end date minimum
        endDatePicker.minimumDate = startDatePicker.date
        
        // If end date is before start date, update it
        if endDatePicker.date < startDatePicker.date {
            let newEndDate = Calendar.current.date(byAdding: .day, value: 1, to: startDatePicker.date) ?? startDatePicker.date
            endDatePicker.date = newEndDate
            eventData.endDate = newEndDate
        }
        
        print("🗓️ EventSchedule: Start date changed to: \(startDatePicker.date)")
    }
    
    @objc private func endDateChanged() {
        eventData.endDate = endDatePicker.date
        print("🗓️ EventSchedule: End date changed to: \(endDatePicker.date)")
    }
    
    @objc private func entryFeeSwitchChanged() {
        let hasEntryFee = entryFeeSwitch.isOn
        entryFeeField.isHidden = !hasEntryFee
        
        if hasEntryFee {
            if entryFeeField.text?.isEmpty == true {
                entryFeeField.text = "100"
                eventData.entryFee = 100
            }
        } else {
            eventData.entryFee = 0
        }
        
        print("🗓️ EventSchedule: Entry fee enabled: \(hasEntryFee)")
    }
    
    @objc private func entryFeeChanged() {
        if let text = entryFeeField.text, let fee = Double(text) {
            eventData.entryFee = fee
        } else {
            eventData.entryFee = 0
        }
        print("🗓️ EventSchedule: Entry fee changed to: \(eventData.entryFee)")
    }
    
    @objc private func prizePoolChanged() {
        if let text = prizePoolField.text, let prize = Double(text) {
            eventData.prizePool = prize
        } else {
            eventData.prizePool = 0
        }
        print("🗓️ EventSchedule: Prize pool changed to: \(eventData.prizePool)")
    }
    
    @objc private func maxParticipantsSwitchChanged() {
        let hasLimit = maxParticipantsSwitch.isOn
        maxParticipantsField.isHidden = !hasLimit
        
        if hasLimit {
            if maxParticipantsField.text?.isEmpty == true {
                maxParticipantsField.text = "50"
                eventData.maxParticipants = 50
            }
        } else {
            eventData.maxParticipants = nil
        }
        
        print("🗓️ EventSchedule: Max participants limit enabled: \(hasLimit)")
    }
    
    @objc private func maxParticipantsChanged() {
        if let text = maxParticipantsField.text, let max = Int(text) {
            eventData.maxParticipants = max
        } else {
            eventData.maxParticipants = nil
        }
        print("🗓️ EventSchedule: Max participants changed to: \(eventData.maxParticipants ?? 0)")
    }
    
    @objc private func visibilitySwitchChanged() {
        eventData.isPublic = visibilitySwitch.isOn
        updateVisibilityDescription()
        print("🗓️ EventSchedule: Event visibility changed to: \(eventData.isPublic ? "public" : "private")")
    }
    
    private func updateVisibilityDescription() {
        if visibilitySwitch.isOn {
            visibilityDescLabel.text = "Anyone can discover and join this event"
        } else {
            visibilityDescLabel.text = "Only team members can see and join this event"
        }
    }
}