import UIKit
import PhotosUI

class UserProfileSetupViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header
    private let headerView = UIView()
    private let backButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    
    // Profile photo section
    private let photoSection = UIView()
    private let photoContainerView = UIView()
    private let profileImageView = UIImageView()
    private let photoOverlayView = UIView()
    private let cameraIconView = UIImageView()
    private let photoTapGesture = UITapGestureRecognizer()
    
    // Username section
    private let usernameSection = UIView()
    private let usernameLabel = UILabel()
    private let usernameTextField = UITextField()
    private let usernameContainer = UIView()
    
    // Fitness goals section
    private let goalsSection = UIView()
    private let goalsLabel = UILabel()
    private let goalsDescription = UILabel()
    private var goalButtons: [GoalButton] = []
    private var selectedGoals: Set<String> = []
    
    // Workout types section
    private let workoutTypesSection = UIView()
    private let workoutTypesLabel = UILabel()
    private let workoutTypesDescription = UILabel()
    private var workoutTypeButtons: [WorkoutTypeButton] = []
    private var selectedWorkoutTypes: Set<String> = []
    
    // Continue button
    private let continueButton = UIButton(type: .custom)
    
    // Photo picker
    private var photoPickerController: PHPickerViewController?
    
    // Completion handler
    var onCompletion: ((UserProfileData) -> Void)?
    
    // Editing mode properties
    private var isEditingMode = false
    private var existingProfileData: UserProfileData?
    
    // Fitness goals data
    private let fitnessGoals = [
        ("lose_weight", "Lose Weight", "🔥"),
        ("build_muscle", "Build Muscle", "💪"),
        ("improve_endurance", "Improve Endurance", "🏃‍♂️"),
        ("stay_active", "Stay Active", "⚡"),
        ("compete", "Compete", "🏆"),
        ("socialize", "Socialize", "👥")
    ]
    
    // Workout types data
    private let workoutTypes = [
        ("running", "Running", "🏃‍♂️"),
        ("cycling", "Cycling", "🚴‍♂️"),
        ("strength", "Strength", "🏋️‍♂️"),
        ("yoga", "Yoga", "🧘‍♀️"),
        ("swimming", "Swimming", "🏊‍♂️"),
        ("dancing", "Dancing", "💃"),
        ("hiking", "Hiking", "🥾"),
        ("sports", "Sports", "⚽")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("👤 ProfileSetup: Loading profile setup view (editing mode: \(isEditingMode))")
        
        setupIndustrialBackground()
        setupScrollView()
        setupHeader()
        setupPhotoSection()
        setupUsernameSection()
        setupGoalsSection()
        setupWorkoutTypesSection()
        setupContinueButton()
        setupConstraints()
        setupTapGestures()
        
        // Pre-populate data if in editing mode
        if let existingData = existingProfileData {
            prePopulateFields(with: existingData)
        }
        
        print("👤 ProfileSetup: Profile setup view loaded successfully")
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
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .onDrag
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupHeader() {
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
        titleLabel.text = isEditingMode ? "Edit Profile" : "Create Profile"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(backButton)
        headerView.addSubview(titleLabel)
        contentView.addSubview(headerView)
    }
    
    private func setupPhotoSection() {
        photoSection.translatesAutoresizingMaskIntoConstraints = false
        
        // Photo container with border
        photoContainerView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        photoContainerView.layer.cornerRadius = 50
        photoContainerView.layer.borderWidth = 3
        photoContainerView.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        photoContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Profile image
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = IndustrialDesign.Colors.secondaryText
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 47
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Photo overlay for camera icon
        photoOverlayView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        photoOverlayView.layer.cornerRadius = 47
        photoOverlayView.alpha = 0
        photoOverlayView.translatesAutoresizingMaskIntoConstraints = false
        
        cameraIconView.image = UIImage(systemName: "camera.fill")
        cameraIconView.tintColor = .white
        cameraIconView.contentMode = .scaleAspectFit
        cameraIconView.translatesAutoresizingMaskIntoConstraints = false
        
        photoOverlayView.addSubview(cameraIconView)
        photoContainerView.addSubview(profileImageView)
        photoContainerView.addSubview(photoOverlayView)
        photoSection.addSubview(photoContainerView)
        contentView.addSubview(photoSection)
    }
    
    private func setupUsernameSection() {
        usernameSection.translatesAutoresizingMaskIntoConstraints = false
        
        usernameLabel.text = "Username"
        usernameLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        usernameLabel.textColor = IndustrialDesign.Colors.primaryText
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Username container
        usernameContainer.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        usernameContainer.layer.cornerRadius = 12
        usernameContainer.layer.borderWidth = 1
        usernameContainer.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        usernameContainer.translatesAutoresizingMaskIntoConstraints = false
        
        usernameTextField.placeholder = "Enter your username"
        usernameTextField.font = UIFont.systemFont(ofSize: 16)
        usernameTextField.textColor = IndustrialDesign.Colors.primaryText
        usernameTextField.backgroundColor = .clear
        usernameTextField.borderStyle = .none
        usernameTextField.autocapitalizationType = .none
        usernameTextField.autocorrectionType = .no
        usernameTextField.returnKeyType = .done
        usernameTextField.delegate = self
        usernameTextField.translatesAutoresizingMaskIntoConstraints = false
        
        usernameContainer.addSubview(usernameTextField)
        usernameSection.addSubview(usernameLabel)
        usernameSection.addSubview(usernameContainer)
        contentView.addSubview(usernameSection)
    }
    
    private func setupGoalsSection() {
        goalsSection.translatesAutoresizingMaskIntoConstraints = false
        
        goalsLabel.text = "Fitness Goals"
        goalsLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        goalsLabel.textColor = IndustrialDesign.Colors.primaryText
        goalsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        goalsDescription.text = "Select what motivates you (choose multiple)"
        goalsDescription.font = UIFont.systemFont(ofSize: 14)
        goalsDescription.textColor = IndustrialDesign.Colors.secondaryText
        goalsDescription.translatesAutoresizingMaskIntoConstraints = false
        
        // Create goal buttons
        for goal in fitnessGoals {
            let button = GoalButton(id: goal.0, title: goal.1, emoji: goal.2)
            button.onTap = { [weak self] goalId in
                self?.toggleGoal(goalId)
            }
            goalButtons.append(button)
            goalsSection.addSubview(button)
        }
        
        goalsSection.addSubview(goalsLabel)
        goalsSection.addSubview(goalsDescription)
        contentView.addSubview(goalsSection)
    }
    
    private func setupWorkoutTypesSection() {
        workoutTypesSection.translatesAutoresizingMaskIntoConstraints = false
        
        workoutTypesLabel.text = "Preferred Activities"
        workoutTypesLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        workoutTypesLabel.textColor = IndustrialDesign.Colors.primaryText
        workoutTypesLabel.translatesAutoresizingMaskIntoConstraints = false
        
        workoutTypesDescription.text = "What activities do you enjoy? (choose multiple)"
        workoutTypesDescription.font = UIFont.systemFont(ofSize: 14)
        workoutTypesDescription.textColor = IndustrialDesign.Colors.secondaryText
        workoutTypesDescription.translatesAutoresizingMaskIntoConstraints = false
        
        // Create workout type buttons
        for workoutType in workoutTypes {
            let button = WorkoutTypeButton(id: workoutType.0, title: workoutType.1, emoji: workoutType.2)
            button.onTap = { [weak self] typeId in
                self?.toggleWorkoutType(typeId)
            }
            workoutTypeButtons.append(button)
            workoutTypesSection.addSubview(button)
        }
        
        workoutTypesSection.addSubview(workoutTypesLabel)
        workoutTypesSection.addSubview(workoutTypesDescription)
        contentView.addSubview(workoutTypesSection)
    }
    
    private func setupContinueButton() {
        continueButton.setTitle(isEditingMode ? "Save Changes" : "Complete Setup", for: .normal)
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        continueButton.backgroundColor = IndustrialDesign.Colors.bitcoin
        continueButton.layer.cornerRadius = 12
        continueButton.layer.borderWidth = 1
        continueButton.layer.borderColor = IndustrialDesign.Colors.bitcoin.cgColor
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        
        contentView.addSubview(continueButton)
        
        updateContinueButtonState()
    }
    
    private func setupTapGestures() {
        photoTapGesture.addTarget(self, action: #selector(photoTapped))
        photoContainerView.addGestureRecognizer(photoTapGesture)
        photoContainerView.isUserInteractionEnabled = true
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
            
            // Photo section
            photoSection.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 32),
            photoSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            photoSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            photoSection.heightAnchor.constraint(equalToConstant: 100),
            
            photoContainerView.centerXAnchor.constraint(equalTo: photoSection.centerXAnchor),
            photoContainerView.centerYAnchor.constraint(equalTo: photoSection.centerYAnchor),
            photoContainerView.widthAnchor.constraint(equalToConstant: 100),
            photoContainerView.heightAnchor.constraint(equalToConstant: 100),
            
            profileImageView.centerXAnchor.constraint(equalTo: photoContainerView.centerXAnchor),
            profileImageView.centerYAnchor.constraint(equalTo: photoContainerView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 94),
            profileImageView.heightAnchor.constraint(equalToConstant: 94),
            
            photoOverlayView.centerXAnchor.constraint(equalTo: photoContainerView.centerXAnchor),
            photoOverlayView.centerYAnchor.constraint(equalTo: photoContainerView.centerYAnchor),
            photoOverlayView.widthAnchor.constraint(equalToConstant: 94),
            photoOverlayView.heightAnchor.constraint(equalToConstant: 94),
            
            cameraIconView.centerXAnchor.constraint(equalTo: photoOverlayView.centerXAnchor),
            cameraIconView.centerYAnchor.constraint(equalTo: photoOverlayView.centerYAnchor),
            cameraIconView.widthAnchor.constraint(equalToConstant: 30),
            cameraIconView.heightAnchor.constraint(equalToConstant: 30),
            
            // Username section
            usernameSection.topAnchor.constraint(equalTo: photoSection.bottomAnchor, constant: 32),
            usernameSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            usernameSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            usernameLabel.topAnchor.constraint(equalTo: usernameSection.topAnchor),
            usernameLabel.leadingAnchor.constraint(equalTo: usernameSection.leadingAnchor),
            usernameLabel.trailingAnchor.constraint(equalTo: usernameSection.trailingAnchor),
            
            usernameContainer.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 8),
            usernameContainer.leadingAnchor.constraint(equalTo: usernameSection.leadingAnchor),
            usernameContainer.trailingAnchor.constraint(equalTo: usernameSection.trailingAnchor),
            usernameContainer.heightAnchor.constraint(equalToConstant: 48),
            usernameContainer.bottomAnchor.constraint(equalTo: usernameSection.bottomAnchor),
            
            usernameTextField.leadingAnchor.constraint(equalTo: usernameContainer.leadingAnchor, constant: 16),
            usernameTextField.trailingAnchor.constraint(equalTo: usernameContainer.trailingAnchor, constant: -16),
            usernameTextField.centerYAnchor.constraint(equalTo: usernameContainer.centerYAnchor),
            
            // Goals section
            goalsSection.topAnchor.constraint(equalTo: usernameSection.bottomAnchor, constant: 32),
            goalsSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            goalsSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            goalsLabel.topAnchor.constraint(equalTo: goalsSection.topAnchor),
            goalsLabel.leadingAnchor.constraint(equalTo: goalsSection.leadingAnchor),
            goalsLabel.trailingAnchor.constraint(equalTo: goalsSection.trailingAnchor),
            
            goalsDescription.topAnchor.constraint(equalTo: goalsLabel.bottomAnchor, constant: 4),
            goalsDescription.leadingAnchor.constraint(equalTo: goalsSection.leadingAnchor),
            goalsDescription.trailingAnchor.constraint(equalTo: goalsSection.trailingAnchor),
            
            // Workout types section
            workoutTypesSection.topAnchor.constraint(equalTo: goalsSection.bottomAnchor, constant: 32),
            workoutTypesSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            workoutTypesSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            workoutTypesLabel.topAnchor.constraint(equalTo: workoutTypesSection.topAnchor),
            workoutTypesLabel.leadingAnchor.constraint(equalTo: workoutTypesSection.leadingAnchor),
            workoutTypesLabel.trailingAnchor.constraint(equalTo: workoutTypesSection.trailingAnchor),
            
            workoutTypesDescription.topAnchor.constraint(equalTo: workoutTypesLabel.bottomAnchor, constant: 4),
            workoutTypesDescription.leadingAnchor.constraint(equalTo: workoutTypesSection.leadingAnchor),
            workoutTypesDescription.trailingAnchor.constraint(equalTo: workoutTypesSection.trailingAnchor),
            
            // Continue button
            continueButton.topAnchor.constraint(equalTo: workoutTypesSection.bottomAnchor, constant: 40),
            continueButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            continueButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            continueButton.heightAnchor.constraint(equalToConstant: 56),
            continueButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
        
        // Layout goal buttons in a grid
        layoutGoalButtons()
        layoutWorkoutTypeButtons()
    }
    
    private func layoutGoalButtons() {
        let buttonsPerRow = 2
        let spacing: CGFloat = 12
        let buttonHeight: CGFloat = 50
        
        for (index, button) in goalButtons.enumerated() {
            let row = index / buttonsPerRow
            let col = index % buttonsPerRow
            
            button.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                button.topAnchor.constraint(equalTo: goalsDescription.bottomAnchor, constant: 16 + CGFloat(row) * (buttonHeight + spacing)),
                button.heightAnchor.constraint(equalToConstant: buttonHeight)
            ])
            
            if buttonsPerRow == 2 {
                if col == 0 {
                    NSLayoutConstraint.activate([
                        button.leadingAnchor.constraint(equalTo: goalsSection.leadingAnchor),
                        button.trailingAnchor.constraint(equalTo: goalsSection.centerXAnchor, constant: -spacing/2)
                    ])
                } else {
                    NSLayoutConstraint.activate([
                        button.leadingAnchor.constraint(equalTo: goalsSection.centerXAnchor, constant: spacing/2),
                        button.trailingAnchor.constraint(equalTo: goalsSection.trailingAnchor)
                    ])
                }
            }
        }
        
        if let lastButton = goalButtons.last {
            goalsSection.bottomAnchor.constraint(equalTo: lastButton.bottomAnchor).isActive = true
        }
    }
    
    private func layoutWorkoutTypeButtons() {
        let buttonsPerRow = 2
        let spacing: CGFloat = 12
        let buttonHeight: CGFloat = 50
        
        for (index, button) in workoutTypeButtons.enumerated() {
            let row = index / buttonsPerRow
            let col = index % buttonsPerRow
            
            button.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                button.topAnchor.constraint(equalTo: workoutTypesDescription.bottomAnchor, constant: 16 + CGFloat(row) * (buttonHeight + spacing)),
                button.heightAnchor.constraint(equalToConstant: buttonHeight)
            ])
            
            if buttonsPerRow == 2 {
                if col == 0 {
                    NSLayoutConstraint.activate([
                        button.leadingAnchor.constraint(equalTo: workoutTypesSection.leadingAnchor),
                        button.trailingAnchor.constraint(equalTo: workoutTypesSection.centerXAnchor, constant: -spacing/2)
                    ])
                } else {
                    NSLayoutConstraint.activate([
                        button.leadingAnchor.constraint(equalTo: workoutTypesSection.centerXAnchor, constant: spacing/2),
                        button.trailingAnchor.constraint(equalTo: workoutTypesSection.trailingAnchor)
                    ])
                }
            }
        }
        
        if let lastButton = workoutTypeButtons.last {
            workoutTypesSection.bottomAnchor.constraint(equalTo: lastButton.bottomAnchor).isActive = true
        }
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        print("👤 ProfileSetup: Back button tapped")
        dismiss(animated: true)
    }
    
    @objc private func photoTapped() {
        print("👤 ProfileSetup: Photo tapped - presenting photo picker")
        presentPhotoPicker()
    }
    
    @objc private func continueButtonTapped() {
        print("👤 ProfileSetup: Continue button tapped")
        
        guard let username = usernameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !username.isEmpty else {
            showAlert(title: "Username Required", message: "Please enter a username to continue.")
            return
        }
        
        let profile = UserProfileData(
            username: username,
            profileImage: profileImageView.image,
            fitnessGoals: Array(selectedGoals),
            preferredWorkoutTypes: Array(selectedWorkoutTypes)
        )
        
        print("👤 ProfileSetup: Created profile for \(username) with \(selectedGoals.count) goals and \(selectedWorkoutTypes.count) workout types")
        onCompletion?(profile)
    }
    
    // MARK: - Helper Methods
    
    private func toggleGoal(_ goalId: String) {
        if selectedGoals.contains(goalId) {
            selectedGoals.remove(goalId)
        } else {
            selectedGoals.insert(goalId)
        }
        
        // Update button states
        for button in goalButtons {
            if button.goalId == goalId {
                button.setSelected(selectedGoals.contains(goalId))
                break
            }
        }
        
        updateContinueButtonState()
        print("👤 ProfileSetup: Toggled goal \(goalId), now have \(selectedGoals.count) selected")
    }
    
    private func toggleWorkoutType(_ typeId: String) {
        if selectedWorkoutTypes.contains(typeId) {
            selectedWorkoutTypes.remove(typeId)
        } else {
            selectedWorkoutTypes.insert(typeId)
        }
        
        // Update button states
        for button in workoutTypeButtons {
            if button.typeId == typeId {
                button.setSelected(selectedWorkoutTypes.contains(typeId))
                break
            }
        }
        
        updateContinueButtonState()
        print("👤 ProfileSetup: Toggled workout type \(typeId), now have \(selectedWorkoutTypes.count) selected")
    }
    
    private func updateContinueButtonState() {
        let hasUsername = !(usernameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        continueButton.isEnabled = hasUsername
        
        UIView.animate(withDuration: 0.2) {
            self.continueButton.alpha = hasUsername ? 1.0 : 0.6
        }
    }
    
    private func presentPhotoPicker() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        photoPickerController = PHPickerViewController(configuration: configuration)
        photoPickerController?.delegate = self
        
        if let picker = photoPickerController {
            present(picker, animated: true)
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Editing Mode Support
    
    func configureForEditing(with profileData: UserProfileData) {
        isEditingMode = true
        existingProfileData = profileData
        
        // Update UI elements that depend on editing mode
        if isViewLoaded {
            titleLabel.text = "Edit Profile"
            continueButton.setTitle("Save Changes", for: .normal)
            prePopulateFields(with: profileData)
        }
    }
    
    private func prePopulateFields(with profileData: UserProfileData) {
        // Pre-populate username
        usernameTextField.text = profileData.username
        
        // Pre-populate profile image
        if let profileImage = profileData.profileImage {
            profileImageView.image = profileImage
        }
        
        // Pre-populate fitness goals
        selectedGoals = Set(profileData.fitnessGoals)
        for button in goalButtons {
            button.setSelected(selectedGoals.contains(button.goalId))
        }
        
        // Pre-populate workout types
        selectedWorkoutTypes = Set(profileData.preferredWorkoutTypes)
        for button in workoutTypeButtons {
            button.setSelected(selectedWorkoutTypes.contains(button.typeId))
        }
        
        // Update continue button state
        updateContinueButtonState()
        
        print("👤 ProfileSetup: Pre-populated fields with existing data - \(profileData.username)")
    }
}

// MARK: - UITextFieldDelegate

extension UserProfileSetupViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Update continue button state after text change
        DispatchQueue.main.async {
            self.updateContinueButtonState()
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - PHPickerViewControllerDelegate

extension UserProfileSetupViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = results.first else { return }
        
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            if let image = object as? UIImage {
                DispatchQueue.main.async {
                    self?.profileImageView.image = image
                    print("👤 ProfileSetup: Profile photo updated")
                }
            }
        }
    }
}

