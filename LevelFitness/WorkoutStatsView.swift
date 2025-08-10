import UIKit

enum StatsPeriod {
    case weekly
    case monthly
    case yearly
    
    var title: String {
        switch self {
        case .weekly: return "WEEKLY"
        case .monthly: return "MONTHLY"
        case .yearly: return "YEARLY"
        }
    }
}

struct WorkoutStats {
    let period: StatsPeriod
    let totalWorkouts: Int
    let totalDistance: Double // in km
    let totalTime: TimeInterval // in seconds
    let averagePace: TimeInterval // seconds per km
    
    var formattedTotalDistance: String {
        return String(format: "%.1f", totalDistance)
    }
    
    var formattedTotalTime: String {
        let hours = Int(totalTime) / 3600
        let minutes = Int(totalTime) % 3600 / 60
        return String(format: "%d:%02d", hours, minutes)
    }
    
    var formattedAveragePace: String {
        let minutes = Int(averagePace) / 60
        let seconds = Int(averagePace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

protocol WorkoutStatsViewDelegate: AnyObject {
    func didSelectStatsPeriod(_ period: StatsPeriod)
}

class WorkoutStatsView: UIView {
    
    // MARK: - Properties
    weak var delegate: WorkoutStatsViewDelegate?
    private var currentPeriod: StatsPeriod = .weekly
    private var statsData: WorkoutStats?
    private var recentWorkouts: [WorkoutData] = []
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let periodSelectorContainer = UIView()
    private let periodButtonsStack = UIStackView()
    private var periodButtons: [StatsPeriod: UIButton] = [:]
    private let statsOverviewContainer = UIView()
    private let statsGrid = UIView()
    private let recentWorkoutsContainer = UIView()
    private let recentWorkoutsTitle = UILabel()
    
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
        
        // Scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.indicatorStyle = .white
        scrollView.backgroundColor = UIColor.clear
        
        // Content view
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = UIColor.clear
        
        // Period selector container
        periodSelectorContainer.translatesAutoresizingMaskIntoConstraints = false
        periodSelectorContainer.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        
        // Add bottom border to period selector
        let borderView = UIView()
        borderView.translatesAutoresizingMaskIntoConstraints = false
        borderView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        periodSelectorContainer.addSubview(borderView)
        
        NSLayoutConstraint.activate([
            borderView.leadingAnchor.constraint(equalTo: periodSelectorContainer.leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: periodSelectorContainer.trailingAnchor),
            borderView.bottomAnchor.constraint(equalTo: periodSelectorContainer.bottomAnchor),
            borderView.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        // Period buttons stack
        periodButtonsStack.translatesAutoresizingMaskIntoConstraints = false
        periodButtonsStack.axis = .horizontal
        periodButtonsStack.distribution = .fillEqually
        periodButtonsStack.spacing = 8
        
        // Create period buttons
        setupPeriodButtons()
        
        // Stats overview container
        statsOverviewContainer.translatesAutoresizingMaskIntoConstraints = false
        statsOverviewContainer.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        statsOverviewContainer.layer.cornerRadius = 12
        statsOverviewContainer.layer.borderWidth = 1
        statsOverviewContainer.layer.borderColor = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0).cgColor
        
        // Add gradient to overview
        DispatchQueue.main.async {
            self.setupOverviewGradient()
        }
        
        // Stats grid
        statsGrid.translatesAutoresizingMaskIntoConstraints = false
        
        // Recent workouts container
        recentWorkoutsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Recent workouts title
        recentWorkoutsTitle.translatesAutoresizingMaskIntoConstraints = false
        recentWorkoutsTitle.text = "THIS WEEK'S WORKOUTS"
        recentWorkoutsTitle.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        recentWorkoutsTitle.textColor = IndustrialDesign.Colors.accentText
        recentWorkoutsTitle.letterSpacing = 1
        
        // Add subviews
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(periodSelectorContainer)
        contentView.addSubview(statsOverviewContainer)
        contentView.addSubview(recentWorkoutsContainer)
        
        periodSelectorContainer.addSubview(periodButtonsStack)
        statsOverviewContainer.addSubview(statsGrid)
        recentWorkoutsContainer.addSubview(recentWorkoutsTitle)
        
        // Add bolt decoration to stats overview
        let boltDecoration = UIView()
        boltDecoration.translatesAutoresizingMaskIntoConstraints = false
        boltDecoration.backgroundColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0)
        boltDecoration.layer.cornerRadius = 3
        boltDecoration.layer.borderWidth = 1
        boltDecoration.layer.borderColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor
        statsOverviewContainer.addSubview(boltDecoration)
        
        NSLayoutConstraint.activate([
            boltDecoration.topAnchor.constraint(equalTo: statsOverviewContainer.topAnchor, constant: 12),
            boltDecoration.trailingAnchor.constraint(equalTo: statsOverviewContainer.trailingAnchor, constant: -12),
            boltDecoration.widthAnchor.constraint(equalToConstant: 6),
            boltDecoration.heightAnchor.constraint(equalToConstant: 6)
        ])
    }
    
    private func setupPeriodButtons() {
        let periods: [StatsPeriod] = [.weekly, .monthly, .yearly]
        
        for period in periods {
            let button = UIButton(type: .custom)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setTitle(period.title, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
            button.titleLabel?.letterSpacing = 0.5
            button.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0).cgColor
            button.layer.cornerRadius = 6
            button.addTarget(self, action: #selector(periodButtonTapped(_:)), for: .touchUpInside)
            button.tag = getTagForPeriod(period)
            
            // Set initial appearance
            if period == currentPeriod {
                button.setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
                button.backgroundColor = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0)
                button.layer.borderColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0).cgColor
            } else {
                button.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
            }
            
            periodButtons[period] = button
            periodButtonsStack.addArrangedSubview(button)
            
            button.heightAnchor.constraint(equalToConstant: 32).isActive = true
        }
    }
    
    private func getTagForPeriod(_ period: StatsPeriod) -> Int {
        switch period {
        case .weekly: return 0
        case .monthly: return 1
        case .yearly: return 2
        }
    }
    
    private func getPeriodForTag(_ tag: Int) -> StatsPeriod {
        switch tag {
        case 0: return .weekly
        case 1: return .monthly
        case 2: return .yearly
        default: return .weekly
        }
    }
    
    private func setupOverviewGradient() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor,
            UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = statsOverviewContainer.bounds
        gradientLayer.cornerRadius = 12
        
        statsOverviewContainer.layer.insertSublayer(gradientLayer, at: 0)
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
            
            // Period selector container
            periodSelectorContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            periodSelectorContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            periodSelectorContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            periodSelectorContainer.heightAnchor.constraint(equalToConstant: 60),
            
            // Period buttons stack
            periodButtonsStack.centerXAnchor.constraint(equalTo: periodSelectorContainer.centerXAnchor),
            periodButtonsStack.centerYAnchor.constraint(equalTo: periodSelectorContainer.centerYAnchor),
            periodButtonsStack.widthAnchor.constraint(equalToConstant: 280),
            
            // Stats overview container
            statsOverviewContainer.topAnchor.constraint(equalTo: periodSelectorContainer.bottomAnchor, constant: 20),
            statsOverviewContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            statsOverviewContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            statsOverviewContainer.heightAnchor.constraint(equalToConstant: 140),
            
            // Stats grid
            statsGrid.topAnchor.constraint(equalTo: statsOverviewContainer.topAnchor, constant: 20),
            statsGrid.leadingAnchor.constraint(equalTo: statsOverviewContainer.leadingAnchor, constant: 20),
            statsGrid.trailingAnchor.constraint(equalTo: statsOverviewContainer.trailingAnchor, constant: -20),
            statsGrid.bottomAnchor.constraint(equalTo: statsOverviewContainer.bottomAnchor, constant: -20),
            
            // Recent workouts container
            recentWorkoutsContainer.topAnchor.constraint(equalTo: statsOverviewContainer.bottomAnchor, constant: 20),
            recentWorkoutsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            recentWorkoutsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            recentWorkoutsContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // Recent workouts title
            recentWorkoutsTitle.topAnchor.constraint(equalTo: recentWorkoutsContainer.topAnchor),
            recentWorkoutsTitle.leadingAnchor.constraint(equalTo: recentWorkoutsContainer.leadingAnchor, constant: 24),
            recentWorkoutsTitle.trailingAnchor.constraint(equalTo: recentWorkoutsContainer.trailingAnchor, constant: -24)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update gradient frame
        if let gradientLayer = statsOverviewContainer.layer.sublayers?.first(where: { $0 is CAGradientLayer }) as? CAGradientLayer {
            gradientLayer.frame = statsOverviewContainer.bounds
        }
    }
    
