import UIKit

class StatItem: UIView {
    
    // MARK: - UI Components
    private let valueLabel = UILabel()
    private let labelLabel = UILabel()
    private let bitcoinSymbol = UILabel()
    
    private let value: String
    private let label: String
    private let isBitcoin: Bool
    
    // MARK: - Initialization
    init(value: String, label: String, isBitcoin: Bool = false) {
        self.value = value
        self.label = label
        self.isBitcoin = isBitcoin
        super.init(frame: .zero)
        
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        // Value label setup
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.text = value
        valueLabel.font = IndustrialDesign.Typography.statValueFont
        valueLabel.textColor = IndustrialDesign.Colors.primaryText
        valueLabel.textAlignment = .center
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.8
        
        // Label label setup
        labelLabel.translatesAutoresizingMaskIntoConstraints = false
        labelLabel.text = label.uppercased()
        labelLabel.font = IndustrialDesign.Typography.statLabelFont
        labelLabel.textColor = IndustrialDesign.Colors.secondaryText
        labelLabel.textAlignment = .center
        labelLabel.adjustsFontSizeToFitWidth = true
        labelLabel.minimumScaleFactor = 0.8
        
        // Bitcoin symbol setup (if needed)
        if isBitcoin {
            bitcoinSymbol.translatesAutoresizingMaskIntoConstraints = false
            bitcoinSymbol.text = "₿"
            bitcoinSymbol.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            bitcoinSymbol.textColor = IndustrialDesign.Colors.bitcoin
            bitcoinSymbol.textAlignment = .center
        }
        
        addSubview(valueLabel)
        addSubview(labelLabel)
        
        if isBitcoin {
            addSubview(bitcoinSymbol)
        }
    }
    
    private func setupConstraints() {
        if isBitcoin {
            // Layout with Bitcoin symbol
            NSLayoutConstraint.activate([
                // Value label
                valueLabel.topAnchor.constraint(equalTo: topAnchor),
                valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
                valueLabel.centerXAnchor.constraint(lessThanOrEqualTo: centerXAnchor, constant: -8),
                
                // Bitcoin symbol
                bitcoinSymbol.centerYAnchor.constraint(equalTo: valueLabel.centerYAnchor),
                bitcoinSymbol.leadingAnchor.constraint(equalTo: valueLabel.trailingAnchor, constant: 2),
                bitcoinSymbol.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
                
                // Label
                labelLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: IndustrialDesign.Spacing.tiny),
                labelLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
                labelLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
                labelLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        } else {
            // Layout without Bitcoin symbol
            NSLayoutConstraint.activate([
                // Value label
                valueLabel.topAnchor.constraint(equalTo: topAnchor),
                valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
                valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
                
                // Label
                labelLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: IndustrialDesign.Spacing.tiny),
                labelLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
                labelLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
                labelLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }
    }
    
    // MARK: - Public Methods
    
    func updateValue(_ newValue: String) {
        valueLabel.text = newValue
    }
    
    func animateValueChange(to newValue: String) {
        // Fade out current value
        UIView.animate(withDuration: 0.15, animations: {
            self.valueLabel.alpha = 0
        }) { _ in
            // Update value
            self.valueLabel.text = newValue
            
            // Fade in new value
            UIView.animate(withDuration: 0.15) {
                self.valueLabel.alpha = 1
            }
        }
    }
}