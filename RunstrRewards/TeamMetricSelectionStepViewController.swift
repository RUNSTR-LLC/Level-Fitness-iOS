import UIKit
import HealthKit

class TeamMetricSelectionStepViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let stepTitleLabel = UILabel()
    private let stepDescriptionLabel = UILabel()
    
    // Metrics selection
    private let metricsContainer = UIView()
    private var metricCards: [MetricSelectionCard] = []
    
    // Team data reference
    private let teamData: TeamCreationData
    
    // Available HealthKit metrics
    private let availableMetrics: [HealthKitMetric] = [
        HealthKitMetric(
            id: "running",
            name: "Running",
            description: "Track distance, pace, and duration for runs",
            icon: "figure.run",
            healthKitTypes: [HKObjectType.workoutType()]
        ),
        HealthKitMetric(
            id: "walking",
            name: "Walking", 
            description: "Daily steps and walking distance",
            icon: "figure.walk",
            healthKitTypes: [HKObjectType.quantityType(forIdentifier: .stepCount)!]
        ),
        HealthKitMetric(
            id: "cycling",
            name: "Cycling",
            description: "Bike rides, distance, and elevation",
            icon: "bicycle",
            healthKitTypes: [HKObjectType.workoutType()]
        ),
        HealthKitMetric(
            id: "strength",
            name: "Strength Training",
            description: "Gym workouts and weightlifting sessions",
            icon: "dumbbell.fill",
            healthKitTypes: [HKObjectType.workoutType()]
        ),
        HealthKitMetric(
            id: "workout_streaks",
            name: "Workout Streaks",
            description: "Consecutive days of any workout activity",
            icon: "flame.fill",
            healthKitTypes: [HKObjectType.workoutType()]
        )
    ]
    
    init(teamData: TeamCreationData) {
        self.teamData = teamData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
        createMetricCards()
        loadExistingSelections()
        
        print("📊 TeamMetricSelection: Step view loaded")
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        view.backgroundColor = UIColor.clear
        
        // Step header
        stepTitleLabel.text = "Tracking Metrics"
        stepTitleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        stepTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        stepTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        stepDescriptionLabel.text = "Choose which fitness activities your team will track. Members' HealthKit data will automatically sync for these activities."
        stepDescriptionLabel.font = UIFont.systemFont(ofSize: 16)
        stepDescriptionLabel.textColor = IndustrialDesign.Colors.secondaryText
        stepDescriptionLabel.numberOfLines = 0
        stepDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Metrics container
        metricsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Add to scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [stepTitleLabel, stepDescriptionLabel, metricsContainer].forEach {
            contentView.addSubview($0)
        }
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
            
            // Step header
            stepTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            stepTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stepTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            stepDescriptionLabel.topAnchor.constraint(equalTo: stepTitleLabel.bottomAnchor, constant: 8),
            stepDescriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stepDescriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            // Metrics container
            metricsContainer.topAnchor.constraint(equalTo: stepDescriptionLabel.bottomAnchor, constant: 32),
            metricsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            metricsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            metricsContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }
    
    private func createMetricCards() {
        print("📊 TeamMetricSelection: Creating \(availableMetrics.count) metric cards")
        var previousCard: UIView? = nil
        
        for (index, metric) in availableMetrics.enumerated() {
            print("📊 TeamMetricSelection: Creating card \(index + 1): \(metric.name)")
            let card = MetricSelectionCard(metric: metric)
            card.delegate = self
            card.translatesAutoresizingMaskIntoConstraints = false
            metricsContainer.addSubview(card)
            metricCards.append(card)
            
            NSLayoutConstraint.activate([
                card.leadingAnchor.constraint(equalTo: metricsContainer.leadingAnchor),
                card.trailingAnchor.constraint(equalTo: metricsContainer.trailingAnchor),
                card.heightAnchor.constraint(equalToConstant: 80)
            ])
            
            if let previousCard = previousCard {
                card.topAnchor.constraint(equalTo: previousCard.bottomAnchor, constant: 12).isActive = true
            } else {
                card.topAnchor.constraint(equalTo: metricsContainer.topAnchor).isActive = true
            }
            
            previousCard = card
        }
        
        if let lastCard = previousCard {
            metricsContainer.bottomAnchor.constraint(equalTo: lastCard.bottomAnchor).isActive = true
        }
        
        print("📊 TeamMetricSelection: Created \(metricCards.count) metric cards successfully")
    }
    
    private func loadExistingSelections() {
        for card in metricCards {
            let isSelected = teamData.selectedMetrics.contains(card.metric.id)
            card.setSelected(isSelected)
        }
    }
}

