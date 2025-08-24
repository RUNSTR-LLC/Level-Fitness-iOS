import UIKit

protocol ProfileTabNavigationViewDelegate: AnyObject {
    func didSelectTab(_ tab: ProfileTab)
}

class ProfileTabNavigationView: UIView {
    
    // MARK: - Properties
    weak var delegate: ProfileTabNavigationViewDelegate?
    private var currentTab: ProfileTab = .workouts
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let workoutsButton = UIButton(type: .custom)
    private let accountButton = UIButton(type: .custom)
    private let selectionIndicator = UIView()
    private var indicatorLeadingConstraint: NSLayoutConstraint?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
        selectTab(.workouts)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    private func setupView() {
        // Container with industrial styling
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        containerView.layer.cornerRadius = 8
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
        
        // Workouts button
        workoutsButton.translatesAutoresizingMaskIntoConstraints = false
        workoutsButton.setTitle("WORKOUTS", for: .normal)
        workoutsButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        workoutsButton.titleLabel?.letterSpacing = 1
        workoutsButton.setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
        workoutsButton.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .highlighted)
        workoutsButton.addTarget(self, action: #selector(workoutsButtonTapped), for: .touchUpInside)
        
        // Account button
        accountButton.translatesAutoresizingMaskIntoConstraints = false
        accountButton.setTitle("ACCOUNT", for: .normal)
        accountButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        accountButton.titleLabel?.letterSpacing = 1
        accountButton.setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
        accountButton.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .highlighted)
        accountButton.addTarget(self, action: #selector(accountButtonTapped), for: .touchUpInside)
        
        // Selection indicator with white accent
        selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        selectionIndicator.backgroundColor = UIColor.white
        selectionIndicator.layer.cornerRadius = 1.5
        
        // Add shadow to indicator for depth
        selectionIndicator.layer.shadowColor = UIColor.white.cgColor
        selectionIndicator.layer.shadowOffset = CGSize(width: 0, height: 0)
        selectionIndicator.layer.shadowRadius = 4
        selectionIndicator.layer.shadowOpacity = 0.3
        
        // Add subviews
        addSubview(containerView)
        containerView.addSubview(workoutsButton)
        containerView.addSubview(accountButton)
        containerView.addSubview(selectionIndicator)
    }
    
    private func setupConstraints() {
        // Create the leading constraint for the indicator (will be updated when switching tabs)
        indicatorLeadingConstraint = selectionIndicator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
        
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Workouts button (left half)
            workoutsButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            workoutsButton.topAnchor.constraint(equalTo: containerView.topAnchor),
            workoutsButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            workoutsButton.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.5),
            
            // Account button (right half)
            accountButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            accountButton.topAnchor.constraint(equalTo: containerView.topAnchor),
            accountButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            accountButton.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.5),
            
            // Selection indicator
            indicatorLeadingConstraint!,
            selectionIndicator.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -2),
            selectionIndicator.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.5, constant: -8),
            selectionIndicator.heightAnchor.constraint(equalToConstant: 3)
        ])
    }
    
    // MARK: - Public Methods
    
    func selectTab(_ tab: ProfileTab) {
        guard tab != currentTab || indicatorLeadingConstraint?.constant == 0 else { return }
        
        currentTab = tab
        
        // Update button appearances
        let selectedColor = IndustrialDesign.Colors.primaryText
        let unselectedColor = IndustrialDesign.Colors.secondaryText
        
        UIView.animate(withDuration: 0.2) {
            self.workoutsButton.setTitleColor(tab == .workouts ? selectedColor : unselectedColor, for: .normal)
            self.accountButton.setTitleColor(tab == .account ? selectedColor : unselectedColor, for: .normal)
        }
        
        // Animate indicator position
        let targetX: CGFloat = tab == .workouts ? 4 : (bounds.width / 2) + 4
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.indicatorLeadingConstraint?.constant = targetX
            self.layoutIfNeeded()
        })
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - Actions
    
    @objc private func workoutsButtonTapped() {
        print("👤 Profile Tab: Workouts tab selected")
        selectTab(.workouts)
        delegate?.didSelectTab(.workouts)
    }
    
    @objc private func accountButtonTapped() {
        print("👤 Profile Tab: Account tab selected")
        selectTab(.account)
        delegate?.didSelectTab(.account)
    }
}