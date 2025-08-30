import UIKit

class LeagueReviewStepViewController: UIViewController {
    
    // MARK: - Properties
    private let leagueData: LeagueCreationData
    private let teamData: TeamData
    private let teamWalletBalance: Int
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header Section
    private let headerLabel = UILabel()
    private let warningContainer = UIView()
    private let warningLabel = UILabel()
    
    // League Info Section
    private let leagueInfoContainer = UIView()
    private let leagueNameLabel = UILabel()
    private let leagueNameValue = UILabel()
    private let durationLabel = UILabel()
    private let durationValue = UILabel()
    private let typeLabel = UILabel()
    private let typeValue = UILabel()
    
    // Prize Pool Section
    private let prizePoolContainer = UIView()
    private let prizePoolTitle = UILabel()
    private let prizePoolAmount = UILabel()
    private let payoutStructureLabel = UILabel()
    private let payoutStructureValue = UILabel()
    
    // Team Info Section
    private let teamInfoContainer = UIView()
    private let teamNameLabel = UILabel()
    private let teamNameValue = UILabel()
    private let memberCountLabel = UILabel()
    private let memberCountValue = UILabel()
    
    // MARK: - Initialization
    
    init(leagueData: LeagueCreationData, teamData: TeamData, teamWalletBalance: Int) {
        self.leagueData = leagueData
        self.teamData = teamData
        self.teamWalletBalance = teamWalletBalance
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupConstraints()
        populateData()
    }
    
    // MARK: - Setup Methods
    
