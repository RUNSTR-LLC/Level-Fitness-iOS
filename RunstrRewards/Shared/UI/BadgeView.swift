import UIKit

// MARK: - Badge View

class BadgeView: UIView {
    
    // MARK: - Properties
    
    private let label = UILabel()
    private var count: Int = 0 {
        didSet {
            updateDisplay()
        }
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
    }
    
    // MARK: - Setup
    
    private func setupView() {
        // Container styling
        backgroundColor = UIColor.systemRed
        layer.cornerRadius = 10
        clipsToBounds = true
        isHidden = true // Hidden by default
        
        // Label setup
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        
        addSubview(label)
        
        // Constraints
        NSLayoutConstraint.activate([
            // Fixed minimum size
            widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
            heightAnchor.constraint(equalToConstant: 20),
            
            // Label fills the badge
            label.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            
            // Width should adjust to content but have a minimum
            widthAnchor.constraint(greaterThanOrEqualTo: label.widthAnchor, constant: 12)
        ])
        
        // Set initial state
        updateDisplay()
    }
    
    // MARK: - Public Methods
    
    func setCount(_ newCount: Int) {
        count = newCount
    }
    
    func increment() {
        count += 1
    }
    
    func decrement() {
        if count > 0 {
            count -= 1
        }
    }
    
    func reset() {
        count = 0
    }
    
    // MARK: - Private Methods
    
    private func updateDisplay() {
        if count <= 0 {
            // Hide badge when count is 0
            isHidden = true
        } else {
            // Show badge with count
            isHidden = false
            
            // Format the count display
            if count > 99 {
                label.text = "99+"
            } else {
                label.text = "\(count)"
            }
            
            // Update corner radius based on content
            DispatchQueue.main.async {
                self.layer.cornerRadius = self.frame.height / 2
            }
        }
    }
    
    // MARK: - Animation Methods
    
    func animateCountChange() {
        // Bounce animation when count changes
        guard !isHidden else { return }
        
        transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.8,
            options: .curveEaseOut
        ) {
            self.transform = CGAffineTransform.identity
        }
    }
    
    func pulseAnimation() {
        // Gentle pulse to draw attention
        guard !isHidden else { return }
        
        UIView.animate(
            withDuration: 0.6,
            delay: 0,
            options: [.autoreverse, .repeat, .curveEaseInOut]
        ) {
            self.alpha = 0.6
        }
        
        // Stop pulsing after 3 cycles
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.6) {
            self.layer.removeAllAnimations()
            self.alpha = 1.0
        }
    }
}