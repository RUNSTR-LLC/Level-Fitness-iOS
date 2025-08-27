import UIKit

protocol ChallengeTypeSelectionDelegate: AnyObject {
    func challengeTypeDidChange(_ type: ChallengeType)
    func challengeDurationDidChange(startDate: Date, endDate: Date)
    func challengeMessageDidChange(_ message: String)
}

class ChallengeTypeSelector: UIView, UITextViewDelegate {
    
    // MARK: - Properties
    weak var delegate: ChallengeTypeSelectionDelegate?
    
    var selectedType: ChallengeType = .fiveK {
        didSet {
            updateTypeSelection()
            updateDurationForType()
            delegate?.challengeTypeDidChange(selectedType)
        }
    }
    
    private var startDate: Date = Date() {
        didSet {
            delegate?.challengeDurationDidChange(startDate: startDate, endDate: endDate)
        }
    }
    
    private var endDate: Date = Date().addingTimeInterval(24 * 60 * 60) {
        didSet {
            delegate?.challengeDurationDidChange(startDate: startDate, endDate: endDate)
        }
    }
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // Challenge type selection
    private let typeSelectionContainer = UIView()
    private let typeStackView = UIStackView()
    private var typeButtons: [ChallengeTypeButton] = []
    
    // Duration configuration
    private let durationContainer = UIView()
    private let durationTitleLabel = UILabel()
    private let durationSegmentedControl = UISegmentedControl()
    private let customDurationContainer = UIView()
    private let startDatePicker = UIDatePicker()
    private let endDatePicker = UIDatePicker()
    
    // Challenge message
    private let messageContainer = UIView()
    private let messageTitleLabel = UILabel()
    private let messageTextView = UITextView()
    private let messageCountLabel = UILabel()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        configureInitialState()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        backgroundColor = .clear
        
        // Scroll view
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Header
        titleLabel.text = "Choose your challenge:"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        subtitleLabel.text = "Select what type of fitness challenge you want to create"
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = IndustrialDesign.Colors.secondaryText
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Challenge type selection
        setupTypeSelection()
        
        // Duration configuration
        setupDurationConfiguration()
        
        // Challenge message
        setupMessageInput()
        
