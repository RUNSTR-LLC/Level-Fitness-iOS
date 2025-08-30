import UIKit

class TeamReviewStepViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let stepTitleLabel = UILabel()
    private let stepDescriptionLabel = UILabel()
    
    // Review sections
    private let teamInfoSection = UIView()
    private let metricsSection = UIView()
    private let leaderboardSection = UIView()
    private let finalNotesSection = UIView()
    
    // Team data reference
    private let teamData: TeamCreationData
    
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
        populateReviewData()
        
        print("✅ TeamReview: Step view loaded")
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        view.backgroundColor = UIColor.clear
        
        // Step header
        stepTitleLabel.text = "Review & Create"
        stepTitleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        stepTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        stepTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        stepDescriptionLabel.text = "Review your team configuration. Once created, your team will be live and ready for members to join!"
        stepDescriptionLabel.font = UIFont.systemFont(ofSize: 16)
        stepDescriptionLabel.textColor = IndustrialDesign.Colors.secondaryText
        stepDescriptionLabel.numberOfLines = 0
        stepDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        setupReviewSections()
        
        // Add to scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [stepTitleLabel, stepDescriptionLabel, teamInfoSection, metricsSection, leaderboardSection, finalNotesSection].forEach {
            contentView.addSubview($0)
        }
    }
    
    private func setupReviewSections() {
        // Team info section
        teamInfoSection.translatesAutoresizingMaskIntoConstraints = false
        teamInfoSection.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        teamInfoSection.layer.cornerRadius = 12
        teamInfoSection.layer.borderWidth = 1
        teamInfoSection.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        // Metrics section
        metricsSection.translatesAutoresizingMaskIntoConstraints = false
        metricsSection.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        metricsSection.layer.cornerRadius = 12
        metricsSection.layer.borderWidth = 1
        metricsSection.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        // Leaderboard section
        leaderboardSection.translatesAutoresizingMaskIntoConstraints = false
        leaderboardSection.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        leaderboardSection.layer.cornerRadius = 12
        leaderboardSection.layer.borderWidth = 1
        leaderboardSection.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        // Final notes section
        finalNotesSection.translatesAutoresizingMaskIntoConstraints = false
        finalNotesSection.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        finalNotesSection.layer.cornerRadius = 12
        finalNotesSection.layer.borderWidth = 1
        finalNotesSection.layer.borderColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 0.5).cgColor // Orange border for consistency
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
            
            // Team info section
            teamInfoSection.topAnchor.constraint(equalTo: stepDescriptionLabel.bottomAnchor, constant: 32),
            teamInfoSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            teamInfoSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            // Metrics section
            metricsSection.topAnchor.constraint(equalTo: teamInfoSection.bottomAnchor, constant: 16),
            metricsSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            metricsSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            // Leaderboard section
            leaderboardSection.topAnchor.constraint(equalTo: metricsSection.bottomAnchor, constant: 16),
            leaderboardSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            leaderboardSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            // Final notes section
            finalNotesSection.topAnchor.constraint(equalTo: leaderboardSection.bottomAnchor, constant: 16),
            finalNotesSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            finalNotesSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            finalNotesSection.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }
    
    private func populateReviewData() {
        // Team info section
        let teamInfoContent = createReviewSection(
            title: "Team Information",
            items: [
                ("Team Name", teamData.teamName.isEmpty ? "Not specified" : teamData.teamName),
                ("Description", teamData.description.isEmpty ? "None" : teamData.description),
                ("Monthly Price", "$1.99")
            ]
        )
        addContentToSection(teamInfoSection, content: teamInfoContent)
        
        // Metrics section
        let metricsContent = createReviewSection(
            title: "Tracking Metrics",
            items: [
                ("Selected Metrics", teamData.selectedMetrics.isEmpty ? "None selected" : teamData.selectedMetrics.joined(separator: ", "))
            ]
        )
        addContentToSection(metricsSection, content: metricsContent)
        
        // Leaderboard section
        let leaderboardContent = createReviewSection(
            title: "Leaderboard Configuration",
            items: [
                ("Ranking Method", teamData.leaderboardType.displayName),
                ("Reset Period", teamData.leaderboardPeriod.displayName)
            ]
        )
        addContentToSection(leaderboardSection, content: leaderboardContent)
        
        // Final notes section
        let finalNotesContent = createReviewSection(
            title: "Ready to Launch! 🚀",
            items: [
                ("Next Steps", "After creation, you'll get a QR code to share with potential members"),
                ("Team Management", "Access your team dashboard to view analytics and manage competitions"),
                ("Member Revenue", "You keep 100% of subscription revenue from your members")
            ],
            highlightColor: UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        )
        addContentToSection(finalNotesSection, content: finalNotesContent)
    }
    
    private func createReviewSection(title: String, items: [(String, String)], highlightColor: UIColor? = nil) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = highlightColor ?? IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)
        
        var previousView: UIView = titleLabel
        
        for (label, value) in items {
            let itemContainer = UIView()
            itemContainer.translatesAutoresizingMaskIntoConstraints = false
            
            let itemLabel = UILabel()
            itemLabel.text = label
            itemLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            itemLabel.textColor = IndustrialDesign.Colors.secondaryText
            itemLabel.translatesAutoresizingMaskIntoConstraints = false
            
            let valueLabel = UILabel()
            valueLabel.text = value
            valueLabel.font = UIFont.systemFont(ofSize: 14)
            valueLabel.textColor = IndustrialDesign.Colors.primaryText
            valueLabel.numberOfLines = 0
            valueLabel.translatesAutoresizingMaskIntoConstraints = false
            
            itemContainer.addSubview(itemLabel)
            itemContainer.addSubview(valueLabel)
            container.addSubview(itemContainer)
            
            NSLayoutConstraint.activate([
                itemContainer.topAnchor.constraint(equalTo: previousView.bottomAnchor, constant: 12),
                itemContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                itemContainer.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                
                itemLabel.topAnchor.constraint(equalTo: itemContainer.topAnchor),
                itemLabel.leadingAnchor.constraint(equalTo: itemContainer.leadingAnchor),
                itemLabel.trailingAnchor.constraint(equalTo: itemContainer.trailingAnchor),
                
                valueLabel.topAnchor.constraint(equalTo: itemLabel.bottomAnchor, constant: 4),
                valueLabel.leadingAnchor.constraint(equalTo: itemContainer.leadingAnchor),
                valueLabel.trailingAnchor.constraint(equalTo: itemContainer.trailingAnchor),
                valueLabel.bottomAnchor.constraint(equalTo: itemContainer.bottomAnchor)
            ])
            
            previousView = itemContainer
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            container.bottomAnchor.constraint(equalTo: previousView.bottomAnchor)
        ])
        
        return container
    }
    
    private func addContentToSection(_ section: UIView, content: UIView) {
        section.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: section.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: section.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: section.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: section.bottomAnchor, constant: -16)
        ])
    }
}