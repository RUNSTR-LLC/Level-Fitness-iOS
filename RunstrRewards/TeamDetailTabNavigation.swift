import UIKit

protocol TeamDetailTabNavigationDelegate: AnyObject {
    func didSelectTab(_ tab: TeamDetailViewController.TabType)
}

class TeamDetailTabNavigation: UIView {
    
    // MARK: - Properties
    weak var delegate: TeamDetailTabNavigationDelegate?
    private var selectedIndex = 0
    private var tabButtons: [UIButton] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupTabs()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    private func setupView() {
        backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        
        // Add bottom border
        let borderLayer = CALayer()
        borderLayer.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
        borderLayer.frame = CGRect(x: 0, y: 47, width: UIScreen.main.bounds.width, height: 1)
        layer.addSublayer(borderLayer)
    }
    
    private func setupTabs() {
        for (index, tab) in TeamDetailViewController.TabType.allCases.enumerated() {
            let button = createTabButton(title: tab.rawValue, index: index)
            tabButtons.append(button)
            addSubview(button)
        }
        
        setupTabConstraints()
        updateTabSelection(index: 0)
    }
    
    private func createTabButton(title: String, index: Int) -> UIButton {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title.uppercased(), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        button.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
        button.tag = index
        button.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
        return button
    }
    
    private func setupTabConstraints() {
        let tabWidth = UIScreen.main.bounds.width / CGFloat(tabButtons.count)
        
        for (index, button) in tabButtons.enumerated() {
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: tabWidth),
                button.heightAnchor.constraint(equalTo: heightAnchor),
                button.centerYAnchor.constraint(equalTo: centerYAnchor),
                button.leadingAnchor.constraint(equalTo: leadingAnchor, constant: CGFloat(index) * tabWidth)
            ])
        }
    }
    
    // MARK: - Actions
    
    @objc private func tabButtonTapped(_ sender: UIButton) {
        let newIndex = sender.tag
        guard newIndex < TeamDetailViewController.TabType.allCases.count else { return }
        
        updateTabSelection(index: newIndex)
        
        let selectedTab = TeamDetailViewController.TabType.allCases[newIndex]
        delegate?.didSelectTab(selectedTab)
    }
    
    private func updateTabSelection(index: Int) {
        selectedIndex = index
        
        for (i, button) in tabButtons.enumerated() {
            if i == index {
                button.setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
                
                // Add underline
                let underline = CALayer()
                underline.backgroundColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0).cgColor
                underline.frame = CGRect(
                    x: button.frame.width * 0.2,
                    y: button.frame.height - 2,
                    width: button.frame.width * 0.6,
                    height: 2
                )
                underline.name = "underline"
                
                // Remove existing underlines
                button.layer.sublayers?.removeAll { $0.name == "underline" }
                button.layer.addSublayer(underline)
                
            } else {
                button.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
                
                // Remove underline
                button.layer.sublayers?.removeAll { $0.name == "underline" }
            }
        }
    }
}