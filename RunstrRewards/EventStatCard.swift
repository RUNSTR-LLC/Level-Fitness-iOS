import UIKit

class EventStatCard: UIView {
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    
    // MARK: - Properties
    private var accentColor: UIColor = UIColor.systemBlue
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        backgroundColor = .clear
        
        // Container view
        containerView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subtle gradient
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 0.9).cgColor,
            UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.9).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = 12
        containerView.layer.insertSublayer(gradientLayer, at: 0)
        
        // Icon
        iconImageView.tintColor = accentColor
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title label
        titleLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = IndustrialDesign.Colors.secondaryText
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Value label
        valueLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        valueLabel.textColor = IndustrialDesign.Colors.primaryText
        valueLabel.textAlignment = .center
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add bolt decoration
        let boltImageView = UIImageView(image: UIImage(systemName: "bolt.fill"))
        boltImageView.tintColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 0.3)
        boltImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(boltImageView)
        
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(valueLabel)
        addSubview(containerView)
        
        // Layout the gradient after the view is laid out
        DispatchQueue.main.async {
            gradientLayer.frame = self.containerView.bounds
        }
        
        NSLayoutConstraint.activate([
            boltImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            boltImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            boltImageView.widthAnchor.constraint(equalToConstant: 12),
            boltImageView.heightAnchor.constraint(equalToConstant: 12)
        ])
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view fills the entire card
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Icon at the top
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            // Value below icon
            valueLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
            valueLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            valueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            // Title at the bottom
            titleLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -8)
        ])
    }
    
    // MARK: - Public Methods
    
    func configure(title: String, value: String, icon: String, color: UIColor) {
        self.accentColor = color
        
        titleLabel.text = title
        valueLabel.text = value
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = color
        
        // Add subtle animation on configuration
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
            self.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                self.transform = .identity
            }
        }
    }
    
    func updateValue(_ newValue: String) {
        // Animate value change
        UIView.animate(withDuration: 0.2, animations: {
            self.valueLabel.alpha = 0.5
            self.valueLabel.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            self.valueLabel.text = newValue
            UIView.animate(withDuration: 0.3, delay: 0.1, options: [.curveEaseOut], animations: {
                self.valueLabel.alpha = 1.0
                self.valueLabel.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }) { _ in
                UIView.animate(withDuration: 0.2) {
                    self.valueLabel.transform = .identity
                }
            }
        }
    }
    
    // MARK: - Animation Methods
    
    func animateUpdate() {
        // Subtle pulse animation
        UIView.animate(withDuration: 0.15, animations: {
            self.containerView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.15) {
                self.containerView.transform = .identity
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update gradient frame
        if let gradientLayer = containerView.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = containerView.bounds
        }
    }
}