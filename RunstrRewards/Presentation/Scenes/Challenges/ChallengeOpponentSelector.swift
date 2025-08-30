import UIKit

protocol OpponentSelectionDelegate: AnyObject {
    func opponentSelectionDidChange(_ opponents: [TeamMemberWithProfile])
}

class OpponentSelectionView: UIView {
    
    // MARK: - Properties
    weak var delegate: OpponentSelectionDelegate?
    private let teamData: TeamData
    private var teamMembers: [TeamMemberWithProfile] = []
    private var filteredMembers: [TeamMemberWithProfile] = []
    
    var selectedOpponents: [TeamMemberWithProfile] = [] {
        didSet {
            updateSelectionDisplay()
            delegate?.opponentSelectionDidChange(selectedOpponents)
        }
    }
    
    // MARK: - UI Components
    private let instructionLabel = UILabel()
    private let searchBar = UISearchBar()
    private let tableView = UITableView()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let emptyStateLabel = UILabel()
    
    // Selection display
    private let selectionHeader = UIView()
    private let selectionLabel = UILabel()
    private let selectionScrollView = UIScrollView()
    private let selectionStackView = UIStackView()
    
    // Constraint references for dynamic layout
    private var tableViewTopToSearchConstraint: NSLayoutConstraint!
    private var tableViewTopToHeaderConstraint: NSLayoutConstraint!
    
    // MARK: - Initialization
    
    init(teamData: TeamData) {
        self.teamData = teamData
        super.init(frame: .zero)
        
        setupUI()
        setupConstraints()
        loadTeamMembers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        backgroundColor = .clear
        
        // Instruction label
        instructionLabel.text = "Select who you want to challenge:"
        instructionLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        instructionLabel.textColor = IndustrialDesign.Colors.primaryText
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Search bar
        searchBar.placeholder = "Search team members..."
        searchBar.backgroundColor = .clear
        searchBar.barTintColor = .clear
        searchBar.searchTextField.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        searchBar.searchTextField.textColor = IndustrialDesign.Colors.primaryText
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        
        // Selection header
        setupSelectionHeader()
        
        // Table view
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(OpponentSelectionCell.self, forCellReuseIdentifier: "OpponentCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // Loading indicator
        loadingIndicator.color = IndustrialDesign.Colors.bitcoin
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        // Empty state
        emptyStateLabel.text = "No team members found"
        emptyStateLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        emptyStateLabel.textColor = IndustrialDesign.Colors.secondaryText
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.isHidden = true
        
        // Add to hierarchy
        addSubview(instructionLabel)
        addSubview(searchBar)
        addSubview(selectionHeader)
        addSubview(tableView)
        addSubview(loadingIndicator)
        addSubview(emptyStateLabel)
    }
    
    private func setupSelectionHeader() {
        selectionHeader.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.8)
        selectionHeader.layer.cornerRadius = 8
        selectionHeader.layer.borderWidth = 1
        selectionHeader.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        selectionHeader.translatesAutoresizingMaskIntoConstraints = false
        selectionHeader.isHidden = true
        
        // Selection label
        selectionLabel.text = "Selected:"
        selectionLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        selectionLabel.textColor = IndustrialDesign.Colors.bitcoin
        selectionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Selection scroll view
        selectionScrollView.showsHorizontalScrollIndicator = false
        selectionScrollView.translatesAutoresizingMaskIntoConstraints = false
        
        // Selection stack view
        selectionStackView.axis = .horizontal
        selectionStackView.spacing = 8
        selectionStackView.translatesAutoresizingMaskIntoConstraints = false
        
        selectionScrollView.addSubview(selectionStackView)
        selectionHeader.addSubview(selectionLabel)
        selectionHeader.addSubview(selectionScrollView)
        
        NSLayoutConstraint.activate([
            selectionLabel.topAnchor.constraint(equalTo: selectionHeader.topAnchor, constant: 8),
            selectionLabel.leadingAnchor.constraint(equalTo: selectionHeader.leadingAnchor, constant: 12),
            selectionLabel.trailingAnchor.constraint(equalTo: selectionHeader.trailingAnchor, constant: -12),
            
            selectionScrollView.topAnchor.constraint(equalTo: selectionLabel.bottomAnchor, constant: 8),
            selectionScrollView.leadingAnchor.constraint(equalTo: selectionHeader.leadingAnchor, constant: 12),
            selectionScrollView.trailingAnchor.constraint(equalTo: selectionHeader.trailingAnchor, constant: -12),
            selectionScrollView.bottomAnchor.constraint(equalTo: selectionHeader.bottomAnchor, constant: -8),
            selectionScrollView.heightAnchor.constraint(equalToConstant: 40),
            
            selectionStackView.topAnchor.constraint(equalTo: selectionScrollView.topAnchor),
            selectionStackView.leadingAnchor.constraint(equalTo: selectionScrollView.leadingAnchor),
            selectionStackView.trailingAnchor.constraint(equalTo: selectionScrollView.trailingAnchor),
            selectionStackView.bottomAnchor.constraint(equalTo: selectionScrollView.bottomAnchor),
            selectionStackView.heightAnchor.constraint(equalTo: selectionScrollView.heightAnchor)
        ])
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Instruction label
            instructionLabel.topAnchor.constraint(equalTo: topAnchor),
            instructionLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            instructionLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            // Search bar
            searchBar.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 12),
            searchBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            searchBar.heightAnchor.constraint(equalToConstant: 44),
            
