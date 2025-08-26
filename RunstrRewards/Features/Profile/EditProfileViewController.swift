import UIKit

protocol EditProfileViewControllerDelegate: AnyObject {
    func didUpdateProfile(username: String, avatar: UIImage?)
}

class EditProfileViewController: UIViewController {
    
    // MARK: - Properties
    weak var delegate: EditProfileViewControllerDelegate?
    private var currentUsername: String = ""
    private var currentAvatar: UIImage?
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let headerView = UIView()
    private let backButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    private let avatarSection = UIView()
    private let avatarImageView = UIImageView()
    private let changeAvatarButton = UIButton(type: .custom)
    private let usernameSection = UIView()
    private let usernameLabel = UILabel()
    private let usernameTextField = UITextField()
    private let saveButton = UIButton(type: .custom)
    
    // Loading states
    private let uploadProgressView = UIView()
    private let uploadProgressLabel = UILabel()
    private let uploadProgressIndicator = UIProgressView()
    private let uploadSpinner = UIActivityIndicatorView(style: .medium)
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("👤 Edit Profile: Loading edit profile view")
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupView()
        setupConstraints()
        loadCurrentProfile()
        
        print("👤 Edit Profile: Edit profile view loaded")
    }
    
    // MARK: - Setup Methods
    
    private func setupView() {
        view.backgroundColor = IndustrialDesign.Colors.background
        
        // Add grid pattern
        let gridView = GridPatternView()
        gridView.translatesAutoresizingMaskIntoConstraints = false
        gridView.isUserInteractionEnabled = false
        view.addSubview(gridView)
        
        NSLayoutConstraint.activate([
            gridView.topAnchor.constraint(equalTo: view.topAnchor),
            gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Header
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Back button
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = IndustrialDesign.Colors.primaryText
        backButton.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        backButton.layer.cornerRadius = 20
        backButton.layer.borderWidth = 1
        backButton.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        // Title
        titleLabel.text = "Edit Profile"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Avatar section
        avatarSection.translatesAutoresizingMaskIntoConstraints = false
        avatarSection.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        avatarSection.layer.cornerRadius = 12
        avatarSection.layer.borderWidth = 1
        avatarSection.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        
        // Avatar image
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 40
        avatarImageView.layer.borderWidth = 2
        avatarImageView.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        avatarImageView.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
        avatarImageView.image = UIImage(systemName: "person.circle.fill")
        avatarImageView.tintColor = IndustrialDesign.Colors.secondaryText
        
        // Change avatar button
        changeAvatarButton.translatesAutoresizingMaskIntoConstraints = false
        changeAvatarButton.setTitle("Change Photo", for: .normal)
        changeAvatarButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        changeAvatarButton.setTitleColor(IndustrialDesign.Colors.accentText, for: .normal)
        changeAvatarButton.addTarget(self, action: #selector(changeAvatarTapped), for: .touchUpInside)
        
        // Username section
        usernameSection.translatesAutoresizingMaskIntoConstraints = false
        usernameSection.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        usernameSection.layer.cornerRadius = 12
        usernameSection.layer.borderWidth = 1
        usernameSection.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        
        // Username label
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        usernameLabel.text = "USERNAME"
        usernameLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        usernameLabel.textColor = IndustrialDesign.Colors.secondaryText
        usernameLabel.letterSpacing = 1
        
        // Username text field
        usernameTextField.translatesAutoresizingMaskIntoConstraints = false
        usernameTextField.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        usernameTextField.textColor = IndustrialDesign.Colors.primaryText
        usernameTextField.backgroundColor = UIColor.clear
        usernameTextField.borderStyle = .none
        usernameTextField.autocapitalizationType = .none
        usernameTextField.autocorrectionType = .no
        usernameTextField.placeholder = "Enter username"
        
        // Save button
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.setTitle("SAVE CHANGES", for: .normal)
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        saveButton.titleLabel?.letterSpacing = 1
        saveButton.setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
        saveButton.backgroundColor = UIColor(red: 0.97, green: 0.57, blue: 0.1, alpha: 1.0) // Bitcoin orange
        saveButton.layer.cornerRadius = 12
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        
        // Upload progress view (initially hidden)
        uploadProgressView.translatesAutoresizingMaskIntoConstraints = false
        uploadProgressView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.95)
        uploadProgressView.layer.cornerRadius = 12
        uploadProgressView.layer.borderWidth = 1
        uploadProgressView.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        uploadProgressView.isHidden = true
        
        uploadProgressLabel.translatesAutoresizingMaskIntoConstraints = false
        uploadProgressLabel.text = "Uploading profile image..."
        uploadProgressLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        uploadProgressLabel.textColor = IndustrialDesign.Colors.primaryText
        uploadProgressLabel.textAlignment = .center
        
        uploadProgressIndicator.translatesAutoresizingMaskIntoConstraints = false
        uploadProgressIndicator.progressTintColor = UIColor(red: 0.97, green: 0.57, blue: 0.1, alpha: 1.0) // Bitcoin orange
        uploadProgressIndicator.trackTintColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        
        uploadSpinner.translatesAutoresizingMaskIntoConstraints = false
        uploadSpinner.color = UIColor(red: 0.97, green: 0.57, blue: 0.1, alpha: 1.0) // Bitcoin orange
        uploadSpinner.hidesWhenStopped = true
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(headerView)
        headerView.addSubview(backButton)
        headerView.addSubview(titleLabel)
        contentView.addSubview(avatarSection)
        avatarSection.addSubview(avatarImageView)
        avatarSection.addSubview(changeAvatarButton)
        contentView.addSubview(usernameSection)
        usernameSection.addSubview(usernameLabel)
        usernameSection.addSubview(usernameTextField)
        contentView.addSubview(saveButton)
        contentView.addSubview(uploadProgressView)
        uploadProgressView.addSubview(uploadProgressLabel)
        uploadProgressView.addSubview(uploadProgressIndicator)
        uploadProgressView.addSubview(uploadSpinner)
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
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            headerView.heightAnchor.constraint(equalToConstant: 44),
            
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            // Avatar section
            avatarSection.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 32),
            avatarSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            avatarSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            avatarSection.heightAnchor.constraint(equalToConstant: 120),
            
            avatarImageView.leadingAnchor.constraint(equalTo: avatarSection.leadingAnchor, constant: 20),
            avatarImageView.centerYAnchor.constraint(equalTo: avatarSection.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 80),
            avatarImageView.heightAnchor.constraint(equalToConstant: 80),
            
            changeAvatarButton.centerYAnchor.constraint(equalTo: avatarSection.centerYAnchor),
            changeAvatarButton.trailingAnchor.constraint(equalTo: avatarSection.trailingAnchor, constant: -20),
            
            // Username section
            usernameSection.topAnchor.constraint(equalTo: avatarSection.bottomAnchor, constant: 24),
            usernameSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            usernameSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            usernameSection.heightAnchor.constraint(equalToConstant: 80),
            
            usernameLabel.topAnchor.constraint(equalTo: usernameSection.topAnchor, constant: 16),
            usernameLabel.leadingAnchor.constraint(equalTo: usernameSection.leadingAnchor, constant: 20),
            
            usernameTextField.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 8),
            usernameTextField.leadingAnchor.constraint(equalTo: usernameSection.leadingAnchor, constant: 20),
            usernameTextField.trailingAnchor.constraint(equalTo: usernameSection.trailingAnchor, constant: -20),
            usernameTextField.heightAnchor.constraint(equalToConstant: 24),
            
            // Save button
            saveButton.topAnchor.constraint(equalTo: usernameSection.bottomAnchor, constant: 32),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            saveButton.heightAnchor.constraint(equalToConstant: 48),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
            
            // Upload progress view
            uploadProgressView.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 16),
            uploadProgressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            uploadProgressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            uploadProgressView.heightAnchor.constraint(equalToConstant: 80),
            
            uploadProgressLabel.topAnchor.constraint(equalTo: uploadProgressView.topAnchor, constant: 16),
            uploadProgressLabel.leadingAnchor.constraint(equalTo: uploadProgressView.leadingAnchor, constant: 20),
            uploadProgressLabel.trailingAnchor.constraint(equalTo: uploadProgressView.trailingAnchor, constant: -20),
            
            uploadProgressIndicator.topAnchor.constraint(equalTo: uploadProgressLabel.bottomAnchor, constant: 8),
            uploadProgressIndicator.leadingAnchor.constraint(equalTo: uploadProgressView.leadingAnchor, constant: 20),
            uploadProgressIndicator.trailingAnchor.constraint(equalTo: uploadProgressView.trailingAnchor, constant: -60),
            uploadProgressIndicator.heightAnchor.constraint(equalToConstant: 4),
            
            uploadSpinner.centerYAnchor.constraint(equalTo: uploadProgressIndicator.centerYAnchor),
            uploadSpinner.trailingAnchor.constraint(equalTo: uploadProgressView.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - Data Loading
    
    private func loadCurrentProfile() {
        if let profileData = AuthenticationService.shared.loadProfileData() {
            currentUsername = profileData.username
            currentAvatar = profileData.profileImage
            
            usernameTextField.text = profileData.username
            if let avatar = profileData.profileImage {
                avatarImageView.image = avatar
            }
        } else if let userSession = AuthenticationService.shared.loadSession() {
            currentUsername = userSession.email ?? "User"
            usernameTextField.text = currentUsername
        }
    }
    
    // MARK: - Upload Progress Methods
    
    private func showUploadProgress(message: String) {
        uploadProgressLabel.text = message
        uploadProgressView.isHidden = false
        uploadSpinner.startAnimating()
        uploadProgressIndicator.progress = 0.0
        
        saveButton.isEnabled = false
        saveButton.alpha = 0.6
    }
    
    private func updateUploadProgress(_ progress: Float, message: String) {
        uploadProgressLabel.text = message
        uploadProgressIndicator.setProgress(progress, animated: true)
    }
    
    private func hideUploadProgress() {
        uploadProgressView.isHidden = true
        uploadSpinner.stopAnimating()
        
        saveButton.isEnabled = true
        saveButton.alpha = 1.0
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        print("👤 Edit Profile: Back button tapped")
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func changeAvatarTapped() {
        print("👤 Edit Profile: Change avatar tapped")
        
        let alert = UIAlertController(title: "Change Profile Photo", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Choose from Library", style: .default) { [weak self] _ in
            self?.presentImagePicker()
        })
        
        alert.addAction(UIAlertAction(title: "Use Default", style: .default) { [weak self] _ in
            self?.avatarImageView.image = UIImage(systemName: "person.circle.fill")
            self?.currentAvatar = nil
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    @objc private func saveButtonTapped() {
        print("👤 Edit Profile: Save button tapped")
        
        guard let username = usernameTextField.text, !username.isEmpty else {
            showAlert(title: "Error", message: "Please enter a username")
            return
        }
        
        // Start the upload process
        Task {
            await saveProfileWithProgress(username: username)
        }
    }
    
    private func saveProfileWithProgress(username: String) async {
        await MainActor.run {
            showUploadProgress(message: "Preparing profile data...")
        }
        
        // Load existing profile data to preserve fitness goals and workout types
        let existingProfile = AuthenticationService.shared.loadProfileData()
        
        do {
            await MainActor.run {
                updateUploadProgress(0.2, message: "Validating profile data...")
            }
            
            // Get current session
            guard let session = AuthenticationService.shared.loadSession() else {
                await MainActor.run {
                    hideUploadProgress()
                    showAlert(title: "Error", message: "No user session found")
                }
                return
            }
            
            await MainActor.run {
                updateUploadProgress(0.4, message: "Preparing image upload...")
            }
            
            // Upload profile with image if available
            var imageData: Data?
            if let currentAvatar = currentAvatar {
                imageData = currentAvatar.jpegData(compressionQuality: 0.8)
            }
            
            await MainActor.run {
                updateUploadProgress(0.6, message: "Uploading to server...")
            }
            
            // Upload to Supabase
            let avatarUrl = try await AuthDataService.shared.updateProfileWithImage(
                userId: session.id,
                username: username,
                fullName: username,
                imageData: imageData
            )
            
            await MainActor.run {
                updateUploadProgress(0.9, message: "Finishing up...")
            }
            
            // Save locally as well for backward compatibility
            let profileData = UserProfileData(
                username: username,
                profileImage: currentAvatar,
                fitnessGoals: existingProfile?.fitnessGoals ?? [],
                preferredWorkoutTypes: existingProfile?.preferredWorkoutTypes ?? []
            )
            
            AuthenticationService.shared.saveProfileData(profileData)
            
            await MainActor.run {
                updateUploadProgress(1.0, message: "Upload complete!")
                
                // Brief delay to show completion
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.hideUploadProgress()
                    
                    // Notify delegate
                    self?.delegate?.didUpdateProfile(username: username, avatar: self?.currentAvatar)
                    
                    // Show success and go back
                    self?.showAlert(title: "Success", message: "Profile updated successfully") { [weak self] in
                        self?.navigationController?.popViewController(animated: true)
                    }
                }
            }
            
        } catch {
            await MainActor.run {
                hideUploadProgress()
                
                // Check if it's an image-related error for better user feedback
                if let imageError = error as? ProfileImageError {
                    showAlert(title: "Image Upload Error", message: imageError.localizedDescription)
                } else {
                    showAlert(title: "Upload Error", message: "Failed to update profile: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func presentImagePicker() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.allowsEditing = true
        present(imagePickerController, animated: true)
    }
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let editedImage = info[.editedImage] as? UIImage {
            avatarImageView.image = editedImage
            currentAvatar = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            avatarImageView.image = originalImage
            currentAvatar = originalImage
        }
        
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}