        // Add to hierarchy
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(typeSelectionContainer)
        contentView.addSubview(durationContainer)
        contentView.addSubview(messageContainer)
    }
    
    private func setupTypeSelection() {
        typeSelectionContainer.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.8)
        typeSelectionContainer.layer.cornerRadius = 12
        typeSelectionContainer.layer.borderWidth = 1
        typeSelectionContainer.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        typeSelectionContainer.translatesAutoresizingMaskIntoConstraints = false
        
        typeStackView.axis = .vertical
        typeStackView.spacing = 8
        typeStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create buttons for each challenge type
        for challengeType in ChallengeType.allCases {
            let button = ChallengeTypeButton(type: challengeType)
            button.addTarget(self, action: #selector(typeButtonTapped(_:)), for: .touchUpInside)
            typeStackView.addArrangedSubview(button)
            typeButtons.append(button)
        }
        
        typeSelectionContainer.addSubview(typeStackView)
    }
    
    private func setupDurationConfiguration() {
        durationContainer.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.8)
        durationContainer.layer.cornerRadius = 12
        durationContainer.layer.borderWidth = 1
        durationContainer.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        durationContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Duration title
        durationTitleLabel.text = "Duration"
        durationTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        durationTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        durationTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Duration options
        durationSegmentedControl.insertSegment(withTitle: "Today", at: 0, animated: false)
        durationSegmentedControl.insertSegment(withTitle: "This Week", at: 1, animated: false)
        durationSegmentedControl.insertSegment(withTitle: "Custom", at: 2, animated: false)
        durationSegmentedControl.selectedSegmentIndex = 0
        durationSegmentedControl.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        durationSegmentedControl.selectedSegmentTintColor = IndustrialDesign.Colors.bitcoin
        durationSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        durationSegmentedControl.setTitleTextAttributes([.foregroundColor: IndustrialDesign.Colors.secondaryText], for: .normal)
        durationSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        durationSegmentedControl.addTarget(self, action: #selector(durationSegmentChanged(_:)), for: .valueChanged)
        
        // Custom duration container
        setupCustomDurationPickers()
        
        durationContainer.addSubview(durationTitleLabel)
        durationContainer.addSubview(durationSegmentedControl)
        durationContainer.addSubview(customDurationContainer)
    }
    
    private func setupCustomDurationPickers() {
        customDurationContainer.translatesAutoresizingMaskIntoConstraints = false
        customDurationContainer.isHidden = true
        
        // Start date picker
        startDatePicker.datePickerMode = .dateAndTime
        startDatePicker.preferredDatePickerStyle = .compact
        startDatePicker.minimumDate = Date()
        startDatePicker.date = startDate
        startDatePicker.translatesAutoresizingMaskIntoConstraints = false
        startDatePicker.addTarget(self, action: #selector(startDateChanged(_:)), for: .valueChanged)
        
        // End date picker
        endDatePicker.datePickerMode = .dateAndTime
        endDatePicker.preferredDatePickerStyle = .compact
        endDatePicker.minimumDate = Date().addingTimeInterval(3600) // At least 1 hour from now
        endDatePicker.date = endDate
        endDatePicker.translatesAutoresizingMaskIntoConstraints = false
        endDatePicker.addTarget(self, action: #selector(endDateChanged(_:)), for: .valueChanged)
        
        let startLabel = createDateLabel(text: "Starts:")
        let endLabel = createDateLabel(text: "Ends:")
        
        customDurationContainer.addSubview(startLabel)
        customDurationContainer.addSubview(startDatePicker)
        customDurationContainer.addSubview(endLabel)
        customDurationContainer.addSubview(endDatePicker)
        
        NSLayoutConstraint.activate([
            startLabel.topAnchor.constraint(equalTo: customDurationContainer.topAnchor, constant: 12),
            startLabel.leadingAnchor.constraint(equalTo: customDurationContainer.leadingAnchor, constant: 16),
            
            startDatePicker.centerYAnchor.constraint(equalTo: startLabel.centerYAnchor),
            startDatePicker.trailingAnchor.constraint(equalTo: customDurationContainer.trailingAnchor, constant: -16),
            
            endLabel.topAnchor.constraint(equalTo: startLabel.bottomAnchor, constant: 16),
            endLabel.leadingAnchor.constraint(equalTo: startLabel.leadingAnchor),
            
            endDatePicker.centerYAnchor.constraint(equalTo: endLabel.centerYAnchor),
            endDatePicker.trailingAnchor.constraint(equalTo: startDatePicker.trailingAnchor),
            
            customDurationContainer.bottomAnchor.constraint(equalTo: endLabel.bottomAnchor, constant: 12)
        ])
    }
    
    private func createDateLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = IndustrialDesign.Colors.secondaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func setupMessageInput() {
        messageContainer.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.8)
        messageContainer.layer.cornerRadius = 12
        messageContainer.layer.borderWidth = 1
        messageContainer.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        messageContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Message title
        messageTitleLabel.text = "Challenge Message (Optional)"
        messageTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        messageTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        messageTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Message text view
        messageTextView.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
        messageTextView.textColor = IndustrialDesign.Colors.primaryText
        messageTextView.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        messageTextView.layer.cornerRadius = 8
        messageTextView.layer.borderWidth = 1
        messageTextView.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        messageTextView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        messageTextView.translatesAutoresizingMaskIntoConstraints = false
        messageTextView.delegate = self
        
        // Placeholder
        messageTextView.text = "Add some trash talk or motivation..."
        messageTextView.textColor = IndustrialDesign.Colors.secondaryText
        
        // Character count
        messageCountLabel.text = "0/200"
        messageCountLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        messageCountLabel.textColor = IndustrialDesign.Colors.secondaryText
        messageCountLabel.textAlignment = .right
        messageCountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        messageContainer.addSubview(messageTitleLabel)
        messageContainer.addSubview(messageTextView)
        messageContainer.addSubview(messageCountLabel)
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
            
            // Header
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            // Type selection container
            typeSelectionContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            typeSelectionContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            typeSelectionContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            typeStackView.topAnchor.constraint(equalTo: typeSelectionContainer.topAnchor, constant: 16),
            typeStackView.leadingAnchor.constraint(equalTo: typeSelectionContainer.leadingAnchor, constant: 16),
            typeStackView.trailingAnchor.constraint(equalTo: typeSelectionContainer.trailingAnchor, constant: -16),
            typeStackView.bottomAnchor.constraint(equalTo: typeSelectionContainer.bottomAnchor, constant: -16),
            
            // Duration container
            durationContainer.topAnchor.constraint(equalTo: typeSelectionContainer.bottomAnchor, constant: 16),
            durationContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            durationContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            durationTitleLabel.topAnchor.constraint(equalTo: durationContainer.topAnchor, constant: 16),
            durationTitleLabel.leadingAnchor.constraint(equalTo: durationContainer.leadingAnchor, constant: 16),
            durationTitleLabel.trailingAnchor.constraint(equalTo: durationContainer.trailingAnchor, constant: -16),
            
            durationSegmentedControl.topAnchor.constraint(equalTo: durationTitleLabel.bottomAnchor, constant: 12),
            durationSegmentedControl.leadingAnchor.constraint(equalTo: durationContainer.leadingAnchor, constant: 16),
            durationSegmentedControl.trailingAnchor.constraint(equalTo: durationContainer.trailingAnchor, constant: -16),
            durationSegmentedControl.heightAnchor.constraint(equalToConstant: 32),
            
            customDurationContainer.topAnchor.constraint(equalTo: durationSegmentedControl.bottomAnchor, constant: 8),
            customDurationContainer.leadingAnchor.constraint(equalTo: durationContainer.leadingAnchor),
            customDurationContainer.trailingAnchor.constraint(equalTo: durationContainer.trailingAnchor),
            customDurationContainer.bottomAnchor.constraint(equalTo: durationContainer.bottomAnchor, constant: -16),
            
            // Message container
            messageContainer.topAnchor.constraint(equalTo: durationContainer.bottomAnchor, constant: 16),
            messageContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            messageContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            messageContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            messageTitleLabel.topAnchor.constraint(equalTo: messageContainer.topAnchor, constant: 16),
            messageTitleLabel.leadingAnchor.constraint(equalTo: messageContainer.leadingAnchor, constant: 16),
            messageTitleLabel.trailingAnchor.constraint(equalTo: messageContainer.trailingAnchor, constant: -16),
            
            messageTextView.topAnchor.constraint(equalTo: messageTitleLabel.bottomAnchor, constant: 12),
            messageTextView.leadingAnchor.constraint(equalTo: messageContainer.leadingAnchor, constant: 16),
            messageTextView.trailingAnchor.constraint(equalTo: messageContainer.trailingAnchor, constant: -16),
            messageTextView.heightAnchor.constraint(equalToConstant: 80),
            
            messageCountLabel.topAnchor.constraint(equalTo: messageTextView.bottomAnchor, constant: 8),
            messageCountLabel.trailingAnchor.constraint(equalTo: messageContainer.trailingAnchor, constant: -16),
            messageCountLabel.bottomAnchor.constraint(equalTo: messageContainer.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Configuration
    
    private func configureInitialState() {
        updateTypeSelection()
        updateDurationForType()
    }
    
    private func updateTypeSelection() {
        for button in typeButtons {
            button.isSelected = (button.challengeType == selectedType)
        }
    }
    
    private func updateDurationForType() {
        let duration = selectedType.defaultDuration
        endDate = startDate.addingTimeInterval(duration)
        
        // Update date pickers
        endDatePicker.date = endDate
        endDatePicker.minimumDate = startDate.addingTimeInterval(3600) // At least 1 hour after start
    }
    
    // MARK: - Actions
    
    @objc private func typeButtonTapped(_ sender: ChallengeTypeButton) {
        selectedType = sender.challengeType
    }
    
    @objc private func durationSegmentChanged(_ sender: UISegmentedControl) {
        let isCustom = sender.selectedSegmentIndex == 2
        customDurationContainer.isHidden = !isCustom
        
        if !isCustom {
            // Set predefined durations
            startDate = Date()
            
            switch sender.selectedSegmentIndex {
            case 0: // Today
                endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate.addingTimeInterval(24 * 60 * 60)
            case 1: // This Week
                endDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: startDate) ?? startDate.addingTimeInterval(7 * 24 * 60 * 60)
            default:
                break
            }
            
            startDatePicker.date = startDate
            endDatePicker.date = endDate
        }
    }
    
    @objc private func startDateChanged(_ sender: UIDatePicker) {
        startDate = sender.date
        
        // Ensure end date is at least 1 hour after start date
        if endDate <= startDate {
            endDate = startDate.addingTimeInterval(3600)
            endDatePicker.date = endDate
        }
        
        endDatePicker.minimumDate = startDate.addingTimeInterval(3600)
    }
    
    @objc private func endDateChanged(_ sender: UIDatePicker) {
        endDate = sender.date
    }
    
    // MARK: - UITextViewDelegate Methods
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == IndustrialDesign.Colors.secondaryText {
            textView.text = ""
            textView.textColor = IndustrialDesign.Colors.primaryText
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Add some trash talk or motivation..."
            textView.textColor = IndustrialDesign.Colors.secondaryText
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        
        // Limit to 200 characters
        if newText.count > 200 {
            return false
        }
        
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let count = textView.text.count
        messageCountLabel.text = "\(count)/200"
        
        let message = textView.textColor == IndustrialDesign.Colors.primaryText ? textView.text : ""
        delegate?.challengeMessageDidChange(message ?? "")
    }
}

// MARK: - Challenge Type Button

class ChallengeTypeButton: UIButton {
    
    let challengeType: ChallengeType
    
    private let iconLabel = UILabel()
    private let challengeTitleLabel = UILabel()
    private let descriptionLabel = UILabel()
    
    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }
    
    init(type: ChallengeType) {
        self.challengeType = type
        super.init(frame: .zero)
        
        setupButton()
        configureForType(type)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupButton() {
        backgroundColor = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0)
        layer.cornerRadius = 12
        layer.borderWidth = 2
        layer.borderColor = UIColor.clear.cgColor
        translatesAutoresizingMaskIntoConstraints = false
        
        // Icon
        iconLabel.font = UIFont.systemFont(ofSize: 24, weight: .regular)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        challengeTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        challengeTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        challengeTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Description
        descriptionLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        descriptionLabel.textColor = IndustrialDesign.Colors.secondaryText
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(iconLabel)
        addSubview(challengeTitleLabel)
        addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 70),
            
            iconLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            challengeTitleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            challengeTitleLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 12),
            challengeTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            descriptionLabel.topAnchor.constraint(equalTo: challengeTitleLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: challengeTitleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: challengeTitleLabel.trailingAnchor),
            descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -12)
        ])
        
        updateAppearance()
    }
    
    private func configureForType(_ type: ChallengeType) {
        challengeTitleLabel.text = type.displayName
        descriptionLabel.text = type.description
        
        // Set icon based on type
        switch type {
        case .fiveK:
            iconLabel.text = "🏃"
        case .tenK:
            iconLabel.text = "🏃‍♂️"
        case .weeklyMiles:
            iconLabel.text = "📊"
        case .dailyStreak:
            iconLabel.text = "🔥"
        case .custom:
            iconLabel.text = "⚙️"
        }
    }
    
    private func updateAppearance() {
        if isSelected {
            layer.borderColor = IndustrialDesign.Colors.bitcoin.cgColor
            backgroundColor = IndustrialDesign.Colors.bitcoin.withAlphaComponent(0.1)
        } else {
            layer.borderColor = UIColor.clear.cgColor
            backgroundColor = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0)
        }
    }
}