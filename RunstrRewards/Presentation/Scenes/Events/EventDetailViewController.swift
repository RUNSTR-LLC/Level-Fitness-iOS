import UIKit

class EventDetailViewController: UIViewController {
    
    // MARK: - Properties
    private let event: CompetitionEvent
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let headerView = UIView()
    private let backButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    private let eventImageView = UIImageView()
    private let detailsContainer = UIView()
    private let descriptionContainer = UIView()
    private let registrationContainer = UIView()
    private let joinButton = UIButton(type: .custom)
    
    // Completion handler for registration
    var onRegistrationComplete: ((Bool) -> Void)?
    
    // MARK: - Initialization
    
    init(event: CompetitionEvent) {
        self.event = event
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("📅 EventDetail: Loading details for event: \(event.name)")
        
        setupIndustrialBackground()
        setupScrollView()
        setupHeader()
        setupEventImage()
        setupDetailsContainer()
        setupDescriptionContainer()
        setupRegistrationContainer()
        setupConstraints()
        
        configureWithEventData()
    }
    
    // MARK: - Setup Methods
    
    private func setupIndustrialBackground() {
        view.backgroundColor = IndustrialDesign.Colors.background
        
        // Add grid pattern
        let gridView = GridPatternView()
        gridView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gridView)
        
        NSLayoutConstraint.activate([
            gridView.topAnchor.constraint(equalTo: view.topAnchor),
            gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Add gear decoration
        let gear = RotatingGearView(size: 80)
        gear.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gear)
        
        NSLayoutConstraint.activate([
            gear.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            gear.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 20),
            gear.widthAnchor.constraint(equalToConstant: 80),
            gear.heightAnchor.constraint(equalToConstant: 80)
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
        
        // Back button
        backButton.setTitle("← Back", for: .normal)
        backButton.setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        // Title
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(backButton)
        headerView.addSubview(titleLabel)
        contentView.addSubview(headerView)
    }
    
    private func setupEventImage() {
        eventImageView.translatesAutoresizingMaskIntoConstraints = false
        eventImageView.contentMode = .scaleAspectFill
        eventImageView.clipsToBounds = true
        eventImageView.layer.cornerRadius = 12
        eventImageView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        
        // Default event type icon if no image
        eventImageView.image = UIImage(systemName: "trophy.fill")
        eventImageView.tintColor = IndustrialDesign.Colors.bitcoin
        
        contentView.addSubview(eventImageView)
    }
    
    private func setupDetailsContainer() {
        detailsContainer.translatesAutoresizingMaskIntoConstraints = false
        detailsContainer.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        detailsContainer.layer.cornerRadius = 12
        detailsContainer.layer.borderWidth = 1
        detailsContainer.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        contentView.addSubview(detailsContainer)
        
        // Create detail items
        createDetailItems()
    }
    
    private func createDetailItems() {
        let detailData = [
            ("📅", "Date Range", event.formattedDateRange),
            ("💰", "Prize Pool", event.formattedPrizePool),
            ("💸", "Entry Fee", event.formattedEntryFee),
            ("👥", "Participants", "\(event.participants)")
        ]
        
        var previousView: UIView? = nil
        
        for (icon, label, value) in detailData {
            let itemView = createDetailItemView(icon: icon, label: label, value: value)
            detailsContainer.addSubview(itemView)
            
            NSLayoutConstraint.activate([
                itemView.leadingAnchor.constraint(equalTo: detailsContainer.leadingAnchor, constant: 20),
                itemView.trailingAnchor.constraint(equalTo: detailsContainer.trailingAnchor, constant: -20),
                itemView.topAnchor.constraint(equalTo: previousView?.bottomAnchor ?? detailsContainer.topAnchor, constant: 16),
                itemView.heightAnchor.constraint(equalToConstant: 40)
            ])
            
            previousView = itemView
        }
        
        // Set container height
        if let lastView = previousView {
            detailsContainer.bottomAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 16).isActive = true
        }
    }
    
