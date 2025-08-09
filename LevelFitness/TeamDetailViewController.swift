import UIKit

class TeamDetailViewController: UIViewController {
    
    // MARK: - Properties
    private let teamData: TeamData
    private var currentTab: TabType = .chat
    
    enum TabType: String, CaseIterable {
        case chat = "Chat"
        case challenges = "Challenges"
        case events = "Events"
    }
    
    // MARK: - Child View Controllers
    private lazy var chatViewController = TeamDetailChatViewController(teamData: teamData)
    private lazy var challengesViewController = TeamDetailChallengesViewController(teamData: teamData)
    private lazy var eventsViewController = TeamDetailEventsViewController(teamData: teamData)
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let headerView = TeamDetailHeaderView()
    private let aboutSection = TeamDetailAboutSection()
    private let tabNavigation = TeamDetailTabNavigation()
    private let tabContentView = UIView()
    
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
        print("🏗️ LevelFitness: Loading team detail for \(teamData.name)")
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupIndustrialBackground()
        setupScrollView()
        setupHeader()
        setupAboutSection()
        setupTabNavigation()
        setupTabContent()
        setupConstraints()
        configureWithData()
        
        print("🏗️ LevelFitness: Team detail loaded successfully!")
    }
    
    // MARK: - Setup Methods
    
    private func setupIndustrialBackground() {
        view.backgroundColor = IndustrialDesign.Colors.background
        
        let gridView = GridPatternView()
        gridView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gridView)
        
        NSLayoutConstraint.activate([
            gridView.topAnchor.constraint(equalTo: view.topAnchor),
            gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let gear = RotatingGearView(size: 120)
        gear.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gear)
        
        NSLayoutConstraint.activate([
            gear.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 60),
            gear.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -30),
            gear.widthAnchor.constraint(equalToConstant: 120),
            gear.heightAnchor.constraint(equalToConstant: 120)
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
        headerView.delegate = self
        contentView.addSubview(headerView)
    }
    
    private func setupAboutSection() {
        aboutSection.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(aboutSection)
    }
    
    private func setupTabNavigation() {
        tabNavigation.translatesAutoresizingMaskIntoConstraints = false
        tabNavigation.delegate = self
        contentView.addSubview(tabNavigation)
    }
    
    private func setupTabContent() {
        tabContentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tabContentView)
        
        // Add child view controllers
        addChild(chatViewController)
        addChild(challengesViewController)
        addChild(eventsViewController)
        
        tabContentView.addSubview(chatViewController.view)
        tabContentView.addSubview(challengesViewController.view)
        tabContentView.addSubview(eventsViewController.view)
        
        chatViewController.didMove(toParent: self)
        challengesViewController.didMove(toParent: self)
        eventsViewController.didMove(toParent: self)
        
        // Setup constraints for child views
        [chatViewController.view, challengesViewController.view, eventsViewController.view].forEach { view in
            view?.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                view!.topAnchor.constraint(equalTo: tabContentView.topAnchor),
                view!.leadingAnchor.constraint(equalTo: tabContentView.leadingAnchor),
                view!.trailingAnchor.constraint(equalTo: tabContentView.trailingAnchor),
                view!.bottomAnchor.constraint(equalTo: tabContentView.bottomAnchor)
            ])
        }
        
        // Initially hide non-chat tabs
        challengesViewController.view.alpha = 0
        eventsViewController.view.alpha = 0
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
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 80),
            
            // About section
            aboutSection.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            aboutSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            aboutSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            aboutSection.heightAnchor.constraint(equalToConstant: 140),
            
            // Tab navigation
            tabNavigation.topAnchor.constraint(equalTo: aboutSection.bottomAnchor),
            tabNavigation.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tabNavigation.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tabNavigation.heightAnchor.constraint(equalToConstant: 48),
            
            // Tab content
            tabContentView.topAnchor.constraint(equalTo: tabNavigation.bottomAnchor),
            tabContentView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tabContentView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tabContentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            tabContentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 400)
        ])
    }
    
    private func configureWithData() {
        headerView.configure(teamName: teamData.name, memberCount: teamData.members)
        aboutSection.configure(
            prizePool: teamData.prizePool,
            avgKm: 156
        )
    }
    
    // MARK: - Tab Switching
    
    private func switchToTab(_ tab: TabType) {
        currentTab = tab
        
        UIView.animate(withDuration: 0.3, animations: {
            // Hide all tabs
            self.chatViewController.view.alpha = 0
            self.challengesViewController.view.alpha = 0
            self.eventsViewController.view.alpha = 0
            
            // Show/hide message input for chat
            if tab == .chat {
                self.chatViewController.showMessageInput(true)
            } else {
                self.chatViewController.showMessageInput(false)
            }
        }) { _ in
            // Show selected tab
            UIView.animate(withDuration: 0.3) {
                switch tab {
                case .chat:
                    self.chatViewController.view.alpha = 1
                case .challenges:
                    self.challengesViewController.view.alpha = 1
                case .events:
                    self.eventsViewController.view.alpha = 1
                }
            }
        }
        
        print("🏗️ LevelFitness: Switched to \(tab.rawValue) tab")
    }
}

// MARK: - TeamDetailHeaderViewDelegate

extension TeamDetailViewController: TeamDetailHeaderViewDelegate {
    func didTapBackButton() {
        print("🏗️ LevelFitness: Team detail back button tapped")
        navigationController?.popViewController(animated: true)
    }
    
    func didTapSettingsButton() {
        print("🏗️ LevelFitness: Team settings tapped")
        // TODO: Implement team settings
    }
}

// MARK: - TeamDetailTabNavigationDelegate

extension TeamDetailViewController: TeamDetailTabNavigationDelegate {
    func didSelectTab(_ tab: TeamDetailViewController.TabType) {
        switchToTab(tab)
    }
}