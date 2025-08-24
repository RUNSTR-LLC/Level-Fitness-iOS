import UIKit

class ChallengeDetailViewController: UIViewController {
    
    // MARK: - Properties
    private let challengeData: ChallengeData
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let headerView = UIView()
    private let backButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    private let challengeIconView = UIView()
    private let progressContainer = UIView()
    private let progressBar = UIProgressView()
    private let progressLabel = UILabel()
    private let detailsContainer = UIView()
    private let descriptionContainer = UIView()
    private let participantsContainer = UIView()
    
    // MARK: - Initialization
    
    init(challengeData: ChallengeData) {
        self.challengeData = challengeData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🏆 ChallengeDetail: Loading details for challenge: \(challengeData.title)")
        
        setupIndustrialBackground()
        setupScrollView()
        setupHeader()
        setupChallengeIcon()
        setupProgressContainer()
        setupDetailsContainer()
        setupDescriptionContainer()
        setupParticipantsContainer()
        setupConstraints()
        
        configureWithChallengeData()
    }
    
    // MARK: - Setup Methods
    
    private func setupIndustrialBackground() {
        view.backgroundColor = IndustrialDesign.Colors.background
        
        // Add grid pattern
        let gridView = GridPatternView()
        gridView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gridView)
        
        NSLayoutConstraint.activate([
            gridView.topAnchor.constraint(equalTo: view.topAnchor),
            gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Add gear decoration
        let gear = RotatingGearView(size: 80)
        gear.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gear)
        
        NSLayoutConstraint.activate([
            gear.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            gear.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 20),
            gear.widthAnchor.constraint(equalToConstant: 80),
            gear.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 0.95)
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Back button
        backButton.setTitle("← Back", for: .normal)
        backButton.setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        // Title
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(backButton)
        headerView.addSubview(titleLabel)
        contentView.addSubview(headerView)
    }
    
    private func setupChallengeIcon() {
        challengeIconView.translatesAutoresizingMaskIntoConstraints = false
        challengeIconView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        challengeIconView.layer.cornerRadius = 40
        challengeIconView.layer.borderWidth = 2
        challengeIconView.layer.borderColor = IndustrialDesign.Colors.bitcoin.cgColor
        
        let iconLabel = UILabel()
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        iconLabel.text = challengeData.icon
        iconLabel.font = UIFont.systemFont(ofSize: 32)
        iconLabel.textAlignment = .center
        
        challengeIconView.addSubview(iconLabel)
        contentView.addSubview(challengeIconView)
        
        NSLayoutConstraint.activate([
            iconLabel.centerXAnchor.constraint(equalTo: challengeIconView.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: challengeIconView.centerYAnchor)
        ])
    }
    
    private func setupProgressContainer() {
        progressContainer.translatesAutoresizingMaskIntoConstraints = false
        progressContainer.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        progressContainer.layer.cornerRadius = 12
        progressContainer.layer.borderWidth = 1
        progressContainer.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        // Progress bar
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.progressTintColor = IndustrialDesign.Colors.bitcoin
        progressBar.trackTintColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0)
        progressBar.layer.cornerRadius = 6
        progressBar.layer.masksToBounds = true
        
        // Progress label
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        progressLabel.textColor = IndustrialDesign.Colors.primaryText
        progressLabel.textAlignment = .center
        
