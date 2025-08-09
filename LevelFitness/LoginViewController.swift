import UIKit
import AuthenticationServices

class LoginViewController: UIViewController, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    private let logoContainerView = UIView()
    private let logoMainView = UIView()
    private let logoShapeLayer = CAShapeLayer()
    private let logoFillLayer = CAShapeLayer()
    private let gear1View = UIView()
    private let gear2View = UIView()
    private let brandNameLabel = UILabel()
    private let taglineLabel = UILabel()
    private let signInButton = ASAuthorizationAppleIDButton(type: .signIn, style: .white)
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
        startAnimationSequence()
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
        logoContainerView.alpha = 0
        view.addSubview(logoContainerView)
        
        // Main logo view
        logoContainerView.addSubview(logoMainView)
        setupIndustrialLogo()
        
        // Decorative gears
        setupDecorativeGears()
        
        // Brand name
        brandNameLabel.text = "Level Fitness"
        brandNameLabel.font = UIFont.systemFont(ofSize: 42, weight: .heavy)
        brandNameLabel.textColor = .white
        brandNameLabel.textAlignment = .center
        brandNameLabel.alpha = 0
        logoContainerView.addSubview(brandNameLabel)
        
        // Tagline
        taglineLabel.text = "SYNC • STACK • REPEAT"
        taglineLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        taglineLabel.textColor = UIColor(white: 0.4, alpha: 1.0)
        taglineLabel.textAlignment = .center
        taglineLabel.alpha = 0
        logoContainerView.addSubview(taglineLabel)
    }
    
    private func setupIndustrialLogo() {
        // Create industrial L path
        let logoPath = createIndustrialLPath()
        
        // Stroke layer for animation
        logoShapeLayer.path = logoPath.cgPath
        logoShapeLayer.fillColor = UIColor.clear.cgColor
        logoShapeLayer.strokeColor = UIColor.white.cgColor
        logoShapeLayer.lineWidth = 4
        logoShapeLayer.lineCap = .square
        logoShapeLayer.strokeEnd = 0
        logoMainView.layer.addSublayer(logoShapeLayer)
        
        // Fill layer
        logoFillLayer.path = logoPath.cgPath
        logoFillLayer.fillColor = UIColor(white: 1.0, alpha: 0.1).cgColor
        logoFillLayer.opacity = 0
        logoMainView.layer.addSublayer(logoFillLayer)
        
        // Industrial details (bolt holes)
        addBoltHoles()
    }
    
    private func createIndustrialLPath() -> UIBezierPath {
        let path = UIBezierPath()
        let scale: CGFloat = 1.5
        
        // Main L shape
        path.move(to: CGPoint(x: 25 * scale, y: 15 * scale))
        path.addLine(to: CGPoint(x: 35 * scale, y: 15 * scale))
        path.addLine(to: CGPoint(x: 35 * scale, y: 75 * scale))
        path.addLine(to: CGPoint(x: 85 * scale, y: 75 * scale))
        path.addLine(to: CGPoint(x: 85 * scale, y: 85 * scale))
        path.addLine(to: CGPoint(x: 25 * scale, y: 85 * scale))
        path.close()
        
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
            boltHole.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
            boltHole.layer.cornerRadius = 3
            boltHole.frame = CGRect(x: position.x - 3, y: position.y - 3, width: 6, height: 6)
            logoMainView.addSubview(boltHole)
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
        signInButton.addTarget(self, action: #selector(handleAppleSignIn), for: .touchUpInside)
        signInButton.layer.cornerRadius = 10
        signInButton.alpha = 0
        view.addSubview(signInButton)
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
        termsLabel.alpha = 0
        view.addSubview(termsLabel)
    }
    
    private func setupConstraints() {
        logoContainerView.translatesAutoresizingMaskIntoConstraints = false
        logoMainView.translatesAutoresizingMaskIntoConstraints = false
        brandNameLabel.translatesAutoresizingMaskIntoConstraints = false
        taglineLabel.translatesAutoresizingMaskIntoConstraints = false
        signInButton.translatesAutoresizingMaskIntoConstraints = false
        loadingDotsContainer.translatesAutoresizingMaskIntoConstraints = false
        termsLabel.translatesAutoresizingMaskIntoConstraints = false
        gear1View.translatesAutoresizingMaskIntoConstraints = false
        gear2View.translatesAutoresizingMaskIntoConstraints = false
        bgGear1View.translatesAutoresizingMaskIntoConstraints = false
        bgGear2View.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Logo container
            logoContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            logoContainerView.widthAnchor.constraint(equalToConstant: 320),
            logoContainerView.heightAnchor.constraint(equalToConstant: 240),
            
            // Main logo
            logoMainView.topAnchor.constraint(equalTo: logoContainerView.topAnchor),
            logoMainView.centerXAnchor.constraint(equalTo: logoContainerView.centerXAnchor),
            logoMainView.widthAnchor.constraint(equalToConstant: 120),
            logoMainView.heightAnchor.constraint(equalToConstant: 120),
            
            // Decorative gears
            gear1View.topAnchor.constraint(equalTo: logoMainView.topAnchor, constant: -20),
            gear1View.trailingAnchor.constraint(equalTo: logoMainView.trailingAnchor, constant: 20),
            gear1View.widthAnchor.constraint(equalToConstant: 40),
            gear1View.heightAnchor.constraint(equalToConstant: 40),
            
            gear2View.bottomAnchor.constraint(equalTo: logoMainView.bottomAnchor, constant: 15),
            gear2View.leadingAnchor.constraint(equalTo: logoMainView.leadingAnchor, constant: -15),
            gear2View.widthAnchor.constraint(equalToConstant: 30),
            gear2View.heightAnchor.constraint(equalToConstant: 30),
            
            // Brand name
            brandNameLabel.topAnchor.constraint(equalTo: logoMainView.bottomAnchor, constant: 40),
            brandNameLabel.centerXAnchor.constraint(equalTo: logoContainerView.centerXAnchor),
            brandNameLabel.leadingAnchor.constraint(greaterThanOrEqualTo: logoContainerView.leadingAnchor, constant: 20),
            brandNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: logoContainerView.trailingAnchor, constant: -20),
            
            // Tagline
            taglineLabel.topAnchor.constraint(equalTo: brandNameLabel.bottomAnchor, constant: 12),
            taglineLabel.centerXAnchor.constraint(equalTo: logoContainerView.centerXAnchor),
            
            // Sign in button
            signInButton.topAnchor.constraint(equalTo: logoContainerView.bottomAnchor, constant: 80),
            signInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signInButton.widthAnchor.constraint(equalToConstant: 320),
            signInButton.heightAnchor.constraint(equalToConstant: 50),
            
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
    
    private func startAnimationSequence() {
        // 0.5s: Logo container fade in
        UIView.animate(withDuration: 2.0, delay: 0.5, options: .curveEaseInOut) {
            self.logoContainerView.alpha = 1
            self.logoContainerView.transform = CGAffineTransform.identity
        }
        
        // Draw logo path animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.animateLogoPath()
        }
        
        // 1.5s: Brand name appears
        UIView.animate(withDuration: 1.0, delay: 1.5, options: .curveEaseInOut) {
            self.brandNameLabel.alpha = 1
            self.brandNameLabel.transform = CGAffineTransform.identity
        }
        
        // Fill logo
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.animateLogoFill()
        }
        
        // 1.8s: Tagline appears
        UIView.animate(withDuration: 1.0, delay: 1.8, options: .curveEaseInOut) {
            self.taglineLabel.alpha = 1
            self.taglineLabel.transform = CGAffineTransform.identity
        }
        
        // 2.2s-2.4s: Decorative gears appear
        self.animateDecorativeGears()
        
        // 2.5s: Sign in button
        UIView.animate(withDuration: 1.0, delay: 2.5, options: .curveEaseInOut) {
            self.signInButton.alpha = 1
            self.signInButton.transform = CGAffineTransform.identity
        }
        
        // 3.0s: Background elements
        self.animateBackgroundElements()
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
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    // MARK: - ASAuthorizationControllerDelegate
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if authorization.credential is ASAuthorizationAppleIDCredential {
            // Handle successful sign in
            print("Apple Sign In successful")
            
            // Navigate to main app
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    let mainViewController = ViewController()
                    let navigationController = UINavigationController(rootViewController: mainViewController)
                    window.rootViewController = navigationController
                    window.makeKeyAndVisible()
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple Sign In failed: \(error.localizedDescription)")
    }
    
    // MARK: - ASAuthorizationControllerPresentationContextProviding
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}