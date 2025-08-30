import UIKit

// MARK: - NotificationCellDelegate Protocol

protocol NotificationCellDelegate: AnyObject {
    func notificationCellTapped(notification: NotificationItem)
}

public class NotificationInboxViewController: UIViewController, NotificationCellDelegate {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header
    private let headerView = UIView()
    private let titleLabel = UILabel()
    
    // Notifications list
    private let notificationsContainer = UIView()
    private let refreshControl = UIRefreshControl()
    private var notificationViews: [UIView] = []
    
    // Empty state
    private let emptyStateView = UIView()
    private let emptyStateIcon = UIImageView()
    private let emptyStateLabel = UILabel()
    private let emptyStateDescription = UILabel()
    
    // Loading
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    // Data
    private var notifications: [NotificationItem] = []
    private var groupedNotifications: [String: [NotificationItem]] = [:]
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        print("📥 NotificationInbox: Loading inbox...")
        
        // Hide navigation bar since we have custom header with back button
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupIndustrialBackground()
        setupScrollView()
        setupHeader()
        setupNotificationsContainer()
        setupEmptyState()
        setupLoadingIndicator()
        setupConstraints()
        loadNotifications()
        
        print("📥 NotificationInbox: Inbox loaded successfully!")
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Only refresh if we don't already have notifications loaded
        if notifications.isEmpty {
            loadNotifications()
        }
    }
    
    // MARK: - Setup Methods
    
    private func setupIndustrialBackground() {
        view.backgroundColor = IndustrialDesign.Colors.background
        
        // Add grid pattern background
        let gridView = GridPatternView()
        gridView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gridView)
        
        NSLayoutConstraint.activate([
            gridView.topAnchor.constraint(equalTo: view.topAnchor),
            gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add refresh control
        refreshControl.addTarget(self, action: #selector(refreshNotifications), for: .valueChanged)
        refreshControl.tintColor = IndustrialDesign.Colors.bitcoin
        scrollView.refreshControl = refreshControl
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        
        // Add bottom border
        let borderLayer = CALayer()
        borderLayer.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
        headerView.layer.addSublayer(borderLayer)
        
        // Back button
        let backButton = UIButton(type: .custom)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = IndustrialDesign.Colors.secondaryText
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        // Title
        titleLabel.text = "Notifications"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(backButton)
        headerView.addSubview(titleLabel)
        contentView.addSubview(headerView)
        
        // Add constraints for header elements
        NSLayoutConstraint.activate([
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        // Update border frame
        DispatchQueue.main.async {
            borderLayer.frame = CGRect(x: 0, y: 59, width: self.view.frame.width, height: 1)
        }
    }
    
    @objc private func backButtonTapped() {
        print("📥 NotificationInbox: Back button tapped")
        navigationController?.popViewController(animated: true)
    }
    
    private func setupNotificationsContainer() {
        notificationsContainer.translatesAutoresizingMaskIntoConstraints = false
        notificationsContainer.backgroundColor = .clear
        contentView.addSubview(notificationsContainer)
    }
    
    private func setupEmptyState() {
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.backgroundColor = .clear
        emptyStateView.isHidden = true
        
        // Icon
        emptyStateIcon.image = UIImage(systemName: "bell.slash")
        emptyStateIcon.tintColor = IndustrialDesign.Colors.secondaryText
        emptyStateIcon.contentMode = .scaleAspectFit
        emptyStateIcon.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        emptyStateLabel.text = "No Notifications"
        emptyStateLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        emptyStateLabel.textColor = IndustrialDesign.Colors.secondaryText
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Description
        emptyStateDescription.text = "When your team has new activity or you receive challenges, they'll appear here."
        emptyStateDescription.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        emptyStateDescription.textColor = IndustrialDesign.Colors.secondaryText
        emptyStateDescription.textAlignment = .center
        emptyStateDescription.numberOfLines = 0
        emptyStateDescription.translatesAutoresizingMaskIntoConstraints = false
        
        emptyStateView.addSubview(emptyStateIcon)
        emptyStateView.addSubview(emptyStateLabel)
        emptyStateView.addSubview(emptyStateDescription)
        contentView.addSubview(emptyStateView)
    }
    
    private func setupLoadingIndicator() {
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.color = IndustrialDesign.Colors.bitcoin
        loadingIndicator.hidesWhenStopped = true
        contentView.addSubview(loadingIndicator)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
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
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            // Notifications container
            notificationsContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 24),
            notificationsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            notificationsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            notificationsContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            // Empty state
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            emptyStateIcon.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            emptyStateIcon.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateIcon.widthAnchor.constraint(equalToConstant: 64),
            emptyStateIcon.heightAnchor.constraint(equalToConstant: 64),
            
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateIcon.bottomAnchor, constant: 16),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            
            emptyStateDescription.topAnchor.constraint(equalTo: emptyStateLabel.bottomAnchor, constant: 8),
            emptyStateDescription.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptyStateDescription.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            emptyStateDescription.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor),
            
            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}