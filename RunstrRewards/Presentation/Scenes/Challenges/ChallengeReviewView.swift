import UIKit

protocol ChallengeReviewDelegate: AnyObject {
    func challengeReviewDidTapEdit(step: Int)
}

class ChallengeReviewView: UIView {
    
    // MARK: - Properties
    weak var delegate: ChallengeReviewDelegate?
    private var challengeData: ChallengeCreationData?
    private var teamData: TeamData?
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // Challenge overview card
    private let overviewContainer = UIView()
    private let challengeTypeLabel = UILabel()
    private let challengeDescriptionLabel = UILabel()
    private let durationLabel = UILabel()
    private let editOverviewButton = UIButton()
    
    // Opponents section
    private let opponentsContainer = UIView()
    private let opponentsTitleLabel = UILabel()
    private let opponentsCountLabel = UILabel()
    private let opponentsStackView = UIStackView()
    private let editOpponentsButton = UIButton()
    
    // Stakes section
    private let stakesContainer = UIView()
    private let stakesTitleLabel = UILabel()
    private let stakesAmountLabel = UILabel()
    private let totalParticipantsLabel = UILabel()
    private let totalPotLabel = UILabel()
    private let teamFeeLabel = UILabel()
    private let winnerPayoutLabel = UILabel()
    private let editStakesButton = UIButton()
    
    // Challenge message section
    private let messageContainer = UIView()
    private let messageTitleLabel = UILabel()
    private let messageLabel = UILabel()
    private let editMessageButton = UIButton()
    
    // Final confirmation
    private let confirmationContainer = UIView()
    private let confirmationIcon = UIImageView()
    private let confirmationLabel = UILabel()
    private let warningLabel = UILabel()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
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
        titleLabel.text = "Review Challenge"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        subtitleLabel.text = "Review all details before creating your challenge"
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = IndustrialDesign.Colors.secondaryText
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup sections
        setupOverviewSection()
        setupOpponentsSection()
        setupStakesSection()
        setupMessageSection()
        setupConfirmationSection()
        
