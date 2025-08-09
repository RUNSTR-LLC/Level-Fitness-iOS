import UIKit

protocol CompetitionTabNavigationViewDelegate: AnyObject {
    func didSelectTab(_ tab: CompetitionTab)
}

class CompetitionTabNavigationView: UIView {
    
    // MARK: - Properties
    weak var delegate: CompetitionTabNavigationViewDelegate?
    private var currentTab: CompetitionTab = .league
    var tabButtons: [CompetitionTab: UIButton] = [:] // Made public for debugging
    
    // MARK: - UI Components
    private let tabStackView = UIStackView()
    private let activeIndicator = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    private func setupView() {
        backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        
        // Add bottom border
        let borderView = UIView()
        borderView.translatesAutoresizingMaskIntoConstraints = false
        borderView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        addSubview(borderView)
        
        NSLayoutConstraint.activate([
            borderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            borderView.bottomAnchor.constraint(equalTo: bottomAnchor),
            borderView.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        // Tab stack view
        tabStackView.translatesAutoresizingMaskIntoConstraints = false
        tabStackView.axis = .horizontal
        tabStackView.distribution = .fillEqually
        tabStackView.spacing = 0
        
        // Create tab buttons
        setupTabButtons()
        
        // Active indicator
        activeIndicator.translatesAutoresizingMaskIntoConstraints = false
        activeIndicator.backgroundColor = UIColor.clear
        
        // Add gradient to active indicator
        DispatchQueue.main.async {
            self.setupActiveIndicatorGradient()
        }
        
        addSubview(tabStackView)
        addSubview(activeIndicator)
    }
    
    private func setupTabButtons() {
        let tabs: [CompetitionTab] = [.league]
        
        for tab in tabs {
            let button = UIButton(type: .custom)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setTitle(tab.title, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            button.titleLabel?.textAlignment = .center
            button.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
            button.backgroundColor = UIColor.clear
            button.contentMode = .center
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.titleLabel?.minimumScaleFactor = 0.8
            button.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
            button.tag = getTagForTab(tab)
            button.isUserInteractionEnabled = true
            
            // Set minimum height for better touch targets
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
            
            print("🏆 LevelFitness: Created tab button for \(tab.title) with tag \(button.tag)")
            
            // Set initial appearance
            if tab == currentTab {
                button.setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
            }
            
            // Add hover effects
            setupButtonHoverEffect(button)
            
            // Add direct tap gesture as backup
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(directTabTapped(_:)))
            tapGesture.cancelsTouchesInView = false
            button.addGestureRecognizer(tapGesture)
            
            tabButtons[tab] = button
            tabStackView.addArrangedSubview(button)
        }
    }
    
    private func setupButtonHoverEffect(_ button: UIButton) {
        let pressGesture = UILongPressGestureRecognizer(target: self, action: #selector(buttonPressed(_:)))
        pressGesture.minimumPressDuration = 0
        button.addGestureRecognizer(pressGesture)
    }
    
    private func setupActiveIndicatorGradient() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            IndustrialDesign.Colors.secondaryText.cgColor,
            UIColor.clear.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        gradientLayer.frame = activeIndicator.bounds
        
        activeIndicator.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Tab stack view - ensure proper spacing from edges
            tabStackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            tabStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            tabStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            tabStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            
            // Active indicator - positioned at bottom with proper margins
            activeIndicator.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            activeIndicator.heightAnchor.constraint(equalToConstant: 3), // Slightly thicker
            activeIndicator.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.25),
            activeIndicator.centerXAnchor.constraint(equalTo: tabButtons[.league]?.centerXAnchor ?? centerXAnchor)
        ])
        
