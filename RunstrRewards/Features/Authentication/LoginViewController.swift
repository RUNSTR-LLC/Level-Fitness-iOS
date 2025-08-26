import UIKit
import AuthenticationServices

class LoginViewController: UIViewController, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    private let logoContainerView = UIView()
    private let logoMainView = UIView()
    private let logoShapeLayer = CAShapeLayer()
    private let logoFillLayer = CAShapeLayer()
    private let gear1View = UIView()
    private let gear2View = UIView()
    private let logoImageView = UIImageView()
    private let taglineLabel = UILabel()
    private let signInButton = ASAuthorizationAppleIDButton(type: .signIn, style: .white)
    private let nostrSignInButton = UIButton(type: .custom)
    private let nsecInputField = UITextField()
    private var isNostrInputVisible = false
    private var nostrButtonTopConstraint: NSLayoutConstraint?
    private let loadingDotsContainer = UIView()
    private let termsLabel = UILabel()
    private let backgroundGridLayer = CALayer()
    private let bgGear1View = UIView()
    private let bgGear2View = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // UI is already visible from viewDidLoad, no animation needed
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        setupBackgroundElements()
        setupLogoContainer()
        setupLoginSection()
        setupLoadingDots()
        setupTermsLabel()
    }
    
    private func setupBackgroundElements() {
        // Background grid pattern
        backgroundGridLayer.opacity = 0
        view.layer.addSublayer(backgroundGridLayer)
        
        // Background decorative gears
        setupBackgroundGear(bgGear1View, size: 100)
        setupBackgroundGear(bgGear2View, size: 150)
        
        view.addSubview(bgGear1View)
        view.addSubview(bgGear2View)
        
        bgGear1View.alpha = 0
        bgGear2View.alpha = 0
    }
    
    private func setupBackgroundGear(_ gearView: UIView, size: CGFloat) {
        let gearLayer = createGearPath(size: size)
        gearLayer.fillColor = UIColor(white: 0.04, alpha: 1.0).cgColor
        gearView.layer.addSublayer(gearLayer)
        
        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.fromValue = 0
        rotation.toValue = Double.pi * 2
        rotation.duration = 60
        rotation.repeatCount = .infinity
        gearView.layer.add(rotation, forKey: "rotation")
    }
    
    private func setupLogoContainer() {
        logoContainerView.alpha = 1  // Show immediately
        view.addSubview(logoContainerView)
        
        // Add logoMainView to the container BEFORE other elements use it
        logoContainerView.addSubview(logoMainView)
        
        // Logo image - show the RunstrRewards ostrich logo
        logoImageView.image = UIImage(named: "RunstrRewardsLogoLarge")
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.alpha = 1  // Show immediately
        logoContainerView.addSubview(logoImageView)
        
        // Remove tagline - just show logo
        
        // Decorative gears only
        setupDecorativeGears()
    }
    
    private func setupIndustrialLogo() {
        // Create industrial L path
        let logoPath = createIndustrialLPath()
        
        // Stroke layer for animation with enhanced branding
        logoShapeLayer.path = logoPath.cgPath
        logoShapeLayer.fillColor = UIColor.clear.cgColor
        logoShapeLayer.strokeColor = UIColor.white.cgColor
        logoShapeLayer.lineWidth = 5  // Slightly thicker for better visibility
        logoShapeLayer.lineCap = .round  // Smoother corners
        logoShapeLayer.strokeEnd = 0
        
        // Add subtle shadow for depth
        logoShapeLayer.shadowColor = UIColor.black.cgColor
        logoShapeLayer.shadowOffset = CGSize(width: 0, height: 2)
        logoShapeLayer.shadowOpacity = 0.3
        logoShapeLayer.shadowRadius = 4
        
        logoMainView.layer.addSublayer(logoShapeLayer)
        
        // Enhanced fill layer with gradient effect
        logoFillLayer.path = logoPath.cgPath
        logoFillLayer.fillColor = UIColor.white.withAlphaComponent(0.15).cgColor
        logoFillLayer.opacity = 0
        
        // Add subtle glow effect
        logoFillLayer.shadowColor = UIColor.white.cgColor
        logoFillLayer.shadowOffset = CGSize.zero
        logoFillLayer.shadowOpacity = 0.0
        logoFillLayer.shadowRadius = 8
        
        logoMainView.layer.addSublayer(logoFillLayer)
        
        // Industrial details (bolt holes) with enhanced styling
        addBoltHoles()
        
        // Add bitcoin accent hint
        addBitcoinAccentHint()
    }
    
    private func createIndustrialLPath() -> UIBezierPath {
        let path = UIBezierPath()
        let scale: CGFloat = 1.5
        
        // Create a simple, correct L shape
        // L shape: vertical stroke on the left, horizontal stroke at the bottom
        path.move(to: CGPoint(x: 25 * scale, y: 15 * scale))       // Top of vertical stroke
        path.addLine(to: CGPoint(x: 35 * scale, y: 15 * scale))    // Top-right of vertical stroke
        path.addLine(to: CGPoint(x: 35 * scale, y: 85 * scale))    // Bottom-right of vertical stroke
        path.addLine(to: CGPoint(x: 85 * scale, y: 85 * scale))    // End of horizontal stroke
        path.addLine(to: CGPoint(x: 85 * scale, y: 75 * scale))    // Top of horizontal stroke
        path.addLine(to: CGPoint(x: 25 * scale, y: 75 * scale))    // Inner corner
        path.close()                                               // Back to start
        
        return path
    }
    
    private func addBoltHoles() {
        let boltPositions = [
            CGPoint(x: 45, y: 60),   // Left vertical
            CGPoint(x: 45, y: 90),   // Left vertical
            CGPoint(x: 75, y: 120),  // Bottom horizontal
            CGPoint(x: 105, y: 120)  // Bottom horizontal
        ]
        
        for position in boltPositions {
            let boltHole = UIView()
            boltHole.backgroundColor = UIColor(white: 0.15, alpha: 1.0) // Slightly darker for better contrast
            boltHole.layer.cornerRadius = 3
            boltHole.frame = CGRect(x: position.x - 3, y: position.y - 3, width: 6, height: 6)
            
            // Add subtle inner shadow to bolt holes for depth
            boltHole.layer.shadowColor = UIColor.black.cgColor
            boltHole.layer.shadowOffset = CGSize(width: 0, height: 1)
            boltHole.layer.shadowOpacity = 0.3
            boltHole.layer.shadowRadius = 1
            boltHole.layer.masksToBounds = false
            
            logoMainView.addSubview(boltHole)
        }
    }
    
    private func addBitcoinAccentHint() {
        // Small bitcoin-colored accent dot in the top right of the L
        let accentDot = UIView()
        accentDot.backgroundColor = IndustrialDesign.Colors.bitcoin
        accentDot.layer.cornerRadius = 2
        accentDot.frame = CGRect(x: 95, y: 25, width: 4, height: 4)
        accentDot.alpha = 0
        
        // Add subtle glow effect
        accentDot.layer.shadowColor = IndustrialDesign.Colors.bitcoin.cgColor
        accentDot.layer.shadowOffset = CGSize.zero
        accentDot.layer.shadowOpacity = 0.8
        accentDot.layer.shadowRadius = 3
        accentDot.layer.masksToBounds = false
        
        logoMainView.addSubview(accentDot)
        
        // Animate the accent dot to appear after logo animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            UIView.animate(withDuration: 1.0, delay: 0, options: .curveEaseInOut) {
                accentDot.alpha = 1.0
            }
            
            // Add subtle pulsing animation
            let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
            pulseAnimation.fromValue = 1.0
            pulseAnimation.toValue = 1.3
            pulseAnimation.duration = 2.0
            pulseAnimation.autoreverses = true
            pulseAnimation.repeatCount = .infinity
            pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            accentDot.layer.add(pulseAnimation, forKey: "pulse")
        }
    }
    
    private func setupDecorativeGears() {
        // Small gear 1 (top right)
        let gear1Layer = createGearPath(size: 40)
        gear1Layer.fillColor = UIColor(white: 0.2, alpha: 1.0).cgColor
        gear1View.layer.addSublayer(gear1Layer)
        gear1View.alpha = 0
        logoMainView.addSubview(gear1View)
        
        // Small gear 2 (bottom left)
        let gear2Layer = createGearPath(size: 30)
        gear2Layer.fillColor = UIColor(white: 0.2, alpha: 1.0).cgColor
        gear2View.layer.addSublayer(gear2Layer)
        gear2View.alpha = 0
        logoMainView.addSubview(gear2View)
    }
    
    private func createGearPath(size: CGFloat) -> CAShapeLayer {
        let path = UIBezierPath()
        let center = CGPoint(x: size/2, y: size/2)
        let radius = size * 0.3
        let toothHeight = size * 0.1
        let toothCount = 12
        
        for i in 0..<toothCount {
            let angle = CGFloat(i) * 2 * .pi / CGFloat(toothCount)
            let innerAngle = angle + .pi / CGFloat(toothCount)
            
            let outerPoint = CGPoint(
                x: center.x + cos(angle) * (radius + toothHeight),
                y: center.y + sin(angle) * (radius + toothHeight)
            )
            let innerPoint = CGPoint(
                x: center.x + cos(innerAngle) * radius,
                y: center.y + sin(innerAngle) * radius
            )
            
            if i == 0 {
                path.move(to: outerPoint)
            } else {
                path.addLine(to: outerPoint)
            }
            path.addLine(to: innerPoint)
        }
        path.close()
        
        let layer = CAShapeLayer()
        layer.path = path.cgPath
        return layer
    }
    
    private func setupLoginSection() {
        // Apple Sign In button
        signInButton.addTarget(self, action: #selector(handleAppleSignIn), for: .touchUpInside)
        signInButton.layer.cornerRadius = 10
        signInButton.alpha = 1  // Show immediately
        view.addSubview(signInButton)
        
        // Nostr nsec input field - Hidden by default
        nsecInputField.placeholder = "Enter your nsec (private key)"
        nsecInputField.borderStyle = .roundedRect
        nsecInputField.backgroundColor = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0)
        nsecInputField.textColor = IndustrialDesign.Colors.primaryText
        nsecInputField.layer.borderWidth = 1
        nsecInputField.layer.borderColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0).cgColor
        nsecInputField.layer.cornerRadius = 10
        nsecInputField.isSecureTextEntry = true
        nsecInputField.autocapitalizationType = .none
        nsecInputField.autocorrectionType = .no
        nsecInputField.alpha = 0  // Hidden by default
        nsecInputField.isHidden = true
        nsecInputField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nsecInputField)
        
        // Nostr Sign In button - White and black like Apple button
        nostrSignInButton.setTitle("Sign in with Nostr", for: .normal)
        nostrSignInButton.setTitleColor(.black, for: .normal)
        nostrSignInButton.backgroundColor = .white
        nostrSignInButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        nostrSignInButton.layer.cornerRadius = 10
        nostrSignInButton.layer.borderWidth = 1
        nostrSignInButton.layer.borderColor = UIColor.lightGray.cgColor
        nostrSignInButton.addTarget(self, action: #selector(nostrButtonTapped), for: .touchUpInside)
        nostrSignInButton.alpha = 0  // Hidden temporarily while Nostr feature is being fixed
        nostrSignInButton.isHidden = true  // Completely hide from users
        nostrSignInButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nostrSignInButton)
        
        // Add Nostr logo to button
        let nostrIcon = UIImageView(image: UIImage(systemName: "key.fill"))
        nostrIcon.tintColor = .black
        nostrIcon.translatesAutoresizingMaskIntoConstraints = false
        nostrSignInButton.addSubview(nostrIcon)
        
        NSLayoutConstraint.activate([
            nostrIcon.leadingAnchor.constraint(equalTo: nostrSignInButton.leadingAnchor, constant: 20),
            nostrIcon.centerYAnchor.constraint(equalTo: nostrSignInButton.centerYAnchor),
            nostrIcon.widthAnchor.constraint(equalToConstant: 20),
            nostrIcon.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    private func setupLoadingDots() {
        loadingDotsContainer.alpha = 0
        view.addSubview(loadingDotsContainer)
        
        for i in 0..<3 {
            let dot = UIView()
            dot.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
            dot.layer.cornerRadius = 3
            dot.frame = CGRect(x: CGFloat(i * 14), y: 0, width: 6, height: 6)
            loadingDotsContainer.addSubview(dot)
            
            // Pulsing animation
            let pulse = CABasicAnimation(keyPath: "opacity")
            pulse.fromValue = 0.3
            pulse.toValue = 1.0
            pulse.duration = 1.5
            pulse.repeatCount = .infinity
            pulse.autoreverses = true
            pulse.beginTime = CACurrentMediaTime() + Double(i) * 0.2
            dot.layer.add(pulse, forKey: "pulse")
        }
    }
    
    private func setupTermsLabel() {
        termsLabel.text = "By signing in, you agree to our Terms of Service"
        termsLabel.font = UIFont.systemFont(ofSize: 11)
        termsLabel.textColor = UIColor(white: 0.27, alpha: 1.0)
        termsLabel.textAlignment = .center
        termsLabel.alpha = 1  // Show immediately
        view.addSubview(termsLabel)
    }
    
    private func setupConstraints() {
        logoContainerView.translatesAutoresizingMaskIntoConstraints = false
        logoMainView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        // taglineLabel removed
        signInButton.translatesAutoresizingMaskIntoConstraints = false
        nsecInputField.translatesAutoresizingMaskIntoConstraints = false
        nostrSignInButton.translatesAutoresizingMaskIntoConstraints = false
        loadingDotsContainer.translatesAutoresizingMaskIntoConstraints = false
        termsLabel.translatesAutoresizingMaskIntoConstraints = false
        gear1View.translatesAutoresizingMaskIntoConstraints = false
        gear2View.translatesAutoresizingMaskIntoConstraints = false
        bgGear1View.translatesAutoresizingMaskIntoConstraints = false
        bgGear2View.translatesAutoresizingMaskIntoConstraints = false
        
        // Set up the Nostr button constraint
        nostrButtonTopConstraint = nostrSignInButton.topAnchor.constraint(equalTo: signInButton.bottomAnchor, constant: 12)
        
        NSLayoutConstraint.activate([
            // Logo container
            logoContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            logoContainerView.widthAnchor.constraint(equalToConstant: 320),
            logoContainerView.heightAnchor.constraint(equalToConstant: 240),
            
            // Logo main view (center of container, reasonable size)
            logoMainView.centerXAnchor.constraint(equalTo: logoContainerView.centerXAnchor),
            logoMainView.centerYAnchor.constraint(equalTo: logoContainerView.centerYAnchor),
            logoMainView.widthAnchor.constraint(equalToConstant: 200),
            logoMainView.heightAnchor.constraint(equalToConstant: 150),
            
            // Logo image - centered in container
            logoImageView.centerXAnchor.constraint(equalTo: logoContainerView.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: logoContainerView.centerYAnchor, constant: -20),
            logoImageView.widthAnchor.constraint(equalToConstant: 280),
            logoImageView.heightAnchor.constraint(equalToConstant: 200),
            
            // Decorative gears - positioned relative to brand name
            gear1View.topAnchor.constraint(equalTo: logoImageView.topAnchor, constant: -10),
            gear1View.trailingAnchor.constraint(equalTo: logoContainerView.trailingAnchor, constant: -20),
            gear1View.widthAnchor.constraint(equalToConstant: 40),
            gear1View.heightAnchor.constraint(equalToConstant: 40),
            
            gear2View.bottomAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 10),
            gear2View.leadingAnchor.constraint(equalTo: logoContainerView.leadingAnchor, constant: 20),
            gear2View.widthAnchor.constraint(equalToConstant: 30),
            gear2View.heightAnchor.constraint(equalToConstant: 30),
            
            // Tagline
            // tagline removed
            
            // Sign in button
            signInButton.topAnchor.constraint(equalTo: logoContainerView.bottomAnchor, constant: 80),
            signInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signInButton.widthAnchor.constraint(equalToConstant: 320),
            signInButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Nostr sign in button - positioned right after Apple button initially
            nostrSignInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nostrSignInButton.widthAnchor.constraint(equalToConstant: 320),
            nostrSignInButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Nsec input field - positioned between Apple and Nostr buttons when shown
            nsecInputField.topAnchor.constraint(equalTo: signInButton.bottomAnchor, constant: 20),
            nsecInputField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nsecInputField.widthAnchor.constraint(equalToConstant: 320),
            nsecInputField.heightAnchor.constraint(equalToConstant: 50),
            
            // Loading dots
            loadingDotsContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingDotsContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60),
            loadingDotsContainer.widthAnchor.constraint(equalToConstant: 34),
            loadingDotsContainer.heightAnchor.constraint(equalToConstant: 6),
            
            // Terms label
            termsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            termsLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            termsLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            termsLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            
            // Background gears
            bgGear1View.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            bgGear1View.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bgGear1View.widthAnchor.constraint(equalToConstant: 100),
            bgGear1View.heightAnchor.constraint(equalToConstant: 100),
            
            bgGear2View.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -120),
            bgGear2View.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            bgGear2View.widthAnchor.constraint(equalToConstant: 150),
            bgGear2View.heightAnchor.constraint(equalToConstant: 150)
        ])
        
        // Activate the Nostr button constraint
        nostrButtonTopConstraint?.isActive = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupBackgroundGrid()
    }
    
    private func setupBackgroundGrid() {
        backgroundGridLayer.frame = view.bounds
        
        let gridSize: CGFloat = 150
        let lineWidth: CGFloat = 1
        let color = UIColor(white: 1.0, alpha: 0.02).cgColor
        
        let verticalLines = UIBezierPath()
        let horizontalLines = UIBezierPath()
        
        var x: CGFloat = 0
        while x <= view.bounds.width {
            verticalLines.move(to: CGPoint(x: x, y: 0))
            verticalLines.addLine(to: CGPoint(x: x, y: view.bounds.height))
            x += gridSize
        }
        
        var y: CGFloat = 0
        while y <= view.bounds.height {
            horizontalLines.move(to: CGPoint(x: 0, y: y))
            horizontalLines.addLine(to: CGPoint(x: view.bounds.width, y: y))
            y += gridSize
        }
        
        let verticalLayer = CAShapeLayer()
        verticalLayer.path = verticalLines.cgPath
        verticalLayer.strokeColor = color
        verticalLayer.lineWidth = lineWidth
        
        let horizontalLayer = CAShapeLayer()
        horizontalLayer.path = horizontalLines.cgPath
        horizontalLayer.strokeColor = color
        horizontalLayer.lineWidth = lineWidth
        
        backgroundGridLayer.addSublayer(verticalLayer)
        backgroundGridLayer.addSublayer(horizontalLayer)
    }
    
    
    private func animateLogoPath() {
        let pathAnimation = CABasicAnimation(keyPath: "strokeEnd")
        pathAnimation.fromValue = 0
        pathAnimation.toValue = 1
        pathAnimation.duration = 2.0
        pathAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        logoShapeLayer.strokeEnd = 1
        logoShapeLayer.add(pathAnimation, forKey: "drawPath")
    }
    
    private func animateLogoFill() {
        let fillAnimation = CABasicAnimation(keyPath: "opacity")
        fillAnimation.fromValue = 0
        fillAnimation.toValue = 1
        fillAnimation.duration = 1.0
        fillAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        logoFillLayer.opacity = 1
        logoFillLayer.add(fillAnimation, forKey: "fillIn")
        
        // Add subtle glow effect animation
        let glowAnimation = CABasicAnimation(keyPath: "shadowOpacity")
        glowAnimation.fromValue = 0.0
        glowAnimation.toValue = 0.3
        glowAnimation.duration = 1.5
        glowAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        logoFillLayer.shadowOpacity = 0.3
        logoFillLayer.add(glowAnimation, forKey: "glowIn")
    }
    
    private func animateDecorativeGears() {
        // Gear 1 animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            UIView.animate(withDuration: 2.0, delay: 0, options: .curveEaseInOut) {
                self.gear1View.alpha = 0.5
                self.gear1View.transform = CGAffineTransform(rotationAngle: .pi/4).scaledBy(x: 1.0, y: 1.0)
            }
        }
        
        // Gear 2 animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            UIView.animate(withDuration: 2.0, delay: 0, options: .curveEaseInOut) {
                self.gear2View.alpha = 0.5
                self.gear2View.transform = CGAffineTransform(rotationAngle: .pi/4).scaledBy(x: 1.0, y: 1.0)
            }
        }
    }
    
    private func animateBackgroundElements() {
        // Grid fade in
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            let gridAnimation = CABasicAnimation(keyPath: "opacity")
            gridAnimation.fromValue = 0
            gridAnimation.toValue = 0.5
            gridAnimation.duration = 3.0
            gridAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            self.backgroundGridLayer.opacity = 0.5
            self.backgroundGridLayer.add(gridAnimation, forKey: "gridFadeIn")
        }
        
        // Background gears
        UIView.animate(withDuration: 3.0, delay: 2.0, options: .curveEaseInOut) {
            self.bgGear1View.alpha = 0.03
            self.bgGear2View.alpha = 0.03
        }
        
        // Loading dots and terms
        UIView.animate(withDuration: 1.0, delay: 3.0, options: .curveEaseInOut) {
            self.loadingDotsContainer.alpha = 1
            self.termsLabel.alpha = 1
        }
    }
    
    @objc private func handleAppleSignIn() {
        print("LoginViewController: Starting Apple Sign In")
        showLoadingState(true)
        
        AuthenticationService.shared.signInWithApple(presentingViewController: self) { [weak self] result in
            DispatchQueue.main.async {
                self?.showLoadingState(false)
                
                switch result {
                case .success(let session):
                    print("LoginViewController: Sign in successful - User ID: \(session.id)")
                    self?.navigateToMainApp()
                    
                case .failure(let error):
                    print("LoginViewController: Sign in failed - \(error.localizedDescription)")
                    self?.showErrorAlert(message: error.localizedDescription)
                }
            }
        }
    }
    
    @objc private func nostrButtonTapped() {
        print("LoginViewController: Nostr button tapped")
        
        if !isNostrInputVisible {
            // Show nsec input field
            showNostrInput()
        } else {
            // Input is visible, proceed with sign in
            handleNostrSignIn()
        }
    }
    
    @objc private func handleNostrSignIn() {
        print("LoginViewController: Starting Nostr Sign In")
        
        guard let nsec = nsecInputField.text, !nsec.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showErrorAlert(message: "Please enter your nsec private key")
            return
        }
        
        showLoadingState(true)
        
        // Use NostrAuthenticationService for real authentication
        NostrAuthenticationService.shared.signInWithNsec(nsec) { [weak self] result in
            DispatchQueue.main.async {
                self?.showLoadingState(false)
                
                switch result {
                case .success(let credentials):
                    print("LoginViewController: Nostr sign in successful - Public Key: \(credentials.npub)")
                    
                    // Create a minimal user session for Nostr authentication
                    self?.createNostrSession()
                    self?.navigateToMainApp()
                    
                case .failure(let error):
                    print("LoginViewController: Nostr sign in failed - \(error.localizedDescription)")
                    self?.showErrorAlert(message: error.localizedDescription)
                }
            }
        }
    }
    
    private func createNostrSession() {
        print("LoginViewController: Creating Nostr session")
        
        // Clear any existing Apple user session data to ensure complete separation
        KeychainService.shared.delete(for: .accessToken)
        KeychainService.shared.delete(for: .refreshToken)
        KeychainService.shared.delete(for: .userId)
        
        // Clear any existing wallet credentials so Nostr user gets their own wallet
        KeychainService.shared.delete(for: .coinOSUsername)
        KeychainService.shared.delete(for: .coinOSPassword)
        
        // Clear profile data
        if let profileData = UserDefaults.standard.data(forKey: "userProfile") {
            UserDefaults.standard.removeObject(forKey: "userProfile")
            print("LoginViewController: Cleared existing profile data")
        }
        
        // Set authentication state for Nostr
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        UserDefaults.standard.set("nostr", forKey: "loginMethod")
        
        print("LoginViewController: Nostr session created with clean slate")
    }
    
    private func navigateToMainApp() {
        // Setup post-authentication services now that user is logged in
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.setupPostAuthenticationServices()
        }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let mainViewController = ViewController()
            let navigationController = UINavigationController(rootViewController: mainViewController)
            
            UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
                window.rootViewController = navigationController
            }, completion: nil)
            
            window.makeKeyAndVisible()
        }
    }
    
    private func showLoadingState(_ loading: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.signInButton.alpha = loading ? 0.5 : 1.0
            self.signInButton.isEnabled = !loading
            self.nostrSignInButton.alpha = loading ? 0.5 : 1.0
            self.nostrSignInButton.isEnabled = !loading
            if self.isNostrInputVisible {
                self.nsecInputField.alpha = loading ? 0.5 : 1.0
                self.nsecInputField.isEnabled = !loading
            }
        }
    }
    
    private func showNostrInput() {
        print("LoginViewController: Showing Nostr input field")
        isNostrInputVisible = true
        
        // Update button title to indicate next step
        nostrSignInButton.setTitle("Continue with Nostr", for: .normal)
        
        // Update the Nostr button position to be below the nsec input field
        nostrButtonTopConstraint?.isActive = false
        nostrButtonTopConstraint = nostrSignInButton.topAnchor.constraint(equalTo: nsecInputField.bottomAnchor, constant: 12)
        nostrButtonTopConstraint?.isActive = true
        
        // Animate the nsec input field appearing and button repositioning
        nsecInputField.isHidden = false
        UIView.animate(withDuration: 0.3, animations: {
            self.nsecInputField.alpha = 1.0
            self.view.layoutIfNeeded() // Animate the button position change
        }) { _ in
            // Focus the input field
            self.nsecInputField.becomeFirstResponder()
        }
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Sign In Failed",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - ASAuthorizationControllerDelegate (Remove these as AuthenticationService handles them)
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        // No longer needed - handled by AuthenticationService
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // No longer needed - handled by AuthenticationService
    }
    
    // MARK: - ASAuthorizationControllerPresentationContextProviding
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}