    // MARK: - Public Methods
    
    func loadSampleData() {
        loadSampleStats()
        loadSampleRecentWorkouts()
    }
    
    func updateWithHealthKitWorkouts(_ workouts: [HealthKitWorkout]) {
        print("🏃‍♂️ LevelFitness: Updating stats view with \(workouts.count) HealthKit workouts")
        
        // Convert HealthKitWorkouts to WorkoutData format
        let workoutData = workouts.map { healthKitWorkout in
            WorkoutData(
                id: healthKitWorkout.id,
                type: mapWorkoutType(healthKitWorkout.workoutType),
                source: .healthKit,
                date: healthKitWorkout.startDate,
                distance: healthKitWorkout.totalDistance / 1000.0, // Convert meters to km
                duration: healthKitWorkout.duration,
                pace: healthKitWorkout.totalDistance > 0 ? healthKitWorkout.duration / (healthKitWorkout.totalDistance / 1000.0) : 0
            )
        }
        
        // Filter workouts based on current period
        let filteredWorkouts = filterWorkoutsForPeriod(workoutData, period: currentPeriod)
        
        // Calculate real stats
        let totalDistance = filteredWorkouts.reduce(0) { $0 + $1.distance }
        let totalTime = filteredWorkouts.reduce(0) { $0 + $1.duration }
        let averagePace = totalDistance > 0 ? totalTime / totalDistance : 0
        
        statsData = WorkoutStats(
            period: currentPeriod,
            totalWorkouts: filteredWorkouts.count,
            totalDistance: totalDistance,
            totalTime: totalTime,
            averagePace: averagePace
        )
        
        // Update recent workouts with real data (last 10)
        recentWorkouts = Array(workoutData.prefix(10))
        
        // Rebuild views with real data
        buildStatsGrid()
        buildRecentWorkoutsList()
    }
    
