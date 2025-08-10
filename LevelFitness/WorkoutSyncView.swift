import UIKit

protocol WorkoutSyncViewDelegate: AnyObject {
    func didTapSyncSource(_ source: SyncSourceData)
}

class WorkoutSyncView: UIView {
    
    // MARK: - Properties
    weak var delegate: WorkoutSyncViewDelegate?
    private var syncSources: [SyncSourceData] = []
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let syncSourcesContainer = UIView()
    private let syncSourcesTitle = UILabel()
    private let sourcesGridContainer = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup Methods
    
    private func setupView() {
        backgroundColor = UIColor.clear
        
        // Scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.indicatorStyle = .white
        scrollView.backgroundColor = UIColor.clear
        
        // Content view
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = UIColor.clear
        
        // Sync sources container
        syncSourcesContainer.translatesAutoresizingMaskIntoConstraints = false
        syncSourcesContainer.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        syncSourcesContainer.layer.cornerRadius = 12
        syncSourcesContainer.layer.borderWidth = 1
        syncSourcesContainer.layer.borderColor = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0).cgColor
        
        // Add gradient background
        DispatchQueue.main.async {
            self.setupSyncSourcesGradient()
        }
        
        // Sync sources title
        syncSourcesTitle.translatesAutoresizingMaskIntoConstraints = false
        syncSourcesTitle.text = "CONNECTED SOURCES"
        syncSourcesTitle.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        syncSourcesTitle.textColor = IndustrialDesign.Colors.accentText
        syncSourcesTitle.letterSpacing = 1
        
        // Sources grid container
        sourcesGridContainer.translatesAutoresizingMaskIntoConstraints = false
        
        
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(syncSourcesContainer)
        
        syncSourcesContainer.addSubview(syncSourcesTitle)
        syncSourcesContainer.addSubview(sourcesGridContainer)
        
