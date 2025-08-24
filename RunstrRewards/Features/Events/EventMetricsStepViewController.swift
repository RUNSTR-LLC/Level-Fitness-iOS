import UIKit
import HealthKit

class EventMetricsStepViewController: UIViewController {
    
    // MARK: - Properties
    private let eventData: EventCreationData
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Title section
    private let stepTitleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // Metrics selection
    private let metricsLabel = UILabel()
    private let metricsContainer = UIView()
    private var metricButtons: [MetricButton] = []
    
    // Target settings (for applicable event types)
    private let targetSection = UIView()
    private let targetLabel = UILabel()
    private let targetContainer = UIView()
    private let targetValueField = UITextField()
    private let targetUnitLabel = UILabel()
    
    // Available metrics
    private let availableMetrics = [
        ("distance", "Distance", "figure.walk", "km"),
        ("steps", "Steps", "figure.step.training", "steps"),
        ("calories", "Calories", "flame.fill", "cal"),
        ("duration", "Duration", "clock.fill", "min"),
        ("heartRate", "Heart Rate", "heart.fill", "bpm"),
        ("elevation", "Elevation", "mountain.2.fill", "m")
    ]
    
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
        print("📊 EventMetrics: Loading metrics step")
        
        setupScrollView()
        setupContent()
        setupConstraints()
        loadExistingData()
        
        print("📊 EventMetrics: Metrics step loaded")
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
        setupMetricsSelection()
        setupTargetSection()
    }
    
    private func setupTitleSection() {
        stepTitleLabel.text = "Competition Metrics"
        stepTitleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        stepTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        stepTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        subtitleLabel.text = "Select which fitness metrics participants will compete in"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textColor = IndustrialDesign.Colors.secondaryText
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stepTitleLabel)
        contentView.addSubview(subtitleLabel)
    }
    
    private func setupMetricsSelection() {
        metricsLabel.text = "Available Metrics"
        metricsLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        metricsLabel.textColor = IndustrialDesign.Colors.primaryText
        metricsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        metricsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Create metric buttons
        for metric in availableMetrics {
            let button = MetricButton(
                identifier: metric.0,
                title: metric.1,
                iconName: metric.2,
                unit: metric.3
            )
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(metricButtonTapped(_:)), for: .touchUpInside)
            metricButtons.append(button)
            metricsContainer.addSubview(button)
        }
        
        contentView.addSubview(metricsLabel)
        contentView.addSubview(metricsContainer)
    }
    
    private func setupTargetSection() {
        targetSection.translatesAutoresizingMaskIntoConstraints = false
        targetSection.isHidden = true // Initially hidden
        
        targetLabel.text = "Target Goal (Optional)"
        targetLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        targetLabel.textColor = IndustrialDesign.Colors.primaryText
        targetLabel.translatesAutoresizingMaskIntoConstraints = false
        
        targetContainer.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        targetContainer.layer.cornerRadius = 8
        targetContainer.layer.borderWidth = 1
        targetContainer.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        targetContainer.translatesAutoresizingMaskIntoConstraints = false
        
        targetValueField.font = UIFont.systemFont(ofSize: 16)
        targetValueField.textColor = IndustrialDesign.Colors.primaryText
        targetValueField.tintColor = IndustrialDesign.Colors.bitcoin
        targetValueField.backgroundColor = .clear
        targetValueField.placeholder = "Enter target..."
        targetValueField.keyboardType = .decimalPad
        targetValueField.translatesAutoresizingMaskIntoConstraints = false
        targetValueField.addTarget(self, action: #selector(targetValueChanged), for: .editingChanged)
        
        targetUnitLabel.text = "units"
        targetUnitLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        targetUnitLabel.textColor = IndustrialDesign.Colors.secondaryText
        targetUnitLabel.translatesAutoresizingMaskIntoConstraints = false
        
        targetContainer.addSubview(targetValueField)
        targetContainer.addSubview(targetUnitLabel)
        
        targetSection.addSubview(targetLabel)
        targetSection.addSubview(targetContainer)
        
        contentView.addSubview(targetSection)
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
            
            // Metrics selection
            metricsLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            metricsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            metricsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            metricsContainer.topAnchor.constraint(equalTo: metricsLabel.bottomAnchor, constant: 12),
            metricsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            metricsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            metricsContainer.heightAnchor.constraint(equalToConstant: 200),
            
            // Target section
            targetSection.topAnchor.constraint(equalTo: metricsContainer.bottomAnchor, constant: 24),
            targetSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            targetSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            targetSection.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            targetLabel.topAnchor.constraint(equalTo: targetSection.topAnchor),
            targetLabel.leadingAnchor.constraint(equalTo: targetSection.leadingAnchor),
            targetLabel.trailingAnchor.constraint(equalTo: targetSection.trailingAnchor),
            
            targetContainer.topAnchor.constraint(equalTo: targetLabel.bottomAnchor, constant: 8),
            targetContainer.leadingAnchor.constraint(equalTo: targetSection.leadingAnchor),
            targetContainer.trailingAnchor.constraint(equalTo: targetSection.trailingAnchor),
            targetContainer.heightAnchor.constraint(equalToConstant: 48),
            targetContainer.bottomAnchor.constraint(equalTo: targetSection.bottomAnchor),
            
            targetValueField.leadingAnchor.constraint(equalTo: targetContainer.leadingAnchor, constant: 16),
            targetValueField.centerYAnchor.constraint(equalTo: targetContainer.centerYAnchor),
            targetValueField.trailingAnchor.constraint(equalTo: targetUnitLabel.leadingAnchor, constant: -12),
            
            targetUnitLabel.trailingAnchor.constraint(equalTo: targetContainer.trailingAnchor, constant: -16),
            targetUnitLabel.centerYAnchor.constraint(equalTo: targetContainer.centerYAnchor),
            targetUnitLabel.widthAnchor.constraint(equalToConstant: 60)
        ])
        
        // Layout metric buttons in 3x2 grid
        layoutMetricButtons()
    }
    
    private func layoutMetricButtons() {
        guard metricButtons.count == 6 else { return }
        
        let buttonHeight: CGFloat = 60
        let spacing: CGFloat = 8
        
        for (index, button) in metricButtons.enumerated() {
            let row = index / 3
            let col = index % 3
            
            if col == 0 {
                // Left column
                NSLayoutConstraint.activate([
                    button.leadingAnchor.constraint(equalTo: metricsContainer.leadingAnchor),
                    button.widthAnchor.constraint(equalTo: metricsContainer.widthAnchor, multiplier: 0.31),
                    button.heightAnchor.constraint(equalToConstant: buttonHeight),
                    button.topAnchor.constraint(equalTo: metricsContainer.topAnchor, constant: CGFloat(row) * (buttonHeight + spacing))
                ])
            } else if col == 1 {
                // Middle column
                NSLayoutConstraint.activate([
                    button.centerXAnchor.constraint(equalTo: metricsContainer.centerXAnchor),
                    button.widthAnchor.constraint(equalTo: metricsContainer.widthAnchor, multiplier: 0.31),
                    button.heightAnchor.constraint(equalToConstant: buttonHeight),
                    button.topAnchor.constraint(equalTo: metricsContainer.topAnchor, constant: CGFloat(row) * (buttonHeight + spacing))
                ])
            } else {
                // Right column
                NSLayoutConstraint.activate([
                    button.trailingAnchor.constraint(equalTo: metricsContainer.trailingAnchor),
                    button.widthAnchor.constraint(equalTo: metricsContainer.widthAnchor, multiplier: 0.31),
                    button.heightAnchor.constraint(equalToConstant: buttonHeight),
                    button.topAnchor.constraint(equalTo: metricsContainer.topAnchor, constant: CGFloat(row) * (buttonHeight + spacing))
                ])
            }
        }
    }
    
    private func loadExistingData() {
        // Select previously chosen metrics
        for button in metricButtons {
            if eventData.selectedMetrics.contains(button.identifier) {
                button.isSelected = true
            }
        }
        
        // Load target value
        if let targetValue = eventData.targetValue {
            targetValueField.text = String(targetValue)
        }
        
        updateTargetSectionVisibility()
    }
    
    // MARK: - Actions
    
    @objc private func metricButtonTapped(_ button: MetricButton) {
        button.isSelected.toggle()
        
        if button.isSelected {
            if !eventData.selectedMetrics.contains(button.identifier) {
                eventData.selectedMetrics.append(button.identifier)
            }
        } else {
            eventData.selectedMetrics.removeAll { $0 == button.identifier }
        }
        
        updateTargetSectionVisibility()
        print("📊 EventMetrics: Selected metrics: \(eventData.selectedMetrics)")
    }
    
    @objc private func targetValueChanged() {
        if let text = targetValueField.text, let value = Double(text) {
            eventData.targetValue = value
        } else {
            eventData.targetValue = nil
        }
        print("📊 EventMetrics: Target value changed to: \(eventData.targetValue ?? 0)")
    }
    
    private func updateTargetSectionVisibility() {
        let hasSelectedMetrics = !eventData.selectedMetrics.isEmpty
        targetSection.isHidden = !hasSelectedMetrics
        
        // Update target unit based on primary selected metric
        if let primaryMetric = eventData.selectedMetrics.first {
            let metric = availableMetrics.first { $0.0 == primaryMetric }
            targetUnitLabel.text = metric?.3 ?? "units"
            eventData.targetUnit = metric?.3 ?? ""
        }
    }
}