    private func mapWorkoutType(_ workoutType: String) -> WorkoutType {
        switch workoutType.lowercased() {
        case "running": return .run
        case "walking": return .recovery // Map walking to recovery run
        case "cycling": return .cycling
        case "swimming": return .swimming
        case "hiit", "high_intensity_interval_training": return .interval
        case "strength_training", "traditional_strength_training", "functional_strength_training": return .strength
        case "yoga": return .yoga
        case "dance": return .recovery // Map dance to recovery
        default: return .run // Default to run for unknown types
        }
    }
    
    private func filterWorkoutsForPeriod(_ workouts: [WorkoutData], period: StatsPeriod) -> [WorkoutData] {
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        switch period {
        case .weekly:
            startDate = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        case .monthly:
            startDate = calendar.dateInterval(of: .month, for: now)?.start ?? now
        case .yearly:
            startDate = calendar.dateInterval(of: .year, for: now)?.start ?? now
        }
        
        return workouts.filter { $0.date >= startDate }
    }
    
    private func loadSampleStats() {
        statsData = WorkoutStats(
            period: currentPeriod,
            totalWorkouts: 5,
            totalDistance: 32.2,
            totalTime: 9900, // 2:45:00
            averagePace: 308 // 5:08
        )
        
        buildStatsGrid()
    }
    
    private func loadSampleRecentWorkouts() {
        let calendar = Calendar.current
        let now = Date()
        
        recentWorkouts = [
            WorkoutData(
                id: "1",
                type: .run,
                source: .healthKit,
                date: calendar.date(byAdding: .hour, value: -2, to: now)!,
                distance: 5.2,
                duration: 1605, // 26:45
                pace: 309 // 5:09
            ),
            WorkoutData(
                id: "2",
                type: .interval,
                source: .healthKit,
                date: calendar.date(byAdding: .day, value: -1, to: calendar.date(bySettingHour: 17, minute: 0, second: 0, of: now)!)!,
                distance: 8.0,
                duration: 2120, // 35:20
                pace: 265 // 4:25
            )
        ]
        
        buildRecentWorkoutsList()
    }
    
