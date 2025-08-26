import UIKit

class EventBasicDetailsViewController: UIViewController {
    
    // MARK: - Properties
    private let eventData: EventCreationData
    private let teamData: TeamData
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Title section
    private let stepTitleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // Event name
    private let eventNameLabel = UILabel()
    private let eventNameTextField = UITextField()
    private let eventNameContainer = UIView()
    
    // Start date selection
    private let startDateLabel = UILabel()
    private let startDateContainer = UIView()
    private let startDatePicker = UIDatePicker()
    
    // Duration selection
    private let durationLabel = UILabel()
    private let durationContainer = UIView()
    private let durationValueLabel = UILabel()
    private let durationStepper = UIStepper()
    private let durationUnitSegmentedControl = UISegmentedControl(items: ["Days", "Weeks", "Months"])
    
    // Entry fee
    private let entryFeeLabel = UILabel()
    private let entryFeeTextField = UITextField()
    private let entryFeeContainer = UIView()
    private let entryFeeInfoLabel = UILabel()
    
    // Duration settings
    private var durationValue: Int = 1 // Default to 1
    private var durationUnit: DurationUnit = .weeks // Default to weeks
    
    enum DurationUnit: Int, CaseIterable {
        case days = 0
        case weeks = 1
        case months = 2
        
        var displayName: String {
            switch self {
            case .days: return "Days"
            case .weeks: return "Weeks"
            case .months: return "Months"
            }
        }
        
        var maxValue: Int {
            switch self {
            case .days: return 365
            case .weeks: return 52
            case .months: return 12
            }
        }
    }
    
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
        print("📝 EventBasicDetails: Loading basic details step")
        
        setupScrollView()
        setupContent()
        setupConstraints()
        setupKeyboardManagement()
        loadExistingData()
        
