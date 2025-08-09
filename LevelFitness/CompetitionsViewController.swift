import UIKit

enum CompetitionTab {
    case league
    
    var title: String {
        switch self {
        case .league: return "LEVEL LEAGUE"
        }
    }
}

protocol CompetitionsHeaderViewDelegate: AnyObject {
    func didTapBackButton()
    func didTapInfoButton()
}

class CompetitionsViewController: UIViewController {
    
    // MARK: - Properties
    private var currentTab: CompetitionTab = .league
    
    // MARK: - UI Components
    private let headerView = UIView()
    private let backButton = UIButton(type: .custom)
    private let pageTitleLabel = UILabel()
    private let infoButton = UIButton(type: .custom)
    private let tabNavigationView = CompetitionTabNavigationView()
    private let contentContainerView = UIView()
    
    // Tab Content Views
    private let leagueView = LeagueView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🏆 LevelFitness: Loading competitions page...")
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupIndustrialBackground()
        setupHeader()
        setupTabNavigation()
        setupContentArea()
        setupConstraints()
        
        // Final z-order: Ensure interactive elements are always on top
        view.bringSubviewToFront(headerView)
        view.bringSubviewToFront(tabNavigationView)
        
        // Ensure tab navigation view is synchronized
        tabNavigationView.selectTab(.league)
        switchToTab(.league)
        