            // Selection header (initially hidden)
            selectionHeader.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 12),
            selectionHeader.leadingAnchor.constraint(equalTo: leadingAnchor),
            selectionHeader.trailingAnchor.constraint(equalTo: trailingAnchor),
            selectionHeader.heightAnchor.constraint(equalToConstant: 70),
            
            // Table view - leading, trailing, and bottom constraints
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            
            // Empty state
            emptyStateLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
        ])
        
        // Set up table view top constraints
        tableViewTopToSearchConstraint = tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 12)
        tableViewTopToHeaderConstraint = tableView.topAnchor.constraint(equalTo: selectionHeader.bottomAnchor, constant: 12)
        
        // Start with search constraint active (header is hidden initially)
        tableViewTopToSearchConstraint.isActive = true
    }
    
    // MARK: - Data Loading
    
    private func loadTeamMembers() {
        loadingIndicator.startAnimating()
        
        Task {
            do {
                let members = try await TeamDataService.shared.fetchTeamMembers(teamId: teamData.id)
                
                await MainActor.run {
                    // Filter out current user
                    if let currentUserId = AuthenticationService.shared.currentUserId {
                        self.teamMembers = members.filter { $0.userId != currentUserId }
                    } else {
                        self.teamMembers = members
                    }
                    
                    self.filteredMembers = self.teamMembers
                    self.loadingIndicator.stopAnimating()
                    self.updateDisplay()
                }
            } catch {
                print("❌ OpponentSelection: Failed to load team members: \(error)")
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    self.showEmptyState()
                }
            }
        }
    }
    
    private func updateDisplay() {
        if filteredMembers.isEmpty {
            showEmptyState()
        } else {
            hideEmptyState()
            tableView.reloadData()
        }
    }
    
    private func showEmptyState() {
        emptyStateLabel.isHidden = false
        tableView.isHidden = true
    }
    
    private func hideEmptyState() {
        emptyStateLabel.isHidden = true
        tableView.isHidden = false
    }
    
    // MARK: - Selection Management
    
    private func updateSelectionDisplay() {
        if selectedOpponents.isEmpty {
            selectionHeader.isHidden = true
            // Switch to search constraint
            tableViewTopToHeaderConstraint.isActive = false
            tableViewTopToSearchConstraint.isActive = true
        } else {
            selectionHeader.isHidden = false
            // Switch to header constraint
            tableViewTopToSearchConstraint.isActive = false
            tableViewTopToHeaderConstraint.isActive = true
            updateSelectionChips()
        }
        
        // Animate the layout change
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
        
        // Reload table to update checkmarks
        tableView.reloadData()
    }
    
    private func updateSelectionChips() {
        // Clear existing chips
        selectionStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add chips for selected opponents
        for opponent in selectedOpponents {
            let chip = createSelectionChip(for: opponent)
            selectionStackView.addArrangedSubview(chip)
        }
    }
    
    private func createSelectionChip(for opponent: TeamMemberWithProfile) -> UIView {
        let chipContainer = UIView()
        chipContainer.backgroundColor = IndustrialDesign.Colors.bitcoin.withAlphaComponent(0.2)
        chipContainer.layer.cornerRadius = 16
        chipContainer.layer.borderWidth = 1
        chipContainer.layer.borderColor = IndustrialDesign.Colors.bitcoin.cgColor
        
        let nameLabel = UILabel()
        nameLabel.text = opponent.profile.username ?? "Unknown"
        nameLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        nameLabel.textColor = IndustrialDesign.Colors.bitcoin
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let removeButton = UIButton(type: .custom)
        removeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        removeButton.tintColor = IndustrialDesign.Colors.bitcoin
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        removeButton.addTarget(self, action: #selector(removeOpponentTapped(_:)), for: .touchUpInside)
        removeButton.tag = selectedOpponents.firstIndex(where: { $0.userId == opponent.userId }) ?? 0
        
        chipContainer.addSubview(nameLabel)
        chipContainer.addSubview(removeButton)
        
        NSLayoutConstraint.activate([
            chipContainer.heightAnchor.constraint(equalToConstant: 32),
            
            nameLabel.leadingAnchor.constraint(equalTo: chipContainer.leadingAnchor, constant: 12),
            nameLabel.centerYAnchor.constraint(equalTo: chipContainer.centerYAnchor),
            
            removeButton.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 6),
            removeButton.trailingAnchor.constraint(equalTo: chipContainer.trailingAnchor, constant: -6),
            removeButton.centerYAnchor.constraint(equalTo: chipContainer.centerYAnchor),
            removeButton.widthAnchor.constraint(equalToConstant: 16),
            removeButton.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        return chipContainer
    }
    
    @objc private func removeOpponentTapped(_ sender: UIButton) {
        guard sender.tag < selectedOpponents.count else { return }
        selectedOpponents.remove(at: sender.tag)
    }
    
    private func toggleOpponentSelection(_ opponent: TeamMemberWithProfile) {
        if let index = selectedOpponents.firstIndex(where: { $0.userId == opponent.userId }) {
            selectedOpponents.remove(at: index)
        } else {
            selectedOpponents.append(opponent)
        }
    }
    
    private func isOpponentSelected(_ opponent: TeamMemberWithProfile) -> Bool {
        return selectedOpponents.contains { $0.userId == opponent.userId }
    }
}

// MARK: - UITableViewDataSource

extension OpponentSelectionView: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredMembers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "OpponentCell", for: indexPath) as! OpponentSelectionCell
        let member = filteredMembers[indexPath.row]
        
        cell.configure(with: member, isSelected: isOpponentSelected(member))
        return cell
    }
}