        print("📝 EventBasicDetails: Basic details step loaded")
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
        setupEventNameField()
        setupStartDateSelection()
        setupDurationSelection()
        setupEntryFeeField()
    }
    
    private func setupTitleSection() {
        stepTitleLabel.text = "Event Details"
        stepTitleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        stepTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        stepTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        subtitleLabel.text = "Complete your \(eventData.eventName) event setup"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textColor = IndustrialDesign.Colors.secondaryText
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stepTitleLabel)
        contentView.addSubview(subtitleLabel)
    }
    
    private func setupEventNameField() {
        eventNameLabel.text = "Event Name"
        eventNameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        eventNameLabel.textColor = IndustrialDesign.Colors.primaryText
        eventNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        eventNameContainer.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        eventNameContainer.layer.cornerRadius = 8
        eventNameContainer.layer.borderWidth = 1
        eventNameContainer.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        eventNameContainer.translatesAutoresizingMaskIntoConstraints = false
        
        eventNameTextField.font = UIFont.systemFont(ofSize: 16)
        eventNameTextField.textColor = IndustrialDesign.Colors.primaryText
        eventNameTextField.tintColor = IndustrialDesign.Colors.bitcoin
        eventNameTextField.backgroundColor = .clear
        eventNameTextField.placeholder = "Enter event name..."
        eventNameTextField.translatesAutoresizingMaskIntoConstraints = false
        eventNameTextField.addTarget(self, action: #selector(eventNameChanged), for: .editingChanged)
        
        // Set placeholder color
        eventNameTextField.attributedPlaceholder = NSAttributedString(
            string: "Enter event name...",
            attributes: [NSAttributedString.Key.foregroundColor: IndustrialDesign.Colors.secondaryText]
        )
        
        eventNameContainer.addSubview(eventNameTextField)
        contentView.addSubview(eventNameLabel)
        contentView.addSubview(eventNameContainer)
    }
    
    private func setupStartDateSelection() {
        startDateLabel.text = "Start Date"
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
        startDatePicker.minimumDate = Date() // Can't schedule in the past
        startDatePicker.date = Date() // Default to now
        startDatePicker.tintColor = IndustrialDesign.Colors.bitcoin
        startDatePicker.translatesAutoresizingMaskIntoConstraints = false
        startDatePicker.addTarget(self, action: #selector(startDateChanged), for: .valueChanged)
        
        startDateContainer.addSubview(startDatePicker)
        contentView.addSubview(startDateLabel)
        contentView.addSubview(startDateContainer)
    }
    
    private func setupDurationSelection() {
        durationLabel.text = "Event Duration"
        durationLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        durationLabel.textColor = IndustrialDesign.Colors.primaryText
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        durationContainer.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        durationContainer.layer.cornerRadius = 8
        durationContainer.layer.borderWidth = 1
        durationContainer.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        durationContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Duration value label
        durationValueLabel.text = "1"
        durationValueLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        durationValueLabel.textColor = IndustrialDesign.Colors.primaryText
        durationValueLabel.textAlignment = .center
        durationValueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Duration stepper
        durationStepper.minimumValue = 1
        durationStepper.maximumValue = 52 // Default max for weeks
        durationStepper.value = 1
        durationStepper.stepValue = 1
        durationStepper.tintColor = IndustrialDesign.Colors.bitcoin
        durationStepper.translatesAutoresizingMaskIntoConstraints = false
        durationStepper.addTarget(self, action: #selector(durationValueChanged), for: .valueChanged)
        
        // Duration unit selector
        durationUnitSegmentedControl.selectedSegmentIndex = 1 // Default to weeks
        durationUnitSegmentedControl.tintColor = IndustrialDesign.Colors.bitcoin
        durationUnitSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        durationUnitSegmentedControl.addTarget(self, action: #selector(durationUnitChanged), for: .valueChanged)
        
        durationContainer.addSubview(durationValueLabel)
        durationContainer.addSubview(durationStepper)
        durationContainer.addSubview(durationUnitSegmentedControl)
        contentView.addSubview(durationLabel)
        contentView.addSubview(durationContainer)
    }
    
    private func setupEntryFeeField() {
        entryFeeLabel.text = "Entry Fee (Optional)"
        entryFeeLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        entryFeeLabel.textColor = IndustrialDesign.Colors.primaryText
        entryFeeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        entryFeeContainer.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        entryFeeContainer.layer.cornerRadius = 8
        entryFeeContainer.layer.borderWidth = 1
        entryFeeContainer.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        entryFeeContainer.translatesAutoresizingMaskIntoConstraints = false
        
        entryFeeTextField.placeholder = "$0.00"
        entryFeeTextField.font = UIFont.systemFont(ofSize: 16)
        entryFeeTextField.textColor = IndustrialDesign.Colors.primaryText
        entryFeeTextField.keyboardType = .decimalPad
        entryFeeTextField.addTarget(self, action: #selector(entryFeeChanged), for: .editingChanged)
        entryFeeTextField.translatesAutoresizingMaskIntoConstraints = false
        
        entryFeeTextField.attributedPlaceholder = NSAttributedString(
            string: "$0.00",
            attributes: [NSAttributedString.Key.foregroundColor: IndustrialDesign.Colors.secondaryText]
        )
        
        entryFeeInfoLabel.text = "Entry fees go directly to the prize pool"
        entryFeeInfoLabel.font = UIFont.systemFont(ofSize: 12)
        entryFeeInfoLabel.textColor = IndustrialDesign.Colors.secondaryText
        entryFeeInfoLabel.numberOfLines = 0
        entryFeeInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        entryFeeContainer.addSubview(entryFeeTextField)
        contentView.addSubview(entryFeeLabel)
        contentView.addSubview(entryFeeContainer)
        contentView.addSubview(entryFeeInfoLabel)
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
            stepTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            stepTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stepTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: stepTitleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            // Event name
            eventNameLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            eventNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            eventNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            eventNameContainer.topAnchor.constraint(equalTo: eventNameLabel.bottomAnchor, constant: 8),
            eventNameContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            eventNameContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            eventNameContainer.heightAnchor.constraint(equalToConstant: 48),
            
            eventNameTextField.leadingAnchor.constraint(equalTo: eventNameContainer.leadingAnchor, constant: 16),
            eventNameTextField.trailingAnchor.constraint(equalTo: eventNameContainer.trailingAnchor, constant: -16),
            eventNameTextField.centerYAnchor.constraint(equalTo: eventNameContainer.centerYAnchor),
            
            // Start date
            startDateLabel.topAnchor.constraint(equalTo: eventNameContainer.bottomAnchor, constant: 24),
            startDateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            startDateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            startDateContainer.topAnchor.constraint(equalTo: startDateLabel.bottomAnchor, constant: 8),
            startDateContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            startDateContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            startDateContainer.heightAnchor.constraint(equalToConstant: 48),
            
            startDatePicker.leadingAnchor.constraint(equalTo: startDateContainer.leadingAnchor, constant: 16),
            startDatePicker.trailingAnchor.constraint(equalTo: startDateContainer.trailingAnchor, constant: -16),
            startDatePicker.centerYAnchor.constraint(equalTo: startDateContainer.centerYAnchor),
            
            // Duration
            durationLabel.topAnchor.constraint(equalTo: startDateContainer.bottomAnchor, constant: 24),
            durationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            durationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            durationContainer.topAnchor.constraint(equalTo: durationLabel.bottomAnchor, constant: 12),
            durationContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            durationContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            durationContainer.heightAnchor.constraint(equalToConstant: 100),
            
            // Entry fee
            entryFeeLabel.topAnchor.constraint(equalTo: durationContainer.bottomAnchor, constant: 24),
            entryFeeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            entryFeeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            entryFeeContainer.topAnchor.constraint(equalTo: entryFeeLabel.bottomAnchor, constant: 8),
            entryFeeContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            entryFeeContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            entryFeeContainer.heightAnchor.constraint(equalToConstant: 48),
            
            entryFeeTextField.leadingAnchor.constraint(equalTo: entryFeeContainer.leadingAnchor, constant: 16),
            entryFeeTextField.trailingAnchor.constraint(equalTo: entryFeeContainer.trailingAnchor, constant: -16),
            entryFeeTextField.centerYAnchor.constraint(equalTo: entryFeeContainer.centerYAnchor),
            
            entryFeeInfoLabel.topAnchor.constraint(equalTo: entryFeeContainer.bottomAnchor, constant: 4),
            entryFeeInfoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            entryFeeInfoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            entryFeeInfoLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        // Layout duration controls
        layoutDurationControls()
    }
    
    private func layoutDurationControls() {
        NSLayoutConstraint.activate([
            // Duration value label and stepper on top row
            durationValueLabel.topAnchor.constraint(equalTo: durationContainer.topAnchor, constant: 16),
            durationValueLabel.leadingAnchor.constraint(equalTo: durationContainer.leadingAnchor, constant: 16),
            durationValueLabel.widthAnchor.constraint(equalToConstant: 60),
            
            durationStepper.centerYAnchor.constraint(equalTo: durationValueLabel.centerYAnchor),
            durationStepper.leadingAnchor.constraint(equalTo: durationValueLabel.trailingAnchor, constant: 16),
            durationStepper.trailingAnchor.constraint(lessThanOrEqualTo: durationContainer.trailingAnchor, constant: -16),
            
            // Unit selector on bottom row
            durationUnitSegmentedControl.topAnchor.constraint(equalTo: durationValueLabel.bottomAnchor, constant: 16),
            durationUnitSegmentedControl.leadingAnchor.constraint(equalTo: durationContainer.leadingAnchor, constant: 16),
            durationUnitSegmentedControl.trailingAnchor.constraint(equalTo: durationContainer.trailingAnchor, constant: -16),
            durationUnitSegmentedControl.bottomAnchor.constraint(equalTo: durationContainer.bottomAnchor, constant: -16)
        ])
    }
    
    private func loadExistingData() {
        // Event name might be pre-populated from preset
        eventNameTextField.text = eventData.eventName.isEmpty ? "" : eventData.eventName
        
        // Load entry fee if set
        if eventData.entryFee > 0 {
            entryFeeTextField.text = String(format: "%.2f", eventData.entryFee)
        }
        
        // Set default dates
        let startDate = Date()
        eventData.startDate = startDate
        startDatePicker.date = startDate
        
        // Update end date based on default duration (1 week)
        updateEndDate()
        
        // Update subtitle with preset info
        updateSubtitle()
    }
    
    private func updateSubtitle() {
        let presetName = eventData.eventName.isEmpty ? "your event" : eventData.eventName
        subtitleLabel.text = "Complete your \(presetName) event setup"
    }
    
    // MARK: - Actions
    
    @objc private func eventNameChanged() {
        eventData.eventName = eventNameTextField.text ?? ""
        updateSubtitle()
        print("📝 EventBasicDetails: Event name changed to: \(eventData.eventName)")
    }
    
    @objc private func entryFeeChanged() {
        let text = entryFeeTextField.text ?? ""
        let cleanedText = text.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")
        eventData.entryFee = Double(cleanedText) ?? 0.0
        print("📝 EventBasicDetails: Entry fee changed to: $\(eventData.entryFee)")
        
        // Format the text field with dollar sign
        if !text.isEmpty && !text.hasPrefix("$") {
            entryFeeTextField.text = "$\(text)"
        }
    }
    
    @objc private func startDateChanged() {
        eventData.startDate = startDatePicker.date
        updateEndDate()
        print("📝 EventBasicDetails: Start date changed to: \(startDatePicker.date)")
    }
    
    @objc private func durationValueChanged() {
        durationValue = Int(durationStepper.value)
        durationValueLabel.text = "\(durationValue)"
        updateEndDate()
        print("📝 EventBasicDetails: Duration value changed to: \(durationValue) \(durationUnit.displayName.lowercased())")
    }
    
    @objc private func durationUnitChanged() {
        durationUnit = DurationUnit(rawValue: durationUnitSegmentedControl.selectedSegmentIndex) ?? .weeks
        
        // Update stepper maximum based on unit
        durationStepper.maximumValue = Double(durationUnit.maxValue)
        
        // If current value exceeds new max, adjust it
        if durationValue > durationUnit.maxValue {
            durationValue = durationUnit.maxValue
            durationStepper.value = Double(durationValue)
            durationValueLabel.text = "\(durationValue)"
        }
        
        updateEndDate()
        print("📝 EventBasicDetails: Duration unit changed to: \(durationUnit.displayName)")
    }
    
    private func updateEndDate() {
        guard let startDate = eventData.startDate else { return }
        
        let calendar = Calendar.current
        var endDate: Date?
        
        switch durationUnit {
        case .days:
            endDate = calendar.date(byAdding: .day, value: durationValue, to: startDate)
        case .weeks:
            endDate = calendar.date(byAdding: .weekOfYear, value: durationValue, to: startDate)
        case .months:
            endDate = calendar.date(byAdding: .month, value: durationValue, to: startDate)
        }
        
        eventData.endDate = endDate ?? startDate
        print("📝 EventBasicDetails: End date updated to: \(eventData.endDate ?? startDate)")
    }
    
    // MARK: - Validation
    
    func isValid() -> Bool {
        return !eventData.eventName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Keyboard Management
    
    private func setupKeyboardManagement() {
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        // Add keyboard toolbar to text inputs
        setupKeyboardToolbar()
    }
    
    private func setupKeyboardToolbar() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
        
        toolbar.setItems([flexSpace, doneButton], animated: false)
        
        // Set toolbar to text inputs
        eventNameTextField.inputAccessoryView = toolbar
        entryFeeTextField.inputAccessoryView = toolbar
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

