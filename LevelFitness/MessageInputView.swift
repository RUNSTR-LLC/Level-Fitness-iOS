import UIKit

protocol MessageInputViewDelegate: AnyObject {
    func didSendMessage(_ message: String)
}

class MessageInputView: UIView {
    
    weak var delegate: MessageInputViewDelegate?
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let inputField = UITextField()
    private let sendButton = UIButton(type: .custom)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupInputView()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    private func setupInputView() {
        backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.95)
        
        // Add top border
        let borderLayer = CALayer()
        borderLayer.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
        borderLayer.frame = CGRect(x: 0, y: 0, width: frame.width, height: 1)
        layer.addSublayer(borderLayer)
        
        // Container view
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Input field
        inputField.translatesAutoresizingMaskIntoConstraints = false
        inputField.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        inputField.layer.cornerRadius = 8
        inputField.layer.borderWidth = 1
        inputField.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        inputField.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        inputField.textColor = IndustrialDesign.Colors.primaryText
        inputField.placeholder = "Type a message..."
        inputField.leftViewMode = .always
        inputField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        inputField.rightViewMode = .always
        inputField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        inputField.delegate = self
        
        // Placeholder styling
        if let placeholder = inputField.placeholder {
            inputField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [.foregroundColor: IndustrialDesign.Colors.secondaryText]
            )
        }
        
        // Send button
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0)
        sendButton.layer.cornerRadius = 8
        sendButton.layer.borderWidth = 1
        sendButton.layer.borderColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0).cgColor
        sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        sendButton.tintColor = IndustrialDesign.Colors.primaryText
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        
        containerView.addSubview(inputField)
        containerView.addSubview(sendButton)
        addSubview(containerView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: IndustrialDesign.Spacing.large),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -IndustrialDesign.Spacing.large),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            
            // Input field
            inputField.topAnchor.constraint(equalTo: containerView.topAnchor),
            inputField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            inputField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -12),
            inputField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            inputField.heightAnchor.constraint(equalToConstant: 36),
            
            // Send button
            sendButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            sendButton.centerYAnchor.constraint(equalTo: inputField.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 36),
            sendButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update border layer width
        if let borderLayer = layer.sublayers?.first {
            borderLayer.frame = CGRect(x: 0, y: 0, width: frame.width, height: 1)
        }
    }
    
    // MARK: - Actions
    
    @objc private func sendButtonTapped() {
        sendMessage()
    }
    
    private func sendMessage() {
        guard let message = inputField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !message.isEmpty else { return }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Button animation
        UIView.animate(withDuration: 0.1, animations: {
            self.sendButton.transform = CGAffineTransform.identity.scaledBy(x: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.sendButton.transform = .identity
            }
        }
        
        delegate?.didSendMessage(message)
        inputField.text = ""
    }
}

// MARK: - UITextFieldDelegate

extension MessageInputView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return true
    }
}