// MARK: - UITableViewDelegate

extension OpponentSelectionView: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let member = filteredMembers[indexPath.row]
        toggleOpponentSelection(member)
    }
}

// MARK: - UISearchBarDelegate

extension OpponentSelectionView: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredMembers = teamMembers
        } else {
            filteredMembers = teamMembers.filter { member in
                member.profile.username?.lowercased().contains(searchText.lowercased()) ?? false
            }
        }
        
        updateDisplay()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - Opponent Selection Cell

class OpponentSelectionCell: UITableViewCell {
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let roleLabel = UILabel()
    private let checkmarkView = UIImageView()
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        // Container
        containerView.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.8)
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Avatar
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.clipsToBounds = true
        avatarImageView.backgroundColor = IndustrialDesign.Colors.bitcoin.withAlphaComponent(0.2)
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Name
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = IndustrialDesign.Colors.primaryText
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Role
        roleLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        roleLabel.textColor = IndustrialDesign.Colors.secondaryText
        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Checkmark
        checkmarkView.image = UIImage(systemName: "checkmark.circle.fill")
        checkmarkView.tintColor = IndustrialDesign.Colors.bitcoin
        checkmarkView.translatesAutoresizingMaskIntoConstraints = false
        checkmarkView.isHidden = true
        
        // Add to hierarchy
        contentView.addSubview(containerView)
        containerView.addSubview(avatarImageView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(roleLabel)
        containerView.addSubview(checkmarkView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            // Avatar
            avatarImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            avatarImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),
            
            // Name
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: checkmarkView.leadingAnchor, constant: -12),
            
            // Role
            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            roleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            roleLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            roleLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -12),
            
            // Checkmark
            checkmarkView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            checkmarkView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            checkmarkView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with member: TeamMemberWithProfile, isSelected: Bool) {
        nameLabel.text = member.profile.username ?? "Unknown"
        roleLabel.text = member.role.capitalized
        
        // Load avatar
        if let avatarUrl = member.profile.avatarUrl, !avatarUrl.isEmpty {
            // TODO: Load actual avatar image
            avatarImageView.backgroundColor = IndustrialDesign.Colors.bitcoin.withAlphaComponent(0.2)
        } else {
            // Show placeholder with initials
            avatarImageView.backgroundColor = IndustrialDesign.Colors.bitcoin.withAlphaComponent(0.2)
        }
        
        // Update selection state
        checkmarkView.isHidden = !isSelected
        containerView.layer.borderColor = isSelected ? 
            IndustrialDesign.Colors.bitcoin.cgColor :
            IndustrialDesign.Colors.cardBorder.cgColor
    }
}