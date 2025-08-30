import UIKit

@objc protocol TeamDetailMembersDelegate: AnyObject {
    func membersDidRequestMemberProfile(_ memberId: String)
    func membersDidRequestLeaderboard()
    @objc optional func membersDidRequestInvite()
    @objc optional func membersDidRequestFullMembersList()
}

class TeamDetailMembersController: UIViewController {
    
    // MARK: - Properties
    private let teamData: TeamData
    weak var delegate: TeamDetailMembersDelegate?
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let teamMembersView = TeamMembersListView()
    private let teamActivityView = TeamActivityFeedView()
    
    // MARK: - Initialization
    init(teamData: TeamData) {
        self.teamData = teamData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        configureWithData()
        setupNotificationListeners()
    }
    
    // MARK: - Setup Methods
    
    private func setupViews() {
        view.backgroundColor = .clear
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [teamMembersView, teamActivityView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        // Setup delegates
        teamMembersView.delegate = self
        teamActivityView.delegate = self
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
            
            // Team members view
            teamMembersView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            teamMembersView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            teamMembersView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            teamMembersView.heightAnchor.constraint(equalToConstant: 300),
            
            // Team activity view
            teamActivityView.topAnchor.constraint(equalTo: teamMembersView.bottomAnchor, constant: 20),
            teamActivityView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            teamActivityView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            teamActivityView.heightAnchor.constraint(equalToConstant: 400),
            teamActivityView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func configureWithData() {
        // Initial configuration with empty data - actual data loaded in loadTeamMembers/loadTeamActivity
        loadTeamMembers()
        loadTeamActivity()
    }
    
    private func loadTeamMembers() {
        Task {
            do {
                let members = try await TeamDataService.shared.fetchTeamMembers(teamId: teamData.id)
                await MainActor.run {
                    teamMembersView.configure(with: members)
                }
            } catch {
                print("TeamDetailMembers: Failed to load team members: \(error)")
            }
        }
    }
    
    private func loadTeamActivity() {
        Task {
            do {
                let activity = try await TeamDataService.shared.fetchTeamActivity(teamId: teamData.id)
                await MainActor.run {
                    teamActivityView.configure(with: activity)
                }
            } catch {
                print("TeamDetailMembers: Failed to load team activity: \(error)")
            }
        }
    }
    
    private func setupNotificationListeners() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTeamUpdate),
            name: .teamDataUpdated,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMembershipChange),
            name: .teamMembershipChanged,
            object: nil
        )
    }
    
    // MARK: - Actions
    
    @objc private func handleTeamUpdate(_ notification: Notification) {
        guard let teamId = notification.userInfo?["teamId"] as? String,
              teamId == teamData.id else { return }
        
        loadTeamMembers()
        loadTeamActivity()
    }
    
    @objc private func handleMembershipChange(_ notification: Notification) {
        guard let teamId = notification.userInfo?["teamId"] as? String,
              teamId == teamData.id else { return }
        
        loadTeamMembers()
    }
    
    // MARK: - Public Methods
    
    func refreshData() {
        loadTeamMembers()
        loadTeamActivity()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - TeamMembersListView Delegate

extension TeamDetailMembersController: TeamMembersListViewDelegate {
    func didTapInviteMembers() {
        delegate?.membersDidRequestInvite?()
    }
    
    func didTapMember(_ member: TeamMemberWithProfile) {
        delegate?.membersDidRequestMemberProfile(member.userId)
    }
    
    func didTapViewAllMembers() {
        delegate?.membersDidRequestFullMembersList?()
    }
}

// MARK: - TeamActivityFeedView Delegate

extension TeamDetailMembersController: TeamActivityFeedViewDelegate {
    func didTapActivity(_ activity: TeamActivity) {
        // Handle activity tap - could show activity details
        print("Activity tapped: \(activity.description)")
    }
    
    func didTapViewAllActivity() {
        delegate?.membersDidRequestLeaderboard()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let teamDataUpdated = Notification.Name("teamDataUpdated")
    static let teamMembershipChanged = Notification.Name("teamMembershipChanged")
}