// MARK: - MetricButton

class MetricButton: UIButton {
    
    let identifier: String
    private let iconImageView = UIImageView()
    private let metricTitleLabel = UILabel()
    private let unitLabel = UILabel()
    
    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }
    
    init(identifier: String, title: String, iconName: String, unit: String) {
        self.identifier = identifier
        super.init(frame: .zero)
        setupButton(title: title, iconName: iconName, unit: unit)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupButton(title: String, iconName: String, unit: String) {
        backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        iconImageView.image = UIImage(systemName: iconName)
        iconImageView.tintColor = IndustrialDesign.Colors.primaryText
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        metricTitleLabel.text = title
        metricTitleLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        metricTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        metricTitleLabel.textAlignment = .center
        metricTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        unitLabel.text = unit
        unitLabel.font = UIFont.systemFont(ofSize: 10)
        unitLabel.textColor = IndustrialDesign.Colors.secondaryText
        unitLabel.textAlignment = .center
        unitLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(iconImageView)
        addSubview(metricTitleLabel)
        addSubview(unitLabel)
        
        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            metricTitleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 4),
            metricTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            metricTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            
            unitLabel.topAnchor.constraint(equalTo: metricTitleLabel.bottomAnchor, constant: 2),
            unitLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            unitLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            unitLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -4)
        ])
        
        updateAppearance()
    }
    
    private func updateAppearance() {
        if isSelected {
            backgroundColor = IndustrialDesign.Colors.bitcoin.withAlphaComponent(0.2)
            layer.borderColor = IndustrialDesign.Colors.bitcoin.cgColor
            iconImageView.tintColor = IndustrialDesign.Colors.bitcoin
        } else {
            backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
            layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
            iconImageView.tintColor = IndustrialDesign.Colors.primaryText
        }
    }
}