// MARK: - Data Models

struct UserProfileData {
    let username: String
    let profileImage: UIImage?
    let fitnessGoals: [String]
    let preferredWorkoutTypes: [String]
}

// MARK: - Custom Buttons

class GoalButton: UIButton {
    let goalId: String
    var onTap: ((String) -> Void)?
    
    init(id: String, title: String, emoji: String) {
        self.goalId = id
        super.init(frame: .zero)
        
        setTitle("\(emoji) \(title)", for: .normal)
        setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
        titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.6)
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func buttonTapped() {
        onTap?(goalId)
    }
    
    func setSelected(_ selected: Bool) {
        UIView.animate(withDuration: 0.2) {
            if selected {
                self.backgroundColor = IndustrialDesign.Colors.bitcoin.withAlphaComponent(0.3)
                self.layer.borderColor = IndustrialDesign.Colors.bitcoin.cgColor
            } else {
                self.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.6)
                self.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
            }
        }
    }
}

class WorkoutTypeButton: UIButton {
    let typeId: String
    var onTap: ((String) -> Void)?
    
    init(id: String, title: String, emoji: String) {
        self.typeId = id
        super.init(frame: .zero)
        
        setTitle("\(emoji) \(title)", for: .normal)
        setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
        titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.6)
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func buttonTapped() {
        onTap?(typeId)
    }
    
    func setSelected(_ selected: Bool) {
        UIView.animate(withDuration: 0.2) {
            if selected {
                self.backgroundColor = IndustrialDesign.Colors.bitcoin.withAlphaComponent(0.3)
                self.layer.borderColor = IndustrialDesign.Colors.bitcoin.cgColor
            } else {
                self.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.6)
                self.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
            }
        }
    }
}