    private func setupView() {
        view.backgroundColor = UIColor.clear
        
        // Scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Header
        headerLabel.text = "REVIEW & CREATE"
        headerLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        headerLabel.textColor = IndustrialDesign.Colors.accentText
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Warning container
        warningContainer.backgroundColor = UIColor(red: 0.15, green: 0.1, blue: 0.05, alpha: 0.9)
        warningContainer.layer.cornerRadius = 12
        warningContainer.layer.borderWidth = 1
        warningContainer.layer.borderColor = IndustrialDesign.Colors.bitcoin.cgColor
        warningContainer.translatesAutoresizingMaskIntoConstraints = false
        
        warningLabel.text = "⚠️ Prizes will be paid from your team's Bitcoin wallet at the end of the month"
        warningLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        warningLabel.textColor = IndustrialDesign.Colors.bitcoin
        warningLabel.numberOfLines = 0
        warningLabel.textAlignment = .center
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // League info container
        leagueInfoContainer.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.9)
        leagueInfoContainer.layer.cornerRadius = 12
        leagueInfoContainer.layer.borderWidth = 1
        leagueInfoContainer.layer.borderColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        leagueInfoContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Prize pool container
        prizePoolContainer.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.9)
        prizePoolContainer.layer.cornerRadius = 12
        prizePoolContainer.layer.borderWidth = 1
        prizePoolContainer.layer.borderColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        prizePoolContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Team info container
        teamInfoContainer.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.9)
        teamInfoContainer.layer.cornerRadius = 12
        teamInfoContainer.layer.borderWidth = 1
        teamInfoContainer.layer.borderColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        teamInfoContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup all labels
        setupLabels()
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(headerLabel)
        contentView.addSubview(warningContainer)
        warningContainer.addSubview(warningLabel)
        
        contentView.addSubview(leagueInfoContainer)
        leagueInfoContainer.addSubview(leagueNameLabel)
        leagueInfoContainer.addSubview(leagueNameValue)
        leagueInfoContainer.addSubview(durationLabel)
        leagueInfoContainer.addSubview(durationValue)
        leagueInfoContainer.addSubview(typeLabel)
        leagueInfoContainer.addSubview(typeValue)
        
        contentView.addSubview(prizePoolContainer)
        prizePoolContainer.addSubview(prizePoolTitle)
        prizePoolContainer.addSubview(prizePoolAmount)
        prizePoolContainer.addSubview(payoutStructureLabel)
        prizePoolContainer.addSubview(payoutStructureValue)
        
        contentView.addSubview(teamInfoContainer)
        teamInfoContainer.addSubview(teamNameLabel)
        teamInfoContainer.addSubview(teamNameValue)
        teamInfoContainer.addSubview(memberCountLabel)
        teamInfoContainer.addSubview(memberCountValue)
    }
    
    private func setupLabels() {
        // League info labels
        leagueNameLabel.text = "League Name:"
        leagueNameLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        leagueNameLabel.textColor = IndustrialDesign.Colors.secondaryText
        leagueNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        leagueNameValue.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        leagueNameValue.textColor = IndustrialDesign.Colors.primaryText
        leagueNameValue.numberOfLines = 0
        leagueNameValue.translatesAutoresizingMaskIntoConstraints = false
        
        durationLabel.text = "Duration:"
        durationLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        durationLabel.textColor = IndustrialDesign.Colors.secondaryText
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        durationValue.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        durationValue.textColor = IndustrialDesign.Colors.primaryText
        durationValue.translatesAutoresizingMaskIntoConstraints = false
        
        typeLabel.text = "Type:"
        typeLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        typeLabel.textColor = IndustrialDesign.Colors.secondaryText
        typeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        typeValue.text = "Distance Competition"
        typeValue.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        typeValue.textColor = IndustrialDesign.Colors.primaryText
        typeValue.translatesAutoresizingMaskIntoConstraints = false
        
        // Prize pool labels
        prizePoolTitle.text = "Prize Pool"
        prizePoolTitle.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        prizePoolTitle.textColor = IndustrialDesign.Colors.accentText
        prizePoolTitle.translatesAutoresizingMaskIntoConstraints = false
        
        prizePoolAmount.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        prizePoolAmount.textColor = IndustrialDesign.Colors.bitcoin
        prizePoolAmount.textAlignment = .center
        prizePoolAmount.translatesAutoresizingMaskIntoConstraints = false
        
        payoutStructureLabel.text = "Distribution:"
        payoutStructureLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        payoutStructureLabel.textColor = IndustrialDesign.Colors.secondaryText
        payoutStructureLabel.translatesAutoresizingMaskIntoConstraints = false
        
        payoutStructureValue.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        payoutStructureValue.textColor = IndustrialDesign.Colors.primaryText
        payoutStructureValue.numberOfLines = 0
        payoutStructureValue.translatesAutoresizingMaskIntoConstraints = false
        
        // Team info labels
        teamNameLabel.text = "Team:"
        teamNameLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        teamNameLabel.textColor = IndustrialDesign.Colors.secondaryText
        teamNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        teamNameValue.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        teamNameValue.textColor = IndustrialDesign.Colors.primaryText
        teamNameValue.translatesAutoresizingMaskIntoConstraints = false
        
        memberCountLabel.text = "Members:"
        memberCountLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        memberCountLabel.textColor = IndustrialDesign.Colors.secondaryText
        memberCountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        memberCountValue.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        memberCountValue.textColor = IndustrialDesign.Colors.primaryText
        memberCountValue.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Header
            headerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Warning container
            warningContainer.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 16),
            warningContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            warningContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            warningLabel.topAnchor.constraint(equalTo: warningContainer.topAnchor, constant: 12),
            warningLabel.leadingAnchor.constraint(equalTo: warningContainer.leadingAnchor, constant: 16),
            warningLabel.trailingAnchor.constraint(equalTo: warningContainer.trailingAnchor, constant: -16),
            warningLabel.bottomAnchor.constraint(equalTo: warningContainer.bottomAnchor, constant: -12),
            
            // League info container
            leagueInfoContainer.topAnchor.constraint(equalTo: warningContainer.bottomAnchor, constant: 20),
            leagueInfoContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            leagueInfoContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // League info content
            leagueNameLabel.topAnchor.constraint(equalTo: leagueInfoContainer.topAnchor, constant: 16),
            leagueNameLabel.leadingAnchor.constraint(equalTo: leagueInfoContainer.leadingAnchor, constant: 16),
            leagueNameLabel.widthAnchor.constraint(equalToConstant: 100),
            
            leagueNameValue.topAnchor.constraint(equalTo: leagueInfoContainer.topAnchor, constant: 16),
            leagueNameValue.leadingAnchor.constraint(equalTo: leagueNameLabel.trailingAnchor, constant: 16),
            leagueNameValue.trailingAnchor.constraint(equalTo: leagueInfoContainer.trailingAnchor, constant: -16),
            
            durationLabel.topAnchor.constraint(equalTo: leagueNameValue.bottomAnchor, constant: 12),
            durationLabel.leadingAnchor.constraint(equalTo: leagueInfoContainer.leadingAnchor, constant: 16),
            durationLabel.widthAnchor.constraint(equalToConstant: 100),
            
            durationValue.topAnchor.constraint(equalTo: leagueNameValue.bottomAnchor, constant: 12),
            durationValue.leadingAnchor.constraint(equalTo: durationLabel.trailingAnchor, constant: 16),
            durationValue.trailingAnchor.constraint(equalTo: leagueInfoContainer.trailingAnchor, constant: -16),
            
            typeLabel.topAnchor.constraint(equalTo: durationValue.bottomAnchor, constant: 12),
            typeLabel.leadingAnchor.constraint(equalTo: leagueInfoContainer.leadingAnchor, constant: 16),
            typeLabel.widthAnchor.constraint(equalToConstant: 100),
            
            typeValue.topAnchor.constraint(equalTo: durationValue.bottomAnchor, constant: 12),
            typeValue.leadingAnchor.constraint(equalTo: typeLabel.trailingAnchor, constant: 16),
            typeValue.trailingAnchor.constraint(equalTo: leagueInfoContainer.trailingAnchor, constant: -16),
            typeValue.bottomAnchor.constraint(equalTo: leagueInfoContainer.bottomAnchor, constant: -16),
            
            // Prize pool container
            prizePoolContainer.topAnchor.constraint(equalTo: leagueInfoContainer.bottomAnchor, constant: 16),
            prizePoolContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            prizePoolContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Prize pool content
            prizePoolTitle.topAnchor.constraint(equalTo: prizePoolContainer.topAnchor, constant: 16),
            prizePoolTitle.centerXAnchor.constraint(equalTo: prizePoolContainer.centerXAnchor),
            
            prizePoolAmount.topAnchor.constraint(equalTo: prizePoolTitle.bottomAnchor, constant: 8),
            prizePoolAmount.leadingAnchor.constraint(equalTo: prizePoolContainer.leadingAnchor, constant: 16),
            prizePoolAmount.trailingAnchor.constraint(equalTo: prizePoolContainer.trailingAnchor, constant: -16),
            
            payoutStructureLabel.topAnchor.constraint(equalTo: prizePoolAmount.bottomAnchor, constant: 16),
            payoutStructureLabel.leadingAnchor.constraint(equalTo: prizePoolContainer.leadingAnchor, constant: 16),
            payoutStructureLabel.widthAnchor.constraint(equalToConstant: 100),
            
            payoutStructureValue.topAnchor.constraint(equalTo: prizePoolAmount.bottomAnchor, constant: 16),
            payoutStructureValue.leadingAnchor.constraint(equalTo: payoutStructureLabel.trailingAnchor, constant: 16),
            payoutStructureValue.trailingAnchor.constraint(equalTo: prizePoolContainer.trailingAnchor, constant: -16),
            payoutStructureValue.bottomAnchor.constraint(equalTo: prizePoolContainer.bottomAnchor, constant: -16),
            
            // Team info container
            teamInfoContainer.topAnchor.constraint(equalTo: prizePoolContainer.bottomAnchor, constant: 16),
            teamInfoContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            teamInfoContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            teamInfoContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            // Team info content
            teamNameLabel.topAnchor.constraint(equalTo: teamInfoContainer.topAnchor, constant: 16),
            teamNameLabel.leadingAnchor.constraint(equalTo: teamInfoContainer.leadingAnchor, constant: 16),
            teamNameLabel.widthAnchor.constraint(equalToConstant: 100),
            
            teamNameValue.topAnchor.constraint(equalTo: teamInfoContainer.topAnchor, constant: 16),
            teamNameValue.leadingAnchor.constraint(equalTo: teamNameLabel.trailingAnchor, constant: 16),
            teamNameValue.trailingAnchor.constraint(equalTo: teamInfoContainer.trailingAnchor, constant: -16),
            
            memberCountLabel.topAnchor.constraint(equalTo: teamNameValue.bottomAnchor, constant: 12),
            memberCountLabel.leadingAnchor.constraint(equalTo: teamInfoContainer.leadingAnchor, constant: 16),
            memberCountLabel.widthAnchor.constraint(equalToConstant: 100),
            
            memberCountValue.topAnchor.constraint(equalTo: teamNameValue.bottomAnchor, constant: 12),
            memberCountValue.leadingAnchor.constraint(equalTo: memberCountLabel.trailingAnchor, constant: 16),
            memberCountValue.trailingAnchor.constraint(equalTo: teamInfoContainer.trailingAnchor, constant: -16),
            memberCountValue.bottomAnchor.constraint(equalTo: teamInfoContainer.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Helper Methods
    
    private func populateData() {
        // League info
        leagueNameValue.text = leagueData.leagueName
        
        // Generate duration for current month
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        durationValue.text = "\(formatter.string(from: startOfMonth)) - \(formatter.string(from: endOfMonth))"
        
        // Prize pool
        let btcAmount = Double(teamWalletBalance) / 100_000_000.0
        prizePoolAmount.text = "₿\(String(format: "%.6f", btcAmount))"
        payoutStructureValue.text = leagueData.payoutType.description
        
        // Team info
        teamNameValue.text = teamData.name
        memberCountValue.text = "\(teamData.members)"
    }
}