    private func buildStatsGrid() {
        // Clear existing views
        statsGrid.subviews.forEach { $0.removeFromSuperview() }
        
        guard let stats = statsData else { return }
        
        // Create stat boxes in 2x2 grid
        let statBoxData: [(String, String)] = [
            ("\(stats.totalWorkouts)", "Workouts"),
            (stats.formattedTotalDistance, "Total KM"),
            (stats.formattedTotalTime, "Total Time"),
            (stats.formattedAveragePace, "Avg Pace")
        ]
        
        for (index, (value, label)) in statBoxData.enumerated() {
            let row = index / 2
            let column = index % 2
            
            let statBox = StatBoxView(value: value, label: label)
            statBox.translatesAutoresizingMaskIntoConstraints = false
            statsGrid.addSubview(statBox)
            
            NSLayoutConstraint.activate([
                statBox.leadingAnchor.constraint(
                    equalTo: column == 0 ? statsGrid.leadingAnchor : statsGrid.centerXAnchor,
                    constant: column == 0 ? 0 : 10
                ),
                statBox.trailingAnchor.constraint(
                    equalTo: column == 0 ? statsGrid.centerXAnchor : statsGrid.trailingAnchor,
                    constant: column == 0 ? -10 : 0
                ),
                statBox.topAnchor.constraint(
                    equalTo: row == 0 ? statsGrid.topAnchor : statsGrid.centerYAnchor,
                    constant: row == 0 ? 0 : 10
                ),
                statBox.bottomAnchor.constraint(
                    equalTo: row == 0 ? statsGrid.centerYAnchor : statsGrid.bottomAnchor,
                    constant: row == 0 ? -10 : 0
                )
            ])
        }
    }
    
    private func buildRecentWorkoutsList() {
        // Remove existing workout cards
        recentWorkoutsContainer.subviews.forEach { view in
            if view != recentWorkoutsTitle {
                view.removeFromSuperview()
            }
        }
        
        var lastView: UIView = recentWorkoutsTitle
        
        for workout in recentWorkouts {
            let workoutCard = WorkoutCard(workoutData: workout)
            workoutCard.translatesAutoresizingMaskIntoConstraints = false
            recentWorkoutsContainer.addSubview(workoutCard)
            
            NSLayoutConstraint.activate([
                workoutCard.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 16),
                workoutCard.leadingAnchor.constraint(equalTo: recentWorkoutsContainer.leadingAnchor, constant: 24),
                workoutCard.trailingAnchor.constraint(equalTo: recentWorkoutsContainer.trailingAnchor, constant: -24)
            ])
            
            lastView = workoutCard
        }
        
        // Set container bottom constraint
        if lastView != recentWorkoutsTitle {
            recentWorkoutsContainer.bottomAnchor.constraint(greaterThanOrEqualTo: lastView.bottomAnchor, constant: 40).isActive = true
        }
    }
    
    // MARK: - Actions
    
    @objc private func periodButtonTapped(_ sender: UIButton) {
        let selectedPeriod = getPeriodForTag(sender.tag)
        
        // Update button appearance
        for (period, button) in periodButtons {
            if period == selectedPeriod {
                button.setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
                button.backgroundColor = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0)
                button.layer.borderColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0).cgColor
            } else {
                button.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
                button.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
                button.layer.borderColor = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0).cgColor
            }
        }
        
        // Add tap feedback
        UIView.animate(withDuration: 0.1, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                sender.transform = .identity
            }
        }
        
        currentPeriod = selectedPeriod
        delegate?.didSelectStatsPeriod(selectedPeriod)
        
        // Update stats for new period
        loadSampleStats()
        updateWorkoutsTitleForPeriod()
        
        print("🏃‍♂️ LevelFitness: Stats period selected: \(selectedPeriod.title)")
    }
    
    private func updateWorkoutsTitleForPeriod() {
        switch currentPeriod {
        case .weekly:
            recentWorkoutsTitle.text = "THIS WEEK'S WORKOUTS"
        case .monthly:
            recentWorkoutsTitle.text = "THIS MONTH'S WORKOUTS"
        case .yearly:
            recentWorkoutsTitle.text = "THIS YEAR'S WORKOUTS"
        }
    }
}

// MARK: - Stat Box Component

class StatBoxView: UIView {
    
    private let valueLabel = UILabel()
    private let labelLabel = UILabel()
    
    init(value: String, label: String) {
        super.init(frame: .zero)
        
        backgroundColor = UIColor.clear
        
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        valueLabel.textColor = IndustrialDesign.Colors.primaryText
        valueLabel.textAlignment = .center
        valueLabel.numberOfLines = 1
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.8
        
        labelLabel.translatesAutoresizingMaskIntoConstraints = false
        labelLabel.text = label.uppercased()
        labelLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        labelLabel.textColor = IndustrialDesign.Colors.secondaryText
        labelLabel.textAlignment = .center
        labelLabel.letterSpacing = 0.5
        labelLabel.numberOfLines = 1
        
        addSubview(valueLabel)
        addSubview(labelLabel)
        
        NSLayoutConstraint.activate([
            valueLabel.topAnchor.constraint(equalTo: topAnchor),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            labelLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 4),
            labelLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            labelLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            labelLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}