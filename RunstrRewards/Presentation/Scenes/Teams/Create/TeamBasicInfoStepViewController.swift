import UIKit

class TeamBasicInfoStepViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let stepTitleLabel = UILabel()
    private let stepDescriptionLabel = UILabel()
    
    // Team name section
    private let teamNameSection = UIView()
    private let teamNameLabel = UILabel()
    private let teamNameInput = UITextField()
    private let teamNameError = UILabel()
    
    // Description section
    private let descriptionSection = UIView()
    private let descriptionLabel = UILabel()
    private let descriptionInput = UITextView()
    private let descriptionError = UILabel()
    private let descriptionCharCount = UILabel()
    
    // Team data reference
    private let teamData: TeamCreationData
    
    init(teamData: TeamCreationData) {
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
        setupInputHandlers()
        loadExistingData()
        
        print("📝 TeamBasicInfo: Step view loaded")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Ensure text input sessions are properly established after view hierarchy is complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.configureTextInputSessions()
        }
        
        print("📝 TeamBasicInfo: View appeared, configuring input sessions")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("📝 TeamBasicInfo: Layout completed - view frame: \(view.frame)")
        print("📝 TeamBasicInfo: ScrollView frame: \(scrollView.frame)")
        print("📝 TeamBasicInfo: ContentView frame: \(contentView.frame)")
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        view.backgroundColor = UIColor.clear
        
        // Step header
        stepTitleLabel.text = "Team Information"
        stepTitleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        stepTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        stepTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        stepDescriptionLabel.text = "Give your team a name and description that attracts the right members. All team memberships are $1.99/month."
        stepDescriptionLabel.font = UIFont.systemFont(ofSize: 16)
        stepDescriptionLabel.textColor = IndustrialDesign.Colors.secondaryText
        stepDescriptionLabel.numberOfLines = 0
        stepDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Team name section
        setupTeamNameSection()
        
        // Description section
        setupDescriptionSection()
        
        // Add to scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [stepTitleLabel, stepDescriptionLabel, teamNameSection, descriptionSection].forEach {
            contentView.addSubview($0)
            print("📝 TeamBasicInfo: Added subview: \(type(of: $0))")
        }
    }
    
    private func setupTeamNameSection() {
        teamNameSection.translatesAutoresizingMaskIntoConstraints = false
        teamNameSection.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        teamNameSection.layer.cornerRadius = 12
        teamNameSection.layer.borderWidth = 1
        teamNameSection.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        teamNameLabel.text = "Team Name *"
        teamNameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        teamNameLabel.textColor = IndustrialDesign.Colors.primaryText
        teamNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        teamNameInput.placeholder = "e.g., Downtown Runners, Iron Warriors, Yoga Flow..."
        teamNameInput.font = UIFont.systemFont(ofSize: 16)
        teamNameInput.textColor = IndustrialDesign.Colors.primaryText
        teamNameInput.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        teamNameInput.layer.cornerRadius = 8
        teamNameInput.layer.borderWidth = 1
        teamNameInput.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        teamNameInput.translatesAutoresizingMaskIntoConstraints = false
        
        // Add padding to text field
        teamNameInput.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
        teamNameInput.leftViewMode = .always
        teamNameInput.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
        teamNameInput.rightViewMode = .always
        
        // Ensure proper text input configuration
        teamNameInput.autocorrectionType = .no
        teamNameInput.spellCheckingType = .no
        teamNameInput.returnKeyType = .next
        
        teamNameError.font = UIFont.systemFont(ofSize: 14)
        teamNameError.textColor = UIColor.systemRed
        teamNameError.numberOfLines = 0
        teamNameError.translatesAutoresizingMaskIntoConstraints = false
        teamNameError.isHidden = true
        
        [teamNameLabel, teamNameInput, teamNameError].forEach {
            teamNameSection.addSubview($0)
        }
    }
    
    private func setupDescriptionSection() {
        descriptionSection.translatesAutoresizingMaskIntoConstraints = false
        descriptionSection.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        descriptionSection.layer.cornerRadius = 12
        descriptionSection.layer.borderWidth = 1
        descriptionSection.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        descriptionLabel.text = "Description"
        descriptionLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        descriptionLabel.textColor = IndustrialDesign.Colors.primaryText
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        descriptionInput.font = UIFont.systemFont(ofSize: 16)
        descriptionInput.textColor = IndustrialDesign.Colors.primaryText
        descriptionInput.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        descriptionInput.layer.cornerRadius = 8
        descriptionInput.layer.borderWidth = 1
        descriptionInput.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        descriptionInput.translatesAutoresizingMaskIntoConstraints = false
        descriptionInput.text = ""
        descriptionInput.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        
        // Ensure proper text input configuration
        descriptionInput.autocorrectionType = .default
        descriptionInput.spellCheckingType = .default
        descriptionInput.returnKeyType = .default
        
        descriptionCharCount.text = "0/200"
        descriptionCharCount.font = UIFont.systemFont(ofSize: 12)
        descriptionCharCount.textColor = IndustrialDesign.Colors.secondaryText
        descriptionCharCount.textAlignment = .right
        descriptionCharCount.translatesAutoresizingMaskIntoConstraints = false
        
        descriptionError.font = UIFont.systemFont(ofSize: 14)
        descriptionError.textColor = UIColor.systemRed
        descriptionError.numberOfLines = 0
        descriptionError.translatesAutoresizingMaskIntoConstraints = false
        descriptionError.isHidden = true
        
        [descriptionLabel, descriptionInput, descriptionCharCount, descriptionError].forEach {
            descriptionSection.addSubview($0)
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Step header
            stepTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            stepTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stepTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            stepDescriptionLabel.topAnchor.constraint(equalTo: stepTitleLabel.bottomAnchor, constant: 8),
            stepDescriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stepDescriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            // Team name section
            teamNameSection.topAnchor.constraint(equalTo: stepDescriptionLabel.bottomAnchor, constant: 32),
            teamNameSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            teamNameSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            teamNameLabel.topAnchor.constraint(equalTo: teamNameSection.topAnchor, constant: 16),
            teamNameLabel.leadingAnchor.constraint(equalTo: teamNameSection.leadingAnchor, constant: 16),
            teamNameLabel.trailingAnchor.constraint(equalTo: teamNameSection.trailingAnchor, constant: -16),
            
            teamNameInput.topAnchor.constraint(equalTo: teamNameLabel.bottomAnchor, constant: 8),
            teamNameInput.leadingAnchor.constraint(equalTo: teamNameSection.leadingAnchor, constant: 16),
            teamNameInput.trailingAnchor.constraint(equalTo: teamNameSection.trailingAnchor, constant: -16),
            teamNameInput.heightAnchor.constraint(equalToConstant: 44),
            
            teamNameError.topAnchor.constraint(equalTo: teamNameInput.bottomAnchor, constant: 4),
            teamNameError.leadingAnchor.constraint(equalTo: teamNameSection.leadingAnchor, constant: 16),
            teamNameError.trailingAnchor.constraint(equalTo: teamNameSection.trailingAnchor, constant: -16),
            teamNameError.bottomAnchor.constraint(lessThanOrEqualTo: teamNameSection.bottomAnchor, constant: -16),
            
            // Description section
            descriptionSection.topAnchor.constraint(equalTo: teamNameSection.bottomAnchor, constant: 24),
            descriptionSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            descriptionSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            descriptionLabel.topAnchor.constraint(equalTo: descriptionSection.topAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: descriptionSection.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: descriptionSection.trailingAnchor, constant: -16),
            
            descriptionInput.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 8),
            descriptionInput.leadingAnchor.constraint(equalTo: descriptionSection.leadingAnchor, constant: 16),
            descriptionInput.trailingAnchor.constraint(equalTo: descriptionSection.trailingAnchor, constant: -16),
            descriptionInput.heightAnchor.constraint(equalToConstant: 100),
            
            descriptionCharCount.topAnchor.constraint(equalTo: descriptionInput.bottomAnchor, constant: 4),
            descriptionCharCount.trailingAnchor.constraint(equalTo: descriptionSection.trailingAnchor, constant: -16),
            
            descriptionError.topAnchor.constraint(equalTo: descriptionCharCount.bottomAnchor, constant: 4),
            descriptionError.leadingAnchor.constraint(equalTo: descriptionSection.leadingAnchor, constant: 16),
            descriptionError.trailingAnchor.constraint(equalTo: descriptionSection.trailingAnchor, constant: -16),
            descriptionError.bottomAnchor.constraint(lessThanOrEqualTo: descriptionSection.bottomAnchor, constant: -16),
            
            // Content view bottom anchor to establish content height
            descriptionSection.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -50)
        ])
    }
    
    private func setupInputHandlers() {
        // Text field input handlers
        teamNameInput.addTarget(self, action: #selector(teamNameChanged), for: .editingChanged)
        teamNameInput.addTarget(self, action: #selector(teamNameEditingDidBegin), for: .editingDidBegin)
        teamNameInput.addTarget(self, action: #selector(teamNameEditingDidEnd), for: .editingDidEnd)
        
        descriptionInput.delegate = self
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        // Add keyboard toolbar to text inputs
        setupKeyboardToolbar()
    }
    
    private func loadExistingData() {
        teamNameInput.text = teamData.teamName
        descriptionInput.text = teamData.description
        updateCharCount()
    }
    
    // MARK: - Input Handlers
    
    @objc private func teamNameChanged() {
        teamData.teamName = teamNameInput.text ?? ""
        validateTeamName()
    }
    
    // MARK: - First Responder Management
    
    @objc private func teamNameEditingDidBegin() {
        print("📝 TeamBasicInfo: Team name field became first responder")
        // Ensure input session is active
        if !teamNameInput.isFirstResponder {
            print("📝 TeamBasicInfo: WARNING - Team name field should be first responder but isn't")
        }
    }
    
    @objc private func teamNameEditingDidEnd() {
        print("📝 TeamBasicInfo: Team name field resigned first responder")
        validateTeamName()
    }
    
    private func validateTeamName() {
        let name = teamNameInput.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        if name.isEmpty {
            showError(for: teamNameError, message: "Team name is required")
        } else if name.count < 3 {
            showError(for: teamNameError, message: "Team name must be at least 3 characters")
        } else if name.count > 50 {
            showError(for: teamNameError, message: "Team name must be less than 50 characters")
        } else {
            hideError(for: teamNameError)
        }
    }
    
    private func updateCharCount() {
        let count = descriptionInput.text.count
        descriptionCharCount.text = "\(count)/200"
        
        if count > 200 {
            descriptionCharCount.textColor = UIColor.systemRed
            showError(for: descriptionError, message: "Description is too long")
        } else {
            descriptionCharCount.textColor = IndustrialDesign.Colors.secondaryText
            hideError(for: descriptionError)
        }
    }
    
    private func showError(for errorLabel: UILabel, message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
    }
    
    private func hideError(for errorLabel: UILabel) {
        errorLabel.isHidden = true
    }
    
    // MARK: - Keyboard Management
    
    private func setupKeyboardToolbar() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
        
        toolbar.setItems([flexSpace, doneButton], animated: false)
        
        // Set toolbar to text inputs
        teamNameInput.inputAccessoryView = toolbar
        descriptionInput.inputAccessoryView = toolbar
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Text Input Session Configuration
    
    private func configureTextInputSessions() {
        print("📝 TeamBasicInfo: Configuring text input sessions")
        
        // Ensure all text fields have proper input session setup
        configureTextFieldInputSession(teamNameInput, identifier: "team_name")
        configureTextViewInputSession(descriptionInput, identifier: "description")
        
        print("📝 TeamBasicInfo: Text input sessions configured successfully")
    }
    
    private func configureTextFieldInputSession(_ textField: UITextField, identifier: String) {
        // Ensure text field can become first responder
        guard textField.canBecomeFirstResponder else {
            print("📝 TeamBasicInfo: WARNING - \(identifier) text field cannot become first responder")
            return
        }
        
        // Configure input traits to ensure stable input session
        textField.reloadInputViews()
        
        print("📝 TeamBasicInfo: \(identifier) text field input session configured")
    }
    
    private func configureTextViewInputSession(_ textView: UITextView, identifier: String) {
        // Ensure text view can become first responder
        guard textView.canBecomeFirstResponder else {
            print("📝 TeamBasicInfo: WARNING - \(identifier) text view cannot become first responder")
            return
        }
        
        // Configure input traits to ensure stable input session
        textView.reloadInputViews()
        
        print("📝 TeamBasicInfo: \(identifier) text view input session configured")
    }
}

// MARK: - UITextViewDelegate

extension TeamBasicInfoStepViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        print("📝 TeamBasicInfo: Description text view began editing")
        
        // Ensure input session is properly established
        if !textView.isFirstResponder {
            print("📝 TeamBasicInfo: WARNING - Description text view should be first responder but isn't")
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        print("📝 TeamBasicInfo: Description text view ended editing")
        teamData.description = textView.text
    }
    
    func textViewDidChange(_ textView: UITextView) {
        teamData.description = textView.text
        updateCharCount()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        return newText.count <= 200
    }
}