// MARK: - MetricSelectionCardDelegate

extension TeamMetricSelectionStepViewController: MetricSelectionCardDelegate {
    func metricSelectionDidChange(_ card: MetricSelectionCard, isSelected: Bool) {
        let metricId = card.metric.id
        
        if isSelected {
            if !teamData.selectedMetrics.contains(metricId) {
                teamData.selectedMetrics.append(metricId)
            }
        } else {
            teamData.selectedMetrics.removeAll { $0 == metricId }
        }
        
        print("📊 TeamMetricSelection: Selected metrics: \(teamData.selectedMetrics)")
    }
}

// MARK: - Metric Selection Card

protocol MetricSelectionCardDelegate: AnyObject {
    func metricSelectionDidChange(_ card: MetricSelectionCard, isSelected: Bool)
}

class MetricSelectionCard: UIView {
    
    weak var delegate: MetricSelectionCardDelegate?
    let metric: HealthKitMetric
    private var isSelected = false
    
    private let iconImageView = UIImageView()
    private let nameLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let checkboxImageView = UIImageView()
    
    init(metric: HealthKitMetric) {
        self.metric = metric
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        setupTapGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        // Icon
        iconImageView.image = UIImage(systemName: metric.icon)
        iconImageView.tintColor = IndustrialDesign.Colors.secondaryText
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Name
        nameLabel.text = metric.name
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = IndustrialDesign.Colors.primaryText
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Description
        descriptionLabel.text = metric.description
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = IndustrialDesign.Colors.secondaryText
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Checkbox
        checkboxImageView.image = UIImage(systemName: "circle")
        checkboxImageView.tintColor = IndustrialDesign.Colors.secondaryText
        checkboxImageView.contentMode = .scaleAspectFit
        checkboxImageView.translatesAutoresizingMaskIntoConstraints = false
        
        [iconImageView, nameLabel, descriptionLabel, checkboxImageView].forEach {
            addSubview($0)
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Icon
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            // Name
            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: checkboxImageView.leadingAnchor, constant: -12),
            
            // Description  
            descriptionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            descriptionLabel.trailingAnchor.constraint(equalTo: checkboxImageView.leadingAnchor, constant: -12),
            descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -16),
            
            // Checkbox
            checkboxImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            checkboxImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            checkboxImageView.widthAnchor.constraint(equalToConstant: 24),
            checkboxImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }
    
    @objc private func cardTapped() {
        setSelected(!isSelected)
        delegate?.metricSelectionDidChange(self, isSelected: isSelected)
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    func setSelected(_ selected: Bool) {
        isSelected = selected
        
        UIView.animate(withDuration: 0.2) {
            if selected {
                self.checkboxImageView.image = UIImage(systemName: "checkmark.circle.fill")
                self.checkboxImageView.tintColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0) // Bitcoin orange
                self.layer.borderColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 0.5).cgColor
                self.backgroundColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 0.1)
                self.iconImageView.tintColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
            } else {
                self.checkboxImageView.image = UIImage(systemName: "circle")
                self.checkboxImageView.tintColor = IndustrialDesign.Colors.secondaryText
                self.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
                self.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
                self.iconImageView.tintColor = IndustrialDesign.Colors.secondaryText
            }
        }
    }
}

// MARK: - HealthKit Metric Model

struct HealthKitMetric {
    let id: String
    let name: String
    let description: String
    let icon: String
    let healthKitTypes: [HKObjectType]
}