        // Add bolt decoration to sync sources
        let boltDecoration = UIView()
        boltDecoration.translatesAutoresizingMaskIntoConstraints = false
        boltDecoration.backgroundColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0)
        boltDecoration.layer.cornerRadius = 3
        boltDecoration.layer.borderWidth = 1
        boltDecoration.layer.borderColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor
        syncSourcesContainer.addSubview(boltDecoration)
        
        NSLayoutConstraint.activate([
            boltDecoration.topAnchor.constraint(equalTo: syncSourcesContainer.topAnchor, constant: 12),
            boltDecoration.trailingAnchor.constraint(equalTo: syncSourcesContainer.trailingAnchor, constant: -12),
            boltDecoration.widthAnchor.constraint(equalToConstant: 6),
            boltDecoration.heightAnchor.constraint(equalToConstant: 6)
        ])
    }
    
    private func setupSyncSourcesGradient() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor,
            UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = syncSourcesContainer.bounds
        
        syncSourcesContainer.layer.insertSublayer(gradientLayer, at: 0)
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
            
            // Sync sources container
            syncSourcesContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            syncSourcesContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            syncSourcesContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            syncSourcesContainer.heightAnchor.constraint(equalToConstant: 220),
            
            // Sync sources title
            syncSourcesTitle.topAnchor.constraint(equalTo: syncSourcesContainer.topAnchor, constant: 20),
            syncSourcesTitle.leadingAnchor.constraint(equalTo: syncSourcesContainer.leadingAnchor, constant: 24),
            syncSourcesTitle.trailingAnchor.constraint(equalTo: syncSourcesContainer.trailingAnchor, constant: -24),
            
            // Sources grid container
            sourcesGridContainer.topAnchor.constraint(equalTo: syncSourcesTitle.bottomAnchor, constant: 20),
            sourcesGridContainer.leadingAnchor.constraint(equalTo: syncSourcesContainer.leadingAnchor, constant: 20),
            sourcesGridContainer.trailingAnchor.constraint(equalTo: syncSourcesContainer.trailingAnchor, constant: -20),
            sourcesGridContainer.bottomAnchor.constraint(equalTo: syncSourcesContainer.bottomAnchor, constant: -20),
            
            // Content view bottom anchor
            syncSourcesContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update gradient frame
        if let gradientLayer = syncSourcesContainer.layer.sublayers?.first(where: { $0 is CAGradientLayer }) as? CAGradientLayer {
            gradientLayer.frame = syncSourcesContainer.bounds
        }
    }
    
    // MARK: - Public Methods
    
    func loadSampleData() {
        loadSampleSyncSources()
    }
    
    func updateHealthKitConnectionStatus(connected: Bool) {
        // Find HealthKit source and update its connection status
        if let index = syncSources.firstIndex(where: { $0.type == .healthKit }) {
            syncSources[index] = SyncSourceData(
                id: syncSources[index].id,
                type: syncSources[index].type,
                isConnected: connected,
                lastSync: connected ? Date() : nil,
                workoutCount: syncSources[index].workoutCount
            )
            buildSyncSourcesGrid()
        }
    }
    
    func updateWithHealthKitWorkouts(_ workouts: [HealthKitWorkout]) {
        print("🏃‍♂️ LevelFitness: Updating sync view with \(workouts.count) HealthKit workouts")
        
        // Update HealthKit source with real data
        let healthKitConnected = !workouts.isEmpty
        let lastSync = workouts.first?.startDate
        
        syncSources = [
            SyncSourceData(
                id: "healthkit",
                type: .healthKit,
                isConnected: healthKitConnected,
                lastSync: lastSync,
                workoutCount: workouts.count
            ),
            SyncSourceData(
                id: "strava",
                type: .strava,
                isConnected: false,
                lastSync: nil,
                workoutCount: 0
            ),
            SyncSourceData(
                id: "garmin",
                type: .garmin,
                isConnected: false,
                lastSync: nil,
                workoutCount: 0
            ),
            SyncSourceData(
                id: "googlefit",
                type: .googleFit,
                isConnected: false,
                lastSync: nil,
                workoutCount: 0
            )
        ]
        
        buildSyncSourcesGrid()
    }
    
    private func loadSampleSyncSources() {
        syncSources = [
            SyncSourceData(
                id: "healthkit",
                type: .healthKit,
                isConnected: true,
                lastSync: Date(),
                workoutCount: 25
            ),
            SyncSourceData(
                id: "strava",
                type: .strava,
                isConnected: false,
                lastSync: nil,
                workoutCount: 0
            ),
            SyncSourceData(
                id: "garmin",
                type: .garmin,
                isConnected: false,
                lastSync: nil,
                workoutCount: 0
            ),
            SyncSourceData(
                id: "googlefit",
                type: .googleFit,
                isConnected: false,
                lastSync: nil,
                workoutCount: 0
            )
        ]
        
        buildSyncSourcesGrid()
    }
    
    
    private func buildSyncSourcesGrid() {
        // Clear existing views
        sourcesGridContainer.subviews.forEach { $0.removeFromSuperview() }
        
        // Create cards for each sync source
        let cards = syncSources.map { source in
            let card = WorkoutSyncSourceCard(sourceData: source)
            card.translatesAutoresizingMaskIntoConstraints = false
            card.delegate = self
            sourcesGridContainer.addSubview(card)
            return card
        }
        
        // Layout cards in 2x2 grid format
        if cards.count >= 4 {
            let spacing: CGFloat = 12
            
            NSLayoutConstraint.activate([
                // Row 1: HealthKit (cards[0]) and Strava (cards[1])
                // HealthKit - top left
                cards[0].topAnchor.constraint(equalTo: sourcesGridContainer.topAnchor),
                cards[0].leadingAnchor.constraint(equalTo: sourcesGridContainer.leadingAnchor),
                cards[0].trailingAnchor.constraint(equalTo: sourcesGridContainer.centerXAnchor, constant: -spacing/2),
                cards[0].heightAnchor.constraint(equalToConstant: 70),
                
                // Strava - top right  
                cards[1].topAnchor.constraint(equalTo: sourcesGridContainer.topAnchor),
                cards[1].leadingAnchor.constraint(equalTo: sourcesGridContainer.centerXAnchor, constant: spacing/2),
                cards[1].trailingAnchor.constraint(equalTo: sourcesGridContainer.trailingAnchor),
                cards[1].heightAnchor.constraint(equalToConstant: 70),
                
                // Row 2: Garmin (cards[2]) and Google Fit (cards[3])
                // Garmin - bottom left
                cards[2].topAnchor.constraint(equalTo: cards[0].bottomAnchor, constant: spacing),
                cards[2].leadingAnchor.constraint(equalTo: sourcesGridContainer.leadingAnchor),
                cards[2].trailingAnchor.constraint(equalTo: sourcesGridContainer.centerXAnchor, constant: -spacing/2),
                cards[2].heightAnchor.constraint(equalToConstant: 70),
                
                // Google Fit - bottom right
                cards[3].topAnchor.constraint(equalTo: cards[1].bottomAnchor, constant: spacing),
                cards[3].leadingAnchor.constraint(equalTo: sourcesGridContainer.centerXAnchor, constant: spacing/2),
                cards[3].trailingAnchor.constraint(equalTo: sourcesGridContainer.trailingAnchor),
                cards[3].heightAnchor.constraint(equalToConstant: 70)
            ])
        }
    }
    
    
    // MARK: - Actions
    
}

// MARK: - WorkoutSyncSourceCardDelegate

extension WorkoutSyncView: WorkoutSyncSourceCardDelegate {
    func didTapSyncSource(_ source: SyncSourceData) {
        print("🏃‍♂️ LevelFitness: Sync source selected: \(source.type.displayName)")
        
        if source.isConnected {
            showDisconnectAlert(for: source)
        } else {
            showConnectAlert(for: source)
        }
        
        delegate?.didTapSyncSource(source)
    }
    
    private func showConnectAlert(for source: SyncSourceData) {
        guard let parentViewController = findViewController() else { return }
        
        let alert = UIAlertController(
            title: "Connect \(source.type.displayName)",
            message: "Connect your \(source.type.displayName) account to automatically sync your workouts and earn rewards.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Connect", style: .default) { _ in
            print("🏃‍♂️ LevelFitness: Connecting to \(source.type.displayName)")
            // TODO: Implement actual connection logic
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        parentViewController.present(alert, animated: true)
    }
    
    private func showDisconnectAlert(for source: SyncSourceData) {
        guard let parentViewController = findViewController() else { return }
        
        let alert = UIAlertController(
            title: "Disconnect \(source.type.displayName)",
            message: "Are you sure you want to disconnect \(source.type.displayName)? You'll stop earning rewards for workouts from this source.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Disconnect", style: .destructive) { _ in
            print("🏃‍♂️ LevelFitness: Disconnecting from \(source.type.displayName)")
            // TODO: Implement actual disconnection logic
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        parentViewController.present(alert, animated: true)
    }
}

// MARK: - Helper Extension

extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}