import UIKit
import Foundation

enum WorkoutType {
    case run
    case cycling
    case swimming
    case interval
    case recovery
    case longRun
    case strength
    case yoga
    
    var displayName: String {
        switch self {
        case .run: return "Morning Run"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .interval: return "Interval Training"
        case .recovery: return "Recovery Run"
        case .longRun: return "Long Run"
        case .strength: return "Strength Training"
        case .yoga: return "Yoga"
        }
    }
}

enum WorkoutSource {
    case healthKit
    case garmin
    case googleFit
    
    var displayName: String {
        switch self {
        case .healthKit: return "HealthKit"
        case .garmin: return "Garmin"
        case .googleFit: return "Google Fit"
        }
    }
    
    var systemIcon: String {
        switch self {
        case .healthKit: return "heart.fill"
        case .garmin: return "location.fill"
        case .googleFit: return "plus.circle"
        }
    }
}

struct WorkoutData {
    let id: String
    let type: WorkoutType
    let source: WorkoutSource
    let date: Date
    let distance: Double // in km
    let duration: TimeInterval // in seconds
    let pace: TimeInterval // seconds per km
    
    var formattedDate: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
            return "Today, \(formatter.string(from: date).lowercased())"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "h:mm a"
            return "Yesterday, \(formatter.string(from: date))"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
    }
    
    var formattedDistance: String {
        return String(format: "%.1f", distance)
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return String(format: "%d:%02d:00", hours, minutes)
        } else {
            let seconds = Int(duration) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var formattedPace: String {
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

class WorkoutCard: UIView {
    
    // MARK: - Properties
    private let workoutData: WorkoutData
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let headerContainer = UIView()
    private let workoutTypeLabel = UILabel()
    private let workoutDateLabel = UILabel()
    private let sourceContainer = UIView()
    private let sourceIconView = UIImageView()
    private let sourceLabel = UILabel()
    private let metricsContainer = UIView()
    private let distanceMetric = MetricView(label: "KM")
    private let durationMetric = MetricView(label: "DURATION")
    private let paceMetric = MetricView(label: "PACE")
    private let boltDecoration = UIView()
    
    // MARK: - Initialization
    
    init(workoutData: WorkoutData) {
        self.workoutData = workoutData
        super.init(frame: .zero)
        setupCard()
        setupConstraints()
        configureWithData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    private func setupCard() {
        backgroundColor = UIColor.clear
        
        // Container view with gradient background
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        containerView.layer.cornerRadius = 10
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0).cgColor
        
        // Add subtle gradient
        DispatchQueue.main.async {
            self.setupGradientBackground()
        }
        
        // Header container
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Workout type label
        workoutTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        workoutTypeLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        workoutTypeLabel.textColor = IndustrialDesign.Colors.primaryText
        workoutTypeLabel.numberOfLines = 1
        
        // Workout date label
        workoutDateLabel.translatesAutoresizingMaskIntoConstraints = false
        workoutDateLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        workoutDateLabel.textColor = IndustrialDesign.Colors.secondaryText
        workoutDateLabel.numberOfLines = 1
        
        // Source container
        sourceContainer.translatesAutoresizingMaskIntoConstraints = false
        sourceContainer.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 0.5)
        sourceContainer.layer.borderWidth = 1
        sourceContainer.layer.borderColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
        sourceContainer.layer.cornerRadius = 4
        
        // Source icon
        sourceIconView.translatesAutoresizingMaskIntoConstraints = false
        sourceIconView.tintColor = IndustrialDesign.Colors.accentText
        sourceIconView.contentMode = .scaleAspectFit
        
        // Source label
        sourceLabel.translatesAutoresizingMaskIntoConstraints = false
        sourceLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        sourceLabel.textColor = IndustrialDesign.Colors.accentText
        sourceLabel.textAlignment = .center
        sourceLabel.letterSpacing = 0.5
        
        // Metrics container
        metricsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup metric views
        distanceMetric.translatesAutoresizingMaskIntoConstraints = false
        durationMetric.translatesAutoresizingMaskIntoConstraints = false
        paceMetric.translatesAutoresizingMaskIntoConstraints = false
        
        // Bolt decoration
        boltDecoration.translatesAutoresizingMaskIntoConstraints = false
        boltDecoration.backgroundColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0)
        boltDecoration.layer.cornerRadius = 3
        boltDecoration.layer.borderWidth = 1
        boltDecoration.layer.borderColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor
        
        // Add subviews
        addSubview(containerView)
        containerView.addSubview(headerContainer)
        containerView.addSubview(sourceContainer)
        containerView.addSubview(metricsContainer)
        containerView.addSubview(boltDecoration)
        
        headerContainer.addSubview(workoutTypeLabel)
        headerContainer.addSubview(workoutDateLabel)
        
        sourceContainer.addSubview(sourceIconView)
        sourceContainer.addSubview(sourceLabel)
        
        metricsContainer.addSubview(distanceMetric)
        metricsContainer.addSubview(durationMetric)
        metricsContainer.addSubview(paceMetric)
        
        setupHoverEffects()
    }
    
    private func setupGradientBackground() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor,
            UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = containerView.bounds
        gradientLayer.cornerRadius = 10
        
        containerView.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 100),
            
            // Header container
            headerContainer.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            headerContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            headerContainer.trailingAnchor.constraint(lessThanOrEqualTo: sourceContainer.leadingAnchor, constant: -12),
            
            // Workout type label
            workoutTypeLabel.topAnchor.constraint(equalTo: headerContainer.topAnchor),
            workoutTypeLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            workoutTypeLabel.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            
            // Workout date label
            workoutDateLabel.topAnchor.constraint(equalTo: workoutTypeLabel.bottomAnchor, constant: 4),
            workoutDateLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            workoutDateLabel.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            workoutDateLabel.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            
            // Source container
            sourceContainer.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            sourceContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            sourceContainer.heightAnchor.constraint(equalToConstant: 24),
            sourceContainer.widthAnchor.constraint(equalToConstant: 80),
            
            // Source icon
            sourceIconView.leadingAnchor.constraint(equalTo: sourceContainer.leadingAnchor, constant: 6),
            sourceIconView.centerYAnchor.constraint(equalTo: sourceContainer.centerYAnchor),
            sourceIconView.widthAnchor.constraint(equalToConstant: 12),
            sourceIconView.heightAnchor.constraint(equalToConstant: 12),
            
            // Source label
            sourceLabel.leadingAnchor.constraint(equalTo: sourceIconView.trailingAnchor, constant: 4),
            sourceLabel.trailingAnchor.constraint(equalTo: sourceContainer.trailingAnchor, constant: -6),
            sourceLabel.centerYAnchor.constraint(equalTo: sourceContainer.centerYAnchor),
            
            // Metrics container
            metricsContainer.topAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: 12),
            metricsContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            metricsContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            metricsContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            
            // Distance metric
            distanceMetric.leadingAnchor.constraint(equalTo: metricsContainer.leadingAnchor),
            distanceMetric.centerYAnchor.constraint(equalTo: metricsContainer.centerYAnchor),
            distanceMetric.widthAnchor.constraint(equalTo: metricsContainer.widthAnchor, multiplier: 0.33),
            
            // Duration metric
            durationMetric.centerXAnchor.constraint(equalTo: metricsContainer.centerXAnchor),
            durationMetric.centerYAnchor.constraint(equalTo: metricsContainer.centerYAnchor),
            durationMetric.widthAnchor.constraint(equalTo: metricsContainer.widthAnchor, multiplier: 0.33),
            
            // Pace metric
            paceMetric.trailingAnchor.constraint(equalTo: metricsContainer.trailingAnchor),
            paceMetric.centerYAnchor.constraint(equalTo: metricsContainer.centerYAnchor),
            paceMetric.widthAnchor.constraint(equalTo: metricsContainer.widthAnchor, multiplier: 0.33),
            
            // Bolt decoration
            boltDecoration.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            boltDecoration.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            boltDecoration.widthAnchor.constraint(equalToConstant: 6),
            boltDecoration.heightAnchor.constraint(equalToConstant: 6)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update gradient frame
        if let gradientLayer = containerView.layer.sublayers?.first(where: { $0 is CAGradientLayer }) as? CAGradientLayer {
            gradientLayer.frame = containerView.bounds
        }
    }
    
    private func configureWithData() {
        workoutTypeLabel.text = workoutData.type.displayName
        workoutDateLabel.text = workoutData.formattedDate
        sourceLabel.text = workoutData.source.displayName.uppercased()
        sourceIconView.image = UIImage(systemName: workoutData.source.systemIcon)
        
        distanceMetric.configure(value: workoutData.formattedDistance)
        durationMetric.configure(value: workoutData.formattedDuration)
        paceMetric.configure(value: workoutData.formattedPace)
    }
    
    private func setupHoverEffects() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        addGestureRecognizer(tapGesture)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(cardPressed(_:)))
        addGestureRecognizer(longPressGesture)
    }
    
    @objc private func cardTapped() {
        // Animation for tap feedback
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = .identity
            }
        }
        
        // Notify delegate or post notification
        NotificationCenter.default.post(name: .workoutCardTapped, object: workoutData)
        print("🏃‍♂️ LevelFitness: Workout tapped: \(workoutData.type.displayName)")
    }
    
    @objc private func cardPressed(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            UIView.animate(withDuration: 0.2) {
                self.transform = CGAffineTransform(translationX: -4, y: 0)
                self.layer.shadowColor = UIColor.black.cgColor
                self.layer.shadowOffset = CGSize(width: 8, height: 0)
                self.layer.shadowOpacity = 0.3
                self.layer.shadowRadius = 12
            }
        case .ended, .cancelled:
            UIView.animate(withDuration: 0.2) {
                self.transform = .identity
                self.layer.shadowOpacity = 0
            }
        default:
            break
        }
    }
}

// MARK: - Metric View Component

class MetricView: UIView {
    
    private let valueLabel = UILabel()
    private let labelLabel = UILabel()
    
    init(label: String) {
        super.init(frame: .zero)
        
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        valueLabel.textColor = IndustrialDesign.Colors.primaryText
        valueLabel.textAlignment = .center
        valueLabel.numberOfLines = 1
        
        labelLabel.translatesAutoresizingMaskIntoConstraints = false
        labelLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        labelLabel.textColor = IndustrialDesign.Colors.secondaryText
        labelLabel.textAlignment = .center
        labelLabel.text = label
        labelLabel.letterSpacing = 0.5
        labelLabel.numberOfLines = 1
        
        addSubview(valueLabel)
        addSubview(labelLabel)
        
        NSLayoutConstraint.activate([
            valueLabel.topAnchor.constraint(equalTo: topAnchor),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            labelLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 2),
            labelLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            labelLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            labelLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(value: String) {
        valueLabel.text = value
    }
}

// MARK: - Notification Names

extension NSNotification.Name {
    static let workoutCardTapped = NSNotification.Name("WorkoutCardTapped")
}