import UIKit

protocol WorkoutTabNavigationViewDelegate: AnyObject {
    func didSelectTab(_ tab: WorkoutTab)
}

class WorkoutTabNavigationView: UIView {
    
    // MARK: - Properties
    weak var delegate: WorkoutTabNavigationViewDelegate?
    private var currentTab: WorkoutTab = .sync
    
    // MARK: - UI Components
    private let stackView = UIStackView()
    private var tabButtons: [WorkoutTab: UIButton] = [:]
    private let underlineView = UIView()
    
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
        
        // Setup stack view
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 0
        addSubview(stackView)
        
        // Create tab buttons
        let tabs: [WorkoutTab] = [.sync, .stats]
        for tab in tabs {
            let button = createTabButton(for: tab)
            tabButtons[tab] = button
            stackView.addArrangedSubview(button)
        }
        
        // Setup underline indicator
        underlineView.translatesAutoresizingMaskIntoConstraints = false
        underlineView.backgroundColor = UIColor.clear
        addSubview(underlineView)
        
        // Create gradient underline
        DispatchQueue.main.async {
            self.setupUnderlineGradient()
        }
    }
    
    private func createTabButton(for tab: WorkoutTab) -> UIButton {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(tab.title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        button.titleLabel?.letterSpacing = 0.5
        button.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
        button.setTitleColor(IndustrialDesign.Colors.primaryText, for: .selected)
        button.backgroundColor = UIColor.clear
        
        button.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
        button.tag = getTagForTab(tab)
        
        return button
    }
    
    private func getTagForTab(_ tab: WorkoutTab) -> Int {
        switch tab {
        case .sync: return 0
        case .stats: return 1
        }
    }
    
    private func getTabForTag(_ tag: Int) -> WorkoutTab {
        switch tag {
        case 0: return .sync
        case 1: return .stats
        default: return .sync
        }
    }
    
    private func setupUnderlineGradient() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            IndustrialDesign.Colors.secondaryText.cgColor,
            UIColor.clear.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.frame = underlineView.bounds
        
        underlineView.layer.addSublayer(gradientLayer)
        
        // Initially hide underline
        underlineView.alpha = 0
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Stack view
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Underline view
            underlineView.heightAnchor.constraint(equalToConstant: 2),
            underlineView.bottomAnchor.constraint(equalTo: bottomAnchor),
            underlineView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.6) // 60% of tab width
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update gradient frame
        if let gradientLayer = underlineView.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = underlineView.bounds
        }
    }
    
    // MARK: - Public Methods
    
    func selectTab(_ tab: WorkoutTab) {
        currentTab = tab
        updateTabAppearance()
        updateUnderlinePosition()
    }
    
    private func updateTabAppearance() {
        for (tab, button) in tabButtons {
            if tab == currentTab {
                button.isSelected = true
                button.setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
            } else {
                button.isSelected = false
                button.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
            }
        }
    }
    
    private func updateUnderlinePosition() {
        guard let selectedButton = tabButtons[currentTab] else { return }
        
        let buttonFrame = selectedButton.frame
        let underlineWidth = frame.width / 3 * 0.6 // 60% of tab width
        let centerX = buttonFrame.midX
        
        // Show underline
        underlineView.alpha = 1
        
        // Animate to new position
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.underlineView.center = CGPoint(x: centerX, y: self.underlineView.center.y)
        }
        
        // Update constraints for proper positioning
        underlineView.removeFromSuperview()
        addSubview(underlineView)
        
        NSLayoutConstraint.activate([
            underlineView.centerXAnchor.constraint(equalTo: selectedButton.centerXAnchor),
            underlineView.bottomAnchor.constraint(equalTo: bottomAnchor),
            underlineView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.2), // 20% of total width
            underlineView.heightAnchor.constraint(equalToConstant: 2)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func tabButtonTapped(_ sender: UIButton) {
        let tab = getTabForTag(sender.tag)
        
        // Add tap feedback animation
        UIView.animate(withDuration: 0.1, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                sender.transform = .identity
            }
        }
        
        selectTab(tab)
        delegate?.didSelectTab(tab)
        
        print("🏃‍♂️ RunstrRewards: Tab selected: \(tab.title)")
    }
}