        print("🏆 LevelFitness: Competitions loaded with proper z-ordering and League tab selected")
    }
    
    
    // MARK: - Setup Methods
    
    private func setupIndustrialBackground() {
        view.backgroundColor = IndustrialDesign.Colors.background
        
        // Add grid pattern
        let gridView = GridPatternView()
        gridView.translatesAutoresizingMaskIntoConstraints = false
        gridView.isUserInteractionEnabled = false // Prevent blocking touch events
        view.addSubview(gridView)
        
        // Add rotating gears
        let gear1 = RotatingGearView(size: 250)
        gear1.translatesAutoresizingMaskIntoConstraints = false
        gear1.isUserInteractionEnabled = false // Prevent blocking touch events
        view.addSubview(gear1)
        
        NSLayoutConstraint.activate([
            gridView.topAnchor.constraint(equalTo: view.topAnchor),
            gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            gear1.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 100),
            gear1.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 50),
            gear1.widthAnchor.constraint(equalToConstant: 250),
            gear1.heightAnchor.constraint(equalToConstant: 250)
        ])
    }
    
    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 0.95) // Semi-transparent background
        headerView.clipsToBounds = false // Allow buttons to extend beyond bounds
        
        // Back button
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = IndustrialDesign.Colors.secondaryText
        backButton.contentMode = .center
        backButton.imageView?.contentMode = .scaleAspectFit
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.isUserInteractionEnabled = true
        
        // Add direct tap gesture as backup
        let backTapGesture = UITapGestureRecognizer(target: self, action: #selector(directBackTapped(_:)))
        backTapGesture.cancelsTouchesInView = false
        backButton.addGestureRecognizer(backTapGesture)
        
        print("🏆 LevelFitness: Back button configured with target-action and tap gesture")
        
        // Page title
        pageTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        pageTitleLabel.text = "Competitions"
        pageTitleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        pageTitleLabel.textAlignment = .center
        pageTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        pageTitleLabel.isUserInteractionEnabled = false // Ensure label doesn't block touches
        
        // Info button
        infoButton.translatesAutoresizingMaskIntoConstraints = false
        infoButton.setImage(UIImage(systemName: "info.circle"), for: .normal)
        infoButton.tintColor = IndustrialDesign.Colors.secondaryText
        infoButton.contentMode = .center
        infoButton.imageView?.contentMode = .scaleAspectFit
        infoButton.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
        
        view.addSubview(headerView)
        headerView.addSubview(backButton)
        headerView.addSubview(pageTitleLabel)
        headerView.addSubview(infoButton)
        
        setupButtonHoverEffects()
    }
    
    private func setupButtonHoverEffects() {
        // Back button hover
        let backPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(backButtonPressed(_:)))
        backPressGesture.minimumPressDuration = 0
        backPressGesture.delegate = self
        backPressGesture.cancelsTouchesInView = false
        backButton.addGestureRecognizer(backPressGesture)
        
        // Info button hover
        let infoPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(infoButtonPressed(_:)))
        infoPressGesture.minimumPressDuration = 0
        infoPressGesture.delegate = self
        infoPressGesture.cancelsTouchesInView = false
        infoButton.addGestureRecognizer(infoPressGesture)
    }
    
    private func setupTabNavigation() {
        tabNavigationView.translatesAutoresizingMaskIntoConstraints = false
        tabNavigationView.delegate = self
        tabNavigationView.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.95)
        tabNavigationView.isUserInteractionEnabled = true
        tabNavigationView.clipsToBounds = false // Allow touch areas to extend
        
        view.addSubview(tabNavigationView)
        print("🏆 LevelFitness: Tab navigation view configured with delegate")
    }
    
    private func setupContentArea() {
        contentContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 0.95)
        contentContainerView.clipsToBounds = true // Prevent content from overlapping header
        
        print("🏆 LevelFitness: Content container background: \(contentContainerView.backgroundColor?.debugDescription ?? "nil")")
        
        // Setup individual views
        leagueView.translatesAutoresizingMaskIntoConstraints = false
        
        leagueView.delegate = self
        
        // Add content container ABOVE background elements (after setupIndustrialBackground)
        // but BELOW header and tab navigation (which will be brought to front)
        view.addSubview(contentContainerView)
        contentContainerView.addSubview(leagueView)
        
        // Hide all views initially
        leagueView.isHidden = true
        
        print("🏆 LevelFitness: Content area setup completed - contentContainer above background")
    }
    
    private func setupConstraints() {
        // Define explicit heights to prevent layout conflicts
        let headerHeight: CGFloat = 90 // Increased for larger buttons
        let tabNavigationHeight: CGFloat = 60 // Increased for better touch targets
        
        NSLayoutConstraint.activate([
            // Header - explicit height and priority
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: headerHeight),
            
            // Back button - increased touch target size with high priority
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 60),
            backButton.heightAnchor.constraint(equalToConstant: 60),
            
            // Page title - ensure it doesn't interfere with buttons
            pageTitleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            pageTitleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            pageTitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 16),
            pageTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: infoButton.leadingAnchor, constant: -16),
            
            // Info button - increased touch target size with high priority
            infoButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            infoButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            infoButton.widthAnchor.constraint(equalToConstant: 60),
            infoButton.heightAnchor.constraint(equalToConstant: 60),
            
            // Tab navigation - explicit height
            tabNavigationView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tabNavigationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabNavigationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabNavigationView.heightAnchor.constraint(equalToConstant: tabNavigationHeight),
            
            // Content container - explicit positioning to prevent overlap
            contentContainerView.topAnchor.constraint(equalTo: tabNavigationView.bottomAnchor),
            contentContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content views - all fill the container with proper constraints
            leagueView.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            leagueView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            leagueView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            leagueView.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor)
        ])
        
        // Set constraint priorities to prevent conflicts
        let buttonConstraints = [
            backButton.widthAnchor.constraint(equalToConstant: 60),
            backButton.heightAnchor.constraint(equalToConstant: 60),
            infoButton.widthAnchor.constraint(equalToConstant: 60),
            infoButton.heightAnchor.constraint(equalToConstant: 60)
        ]
        
        buttonConstraints.forEach { constraint in
            constraint.priority = UILayoutPriority(999) // High priority
        }
        
        print("🏆 LevelFitness: Layout constraints configured with explicit heights - header: \(headerHeight), tabs: \(tabNavigationHeight)")
    }
    
    // MARK: - Tab Management
    
    private func switchToTab(_ tab: CompetitionTab) {
        print("🏆 LevelFitness: === SWITCHING TO TAB: \(tab.title) ===")
        print("🏆 LevelFitness: Previous tab was: \(currentTab.title)")
        currentTab = tab
        
        // Hide all views
        print("🏆 LevelFitness: Hiding all views...")
        leagueView.isHidden = true
        print("🏆 LevelFitness: League view hidden: \(leagueView.isHidden)")
        
        // Show selected view
        switch tab {
        case .league:
            print("🏆 LevelFitness: Showing League view...")
            leagueView.isHidden = false
            leagueView.loadSampleData()
            print("🏆 LevelFitness: League view visible: \(!leagueView.isHidden)")
            print("🏆 LevelFitness: League view frame: \(leagueView.frame)")
            print("🏆 LevelFitness: League view superview: \(leagueView.superview?.debugDescription ?? "nil")")
        }
        
        print("🏆 LevelFitness: Content container frame: \(contentContainerView.frame)")
        print("🏆 LevelFitness: Content container hidden: \(contentContainerView.isHidden)")
        print("🏆 LevelFitness: === TAB SWITCH COMPLETED ===")
    }
    
    // MARK: - Actions
    
    @objc private func directBackTapped(_ gesture: UITapGestureRecognizer) {
        print("🏆 LevelFitness: Direct tap gesture detected on back button")
        backButtonTapped()
    }
    
    @objc private func backButtonTapped() {
        print("🏆 LevelFitness: Competitions back button tapped")
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func infoButtonTapped() {
        print("🏆 LevelFitness: Info button tapped")
        showInfoAlert()
    }
    
    @objc private func backButtonPressed(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            print("🏆 LevelFitness: Back button press began")
            UIView.animate(withDuration: 0.1) { [self] in
                self.backButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                self.backButton.alpha = 0.7
            }
        case .ended:
            print("🏆 LevelFitness: Back button press ended - triggering action")
            UIView.animate(withDuration: 0.2) { [self] in
                self.backButton.transform = .identity
                self.backButton.alpha = 1.0
            }
            // Trigger the button action on press end
            if gesture.location(in: backButton).x >= 0 &&
               gesture.location(in: backButton).x <= backButton.bounds.width &&
               gesture.location(in: backButton).y >= 0 &&
               gesture.location(in: backButton).y <= backButton.bounds.height {
                backButtonTapped()
            }
        case .cancelled:
            print("🏆 LevelFitness: Back button press cancelled")
            UIView.animate(withDuration: 0.2) { [self] in
                self.backButton.transform = .identity
                self.backButton.alpha = 1.0
            }
        default:
            break
        }
    }
    
    @objc private func infoButtonPressed(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            UIView.animate(withDuration: 0.1) { [self] in
                self.infoButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                self.infoButton.alpha = 0.7
            }
        case .ended, .cancelled:
            UIView.animate(withDuration: 0.2) { [self] in
                self.infoButton.transform = .identity
                self.infoButton.alpha = 1.0
            }
        default:
            break
        }
    }
    
    private func showInfoAlert() {
        let alert = UIAlertController(
            title: "Competitions",
            message: "Compete with other Level Fitness users for Bitcoin rewards. Join weekly leagues or specific events to earn your share of the prize pool.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Got it", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Touch Handling
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Bring critical interactive elements to front after layout
        view.bringSubviewToFront(headerView)
        view.bringSubviewToFront(tabNavigationView)
        
        // Debug button frames after layout
        print("🏆 LevelFitness: Layout completed - Button frames:")
        print("🏆 LevelFitness: Back button frame: \(backButton.frame)")
        print("🏆 LevelFitness: Header view frame: \(headerView.frame)")
        print("🏆 LevelFitness: Tab navigation view frame: \(tabNavigationView.frame)")
        
        // Check if buttons have proper hit areas
        if backButton.frame.width < 44 || backButton.frame.height < 44 {
            print("🏆 LevelFitness: WARNING - Back button frame too small for proper touch: \(backButton.frame)")
        } else {
            print("🏆 LevelFitness: ✅ Back button frame is adequate: \(backButton.frame)")
        }
        
        if infoButton.frame.width < 44 || infoButton.frame.height < 44 {
            print("🏆 LevelFitness: WARNING - Info button frame too small for proper touch: \(infoButton.frame)")
        } else {
            print("🏆 LevelFitness: ✅ Info button frame is adequate: \(infoButton.frame)")
        }
        
        // Check tab buttons
        DispatchQueue.main.async {
            for (tab, button) in self.tabNavigationView.tabButtons {
                print("🏆 LevelFitness: \(tab.title) button frame: \(button.frame)")
                if button.frame.width == 0 || button.frame.height == 0 {
                    print("🏆 LevelFitness: WARNING - \(tab.title) button has zero frame!")
                }
            }
        }
    }
    
    // MARK: - Touch Debugging
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if let touch = touches.first {
            let location = touch.location(in: view)
            print("🏆 LevelFitness: Touch detected at location: \(location)")
            
            // Check if touch is in header area (back button region)
            let headerFrame = headerView.frame
            print("🏆 LevelFitness: Header frame: \(headerFrame)")
            if headerFrame.contains(location) {
                print("🏆 LevelFitness: Touch is in header area!")
                let backButtonFrame = backButton.frame
                print("🏆 LevelFitness: Back button frame: \(backButtonFrame)")
                if backButtonFrame.contains(touch.location(in: headerView)) {
                    print("🏆 LevelFitness: Touch is over back button!")
                }
            }
            
            // Check if touch is in tab navigation area
            let tabNavFrame = tabNavigationView.frame
            print("🏆 LevelFitness: Tab navigation frame: \(tabNavFrame)")
            if tabNavFrame.contains(location) {
                print("🏆 LevelFitness: Touch is in tab navigation area!")
            }
        }
    }
}

