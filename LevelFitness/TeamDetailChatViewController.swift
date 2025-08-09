import UIKit

class TeamDetailChatViewController: UIViewController {
    
    // MARK: - Properties
    private let teamData: TeamData
    
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
        loadSampleMessages()
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
    
    private func loadSampleMessages() {
        let messages = [
            MessageData(author: "@ironlegs", avatar: "IR", message: "Great job everyone on completing the 10K challenge! Prize distribution happening at midnight UTC 🏃‍♂️⚡", time: "2 hours ago"),
            MessageData(author: "@runnerboy", avatar: "RB", message: "Just crushed my personal best! 42:15 for 10K. Feeling pumped for tomorrow's event!", time: "1 hour ago"),
            MessageData(author: "@speedforce", avatar: "SF", message: "Anyone up for an early morning run tomorrow? Meeting at Steel Bridge at 6 AM", time: "45 min ago"),
            MessageData(author: "@marathonlisa", avatar: "ML", message: "Count me in! Need those miles for the monthly challenge 💪", time: "30 min ago"),
            MessageData(author: "@trackchamp", avatar: "TC", message: "New challenge idea: Progressive distance week. Start with 5K Monday, add 1K each day. Who's in?", time: "15 min ago")
        ]
        
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
        print("🏗️ LevelFitness: Message sent: \(message)")
        // TODO: Implement message sending
    }
}