        progressContainer.addSubview(progressBar)
        progressContainer.addSubview(progressLabel)
        contentView.addSubview(progressContainer)
    }
    
    private func setupDetailsContainer() {
        detailsContainer.translatesAutoresizingMaskIntoConstraints = false
        detailsContainer.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        detailsContainer.layer.cornerRadius = 12
        detailsContainer.layer.borderWidth = 1
        detailsContainer.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        contentView.addSubview(detailsContainer)
        
        // Create detail items
        createDetailItems()
    }
    
    private func createDetailItems() {
        let detailData = [
            ("⏰", "Time Remaining", challengeData.formattedTimeRemaining),
            ("🎯", "Goal", challengeData.formattedGoal),
            ("🏆", "Reward", challengeData.formattedReward),
            ("👥", "Participants", "\(challengeData.participantCount)")
        ]
        
        var previousView: UIView? = nil
        
        for (icon, label, value) in detailData {
            let itemView = createDetailItemView(icon: icon, label: label, value: value)
            detailsContainer.addSubview(itemView)
            
            NSLayoutConstraint.activate([
                itemView.leadingAnchor.constraint(equalTo: detailsContainer.leadingAnchor, constant: 20),
                itemView.trailingAnchor.constraint(equalTo: detailsContainer.trailingAnchor, constant: -20),
                itemView.topAnchor.constraint(equalTo: previousView?.bottomAnchor ?? detailsContainer.topAnchor, constant: 16),
                itemView.heightAnchor.constraint(equalToConstant: 40)
            ])
            
            previousView = itemView
        }
        
        // Set container height
        if let lastView = previousView {
            detailsContainer.bottomAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 16).isActive = true
        }
    }
    
    private func createDetailItemView(icon: String, label: String, value: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let iconLabel = UILabel()
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        iconLabel.text = icon
        iconLabel.font = UIFont.systemFont(ofSize: 16)
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = label
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = IndustrialDesign.Colors.secondaryText
        
        let valueLabel = UILabel()
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        valueLabel.textColor = IndustrialDesign.Colors.primaryText
        valueLabel.textAlignment = .right
        
        container.addSubview(iconLabel)
        container.addSubview(titleLabel)
        container.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            iconLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconLabel.widthAnchor.constraint(equalToConstant: 30),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 16)
        ])
        
        return container
    }
    
    private func setupDescriptionContainer() {
        descriptionContainer.translatesAutoresizingMaskIntoConstraints = false
        descriptionContainer.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        descriptionContainer.layer.cornerRadius = 12
        descriptionContainer.layer.borderWidth = 1
        descriptionContainer.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        let descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = challengeData.description
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textColor = IndustrialDesign.Colors.primaryText
        descriptionLabel.numberOfLines = 0
        
        descriptionContainer.addSubview(descriptionLabel)
        contentView.addSubview(descriptionContainer)
        
        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: descriptionContainer.topAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: descriptionContainer.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: descriptionContainer.trailingAnchor, constant: -20),
            descriptionLabel.bottomAnchor.constraint(equalTo: descriptionContainer.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupParticipantsContainer() {
        participantsContainer.translatesAutoresizingMaskIntoConstraints = false
        participantsContainer.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        participantsContainer.layer.cornerRadius = 12
        participantsContainer.layer.borderWidth = 1
        participantsContainer.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "LEADERBOARD"
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.accentText
        titleLabel.letterSpacing = 1
        
        participantsContainer.addSubview(titleLabel)
        contentView.addSubview(participantsContainer)
        
        // Add sample leaderboard entries
        createLeaderboardEntries(titleLabel)
    }
    
    private func createLeaderboardEntries(_ titleLabel: UILabel) {
        let leaderboardData = [
            ("1", "You", challengeData.currentProgress, true),
            ("2", "Sarah M.", "8.2 km", false),
            ("3", "Mike T.", "7.5 km", false),
            ("4", "Jenny L.", "6.8 km", false)
        ]
        
        var previousView: UIView = titleLabel
        
        for (rank, name, progress, isCurrentUser) in leaderboardData {
            let entryView = createLeaderboardEntry(rank: rank, name: name, progress: progress, isCurrentUser: isCurrentUser)
            participantsContainer.addSubview(entryView)
            
            NSLayoutConstraint.activate([
                entryView.leadingAnchor.constraint(equalTo: participantsContainer.leadingAnchor, constant: 20),
                entryView.trailingAnchor.constraint(equalTo: participantsContainer.trailingAnchor, constant: -20),
                entryView.topAnchor.constraint(equalTo: previousView.bottomAnchor, constant: 12),
                entryView.heightAnchor.constraint(equalToConstant: 40)
            ])
            
            previousView = entryView
        }
        
        // Set container height
        participantsContainer.bottomAnchor.constraint(equalTo: previousView.bottomAnchor, constant: 20).isActive = true
    }
    
    private func createLeaderboardEntry(rank: String, name: String, progress: String, isCurrentUser: Bool) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        if isCurrentUser {
            container.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
            container.layer.cornerRadius = 8
        }
        
        let rankLabel = UILabel()
        rankLabel.translatesAutoresizingMaskIntoConstraints = false
        rankLabel.text = rank
        rankLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        rankLabel.textColor = rank == "1" ? IndustrialDesign.Colors.bitcoin : IndustrialDesign.Colors.primaryText
        rankLabel.textAlignment = .center
        
        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = name
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: isCurrentUser ? .semibold : .medium)
        nameLabel.textColor = isCurrentUser ? IndustrialDesign.Colors.bitcoin : IndustrialDesign.Colors.primaryText
        
        let progressLabel = UILabel()
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.text = progress
        progressLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        progressLabel.textColor = IndustrialDesign.Colors.primaryText
        progressLabel.textAlignment = .right
        
        container.addSubview(rankLabel)
        container.addSubview(nameLabel)
        container.addSubview(progressLabel)
        
        NSLayoutConstraint.activate([
            rankLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: isCurrentUser ? 12 : 0),
            rankLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            rankLabel.widthAnchor.constraint(equalToConstant: 30),
            
            nameLabel.leadingAnchor.constraint(equalTo: rankLabel.trailingAnchor, constant: 12),
            nameLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            progressLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: isCurrentUser ? -12 : 0),
            progressLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            progressLabel.leadingAnchor.constraint(greaterThanOrEqualTo: nameLabel.trailingAnchor, constant: 16)
        ])
        
        return container
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Header
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            headerView.heightAnchor.constraint(equalToConstant: 80),
            
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            backButton.topAnchor.constraint(equalTo: headerView.topAnchor),
            
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            
            // Challenge Icon
            challengeIconView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            challengeIconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            challengeIconView.widthAnchor.constraint(equalToConstant: 80),
            challengeIconView.heightAnchor.constraint(equalToConstant: 80),
            
            // Progress Container
            progressContainer.topAnchor.constraint(equalTo: challengeIconView.bottomAnchor, constant: 20),
            progressContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            progressContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            progressContainer.heightAnchor.constraint(equalToConstant: 80),
            
            progressBar.centerXAnchor.constraint(equalTo: progressContainer.centerXAnchor),
            progressBar.topAnchor.constraint(equalTo: progressContainer.topAnchor, constant: 20),
            progressBar.leadingAnchor.constraint(equalTo: progressContainer.leadingAnchor, constant: 20),
            progressBar.trailingAnchor.constraint(equalTo: progressContainer.trailingAnchor, constant: -20),
            progressBar.heightAnchor.constraint(equalToConstant: 12),
            
            progressLabel.centerXAnchor.constraint(equalTo: progressContainer.centerXAnchor),
            progressLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 8),
            progressLabel.leadingAnchor.constraint(equalTo: progressContainer.leadingAnchor, constant: 20),
            progressLabel.trailingAnchor.constraint(equalTo: progressContainer.trailingAnchor, constant: -20),
            
            // Details Container
            detailsContainer.topAnchor.constraint(equalTo: progressContainer.bottomAnchor, constant: 20),
            detailsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            detailsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            // Description Container
            descriptionContainer.topAnchor.constraint(equalTo: detailsContainer.bottomAnchor, constant: 20),
            descriptionContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            descriptionContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            // Participants Container
            participantsContainer.topAnchor.constraint(equalTo: descriptionContainer.bottomAnchor, constant: 20),
            participantsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            participantsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            participantsContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
            
            // Title label in participants container
            participantsContainer.subviews.first!.topAnchor.constraint(equalTo: participantsContainer.topAnchor, constant: 20),
            participantsContainer.subviews.first!.leadingAnchor.constraint(equalTo: participantsContainer.leadingAnchor, constant: 20)
        ])
    }
    
    private func configureWithChallengeData() {
        titleLabel.text = challengeData.title
        
        // Set progress
        progressBar.setProgress(challengeData.progress, animated: true)
        progressLabel.text = "\(Int(challengeData.progress * 100))% Complete - \(challengeData.currentProgress)"
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        print("🏆 ChallengeDetail: Back button tapped")
        navigationController?.popViewController(animated: true)
    }
}