// MARK: - CompetitionTabNavigationViewDelegate

extension CompetitionsViewController: CompetitionTabNavigationViewDelegate {
    func didSelectTab(_ tab: CompetitionTab) {
        print("🏆 LevelFitness: === DELEGATE didSelectTab CALLED ===")
        print("🏆 LevelFitness: Tab: \(tab.title)")
        print("🏆 LevelFitness: Current view controller: \(self)")
        print("🏆 LevelFitness: Calling switchToTab...")
        switchToTab(tab)
        print("🏆 LevelFitness: === DELEGATE CALL COMPLETED ===")
    }
}

// MARK: - LeagueViewDelegate

extension CompetitionsViewController: LeagueViewDelegate {
    func didTapLeaderboardUser(_ user: LeaderboardUser) {
        print("🏆 LevelFitness: Tapped leaderboard user: \(user.username)")
        // TODO: Show user profile
    }
    
    func didTapStreakCard(_ type: StreakType) {
        print("🏆 LevelFitness: Tapped streak card: \(type)")
        // TODO: Show streak details
    }
}


// MARK: - UIGestureRecognizerDelegate

extension CompetitionsViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow multiple gesture recognizers to work together
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Always receive touches for our buttons
        if touch.view == backButton || touch.view == infoButton {
            print("🏆 LevelFitness: Gesture recognizer will receive touch for button")
            return true
        }
        return true
    }
}