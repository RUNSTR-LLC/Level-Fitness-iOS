import UIKit

protocol TeamMembersListViewDelegate: AnyObject {
    func didTapInviteMembers()
    func didTapMember(_ member: TeamMemberWithProfile)
    func didTapViewAllMembers()
}

class TeamMembersListView: UIView {
    
    // MARK: - Properties
    weak var delegate: TeamMembersListViewDelegate?
    private var members: [TeamMemberWithProfile] = []
    private var isTeamOwner: Bool = false
    
    // MARK: - UI Components
    private let titleLabel = UILabel()
    private let viewAllButton = UIButton(type: .custom)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    // Members container
    private let membersContainer = UIView()
    private var memberViews: [TeamMemberView] = []
    
    // Invite section (only visible to team owners)
    private let inviteSection = UIView()
    private let inviteButton = UIButton(type: .custom)
    
    // Empty state
    private let emptyStateView = UIView()
    private let emptyStateLabel = UILabel()
    private let emptyStateDescription = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        showEmptyState()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        // Title section
        titleLabel.text = "Team Members"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // View all button
        viewAllButton.setTitle("View All", for: .normal)
        viewAllButton.setTitleColor(UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0), for: .normal)
        viewAllButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        viewAllButton.translatesAutoresizingMaskIntoConstraints = false
        viewAllButton.addTarget(self, action: #selector(viewAllTapped), for: .touchUpInside)
        
        // Loading indicator
        loadingIndicator.color = IndustrialDesign.Colors.secondaryText
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        
        // Members container
        membersContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Invite section
        setupInviteSection()
        
        // Empty state
        setupEmptyState()
        
        addSubview(titleLabel)
        addSubview(viewAllButton)
        addSubview(loadingIndicator)
        addSubview(membersContainer)
        addSubview(inviteSection)
        addSubview(emptyStateView)
        
        // Add bolt decoration
        DispatchQueue.main.async {
            self.addBoltDecoration()
        }
    }
    
    private func setupInviteSection() {
        inviteSection.translatesAutoresizingMaskIntoConstraints = false
        inviteSection.isHidden = true // Hidden by default
        
        inviteButton.setTitle("+ Invite Members", for: .normal)
        inviteButton.setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
        inviteButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        inviteButton.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)
        inviteButton.layer.cornerRadius = 8
        inviteButton.layer.borderWidth = 1
        inviteButton.layer.borderColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0).cgColor
        // Note: iOS doesn't support native dashed borders on CALayer
        inviteButton.translatesAutoresizingMaskIntoConstraints = false
        inviteButton.addTarget(self, action: #selector(inviteTapped), for: .touchUpInside)
        
        inviteSection.addSubview(inviteButton)
    }
    
    private func setupEmptyState() {
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.isHidden = false
        
        emptyStateLabel.text = "No Members Yet"
        emptyStateLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        emptyStateLabel.textColor = IndustrialDesign.Colors.primaryText
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        emptyStateDescription.text = "Invite members to join your team and start competing together"
        emptyStateDescription.font = UIFont.systemFont(ofSize: 14)
        emptyStateDescription.textColor = IndustrialDesign.Colors.secondaryText
        emptyStateDescription.textAlignment = .center
        emptyStateDescription.numberOfLines = 0
        emptyStateDescription.translatesAutoresizingMaskIntoConstraints = false
        
        emptyStateView.addSubview(emptyStateLabel)
        emptyStateView.addSubview(emptyStateDescription)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Title and view all button
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            
            viewAllButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            viewAllButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            loadingIndicator.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            loadingIndicator.centerXAnchor.constraint(equalTo: viewAllButton.centerXAnchor),
            
            // Members container
            membersContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            membersContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            membersContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            // Invite section
            inviteSection.topAnchor.constraint(equalTo: membersContainer.bottomAnchor, constant: 8),
            inviteSection.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            inviteSection.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            inviteSection.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            inviteSection.heightAnchor.constraint(equalToConstant: 44),
            
            inviteButton.topAnchor.constraint(equalTo: inviteSection.topAnchor),
            inviteButton.leadingAnchor.constraint(equalTo: inviteSection.leadingAnchor),
            inviteButton.trailingAnchor.constraint(equalTo: inviteSection.trailingAnchor),
            inviteButton.bottomAnchor.constraint(equalTo: inviteSection.bottomAnchor),
            
            // Empty state
            emptyStateView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            emptyStateView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            emptyStateView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            emptyStateView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateView.topAnchor, constant: 20),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            
            emptyStateDescription.topAnchor.constraint(equalTo: emptyStateLabel.bottomAnchor, constant: 8),
            emptyStateDescription.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptyStateDescription.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            emptyStateDescription.bottomAnchor.constraint(lessThanOrEqualTo: emptyStateView.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Public Methods
    
    func configure(with members: [TeamMemberWithProfile], isTeamOwner: Bool = false) {
        print("🏗️ TeamMembersListView: Configuring with \(members.count) members, isTeamOwner: \(isTeamOwner)")
        
        self.members = members
        self.isTeamOwner = isTeamOwner
        
        if members.isEmpty {
            print("🏗️ TeamMembersListView: No members found - showing empty state")
            showEmptyState()
        } else {
            print("🏗️ TeamMembersListView: \(members.count) members found - showing members data")
            showMembersData()
            createMemberViews()
        }
        
        // Show/hide invite section based on ownership
        inviteSection.isHidden = !isTeamOwner
        updateViewAllButtonVisibility()
    }
    
    func showLoading() {
        viewAllButton.isHidden = true
        loadingIndicator.startAnimating()
        emptyStateView.isHidden = true
        membersContainer.isHidden = true
        inviteSection.isHidden = true
    }
    
    func hideLoading() {
        viewAllButton.isHidden = false
        loadingIndicator.stopAnimating()
    }
    
    func showEmptyState() {
        emptyStateView.isHidden = false
        membersContainer.isHidden = true
        hideLoading()
        updateViewAllButtonVisibility()
    }
    
    func showMembersData() {
        emptyStateView.isHidden = true
        membersContainer.isHidden = false
        hideLoading()
        updateViewAllButtonVisibility()
    }
    
    // MARK: - Private Methods
    
    private func createMemberViews() {
        // Clear existing member views
        memberViews.forEach { $0.removeFromSuperview() }
        memberViews.removeAll()
        
        // Show up to 6 members in a 2x3 grid
        let membersToShow = Array(members.prefix(6))
        
        print("🏗️ TeamMembersListView: Creating views for \(membersToShow.count) members")
        
        for (index, member) in membersToShow.enumerated() {
            print("🏗️ TeamMembersListView: Member \(index): \(member.profile.id), Role: \(member.role)")
            
            let memberView = TeamMemberView(member: member)
            memberView.translatesAutoresizingMaskIntoConstraints = false
            memberView.delegate = self
            membersContainer.addSubview(memberView)
            memberViews.append(memberView)
            
            let row = index / 3
            let col = index % 3
            let containerWidth = max(300, frame.width) // Use minimum width to prevent division by zero
            let memberWidth = (containerWidth - 64) / 3 // Account for padding and spacing
            let memberHeight: CGFloat = 80
            
            NSLayoutConstraint.activate([
                memberView.leadingAnchor.constraint(equalTo: membersContainer.leadingAnchor, constant: CGFloat(col) * (memberWidth + 8)),
                memberView.topAnchor.constraint(equalTo: membersContainer.topAnchor, constant: CGFloat(row) * (memberHeight + 8)),
                memberView.widthAnchor.constraint(equalToConstant: memberWidth),
                memberView.heightAnchor.constraint(equalToConstant: memberHeight)
            ])
        }
        
        // Set container height
        let totalRows = (membersToShow.count + 2) / 3 // Round up
        let containerHeight = CGFloat(totalRows) * 80 + CGFloat(max(0, totalRows - 1)) * 8
        membersContainer.heightAnchor.constraint(equalToConstant: containerHeight).isActive = true
    }
    
    private func updateViewAllButtonVisibility() {
        viewAllButton.isHidden = members.count <= 6
    }
    
    @objc private func viewAllTapped() {
        delegate?.didTapViewAllMembers()
    }
    
    @objc private func inviteTapped() {
        delegate?.didTapInviteMembers()
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func addBoltDecoration() {
        // Add a simple circular decoration instead of bolt
        let decoration = UIView()
        decoration.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0)
        decoration.layer.cornerRadius = 6
        decoration.translatesAutoresizingMaskIntoConstraints = false
        addSubview(decoration)
        
        NSLayoutConstraint.activate([
            decoration.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            decoration.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            decoration.widthAnchor.constraint(equalToConstant: 12),
            decoration.heightAnchor.constraint(equalToConstant: 12)
        ])
    }
}

