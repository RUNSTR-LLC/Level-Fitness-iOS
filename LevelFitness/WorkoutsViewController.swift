import UIKit

enum WorkoutTab {
    case sync
    case stats 
    
    var title: String {
        switch self {
        case .sync: return "SYNC"
        case .stats: return "STATS"
        }
    }
}

protocol WorkoutsHeaderViewDelegate: AnyObject {
    func didTapBackButton()
    func didTapSyncButton()
}

class WorkoutsViewController: UIViewController {
    
    // MARK: - Properties
    private var currentTab: WorkoutTab = .sync
    
    // MARK: - UI Components
    private let headerView = UIView()
    private let backButton = UIButton(type: .custom)
    private let pageTitleLabel = UILabel()
    private let syncButton = UIButton(type: .custom)
    private let tabNavigationView = WorkoutTabNavigationView()
    private let contentContainerView = UIView()
    
    // Tab Content Views
    private let syncView = WorkoutSyncView()
    private let statsView = WorkoutStatsView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🏃‍♂️ LevelFitness: Loading workouts page...")
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupIndustrialBackground()
        setupHeader()
        setupTabNavigation()
        setupContentArea()
        setupConstraints()
        switchToTab(.sync)
        
        print("🏃‍♂️ LevelFitness: Workouts loaded successfully!")
    }
    
    // MARK: - Setup Methods
    
    private func setupIndustrialBackground() {
        view.backgroundColor = IndustrialDesign.Colors.background
        
        // Add grid pattern
        let gridView = GridPatternView()
        gridView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gridView)
        
        // Add rotating gears
        let gear1 = RotatingGearView(size: 200)
        gear1.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gear1)
        
        NSLayoutConstraint.activate([
            gridView.topAnchor.constraint(equalTo: view.topAnchor),
            gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            gear1.topAnchor.constraint(equalTo: view.topAnchor, constant: 200),
            gear1.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 50),
            gear1.widthAnchor.constraint(equalToConstant: 200),
            gear1.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = UIColor.clear
        
        // Back button
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = IndustrialDesign.Colors.secondaryText
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        // Page title
        pageTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        pageTitleLabel.text = "Workouts"
        pageTitleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        pageTitleLabel.textAlignment = .center
        
        // Create gradient for title
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.white.cgColor,
            IndustrialDesign.Colors.secondaryText.cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        
        pageTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        
        // Sync button
        syncButton.translatesAutoresizingMaskIntoConstraints = false
        syncButton.setTitle("SYNC", for: .normal)
        syncButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        syncButton.setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
        syncButton.backgroundColor = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0)
        syncButton.layer.borderWidth = 1
        syncButton.layer.borderColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0).cgColor
        syncButton.layer.cornerRadius = 6
        syncButton.addTarget(self, action: #selector(syncButtonTapped), for: .touchUpInside)
        
        // Add sync icon
        let syncIcon = UIImageView(image: UIImage(systemName: "arrow.clockwise"))
        syncIcon.translatesAutoresizingMaskIntoConstraints = false
        syncIcon.tintColor = IndustrialDesign.Colors.primaryText
        syncIcon.contentMode = .scaleAspectFit
        
        view.addSubview(headerView)
        headerView.addSubview(backButton)
        headerView.addSubview(pageTitleLabel)
        headerView.addSubview(syncButton)
        syncButton.addSubview(syncIcon)
        
        NSLayoutConstraint.activate([
            // Sync icon inside sync button
            syncIcon.leadingAnchor.constraint(equalTo: syncButton.leadingAnchor, constant: 8),
            syncIcon.centerYAnchor.constraint(equalTo: syncButton.centerYAnchor),
            syncIcon.widthAnchor.constraint(equalToConstant: 16),
            syncIcon.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        setupSyncButtonHoverEffects()
    }
    
    private func setupSyncButtonHoverEffects() {
        syncButton.addTarget(self, action: #selector(syncButtonPressed), for: .touchDown)
        syncButton.addTarget(self, action: #selector(syncButtonReleased), for: .touchUpInside)
        syncButton.addTarget(self, action: #selector(syncButtonReleased), for: .touchUpOutside)
        syncButton.addTarget(self, action: #selector(syncButtonReleased), for: .touchCancel)
    }
    
    private func setupTabNavigation() {
        tabNavigationView.translatesAutoresizingMaskIntoConstraints = false
        tabNavigationView.delegate = self
        tabNavigationView.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        
        view.addSubview(tabNavigationView)
    }
    
    private func setupContentArea() {
        contentContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 0.95)
        
        // Setup individual views
        syncView.translatesAutoresizingMaskIntoConstraints = false
        statsView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(contentContainerView)
        contentContainerView.addSubview(syncView)
        contentContainerView.addSubview(statsView)
        
        // Hide all views initially
        syncView.isHidden = true
        statsView.isHidden = true
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Header
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 80),
            
            // Back button
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 24),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Page title
            pageTitleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            pageTitleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            // Sync button
            syncButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -24),
            syncButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            syncButton.widthAnchor.constraint(equalToConstant: 80),
            syncButton.heightAnchor.constraint(equalToConstant: 32),
            
            // Tab navigation
            tabNavigationView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tabNavigationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabNavigationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabNavigationView.heightAnchor.constraint(equalToConstant: 50),
            
            // Content container
            contentContainerView.topAnchor.constraint(equalTo: tabNavigationView.bottomAnchor),
            contentContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content views - all fill the container
            syncView.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            syncView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            syncView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            syncView.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor),
            
            statsView.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            statsView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            statsView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            statsView.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor)
        ])
    }
    
    // MARK: - Tab Management
    
    private func switchToTab(_ tab: WorkoutTab) {
        currentTab = tab
        
        // Hide all views
        syncView.isHidden = true
        statsView.isHidden = true
        
        // Show selected view
        switch tab {
        case .sync:
            syncView.isHidden = false
            syncView.loadSampleData()
        case .stats:
            statsView.isHidden = false
            statsView.loadSampleData()
        }
        
        // Update tab navigation
        tabNavigationView.selectTab(tab)
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        print("🏃‍♂️ LevelFitness: Workouts back button tapped")
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func syncButtonTapped() {
        print("🏃‍♂️ LevelFitness: Sync button tapped")
        // TODO: Implement workout sync
        showSyncAnimation()
    }
    
    @objc private func syncButtonPressed() {
        UIView.animate(withDuration: 0.1) {
            self.syncButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.syncButton.alpha = 0.8
        }
    }
    
    @objc private func syncButtonReleased() {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            self.syncButton.transform = .identity
            self.syncButton.alpha = 1.0
        }
    }
    
    private func showSyncAnimation() {
        guard let syncIcon = syncButton.subviews.first(where: { $0 is UIImageView }) else { return }
        
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = 0
        rotation.toValue = CGFloat.pi * 2
        rotation.duration = 1.0
        rotation.repeatCount = 2
        rotation.isRemovedOnCompletion = true
        
        syncIcon.layer.add(rotation, forKey: "syncRotation")
    }
}

// MARK: - WorkoutTabNavigationViewDelegate

extension WorkoutsViewController: WorkoutTabNavigationViewDelegate {
    func didSelectTab(_ tab: WorkoutTab) {
        print("🏃‍♂️ LevelFitness: Selected tab: \(tab)")
        switchToTab(tab)
    }
}