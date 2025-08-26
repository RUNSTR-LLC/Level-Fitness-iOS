import UIKit

protocol ProfileSectionViewDelegate: AnyObject {
    func didTapProfileSection()
}

class ProfileSectionView: UIView {
    
    // MARK: - Properties
    weak var delegate: ProfileSectionViewDelegate?
    private var gradientLayer: CAGradientLayer?
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let avatarImageView = UIImageView()
    private let usernameLabel = UILabel()
    private let profileSubtitleLabel = UILabel()
    private let boltDecoration = UIView()
    
    // MARK: - Data
    private var currentUsername: String = "Loading..."
    private var currentAvatar: UIImage?
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        setupInteractions()
        loadUserProfile()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = containerView.bounds
        
        // Update bolt decoration position
        boltDecoration.frame = CGRect(
            x: containerView.bounds.width - 18,
            y: 10,
            width: IndustrialDesign.Sizing.boltSize,
            height: IndustrialDesign.Sizing.boltSize
        )
    }
    
    // MARK: - Setup Methods
    
    private func setupViews() {
        // Container setup with industrial styling
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = IndustrialDesign.Colors.cardBackground
        containerView.layer.cornerRadius = IndustrialDesign.Sizing.cardCornerRadius
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        
        // Add gradient background
        let gradient = CAGradientLayer.industrial()
        gradient.cornerRadius = IndustrialDesign.Sizing.cardCornerRadius
        containerView.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient
        
        // Shadow for depth
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 8
        containerView.layer.shadowOpacity = 0.3
        
        // Avatar setup
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 25 // 50x50 avatar with radius 25
        avatarImageView.layer.borderWidth = 2
        avatarImageView.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        avatarImageView.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
        avatarImageView.image = UIImage(systemName: "person.circle.fill")
        avatarImageView.tintColor = IndustrialDesign.Colors.secondaryText
        
        // Username label
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        usernameLabel.text = currentUsername
        usernameLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        usernameLabel.textColor = IndustrialDesign.Colors.primaryText
        usernameLabel.numberOfLines = 1
        
        // Profile subtitle
        profileSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        profileSubtitleLabel.text = "Tap to view profile"
        profileSubtitleLabel.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        profileSubtitleLabel.textColor = IndustrialDesign.Colors.secondaryText
        profileSubtitleLabel.numberOfLines = 1
        
        // Industrial bolt decoration
        boltDecoration.backgroundColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0)
        boltDecoration.layer.cornerRadius = IndustrialDesign.Sizing.boltSize / 2
        boltDecoration.layer.borderWidth = 1
        boltDecoration.layer.borderColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor
        
        // Add subviews
        containerView.addSubview(avatarImageView)
        containerView.addSubview(usernameLabel)
        containerView.addSubview(profileSubtitleLabel)
        containerView.addSubview(boltDecoration)
        addSubview(containerView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container fills the view
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: IndustrialDesign.Spacing.xLarge),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -IndustrialDesign.Spacing.xLarge),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Avatar positioned on left
            avatarImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: IndustrialDesign.Spacing.regular),
            avatarImageView.widthAnchor.constraint(equalToConstant: 50),
            avatarImageView.heightAnchor.constraint(equalToConstant: 50),
            
            // Username label next to avatar
            usernameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            usernameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: IndustrialDesign.Spacing.medium),
            usernameLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -40),
            
            // Subtitle below username
            profileSubtitleLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: IndustrialDesign.Spacing.tiny),
            profileSubtitleLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: IndustrialDesign.Spacing.medium),
            profileSubtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -40),
            profileSubtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupInteractions() {
        // Profile section tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileSectionTapped))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }
    
    // MARK: - Actions
    
    @objc private func profileSectionTapped() {
        print("👤 ProfileSectionView: Profile section tapped")
        delegate?.didTapProfileSection()
        
        // Add tap animation
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = .identity
            }
        }
    }
    
    // MARK: - Profile Loading
    
    private func loadUserProfile() {
        // Check if this is a Nostr user
        if UserDefaults.standard.string(forKey: "loginMethod") == "nostr",
           let nostrCredentials = NostrAuthenticationService.shared.currentNostrCredentials {
            
            // Use the hex public key for profile fetching
            let hexPubkey = nostrCredentials.hexPublicKey
            print("ProfileSectionView: Using hex pubkey for relay queries: \(hexPubkey.prefix(16))...")
            
            // Try to get cached profile first for immediate display
            if let cachedProfile = NostrCacheManager.shared.getCachedProfile(pubkey: hexPubkey) {
                currentUsername = cachedProfile.effectiveDisplayName
                usernameLabel.text = currentUsername
                profileSubtitleLabel.text = "Nostr Profile"
                
                // Load avatar if available
                if let pictureUrl = cachedProfile.picture, let url = URL(string: pictureUrl) {
                    loadAvatarImage(from: url)
                } else {
                    setNostrDefaultAvatar()
                }
                
                print("ProfileSectionView: Loaded cached Nostr profile - \(currentUsername)")
            } else {
                // Show fallback while loading
                currentUsername = "Nostr User"
                usernameLabel.text = currentUsername
                profileSubtitleLabel.text = "Loading profile..."
                setNostrDefaultAvatar()
            }
            
            // Fetch real profile from relays in background
            Task {
                await fetchNostrProfile(hexPubkey: hexPubkey)
            }
            
            return
        }
        
        // Fall back to Apple user profile data
        if let profileData = AuthenticationService.shared.loadProfileData() {
            currentUsername = profileData.username
            currentAvatar = profileData.profileImage
            
            usernameLabel.text = currentUsername
            profileSubtitleLabel.text = "Tap to view profile"
            
            if let avatar = currentAvatar {
                avatarImageView.image = avatar
                avatarImageView.tintColor = nil // Remove tint for real images
            }
            
            print("ProfileSectionView: Loaded Apple user profile - \(currentUsername)")
        } else {
            // Final fallback - check for user session to show email
            if let userSession = AuthenticationService.shared.loadSession() {
                currentUsername = userSession.email ?? "Profile"
                usernameLabel.text = currentUsername
                profileSubtitleLabel.text = "Tap to complete profile"
                
                // Use default person icon
                avatarImageView.image = UIImage(systemName: "person.circle.fill")
                avatarImageView.tintColor = IndustrialDesign.Colors.secondaryText
                
                print("ProfileSectionView: Using session email fallback - \(currentUsername)")
            } else {
                // No user data at all
                currentUsername = "Profile"
                usernameLabel.text = currentUsername
                profileSubtitleLabel.text = "Tap to sign in"
                
                // Use default person icon
                avatarImageView.image = UIImage(systemName: "person.circle.fill")
                avatarImageView.tintColor = IndustrialDesign.Colors.secondaryText
                
                print("ProfileSectionView: No user data found")
            }
        }
    }
    
    private func fetchNostrProfile(hexPubkey: String) async {
        // Fetch from Nostr relays
        if let profile = await NostrProfileFetcher.shared.fetchProfile(pubkeyHex: hexPubkey) {
            // Cache the result
            NostrCacheManager.shared.cacheProfile(pubkey: hexPubkey, profile: profile)
            
            // Update UI on main thread
            await MainActor.run {
                currentUsername = profile.effectiveDisplayName
                usernameLabel.text = currentUsername
                profileSubtitleLabel.text = "Nostr Profile"
                
                // Load avatar if available
                if let pictureUrl = profile.picture, let url = URL(string: pictureUrl) {
                    loadAvatarImage(from: url)
                }
                
                print("ProfileSectionView: Updated with real Nostr profile - \(currentUsername)")
            }
        } else {
            print("ProfileSectionView: No published profile found - keeping 'Nostr User' display")
        }
    }
    
    private func setNostrDefaultAvatar() {
        avatarImageView.image = UIImage(systemName: "key.fill")
        avatarImageView.tintColor = UIColor(red: 0.97, green: 0.57, blue: 0.1, alpha: 1.0) // Bitcoin orange
        avatarImageView.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
    }
    
    private func loadAvatarImage(from url: URL) {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        avatarImageView.image = image
                        avatarImageView.tintColor = nil // Remove tint for real images
                    }
                }
            } catch {
                print("ProfileSectionView: Failed to load avatar image: \(error)")
                await MainActor.run {
                    setNostrDefaultAvatar()
                }
            }
        }
    }
    
    // MARK: - Public Methods
    
    func refreshProfile() {
        loadUserProfile()
    }
}