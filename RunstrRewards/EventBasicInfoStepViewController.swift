import UIKit

class EventBasicInfoStepViewController: UIViewController {
    
    // MARK: - Properties
    private let eventData: EventCreationData
    private let teamData: TeamData
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Title section
    private let stepTitleLabel = UILabel()
    private let substepTitleLabel = UILabel()
    
    // Event name
    private let eventNameLabel = UILabel()
    private let eventNameTextField = UITextField()
    private let eventNameContainer = UIView()
    
    // Event type
    private let eventTypeLabel = UILabel()
    private let eventTypeContainer = UIView()
    private var eventTypeButtons: [EventTypeButton] = []
    
    // Description
    private let descriptionLabel = UILabel()
    private let descriptionTextView = UITextView()
    private let descriptionContainer = UIView()
    
    // Entry fee
    private let entryFeeLabel = UILabel()
    private let entryFeeTextField = UITextField()
    private let entryFeeContainer = UIView()
    private let entryFeeInfoLabel = UILabel()
    
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
        print("📅 EventBasicInfo: Loading basic info step")
        
        setupScrollView()
        setupContent()
        setupConstraints()
        setupKeyboardManagement()
        loadExistingData()
        
        print("📅 EventBasicInfo: Basic info step loaded")
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
        setupEventTypeSelection()
        setupEntryFeeField()
        setupDescriptionField()
    }
    
    private func setupTitleSection() {
        stepTitleLabel.text = "Event Details"
        stepTitleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        stepTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        stepTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        substepTitleLabel.text = "Create an event for \(teamData.name)"
        substepTitleLabel.font = UIFont.systemFont(ofSize: 16)
        substepTitleLabel.textColor = IndustrialDesign.Colors.secondaryText
        substepTitleLabel.numberOfLines = 0
        substepTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stepTitleLabel)
        contentView.addSubview(substepTitleLabel)
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
    
    private func setupEventTypeSelection() {
        eventTypeLabel.text = "Event Type"
        eventTypeLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        eventTypeLabel.textColor = IndustrialDesign.Colors.primaryText
        eventTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        eventTypeContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Create event type buttons
        for (_, eventType) in EventType.allCases.enumerated() {
            let button = EventTypeButton(eventType: eventType)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(eventTypeSelected(_:)), for: .touchUpInside)
            eventTypeButtons.append(button)
            eventTypeContainer.addSubview(button)
        }
        
        // Select default type
        if let firstButton = eventTypeButtons.first {
            selectEventType(firstButton)
        }
        
        contentView.addSubview(eventTypeLabel)
        contentView.addSubview(eventTypeContainer)
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
        
        entryFeeInfoLabel.text = "Entry fees go directly to the team's prize pool"
        entryFeeInfoLabel.font = UIFont.systemFont(ofSize: 12)
        entryFeeInfoLabel.textColor = IndustrialDesign.Colors.secondaryText
        entryFeeInfoLabel.numberOfLines = 0
        entryFeeInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        entryFeeContainer.addSubview(entryFeeTextField)
        contentView.addSubview(entryFeeLabel)
        contentView.addSubview(entryFeeContainer)
        contentView.addSubview(entryFeeInfoLabel)
    }
    
    private func setupDescriptionField() {
        descriptionLabel.text = "Description (Optional)"
        descriptionLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        descriptionLabel.textColor = IndustrialDesign.Colors.primaryText
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        descriptionContainer.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        descriptionContainer.layer.cornerRadius = 8
        descriptionContainer.layer.borderWidth = 1
        descriptionContainer.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        descriptionContainer.translatesAutoresizingMaskIntoConstraints = false
        
        descriptionTextView.font = UIFont.systemFont(ofSize: 16)
        descriptionTextView.textColor = IndustrialDesign.Colors.primaryText
        descriptionTextView.tintColor = IndustrialDesign.Colors.bitcoin
        descriptionTextView.backgroundColor = .clear
        descriptionTextView.layer.cornerRadius = 8
        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        descriptionTextView.delegate = self
        
        descriptionContainer.addSubview(descriptionTextView)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(descriptionContainer)
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
            
            substepTitleLabel.topAnchor.constraint(equalTo: stepTitleLabel.bottomAnchor, constant: 8),
            substepTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            substepTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            // Event name
            eventNameLabel.topAnchor.constraint(equalTo: substepTitleLabel.bottomAnchor, constant: 24),
            eventNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            eventNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            eventNameContainer.topAnchor.constraint(equalTo: eventNameLabel.bottomAnchor, constant: 8),
            eventNameContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            eventNameContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            eventNameContainer.heightAnchor.constraint(equalToConstant: 48),
            
            eventNameTextField.leadingAnchor.constraint(equalTo: eventNameContainer.leadingAnchor, constant: 16),
            eventNameTextField.trailingAnchor.constraint(equalTo: eventNameContainer.trailingAnchor, constant: -16),
            eventNameTextField.centerYAnchor.constraint(equalTo: eventNameContainer.centerYAnchor),
            
            // Event type
            eventTypeLabel.topAnchor.constraint(equalTo: eventNameContainer.bottomAnchor, constant: 24),
            eventTypeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            eventTypeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            eventTypeContainer.topAnchor.constraint(equalTo: eventTypeLabel.bottomAnchor, constant: 12),
            eventTypeContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            eventTypeContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            eventTypeContainer.heightAnchor.constraint(equalToConstant: 120),
            
            // Entry fee
            entryFeeLabel.topAnchor.constraint(equalTo: eventTypeContainer.bottomAnchor, constant: 24),
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
            
            // Description
            descriptionLabel.topAnchor.constraint(equalTo: entryFeeInfoLabel.bottomAnchor, constant: 24),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            descriptionContainer.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 8),
            descriptionContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            descriptionContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            descriptionContainer.heightAnchor.constraint(equalToConstant: 80),
            descriptionContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            descriptionTextView.leadingAnchor.constraint(equalTo: descriptionContainer.leadingAnchor, constant: 12),
            descriptionTextView.trailingAnchor.constraint(equalTo: descriptionContainer.trailingAnchor, constant: -12),
            descriptionTextView.topAnchor.constraint(equalTo: descriptionContainer.topAnchor, constant: 8),
            descriptionTextView.bottomAnchor.constraint(equalTo: descriptionContainer.bottomAnchor, constant: -8)
        ])
        
        // Layout event type buttons in 2x2 grid
        layoutEventTypeButtons()
    }
    
    private func layoutEventTypeButtons() {
        guard eventTypeButtons.count == 4 else { return }
        
        let buttonHeight: CGFloat = 50
        let spacing: CGFloat = 8
        
        for (index, button) in eventTypeButtons.enumerated() {
            let row = index / 2
            let col = index % 2
            
            if col == 0 {
                // Left column
                NSLayoutConstraint.activate([
                    button.leadingAnchor.constraint(equalTo: eventTypeContainer.leadingAnchor),
                    button.trailingAnchor.constraint(equalTo: eventTypeContainer.centerXAnchor, constant: -spacing/2),
                    button.heightAnchor.constraint(equalToConstant: buttonHeight),
                    button.topAnchor.constraint(equalTo: eventTypeContainer.topAnchor, constant: CGFloat(row) * (buttonHeight + spacing))
                ])
            } else {
                // Right column
                NSLayoutConstraint.activate([
                    button.leadingAnchor.constraint(equalTo: eventTypeContainer.centerXAnchor, constant: spacing/2),
                    button.trailingAnchor.constraint(equalTo: eventTypeContainer.trailingAnchor),
                    button.heightAnchor.constraint(equalToConstant: buttonHeight),
                    button.topAnchor.constraint(equalTo: eventTypeContainer.topAnchor, constant: CGFloat(row) * (buttonHeight + spacing))
                ])
            }
        }
    }
    
    private func loadExistingData() {
        eventNameTextField.text = eventData.eventName
        descriptionTextView.text = eventData.description
        
        // Load entry fee if set
        if eventData.entryFee > 0 {
            entryFeeTextField.text = String(format: "%.2f", eventData.entryFee)
        }
        
        // Select the current event type button
        for button in eventTypeButtons {
            if button.eventType == eventData.eventType {
                selectEventType(button)
                break
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func eventNameChanged() {
        eventData.eventName = eventNameTextField.text ?? ""
        print("📅 EventBasicInfo: Event name changed to: \(eventData.eventName)")
    }
    
    @objc private func entryFeeChanged() {
        let text = entryFeeTextField.text ?? ""
        let cleanedText = text.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")
        eventData.entryFee = Double(cleanedText) ?? 0.0
        print("📅 EventBasicInfo: Entry fee changed to: $\(eventData.entryFee)")
        
        // Format the text field with dollar sign
        if !text.isEmpty && !text.hasPrefix("$") {
            entryFeeTextField.text = "$\(text)"
        }
    }
    
    @objc private func eventTypeSelected(_ button: EventTypeButton) {
        selectEventType(button)
        eventData.eventType = button.eventType
        print("📅 EventBasicInfo: Event type selected: \(button.eventType.displayName)")
    }
    
    private func selectEventType(_ selectedButton: EventTypeButton) {
        // Deselect all buttons
        for button in eventTypeButtons {
            button.isSelected = false
        }
        
        // Select the chosen button
        selectedButton.isSelected = true
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
        descriptionTextView.inputAccessoryView = toolbar
        entryFeeTextField.inputAccessoryView = toolbar
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - UITextViewDelegate

extension EventBasicInfoStepViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        eventData.description = textView.text
        print("📅 EventBasicInfo: Description changed")
    }
}

// MARK: - EventTypeButton

class EventTypeButton: UIButton {
    
    let eventType: EventType
    private let stepTitleLabel = UILabel()
    private let descriptionLabel = UILabel()
    
    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }
    
    init(eventType: EventType) {
        self.eventType = eventType
        super.init(frame: .zero)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupButton() {
        backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        stepTitleLabel.text = eventType.displayName
        stepTitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        stepTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        stepTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        descriptionLabel.text = eventType.description
        descriptionLabel.font = UIFont.systemFont(ofSize: 11)
        descriptionLabel.textColor = IndustrialDesign.Colors.secondaryText
        descriptionLabel.numberOfLines = 2
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stepTitleLabel)
        addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            stepTitleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stepTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stepTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            
            descriptionLabel.topAnchor.constraint(equalTo: stepTitleLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -8)
        ])
        
        updateAppearance()
    }
    
    private func updateAppearance() {
        if isSelected {
            backgroundColor = IndustrialDesign.Colors.bitcoin.withAlphaComponent(0.2)
            layer.borderColor = IndustrialDesign.Colors.bitcoin.cgColor
        } else {
            backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
            layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        }
    }
}