import UIKit

class CaptainAnnouncementViewController: UIViewController {
    
    // MARK: - Properties
    private let teamData: TeamData
    private var selectedPriority: TeamAnnouncement.AnnouncementPriority = .normal
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    
    private let formContainer = UIView()
    private let announcementTitleField = UITextField()
    private let messageTextView = UITextView()
    private let prioritySelector = UISegmentedControl(items: ["Info", "Normal", "Important", "Urgent"])
    
    private let previewContainer = UIView()
    private let previewLabel = UILabel()
    private let previewContent = UILabel()
    
    private let sendButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
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
        setupUI()
        setupConstraints()
        setupActions()
        
        print("CaptainAnnouncement: Announcement composer opened for team \(teamData.name)")
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        view.backgroundColor = IndustrialDesign.Colors.background
        
        setupScrollView()
        setupHeader()
        setupForm()
        setupPreview()
        setupSendButton()
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.95)
        headerView.layer.cornerRadius = 16
        headerView.layer.borderWidth = 1
        headerView.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        
        titleLabel.text = "Send Team Announcement"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = IndustrialDesign.Colors.secondaryText
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        [titleLabel, closeButton].forEach { headerView.addSubview($0) }
        contentView.addSubview(headerView)
    }
    
    private func setupForm() {
        formContainer.translatesAutoresizingMaskIntoConstraints = false
        formContainer.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.95)
        formContainer.layer.cornerRadius = 16
        formContainer.layer.borderWidth = 1
        formContainer.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        
        // Title field
        announcementTitleField.placeholder = "Announcement title..."
        announcementTitleField.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        announcementTitleField.textColor = IndustrialDesign.Colors.primaryText
        announcementTitleField.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        announcementTitleField.layer.cornerRadius = 8
        announcementTitleField.layer.borderWidth = 1
        announcementTitleField.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        announcementTitleField.translatesAutoresizingMaskIntoConstraints = false
        
        // Add padding to text field
        announcementTitleField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        announcementTitleField.leftViewMode = .always
        announcementTitleField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        announcementTitleField.rightViewMode = .always
        
        // Message text view
        messageTextView.text = "Write your message to the team..."
        messageTextView.font = UIFont.systemFont(ofSize: 14)
        messageTextView.textColor = IndustrialDesign.Colors.secondaryText
        messageTextView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        messageTextView.layer.cornerRadius = 8
        messageTextView.layer.borderWidth = 1
        messageTextView.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        messageTextView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        messageTextView.translatesAutoresizingMaskIntoConstraints = false
        
        // Priority selector
        prioritySelector.selectedSegmentIndex = 1 // Normal
        prioritySelector.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        prioritySelector.selectedSegmentTintColor = IndustrialDesign.Colors.bitcoin
        prioritySelector.setTitleTextAttributes([.foregroundColor: IndustrialDesign.Colors.primaryText], for: .normal)
        prioritySelector.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
        prioritySelector.translatesAutoresizingMaskIntoConstraints = false
        
        let priorityLabel = UILabel()
        priorityLabel.text = "Priority Level"
        priorityLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        priorityLabel.textColor = IndustrialDesign.Colors.primaryText
        priorityLabel.translatesAutoresizingMaskIntoConstraints = false
        
        [announcementTitleField, messageTextView, priorityLabel, prioritySelector].forEach {
            formContainer.addSubview($0)
        }
        
        contentView.addSubview(formContainer)
    }
    
    private func setupPreview() {
        previewContainer.translatesAutoresizingMaskIntoConstraints = false
        previewContainer.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.95)
        previewContainer.layer.cornerRadius = 16
        previewContainer.layer.borderWidth = 1
        previewContainer.layer.borderColor = UIColor(red: 0.27, green: 0.47, blue: 0.87, alpha: 0.5).cgColor // Blue border
        
        previewLabel.text = "Notification Preview"
        previewLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        previewLabel.textColor = UIColor(red: 0.27, green: 0.47, blue: 0.87, alpha: 1.0)
        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        
        previewContent.text = "📢 \(teamData.name)\nYour announcement will appear here..."
        previewContent.font = UIFont.systemFont(ofSize: 13)
        previewContent.textColor = IndustrialDesign.Colors.secondaryText
        previewContent.numberOfLines = 0
        previewContent.translatesAutoresizingMaskIntoConstraints = false
        
        [previewLabel, previewContent].forEach { previewContainer.addSubview($0) }
        contentView.addSubview(previewContainer)
    }
    
    private func setupSendButton() {
        sendButton.setTitle("Send Announcement", for: .normal)
        sendButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        sendButton.setTitleColor(.black, for: .normal)
        sendButton.backgroundColor = IndustrialDesign.Colors.bitcoin
        sendButton.layer.cornerRadius = 25
        sendButton.layer.shadowColor = UIColor.black.cgColor
        sendButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        sendButton.layer.shadowRadius = 8
        sendButton.layer.shadowOpacity = 0.3
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        
        loadingIndicator.color = .black
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        
        sendButton.addSubview(loadingIndicator)
        contentView.addSubview(sendButton)
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
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 28),
            closeButton.heightAnchor.constraint(equalToConstant: 28),
            
            // Form container
            formContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            formContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            formContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Form fields within container
            announcementTitleField.topAnchor.constraint(equalTo: formContainer.topAnchor, constant: 20),
            announcementTitleField.leadingAnchor.constraint(equalTo: formContainer.leadingAnchor, constant: 16),
            announcementTitleField.trailingAnchor.constraint(equalTo: formContainer.trailingAnchor, constant: -16),
            announcementTitleField.heightAnchor.constraint(equalToConstant: 44),
            
            messageTextView.topAnchor.constraint(equalTo: announcementTitleField.bottomAnchor, constant: 16),
            messageTextView.leadingAnchor.constraint(equalTo: formContainer.leadingAnchor, constant: 16),
            messageTextView.trailingAnchor.constraint(equalTo: formContainer.trailingAnchor, constant: -16),
            messageTextView.heightAnchor.constraint(equalToConstant: 120),
            
            // Priority label is set up within form container constraints
            formContainer.subviews[2].topAnchor.constraint(equalTo: messageTextView.bottomAnchor, constant: 20),
            formContainer.subviews[2].leadingAnchor.constraint(equalTo: formContainer.leadingAnchor, constant: 16),
            
            prioritySelector.topAnchor.constraint(equalTo: formContainer.subviews[2].bottomAnchor, constant: 8),
            prioritySelector.leadingAnchor.constraint(equalTo: formContainer.leadingAnchor, constant: 16),
            prioritySelector.trailingAnchor.constraint(equalTo: formContainer.trailingAnchor, constant: -16),
            prioritySelector.heightAnchor.constraint(equalToConstant: 36),
            prioritySelector.bottomAnchor.constraint(equalTo: formContainer.bottomAnchor, constant: -20),
            
            // Preview container
            previewContainer.topAnchor.constraint(equalTo: formContainer.bottomAnchor, constant: 20),
            previewContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            previewContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            previewLabel.topAnchor.constraint(equalTo: previewContainer.topAnchor, constant: 16),
            previewLabel.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: 16),
            
            previewContent.topAnchor.constraint(equalTo: previewLabel.bottomAnchor, constant: 8),
            previewContent.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: 16),
            previewContent.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: -16),
            previewContent.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: -16),
            
            // Send button
            sendButton.topAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: 30),
            sendButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            sendButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            sendButton.heightAnchor.constraint(equalToConstant: 50),
            sendButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
            
            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: sendButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: sendButton.centerYAnchor)
        ])
    }
    
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        prioritySelector.addTarget(self, action: #selector(priorityChanged), for: .valueChanged)
        
        announcementTitleField.addTarget(self, action: #selector(updatePreview), for: .editingChanged)
        
        // Text view delegate for live preview updates
        messageTextView.delegate = self
        
        // Dismiss keyboard when tapping outside
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Actions
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func sendButtonTapped() {
        guard let title = announcementTitleField.text, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let message = messageTextView.text, !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              message != "Write your message to the team..." else {
            showAlert(title: "Missing Information", message: "Please enter both a title and message for your announcement.")
            return
        }
        
        sendButton.isEnabled = false
        loadingIndicator.startAnimating()
        sendButton.setTitle("", for: .normal)
        
        Task {
            do {
                try await CaptainAnnouncementService.shared.sendTeamAnnouncement(
                    teamId: teamData.id,
                    title: title,
                    message: message,
                    priority: selectedPriority
                )
                
                await MainActor.run {
                    self.dismiss(animated: true) {
                        // Show success message in parent view
                        NotificationCenter.default.post(
                            name: .announcementSent, 
                            object: nil, 
                            userInfo: ["title": title]
                        )
                    }
                }
            } catch {
                await MainActor.run {
                    self.sendButton.isEnabled = true
                    self.loadingIndicator.stopAnimating()
                    self.sendButton.setTitle("Send Announcement", for: .normal)
                    
                    self.showAlert(
                        title: "Send Failed", 
                        message: error.localizedDescription
                    )
                }
            }
        }
    }
    
    @objc private func priorityChanged() {
        let priorities = TeamAnnouncement.AnnouncementPriority.allCases
        let index = prioritySelector.selectedSegmentIndex
        selectedPriority = (index >= 0 && index < priorities.count) ? priorities[index] : .normal
        updatePreview()
    }
    
    @objc private func updatePreview() {
        let title = announcementTitleField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let message = messageTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        if title.isEmpty && message.isEmpty {
            previewContent.text = "📢 \(teamData.name)\nYour announcement will appear here..."
        } else {
            let priorityEmoji = getPriorityEmoji(selectedPriority)
            let previewTitle = title.isEmpty ? "Untitled Announcement" : title
            let previewMessage = message.isEmpty || message == "Write your message to the team..." ? "Your message here..." : message
            
            previewContent.text = "\(priorityEmoji) \(teamData.name)\n\(previewTitle)\n\n\(previewMessage)"
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Helper Methods
    
    private func getPriorityEmoji(_ priority: TeamAnnouncement.AnnouncementPriority) -> String {
        switch priority {
        case .low: return "ℹ️"
        case .normal: return "📢"
        case .high: return "⚠️"
        case .urgent: return "🚨"
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextViewDelegate

extension CaptainAnnouncementViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Write your message to the team..." {
            textView.text = ""
            textView.textColor = IndustrialDesign.Colors.primaryText
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = "Write your message to the team..."
            textView.textColor = IndustrialDesign.Colors.secondaryText
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        updatePreview()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let announcementSent = Notification.Name("announcementSent")
}