    private func createDetailItemView(icon: String, label: String, value: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let iconLabel = UILabel()
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        iconLabel.text = icon
        iconLabel.font = UIFont.systemFont(ofSize: 16)
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = label
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = IndustrialDesign.Colors.secondaryText
        
        let valueLabel = UILabel()
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        valueLabel.textColor = IndustrialDesign.Colors.primaryText
        valueLabel.textAlignment = .right
        
        container.addSubview(iconLabel)
        container.addSubview(titleLabel)
        container.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            iconLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconLabel.widthAnchor.constraint(equalToConstant: 30),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 16)
        ])
        
        return container
    }
    
    private func setupDescriptionContainer() {
        descriptionContainer.translatesAutoresizingMaskIntoConstraints = false
        descriptionContainer.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        descriptionContainer.layer.cornerRadius = 12
        descriptionContainer.layer.borderWidth = 1
        descriptionContainer.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        let descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = event.description ?? "Join this exciting fitness event and compete with others to win Bitcoin rewards!"
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textColor = IndustrialDesign.Colors.primaryText
        descriptionLabel.numberOfLines = 0
        
        descriptionContainer.addSubview(descriptionLabel)
        contentView.addSubview(descriptionContainer)
        
        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: descriptionContainer.topAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: descriptionContainer.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: descriptionContainer.trailingAnchor, constant: -20),
            descriptionLabel.bottomAnchor.constraint(equalTo: descriptionContainer.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupRegistrationContainer() {
        registrationContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Join button
        joinButton.translatesAutoresizingMaskIntoConstraints = false
        joinButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        joinButton.layer.cornerRadius = 12
        joinButton.addTarget(self, action: #selector(joinButtonTapped), for: .touchUpInside)
        
        registrationContainer.addSubview(joinButton)
        contentView.addSubview(registrationContainer)
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
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            headerView.heightAnchor.constraint(equalToConstant: 80),
            
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            backButton.topAnchor.constraint(equalTo: headerView.topAnchor),
            
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            
            // Event Image
            eventImageView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            eventImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            eventImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            eventImageView.heightAnchor.constraint(equalToConstant: 200),
            
            // Details Container
            detailsContainer.topAnchor.constraint(equalTo: eventImageView.bottomAnchor, constant: 20),
            detailsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            detailsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            // Description Container
            descriptionContainer.topAnchor.constraint(equalTo: detailsContainer.bottomAnchor, constant: 20),
            descriptionContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            descriptionContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            // Registration Container
            registrationContainer.topAnchor.constraint(equalTo: descriptionContainer.bottomAnchor, constant: 20),
            registrationContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            registrationContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            registrationContainer.heightAnchor.constraint(equalToConstant: 80),
            registrationContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
            
            // Join Button
            joinButton.topAnchor.constraint(equalTo: registrationContainer.topAnchor),
            joinButton.leadingAnchor.constraint(equalTo: registrationContainer.leadingAnchor),
            joinButton.trailingAnchor.constraint(equalTo: registrationContainer.trailingAnchor),
            joinButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func configureWithEventData() {
        titleLabel.text = event.name
        
        // Configure join button based on registration status
        if event.isRegistered {
            joinButton.setTitle("ALREADY REGISTERED", for: .normal)
            joinButton.backgroundColor = UIColor.clear
            joinButton.layer.borderWidth = 1
            joinButton.layer.borderColor = IndustrialDesign.Colors.secondaryText.cgColor
            joinButton.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
            joinButton.isEnabled = false
        } else {
            joinButton.setTitle("JOIN EVENT - \(event.formattedEntryFee)", for: .normal)
            joinButton.backgroundColor = IndustrialDesign.Colors.bitcoin
            joinButton.setTitleColor(.white, for: .normal)
            joinButton.isEnabled = true
        }
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        print("📅 EventDetail: Back button tapped")
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func joinButtonTapped() {
        guard !event.isRegistered else { return }
        
        print("📅 EventDetail: Join button tapped for event: \(event.name)")
        
        let alert = UIAlertController(
            title: "Join Event",
            message: "Are you sure you want to join '\(event.name)' for \(event.formattedEntryFee)?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Join", style: .default) { _ in
            self.processEventRegistration()
        })
        
        present(alert, animated: true)
    }
    
    private func processEventRegistration() {
        // Show loading state
        joinButton.setTitle("JOINING...", for: .normal)
        joinButton.isEnabled = false
        
        Task {
            do {
                // Register user for event via SupabaseService
                try await SupabaseService.shared.registerUserForEvent(eventId: event.id, userId: AuthenticationService.shared.currentUserId ?? "")
                
                await MainActor.run {
                    // Update button to registered state
                    joinButton.setTitle("REGISTERED ✓", for: .normal)
                    joinButton.backgroundColor = UIColor.clear
                    joinButton.layer.borderWidth = 1
                    joinButton.layer.borderColor = IndustrialDesign.Colors.bitcoin.cgColor
                    joinButton.setTitleColor(IndustrialDesign.Colors.bitcoin, for: .normal)
                    
                    // Call completion handler
                    onRegistrationComplete?(true)
                    
                    print("📅 EventDetail: Successfully registered for event: \(event.name)")
                }
                
            } catch {
                print("📅 EventDetail: Failed to register for event: \(error)")
                
                await MainActor.run {
                    // Reset button state
                    joinButton.setTitle("JOIN EVENT - \(event.formattedEntryFee)", for: .normal)
                    joinButton.isEnabled = true
                    
                    // Show error alert
                    let errorAlert = UIAlertController(
                        title: "Registration Failed",
                        message: "Sorry, we couldn't register you for this event. Please try again.",
                        preferredStyle: .alert
                    )
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    present(errorAlert, animated: true)
                    
                    onRegistrationComplete?(false)
                }
            }
        }
    }
}