// MARK: - TeamMemberViewDelegate

extension TeamMembersListView: TeamMemberViewDelegate {
    func didTapTeamMember(_ member: TeamMemberWithProfile) {
        delegate?.didTapMember(member)
    }
}

// MARK: - TeamMemberView Component

protocol TeamMemberViewDelegate: AnyObject {
    func didTapTeamMember(_ member: TeamMemberWithProfile)
}

private class TeamMemberView: UIView {
    
    weak var delegate: TeamMemberViewDelegate?
    private let member: TeamMemberWithProfile
    
    // UI Components
    private let avatarView = UIView()
    private let avatarLabel = UILabel()
    private let usernameLabel = UILabel()
    private let roleLabel = UILabel()
    private let activityIndicator = UIView()
    
    init(member: TeamMemberWithProfile) {
        self.member = member
        super.init(frame: .zero)
        setupUI()
        setupTapGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0).cgColor
        
        // Avatar
        avatarView.backgroundColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 0.2)
        avatarView.layer.cornerRadius = 16
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        
        // Better fallback logic for display name and initials
        let displayName = getDisplayName(from: member.profile)
        avatarLabel.text = getInitials(from: displayName)
        avatarLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        avatarLabel.textColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        avatarLabel.textAlignment = .center
        avatarLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Username
        usernameLabel.text = displayName
        usernameLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        usernameLabel.textColor = IndustrialDesign.Colors.primaryText
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        usernameLabel.adjustsFontSizeToFitWidth = true
        usernameLabel.minimumScaleFactor = 0.8
        
        // Role
        roleLabel.text = member.role.uppercased()
        roleLabel.font = UIFont.systemFont(ofSize: 9, weight: .medium)
        roleLabel.textColor = member.role == "captain" ? UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0) : IndustrialDesign.Colors.secondaryText
        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Activity indicator (shows if user has recent workouts)
        activityIndicator.backgroundColor = UIColor.systemGreen
        activityIndicator.layer.cornerRadius = 3
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.isHidden = (member.profile.totalWorkouts ?? 0) == 0
        
        avatarView.addSubview(avatarLabel)
        addSubview(avatarView)
        addSubview(usernameLabel)
        addSubview(roleLabel)
        addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            // Avatar
            avatarView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            avatarView.centerXAnchor.constraint(equalTo: centerXAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 32),
            avatarView.heightAnchor.constraint(equalToConstant: 32),
            
            avatarLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            
            // Username
            usernameLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 4),
            usernameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            usernameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            
            // Role
            roleLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 2),
            roleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            roleLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -8),
            
            // Activity indicator
            activityIndicator.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            activityIndicator.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            activityIndicator.widthAnchor.constraint(equalToConstant: 6),
            activityIndicator.heightAnchor.constraint(equalToConstant: 6)
        ])
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(memberTapped))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }
    
    @objc private func memberTapped() {
        delegate?.didTapTeamMember(member)
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Visual feedback
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = .identity
            }
        }
    }
    
    private func getDisplayName(from profile: UserProfile) -> String {
        print("🏗️ TeamMembersListView: Getting display name for profile - ID: \(profile.id), Username: \(profile.username ?? "nil"), FullName: \(profile.fullName ?? "nil"), Email: \(profile.email ?? "nil")")
        
        // Try username first - this should be the updated username from profile editing
        if let username = profile.username, !username.isEmpty, username != profile.email {
            print("🏗️ TeamMembersListView: Using username: \(username)")
            return username
        }
        
        // Try full name
        if let fullName = profile.fullName, !fullName.isEmpty {
            print("🏗️ TeamMembersListView: Using fullName: \(fullName)")
            return fullName
        }
        
        // Try email as fallback (extract username part before @)
        if let email = profile.email, !email.isEmpty {
            let emailUsername = email.components(separatedBy: "@").first ?? email
            // Make it more user-friendly by capitalizing first letter
            let displayName = emailUsername.prefix(1).uppercased() + emailUsername.dropFirst()
            print("🏗️ TeamMembersListView: Using email-based name: \(displayName)")
            return displayName
        }
        
        // Final fallback: create a friendly name from user ID
        let shortId = String(profile.id.prefix(8))
        let fallbackName = "Member\(shortId)"
        print("🏗️ TeamMembersListView: Using fallback name: \(fallbackName)")
        return fallbackName
    }
    
    private func getInitials(from name: String) -> String {
        // Handle member ID format (MemberXXXXXXXX)
        if name.hasPrefix("Member") {
            return "M" + String(name.dropFirst(6).prefix(1))
        }
        
        // Handle email-based usernames (e.g., "John.doe" from "john.doe@email.com")
        if name.contains(".") {
            let parts = name.components(separatedBy: ".")
            let initials = parts.compactMap { $0.first }.map { String($0).uppercased() }
            return String(initials.prefix(2).joined())
        }
        
        let words = name.components(separatedBy: .whitespacesAndNewlines)
        let initials = words.compactMap { $0.first }.map { String($0).uppercased() }
        let result = String(initials.prefix(2).joined())
        
        // Ensure we always return at least one character
        return result.isEmpty ? "?" : result
    }
}