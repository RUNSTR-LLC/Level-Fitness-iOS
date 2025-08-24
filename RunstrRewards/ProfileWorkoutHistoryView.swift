import UIKit

class ProfileWorkoutHistoryView: UIView {
    
    // MARK: - UI Components
    private let containerView = UIView()
    private var gradientLayer: CAGradientLayer?
    private let titleLabel = UILabel()
    private let emptyStateLabel = UILabel()
    private let tableView = UITableView()
    private let boltDecoration = UIView()
    
    // MARK: - Properties
    private var workouts: [ProfileWorkoutData] = []
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
        showEmptyState()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = containerView.bounds
    }
    
    // MARK: - Setup Methods
    
    private func setupView() {
        // Container with industrial styling
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        containerView.layer.cornerRadius = IndustrialDesign.Sizing.cardCornerRadius
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        
        // Add gradient
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor,
            UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1.0).cgColor
        ]
        gradient.locations = [0.0, 1.0]
        gradient.cornerRadius = IndustrialDesign.Sizing.cardCornerRadius
        containerView.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient
        
        // Title label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "RECENT WORKOUTS"
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.accentText
        titleLabel.letterSpacing = 1
        
        // Empty state label
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.text = "No workouts synced yet.\nConnect a data source to get started!"
        emptyStateLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        emptyStateLabel.textColor = IndustrialDesign.Colors.secondaryText
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.isHidden = true
        
        // Table view
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor.clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = true
        tableView.indicatorStyle = .white
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(WorkoutHistoryCell.self, forCellReuseIdentifier: "WorkoutCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        
        // Bolt decoration
        boltDecoration.translatesAutoresizingMaskIntoConstraints = false
        boltDecoration.backgroundColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0)
        boltDecoration.layer.cornerRadius = 3
        boltDecoration.layer.borderWidth = 1
        boltDecoration.layer.borderColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor
        
        // Add subviews
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(emptyStateLabel)
        containerView.addSubview(tableView)
        containerView.addSubview(boltDecoration)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            
            // Empty state
            emptyStateLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 40),
            emptyStateLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -40),
            
            // Table view
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            
            // Bolt decoration
            boltDecoration.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            boltDecoration.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            boltDecoration.widthAnchor.constraint(equalToConstant: 6),
            boltDecoration.heightAnchor.constraint(equalToConstant: 6)
        ])
    }
    
    // MARK: - Public Methods
    
    func updateWorkouts(_ workouts: [ProfileWorkoutData]) {
        self.workouts = workouts
        
        if workouts.isEmpty {
            showEmptyState()
        } else {
            hideEmptyState()
            tableView.reloadData()
        }
    }
    
    // MARK: - Private Methods
    
    private func showEmptyState() {
        emptyStateLabel.isHidden = false
        tableView.isHidden = true
    }
    
    private func hideEmptyState() {
        emptyStateLabel.isHidden = true
        tableView.isHidden = false
    }
}

// MARK: - UITableViewDataSource

extension ProfileWorkoutHistoryView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return workouts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WorkoutCell", for: indexPath) as! WorkoutHistoryCell
        cell.configure(with: workouts[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ProfileWorkoutHistoryView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        print("👤 Workout History: Selected workout at index \(indexPath.row)")
    }
}

// MARK: - WorkoutHistoryCell

class WorkoutHistoryCell: UITableViewCell {
    
    private let containerView = UIView()
    private let typeIcon = UIImageView()
    private let typeLabel = UILabel()
    private let dateLabel = UILabel()
    private let statsStack = UIStackView()
    private let distanceLabel = UILabel()
    private let durationLabel = UILabel()
    private let satsLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        backgroundColor = UIColor.clear
        selectionStyle = .none
        
        // Container
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.5)
        containerView.layer.cornerRadius = 8
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0).cgColor
        
        // Type icon
        typeIcon.translatesAutoresizingMaskIntoConstraints = false
        typeIcon.contentMode = .scaleAspectFit
        typeIcon.tintColor = IndustrialDesign.Colors.accentText
        
        // Type label
        typeLabel.translatesAutoresizingMaskIntoConstraints = false
        typeLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        typeLabel.textColor = IndustrialDesign.Colors.primaryText
        
        // Date label
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        dateLabel.textColor = IndustrialDesign.Colors.secondaryText
        
        // Stats stack
        statsStack.translatesAutoresizingMaskIntoConstraints = false
        statsStack.axis = .horizontal
        statsStack.spacing = 16
        statsStack.distribution = .fillEqually
        
        // Distance label
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        distanceLabel.textColor = IndustrialDesign.Colors.primaryText
        
        // Duration label
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        durationLabel.textColor = IndustrialDesign.Colors.primaryText
        
        // Sats label
        satsLabel.translatesAutoresizingMaskIntoConstraints = false
        satsLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        satsLabel.textColor = UIColor(red: 0.97, green: 0.57, blue: 0.1, alpha: 1.0) // Bitcoin orange
        
        // Add to stack
        statsStack.addArrangedSubview(distanceLabel)
        statsStack.addArrangedSubview(durationLabel)
        statsStack.addArrangedSubview(satsLabel)
        
        // Add subviews
        contentView.addSubview(containerView)
        containerView.addSubview(typeIcon)
        containerView.addSubview(typeLabel)
        containerView.addSubview(dateLabel)
        containerView.addSubview(statsStack)
        
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            containerView.heightAnchor.constraint(equalToConstant: 72),
            
            // Type icon
            typeIcon.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            typeIcon.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            typeIcon.widthAnchor.constraint(equalToConstant: 24),
            typeIcon.heightAnchor.constraint(equalToConstant: 24),
            
            // Type label
            typeLabel.leadingAnchor.constraint(equalTo: typeIcon.trailingAnchor, constant: 12),
            typeLabel.centerYAnchor.constraint(equalTo: typeIcon.centerYAnchor),
            
            // Date label
            dateLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            dateLabel.centerYAnchor.constraint(equalTo: typeIcon.centerYAnchor),
            
            // Stats stack
            statsStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            statsStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            statsStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with workout: ProfileWorkoutData) {
        // Set icon based on workout type
        switch workout.type.lowercased() {
        case "running", "run":
            typeIcon.image = UIImage(systemName: "figure.run")
        case "cycling", "bike", "bicycle":
            typeIcon.image = UIImage(systemName: "bicycle")
        case "walking", "walk":
            typeIcon.image = UIImage(systemName: "figure.walk")
        case "swimming", "swim":
            typeIcon.image = UIImage(systemName: "figure.pool.swim")
        default:
            typeIcon.image = UIImage(systemName: "heart.fill")
        }
        
        typeLabel.text = workout.type
        dateLabel.text = workout.formattedDate
        distanceLabel.text = workout.formattedDistance
        durationLabel.text = workout.formattedDuration
        satsLabel.text = workout.formattedSats
    }
}