        // Add to hierarchy
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(overviewContainer)
        contentView.addSubview(opponentsContainer)
        contentView.addSubview(stakesContainer)
        contentView.addSubview(messageContainer)
        contentView.addSubview(confirmationContainer)
    }
    
    private func setupOverviewSection() {
        overviewContainer.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.8)
        overviewContainer.layer.cornerRadius = 12
        overviewContainer.layer.borderWidth = 1
        overviewContainer.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        overviewContainer.translatesAutoresizingMaskIntoConstraints = false
        
        challengeTypeLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        challengeTypeLabel.textColor = IndustrialDesign.Colors.bitcoin
        challengeTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        challengeDescriptionLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        challengeDescriptionLabel.textColor = IndustrialDesign.Colors.secondaryText
        challengeDescriptionLabel.numberOfLines = 0
        challengeDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        durationLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        durationLabel.textColor = IndustrialDesign.Colors.primaryText
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        editOverviewButton.setTitle("Edit", for: .normal)
        editOverviewButton.setTitleColor(IndustrialDesign.Colors.bitcoin, for: .normal)
        editOverviewButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        editOverviewButton.translatesAutoresizingMaskIntoConstraints = false
        editOverviewButton.addTarget(self, action: #selector(editOverviewTapped), for: .touchUpInside)
        
        overviewContainer.addSubview(challengeTypeLabel)
        overviewContainer.addSubview(challengeDescriptionLabel)
        overviewContainer.addSubview(durationLabel)
        overviewContainer.addSubview(editOverviewButton)
    }
    
    private func setupOpponentsSection() {
        opponentsContainer.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.8)
        opponentsContainer.layer.cornerRadius = 12
        opponentsContainer.layer.borderWidth = 1
        opponentsContainer.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        opponentsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        opponentsTitleLabel.text = "Opponents"
        opponentsTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        opponentsTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        opponentsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        opponentsCountLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        opponentsCountLabel.textColor = IndustrialDesign.Colors.bitcoin
        opponentsCountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        opponentsStackView.axis = .vertical
        opponentsStackView.spacing = 8
        opponentsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        editOpponentsButton.setTitle("Edit", for: .normal)
        editOpponentsButton.setTitleColor(IndustrialDesign.Colors.bitcoin, for: .normal)
        editOpponentsButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        editOpponentsButton.translatesAutoresizingMaskIntoConstraints = false
        editOpponentsButton.addTarget(self, action: #selector(editOpponentsTapped), for: .touchUpInside)
        
        opponentsContainer.addSubview(opponentsTitleLabel)
        opponentsContainer.addSubview(opponentsCountLabel)
        opponentsContainer.addSubview(opponentsStackView)
        opponentsContainer.addSubview(editOpponentsButton)
    }
    
    private func setupStakesSection() {
        stakesContainer.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.8)
        stakesContainer.layer.cornerRadius = 12
        stakesContainer.layer.borderWidth = 1
        stakesContainer.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        stakesContainer.translatesAutoresizingMaskIntoConstraints = false
        
        stakesTitleLabel.text = "Stakes & Rewards"
        stakesTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        stakesTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        stakesTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        stakesAmountLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        stakesAmountLabel.textColor = IndustrialDesign.Colors.primaryText
        stakesAmountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        totalParticipantsLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        totalParticipantsLabel.textColor = IndustrialDesign.Colors.secondaryText
        totalParticipantsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        totalPotLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        totalPotLabel.textColor = IndustrialDesign.Colors.primaryText
        totalPotLabel.translatesAutoresizingMaskIntoConstraints = false
        
        teamFeeLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        teamFeeLabel.textColor = IndustrialDesign.Colors.secondaryText
        teamFeeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        winnerPayoutLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        winnerPayoutLabel.textColor = IndustrialDesign.Colors.bitcoin
        winnerPayoutLabel.translatesAutoresizingMaskIntoConstraints = false
        
        editStakesButton.setTitle("Edit", for: .normal)
        editStakesButton.setTitleColor(IndustrialDesign.Colors.bitcoin, for: .normal)
        editStakesButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        editStakesButton.translatesAutoresizingMaskIntoConstraints = false
        editStakesButton.addTarget(self, action: #selector(editStakesTapped), for: .touchUpInside)
        
        stakesContainer.addSubview(stakesTitleLabel)
        stakesContainer.addSubview(stakesAmountLabel)
        stakesContainer.addSubview(totalParticipantsLabel)
        stakesContainer.addSubview(totalPotLabel)
        stakesContainer.addSubview(teamFeeLabel)
        stakesContainer.addSubview(winnerPayoutLabel)
        stakesContainer.addSubview(editStakesButton)
    }
    
    private func setupMessageSection() {
        messageContainer.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.8)
        messageContainer.layer.cornerRadius = 12
        messageContainer.layer.borderWidth = 1
        messageContainer.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        messageContainer.translatesAutoresizingMaskIntoConstraints = false
        
        messageTitleLabel.text = "Challenge Message"
        messageTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        messageTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        messageTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        messageLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        messageLabel.textColor = IndustrialDesign.Colors.primaryText
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        editMessageButton.setTitle("Edit", for: .normal)
        editMessageButton.setTitleColor(IndustrialDesign.Colors.bitcoin, for: .normal)
        editMessageButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        editMessageButton.translatesAutoresizingMaskIntoConstraints = false
        editMessageButton.addTarget(self, action: #selector(editMessageTapped), for: .touchUpInside)
        
        messageContainer.addSubview(messageTitleLabel)
        messageContainer.addSubview(messageLabel)
        messageContainer.addSubview(editMessageButton)
    }
    
    private func setupConfirmationSection() {
        confirmationContainer.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.9)
        confirmationContainer.layer.cornerRadius = 12
        confirmationContainer.layer.borderWidth = 2
        confirmationContainer.layer.borderColor = IndustrialDesign.Colors.bitcoin.withAlphaComponent(0.5).cgColor
        confirmationContainer.translatesAutoresizingMaskIntoConstraints = false
        
        confirmationIcon.image = UIImage(systemName: "bolt.circle.fill")
        confirmationIcon.tintColor = IndustrialDesign.Colors.bitcoin
        confirmationIcon.contentMode = .scaleAspectFit
        confirmationIcon.translatesAutoresizingMaskIntoConstraints = false
        
        confirmationLabel.text = "Ready to create challenge!"
        confirmationLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        confirmationLabel.textColor = IndustrialDesign.Colors.bitcoin
        confirmationLabel.textAlignment = .center
        confirmationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        warningLabel.text = "Your opponents will be notified and can accept or decline this challenge."
        warningLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        warningLabel.textColor = IndustrialDesign.Colors.secondaryText
        warningLabel.numberOfLines = 0
        warningLabel.textAlignment = .center
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        
        confirmationContainer.addSubview(confirmationIcon)
        confirmationContainer.addSubview(confirmationLabel)
        confirmationContainer.addSubview(warningLabel)
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
            
            // Overview container
            overviewContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            overviewContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            overviewContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            challengeTypeLabel.topAnchor.constraint(equalTo: overviewContainer.topAnchor, constant: 16),
            challengeTypeLabel.leadingAnchor.constraint(equalTo: overviewContainer.leadingAnchor, constant: 16),
            challengeTypeLabel.trailingAnchor.constraint(equalTo: editOverviewButton.leadingAnchor, constant: -8),
            
            editOverviewButton.topAnchor.constraint(equalTo: overviewContainer.topAnchor, constant: 16),
            editOverviewButton.trailingAnchor.constraint(equalTo: overviewContainer.trailingAnchor, constant: -16),
            
            challengeDescriptionLabel.topAnchor.constraint(equalTo: challengeTypeLabel.bottomAnchor, constant: 4),
            challengeDescriptionLabel.leadingAnchor.constraint(equalTo: overviewContainer.leadingAnchor, constant: 16),
            challengeDescriptionLabel.trailingAnchor.constraint(equalTo: overviewContainer.trailingAnchor, constant: -16),
            
            durationLabel.topAnchor.constraint(equalTo: challengeDescriptionLabel.bottomAnchor, constant: 8),
            durationLabel.leadingAnchor.constraint(equalTo: overviewContainer.leadingAnchor, constant: 16),
            durationLabel.trailingAnchor.constraint(equalTo: overviewContainer.trailingAnchor, constant: -16),
            durationLabel.bottomAnchor.constraint(equalTo: overviewContainer.bottomAnchor, constant: -16),
            
            // Opponents container
            opponentsContainer.topAnchor.constraint(equalTo: overviewContainer.bottomAnchor, constant: 12),
            opponentsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            opponentsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            opponentsTitleLabel.topAnchor.constraint(equalTo: opponentsContainer.topAnchor, constant: 16),
            opponentsTitleLabel.leadingAnchor.constraint(equalTo: opponentsContainer.leadingAnchor, constant: 16),
            opponentsTitleLabel.trailingAnchor.constraint(equalTo: editOpponentsButton.leadingAnchor, constant: -8),
            
            editOpponentsButton.topAnchor.constraint(equalTo: opponentsContainer.topAnchor, constant: 16),
            editOpponentsButton.trailingAnchor.constraint(equalTo: opponentsContainer.trailingAnchor, constant: -16),
            
            opponentsCountLabel.topAnchor.constraint(equalTo: opponentsTitleLabel.bottomAnchor, constant: 4),
            opponentsCountLabel.leadingAnchor.constraint(equalTo: opponentsContainer.leadingAnchor, constant: 16),
            opponentsCountLabel.trailingAnchor.constraint(equalTo: opponentsContainer.trailingAnchor, constant: -16),
            
            opponentsStackView.topAnchor.constraint(equalTo: opponentsCountLabel.bottomAnchor, constant: 8),
            opponentsStackView.leadingAnchor.constraint(equalTo: opponentsContainer.leadingAnchor, constant: 16),
            opponentsStackView.trailingAnchor.constraint(equalTo: opponentsContainer.trailingAnchor, constant: -16),
            opponentsStackView.bottomAnchor.constraint(equalTo: opponentsContainer.bottomAnchor, constant: -16),
            
            // Stakes container
            stakesContainer.topAnchor.constraint(equalTo: opponentsContainer.bottomAnchor, constant: 12),
            stakesContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stakesContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            stakesTitleLabel.topAnchor.constraint(equalTo: stakesContainer.topAnchor, constant: 16),
            stakesTitleLabel.leadingAnchor.constraint(equalTo: stakesContainer.leadingAnchor, constant: 16),
            stakesTitleLabel.trailingAnchor.constraint(equalTo: editStakesButton.leadingAnchor, constant: -8),
            
            editStakesButton.topAnchor.constraint(equalTo: stakesContainer.topAnchor, constant: 16),
            editStakesButton.trailingAnchor.constraint(equalTo: stakesContainer.trailingAnchor, constant: -16),
            
            stakesAmountLabel.topAnchor.constraint(equalTo: stakesTitleLabel.bottomAnchor, constant: 8),
            stakesAmountLabel.leadingAnchor.constraint(equalTo: stakesContainer.leadingAnchor, constant: 16),
            stakesAmountLabel.trailingAnchor.constraint(equalTo: stakesContainer.trailingAnchor, constant: -16),
            
            totalParticipantsLabel.topAnchor.constraint(equalTo: stakesAmountLabel.bottomAnchor, constant: 4),
            totalParticipantsLabel.leadingAnchor.constraint(equalTo: stakesContainer.leadingAnchor, constant: 16),
            totalParticipantsLabel.trailingAnchor.constraint(equalTo: stakesContainer.trailingAnchor, constant: -16),
            
            totalPotLabel.topAnchor.constraint(equalTo: totalParticipantsLabel.bottomAnchor, constant: 4),
            totalPotLabel.leadingAnchor.constraint(equalTo: stakesContainer.leadingAnchor, constant: 16),
            totalPotLabel.trailingAnchor.constraint(equalTo: stakesContainer.trailingAnchor, constant: -16),
            
            teamFeeLabel.topAnchor.constraint(equalTo: totalPotLabel.bottomAnchor, constant: 4),
            teamFeeLabel.leadingAnchor.constraint(equalTo: stakesContainer.leadingAnchor, constant: 16),
            teamFeeLabel.trailingAnchor.constraint(equalTo: stakesContainer.trailingAnchor, constant: -16),
            
            winnerPayoutLabel.topAnchor.constraint(equalTo: teamFeeLabel.bottomAnchor, constant: 8),
            winnerPayoutLabel.leadingAnchor.constraint(equalTo: stakesContainer.leadingAnchor, constant: 16),
            winnerPayoutLabel.trailingAnchor.constraint(equalTo: stakesContainer.trailingAnchor, constant: -16),
            winnerPayoutLabel.bottomAnchor.constraint(equalTo: stakesContainer.bottomAnchor, constant: -16),
            
            // Message container
            messageContainer.topAnchor.constraint(equalTo: stakesContainer.bottomAnchor, constant: 12),
            messageContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            messageContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            messageTitleLabel.topAnchor.constraint(equalTo: messageContainer.topAnchor, constant: 16),
            messageTitleLabel.leadingAnchor.constraint(equalTo: messageContainer.leadingAnchor, constant: 16),
            messageTitleLabel.trailingAnchor.constraint(equalTo: editMessageButton.leadingAnchor, constant: -8),
            
            editMessageButton.topAnchor.constraint(equalTo: messageContainer.topAnchor, constant: 16),
            editMessageButton.trailingAnchor.constraint(equalTo: messageContainer.trailingAnchor, constant: -16),
            
            messageLabel.topAnchor.constraint(equalTo: messageTitleLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: messageContainer.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: messageContainer.trailingAnchor, constant: -16),
            messageLabel.bottomAnchor.constraint(equalTo: messageContainer.bottomAnchor, constant: -16),
            
            // Confirmation container
            confirmationContainer.topAnchor.constraint(equalTo: messageContainer.bottomAnchor, constant: 20),
            confirmationContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            confirmationContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            confirmationContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            confirmationIcon.topAnchor.constraint(equalTo: confirmationContainer.topAnchor, constant: 20),
            confirmationIcon.centerXAnchor.constraint(equalTo: confirmationContainer.centerXAnchor),
            confirmationIcon.widthAnchor.constraint(equalToConstant: 40),
            confirmationIcon.heightAnchor.constraint(equalToConstant: 40),
            
            confirmationLabel.topAnchor.constraint(equalTo: confirmationIcon.bottomAnchor, constant: 12),
            confirmationLabel.leadingAnchor.constraint(equalTo: confirmationContainer.leadingAnchor, constant: 16),
            confirmationLabel.trailingAnchor.constraint(equalTo: confirmationContainer.trailingAnchor, constant: -16),
            
            warningLabel.topAnchor.constraint(equalTo: confirmationLabel.bottomAnchor, constant: 8),
            warningLabel.leadingAnchor.constraint(equalTo: confirmationContainer.leadingAnchor, constant: 16),
            warningLabel.trailingAnchor.constraint(equalTo: confirmationContainer.trailingAnchor, constant: -16),
            warningLabel.bottomAnchor.constraint(equalTo: confirmationContainer.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with challengeData: ChallengeCreationData, teamData: TeamData) {
        self.challengeData = challengeData
        self.teamData = teamData
        
        updateOverviewSection()
        updateOpponentsSection()
        updateStakesSection()
        updateMessageSection()
    }
    
    private func updateOverviewSection() {
        guard let challengeData = challengeData else { return }
        
        challengeTypeLabel.text = challengeData.challengeType.displayName
        challengeDescriptionLabel.text = challengeData.challengeType.description
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        durationLabel.text = "From \(dateFormatter.string(from: challengeData.startDate)) to \(dateFormatter.string(from: challengeData.endDate))"
    }
    
    private func updateOpponentsSection() {
        guard let challengeData = challengeData else { return }
        
        let count = challengeData.selectedOpponents.count
        opponentsCountLabel.text = "\(count) opponent\(count == 1 ? "" : "s") selected"
        
        // Clear existing opponent views
        opponentsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add opponent views
        for opponent in challengeData.selectedOpponents {
            let opponentView = createOpponentView(for: opponent)
            opponentsStackView.addArrangedSubview(opponentView)
        }
    }
    
    private func createOpponentView(for opponent: TeamMemberWithProfile) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0)
        container.layer.cornerRadius = 8
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let nameLabel = UILabel()
        nameLabel.text = opponent.profile.username
        nameLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        nameLabel.textColor = IndustrialDesign.Colors.primaryText
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let roleLabel = UILabel()
        roleLabel.text = opponent.role.capitalized
        roleLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        roleLabel.textColor = IndustrialDesign.Colors.secondaryText
        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(nameLabel)
        container.addSubview(roleLabel)
        
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 50),
            
            nameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            
            roleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            roleLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            roleLabel.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -8)
        ])
        
        return container
    }
    
    private func updateStakesSection() {
        guard let challengeData = challengeData else { return }
        
        if challengeData.stakeAmount > 0 {
            stakesAmountLabel.text = "\(challengeData.stakeAmount.formatted()) sats per person"
            
            let participantCount = challengeData.selectedOpponents.count + 1
            totalParticipantsLabel.text = "\(participantCount) total participants"
            
            let totalPot = challengeData.stakeAmount * participantCount
            totalPotLabel.text = "Total pot: \(totalPot.formatted()) sats"
            
            let teamFeeAmount = challengeData.teamFeeAmount
            teamFeeLabel.text = "Team fee (\(challengeData.teamArbitrationFee)%): \(teamFeeAmount.formatted()) sats"
            
            let winnerPayout = challengeData.winnerPayout
            winnerPayoutLabel.text = "Winner gets: \(winnerPayout.formatted()) sats"
            
            stakesContainer.isHidden = false
        } else {
            stakesAmountLabel.text = "No stakes - this is a free challenge"
            totalParticipantsLabel.text = ""
            totalPotLabel.text = ""
            teamFeeLabel.text = ""
            winnerPayoutLabel.text = "Bragging rights only! 🏆"
            
            stakesContainer.isHidden = false
        }
    }
    
    private func updateMessageSection() {
        guard let challengeData = challengeData else { return }
        
        if challengeData.challengeMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messageLabel.text = "No challenge message"
            messageLabel.textColor = IndustrialDesign.Colors.secondaryText
        } else {
            messageLabel.text = "\"" + challengeData.challengeMessage + "\""
            messageLabel.textColor = IndustrialDesign.Colors.primaryText
        }
    }
    
    // MARK: - Actions
    
    @objc private func editOverviewTapped() {
        delegate?.challengeReviewDidTapEdit(step: 1) // Challenge type step
    }
    
    @objc private func editOpponentsTapped() {
        delegate?.challengeReviewDidTapEdit(step: 0) // Opponent selection step
    }
    
    @objc private func editStakesTapped() {
        delegate?.challengeReviewDidTapEdit(step: 2) // Stakes configuration step
    }
    
    @objc private func editMessageTapped() {
        delegate?.challengeReviewDidTapEdit(step: 1) // Challenge type step (message is part of it)
    }
}

// MARK: - Int Extension for Formatting

private extension Int {
    func formatted() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? String(self)
    }
}