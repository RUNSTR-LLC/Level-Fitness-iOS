import UIKit

class TeamDetailChatViewController: UIViewController {
    
    // MARK: - Properties
    private let teamData: TeamData
    private var currentMessages: [MessageData] = []
    
    // MARK: - UI Components
    private let chatContainer = UIView()
    private let messageInput = MessageInputView()
    private var messageViews: [MessageView] = []
    
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
        setupChatContainer()
        setupMessageInput()
        loadRealMessages()
    }
    
    // MARK: - Setup Methods
    
    private func setupChatContainer() {
        chatContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chatContainer)
        
        NSLayoutConstraint.activate([
            chatContainer.topAnchor.constraint(equalTo: view.topAnchor),
            chatContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chatContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chatContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -68)
        ])
    }
    
    private func setupMessageInput() {
        messageInput.translatesAutoresizingMaskIntoConstraints = false
        messageInput.delegate = self
        view.addSubview(messageInput)
        
        NSLayoutConstraint.activate([
            messageInput.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messageInput.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messageInput.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            messageInput.heightAnchor.constraint(equalToConstant: 68)
        ])
    }
    
    private func loadRealMessages() {
        // Generate team ID based on team name
        let teamId = "team-\(teamData.name.lowercased().replacingOccurrences(of: " ", with: "-"))"
        
        Task {
            do {
                let teamMessages = try await SupabaseService.shared.fetchTeamMessages(teamId: teamId, limit: 50)
                
                let messageDataArray = teamMessages.map { message in
                    MessageData(
                        author: message.username ?? "@anonymous",
                        avatar: String((message.username ?? "A").prefix(2)).uppercased(),
                        message: message.message,
                        time: formatTimestamp(message.createdAt)
                    )
                }
                
                await MainActor.run {
                    displayMessages(messageDataArray)
                    print("🏗️ LevelFitness: Loaded \(messageDataArray.count) team messages from Supabase")
                }
                
                // Subscribe to real-time chat updates
                SupabaseService.shared.subscribeToTeamChat(teamId: teamId) { [weak self] newMessage in
                    let newMessageData = MessageData(
                        author: newMessage.username ?? "@anonymous",
                        avatar: String((newMessage.username ?? "A").prefix(2)).uppercased(),
                        message: newMessage.message,
                        time: self?.formatTimestamp(newMessage.createdAt) ?? ""
                    )
                    
                    DispatchQueue.main.async {
                        // Add new message to existing messages
                        var currentMessages = self?.getCurrentMessages() ?? []
                        currentMessages.append(newMessageData)
                        self?.displayMessages(currentMessages)
                        print("🏗️ LevelFitness: New real-time team message: \(newMessage.message)")
                    }
                }
                
            } catch {
                print("🏗️ LevelFitness: Error fetching team messages: \(error)")
                await MainActor.run {
                    displayMessages([])
                }
            }
        }
    }
    
    private func displayMessages(_ messages: [MessageData]) {
        currentMessages = messages
        
        // Clear existing messages
        messageViews.forEach { $0.removeFromSuperview() }
        messageViews.removeAll()
        
        // Clear empty state if it exists
        chatContainer.subviews.forEach { view in
            if view is UILabel {
                view.removeFromSuperview()
            }
        }
        
        if messages.isEmpty {
            showEmptyState("No messages yet. Be the first to say hello!")
            return
        }
        
        var lastView: UIView? = nil
        
        for messageData in messages {
            let messageView = MessageView(messageData: messageData)
            messageView.translatesAutoresizingMaskIntoConstraints = false
            chatContainer.addSubview(messageView)
            messageViews.append(messageView)
            
            NSLayoutConstraint.activate([
                messageView.leadingAnchor.constraint(equalTo: chatContainer.leadingAnchor, constant: IndustrialDesign.Spacing.large),
                messageView.trailingAnchor.constraint(equalTo: chatContainer.trailingAnchor, constant: -IndustrialDesign.Spacing.large)
            ])
            
            if let lastView = lastView {
                messageView.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: IndustrialDesign.Spacing.medium).isActive = true
            } else {
                messageView.topAnchor.constraint(equalTo: chatContainer.topAnchor, constant: IndustrialDesign.Spacing.large).isActive = true
            }
            
            lastView = messageView
        }
        
        if let lastView = lastView {
            chatContainer.bottomAnchor.constraint(greaterThanOrEqualTo: lastView.bottomAnchor, constant: IndustrialDesign.Spacing.large).isActive = true
        }
    }
    
    private func getCurrentMessages() -> [MessageData] {
        return currentMessages
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        let timeInterval = Date().timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes) min ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
    
    private func showEmptyState(_ message: String) {
        let emptyLabel = UILabel()
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.text = message
        emptyLabel.textColor = IndustrialDesign.Colors.secondaryText
        emptyLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        
        chatContainer.addSubview(emptyLabel)
        
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: chatContainer.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: chatContainer.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: chatContainer.leadingAnchor, constant: 40),
            emptyLabel.trailingAnchor.constraint(equalTo: chatContainer.trailingAnchor, constant: -40)
        ])
    }
    
    // MARK: - Public Methods
    
    func showMessageInput(_ show: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.messageInput.alpha = show ? 1 : 0
        }
    }
}

// MARK: - MessageInputViewDelegate

extension TeamDetailChatViewController: MessageInputViewDelegate {
    func didSendMessage(_ message: String) {
        print("🏗️ LevelFitness: Sending message: \(message)")
        
        guard let userSession = AuthenticationService.shared.loadSession() else {
            print("🏗️ LevelFitness: No user session found for sending message")
            return
        }
        
        let teamId = "team-\(teamData.name.lowercased().replacingOccurrences(of: " ", with: "-"))"
        
        Task {
            do {
                try await SupabaseService.shared.sendTeamMessage(
                    teamId: teamId,
                    userId: userSession.id,
                    message: message,
                    messageType: "text"
                )
                
                print("🏗️ LevelFitness: Message sent successfully")
                
                // Optimistically add message to UI (real-time subscription will also receive it)
                let newMessageData = MessageData(
                    author: "@me", // Will be replaced by real username from subscription
                    avatar: "ME",
                    message: message,
                    time: formatTimestamp(Date())
                )
                
                await MainActor.run {
                    var updatedMessages = getCurrentMessages()
                    updatedMessages.append(newMessageData)
                    displayMessages(updatedMessages)
                }
                
            } catch {
                print("🏗️ LevelFitness: Error sending message: \(error)")
            }
        }
    }
}