        print("🏆 LevelFitness: Tab navigation constraints configured with improved spacing")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update gradient frame
        if let gradientLayer = activeIndicator.layer.sublayers?.first(where: { $0 is CAGradientLayer }) as? CAGradientLayer {
            gradientLayer.frame = activeIndicator.bounds
        }
    }
    
    // MARK: - Helper Methods
    
    private func getTagForTab(_ tab: CompetitionTab) -> Int {
        switch tab {
        case .league: return 0
        }
    }
    
    private func getTabForTag(_ tag: Int) -> CompetitionTab {
        switch tag {
        case 0: return .league
        default: return .league
        }
    }
    
    // MARK: - Public Methods
    
    func selectTab(_ tab: CompetitionTab) {
        print("🏆 LevelFitness: selectTab called with: \(tab.title), current was: \(currentTab.title)")
        currentTab = tab
        print("🏆 LevelFitness: currentTab updated to: \(currentTab.title)")
        updateTabAppearance()
        animateActiveIndicator(to: tab)
    }
    
    private func updateTabAppearance() {
        for (tab, button) in tabButtons {
            if tab == currentTab {
                button.setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
            } else {
                button.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
            }
        }
    }
    
    private func animateActiveIndicator(to tab: CompetitionTab) {
        guard let targetButton = tabButtons[tab] else { return }
        
        // Remove existing constraints
        activeIndicator.constraints.forEach { constraint in
            if constraint.firstAttribute == .centerX {
                constraint.isActive = false
            }
        }
        
        // Add new constraint
        let centerConstraint = activeIndicator.centerXAnchor.constraint(equalTo: targetButton.centerXAnchor)
        centerConstraint.isActive = true
        
        // Animate the transition
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.layoutIfNeeded()
        }
    }
    
    // MARK: - Actions
    
    @objc private func directTabTapped(_ gesture: UITapGestureRecognizer) {
        guard let button = gesture.view as? UIButton else { return }
        print("🏆 LevelFitness: Direct tap gesture detected on button with tag: \(button.tag)")
        tabButtonTapped(button)
    }
    
    @objc private func tabButtonTapped(_ sender: UIButton) {
        let selectedTab = getTabForTag(sender.tag)
        
        print("🏆 LevelFitness: === TAB BUTTON TAPPED ===")
        print("🏆 LevelFitness: Button frame: \(sender.frame)")
        print("🏆 LevelFitness: Button tag: \(sender.tag)")
        print("🏆 LevelFitness: Selected tab: \(selectedTab.title)")
        print("🏆 LevelFitness: Current tab: \(currentTab.title)")
        print("🏆 LevelFitness: Delegate exists: \(delegate != nil)")
        
        // Add visual tap feedback
        UIView.animate(withDuration: 0.1, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            sender.alpha = 0.7
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                sender.transform = .identity
                sender.alpha = 1.0
            }
        }
        
        // Always proceed with tab selection to ensure delegate is called
        print("🏆 LevelFitness: Calling selectTab(\(selectedTab.title))...")
        selectTab(selectedTab)
        
        print("🏆 LevelFitness: Calling delegate.didSelectTab(\(selectedTab.title))...")
        delegate?.didSelectTab(selectedTab)
        
        print("🏆 LevelFitness: Tab selection completed for: \(selectedTab.title)")
        print("🏆 LevelFitness: ========================")
    }
    
    @objc private func buttonPressed(_ gesture: UILongPressGestureRecognizer) {
        guard let button = gesture.view as? UIButton else { return }
        
        switch gesture.state {
        case .began:
            UIView.animate(withDuration: 0.1) {
                button.alpha = 0.7
            }
        case .ended, .cancelled:
            UIView.animate(withDuration: 0.2) {
                button.alpha = 1.0
            }
        default:
            break
        }
    }
    
    // MARK: - Touch Handling
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Expand touch area for tab buttons
        let expandedTouchArea: CGFloat = 10
        
        for (tab, button) in tabButtons {
            let buttonPoint = button.convert(point, from: self)
            let expandedFrame = button.bounds.insetBy(dx: -expandedTouchArea, dy: -expandedTouchArea)
            if expandedFrame.contains(buttonPoint) {
                print("🏆 LevelFitness: Hit test detected touch on \(tab.title) button")
                return button
            }
        }
        
        return super.hitTest(point, with: event)
    }
    
    // MARK: - Touch Debugging
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if let touch = touches.first {
            let location = touch.location(in: self)
            print("🏆 LevelFitness: TabNavigation touch detected at location: \(location)")
            print("🏆 LevelFitness: TabNavigation bounds: \(bounds)")
            
            // Check which button might be touched
            for (tab, button) in tabButtons {
                let buttonFrame = button.frame
                print("🏆 LevelFitness: \(tab.title) button frame: \(buttonFrame)")
                if buttonFrame.contains(location) {
                    print("🏆 LevelFitness: Touch is over \(tab.title) button!")
                }
            }
        }
    }
}