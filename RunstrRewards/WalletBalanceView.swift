import UIKit

struct WalletData {
    let bitcoinBalance: Double
    let usdBalance: Double
    let lastUpdated: Date
}

protocol WalletBalanceViewDelegate: AnyObject {
    func didTapReceiveButton()
    func didTapSendButton()
}

class WalletBalanceView: UIView {
    
    // MARK: - Properties
    weak var delegate: WalletBalanceViewDelegate?
    
    // MARK: - UI Components
    private let balanceLabel = UILabel()
    private let balanceAmountContainer = UIView()
    private let bitcoinSymbolLabel = UILabel()
    private let balanceValueLabel = UILabel()
    private let usdLabel = UILabel()
    private let actionsContainer = UIView()
    private let receiveButton = WalletActionButton(title: "RECEIVE", icon: .receive)
    private let sendButton = WalletActionButton(title: "SEND", icon: .send)
    private let boltDecoration1 = UIView()
    private let boltDecoration2 = UIView()
    
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
        backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        
        // Add bottom border
        let borderLayer = CALayer()
        borderLayer.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        borderLayer.frame = CGRect(x: 0, y: 219, width: UIScreen.main.bounds.width, height: 1)
        layer.addSublayer(borderLayer)
        
        // Balance label
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        balanceLabel.text = "TOTAL BALANCE"
        balanceLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        balanceLabel.textColor = IndustrialDesign.Colors.secondaryText
        balanceLabel.textAlignment = .center
        balanceLabel.letterSpacing = 1
        
        // Balance amount container
        balanceAmountContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Bitcoin symbol - now shows "sats"
        bitcoinSymbolLabel.translatesAutoresizingMaskIntoConstraints = false
        bitcoinSymbolLabel.text = "sats"
        bitcoinSymbolLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        bitcoinSymbolLabel.textColor = IndustrialDesign.Colors.bitcoin
        
        // Balance value
        balanceValueLabel.translatesAutoresizingMaskIntoConstraints = false
        balanceValueLabel.font = UIFont.systemFont(ofSize: 48, weight: .bold)
        balanceValueLabel.textColor = IndustrialDesign.Colors.primaryText
        
        // USD label
        usdLabel.translatesAutoresizingMaskIntoConstraints = false
        usdLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        usdLabel.textColor = IndustrialDesign.Colors.accentText
        usdLabel.textAlignment = .center
        
        // Actions container
        actionsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Buttons
        receiveButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        
        receiveButton.addTarget(self, action: #selector(receiveButtonTapped), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        
        // Bolt decorations
        setupBoltDecorations()
        
        addSubview(balanceLabel)
        addSubview(balanceAmountContainer)
        addSubview(usdLabel)
        addSubview(actionsContainer)
        addSubview(boltDecoration1)
        addSubview(boltDecoration2)
        
        balanceAmountContainer.addSubview(bitcoinSymbolLabel)
        balanceAmountContainer.addSubview(balanceValueLabel)
        
        actionsContainer.addSubview(receiveButton)
        actionsContainer.addSubview(sendButton)
    }
    
    private func setupBoltDecorations() {
        [boltDecoration1, boltDecoration2].forEach { bolt in
            bolt.backgroundColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0)
            bolt.layer.cornerRadius = IndustrialDesign.Sizing.boltSize / 2
            bolt.layer.borderWidth = 1
            bolt.layer.borderColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor
            
            let shadowLayer = CALayer()
            shadowLayer.backgroundColor = UIColor.black.cgColor
            shadowLayer.frame = CGRect(x: 1, y: 1, width: IndustrialDesign.Sizing.boltSize - 2, height: IndustrialDesign.Sizing.boltSize - 2)
            shadowLayer.cornerRadius = (IndustrialDesign.Sizing.boltSize - 2) / 2
            bolt.layer.addSublayer(shadowLayer)
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Balance label
            balanceLabel.topAnchor.constraint(equalTo: topAnchor, constant: 30),
            balanceLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            // Balance amount container
            balanceAmountContainer.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor, constant: 12),
            balanceAmountContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            balanceAmountContainer.heightAnchor.constraint(equalToConstant: 60),
            
            // Balance value
            balanceValueLabel.centerXAnchor.constraint(equalTo: balanceAmountContainer.centerXAnchor),
            balanceValueLabel.topAnchor.constraint(equalTo: balanceAmountContainer.topAnchor),
            
            // Bitcoin symbol (sats) positioned below balance value
            bitcoinSymbolLabel.topAnchor.constraint(equalTo: balanceValueLabel.bottomAnchor, constant: -4),
            bitcoinSymbolLabel.centerXAnchor.constraint(equalTo: balanceValueLabel.centerXAnchor),
            bitcoinSymbolLabel.bottomAnchor.constraint(equalTo: balanceAmountContainer.bottomAnchor),
            
            // USD label
            usdLabel.topAnchor.constraint(equalTo: balanceAmountContainer.bottomAnchor, constant: 8),
            usdLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            // Actions container
            actionsContainer.topAnchor.constraint(equalTo: usdLabel.bottomAnchor, constant: 24),
            actionsContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            actionsContainer.widthAnchor.constraint(equalToConstant: 296), // 140 + 16 + 140
            actionsContainer.heightAnchor.constraint(equalToConstant: 48),
            
            // Buttons
            receiveButton.leadingAnchor.constraint(equalTo: actionsContainer.leadingAnchor),
            receiveButton.centerYAnchor.constraint(equalTo: actionsContainer.centerYAnchor),
            receiveButton.widthAnchor.constraint(equalToConstant: 140),
            receiveButton.heightAnchor.constraint(equalToConstant: 48),
            
            sendButton.trailingAnchor.constraint(equalTo: actionsContainer.trailingAnchor),
            sendButton.centerYAnchor.constraint(equalTo: actionsContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 140),
            sendButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Position bolt decorations
        boltDecoration1.frame = CGRect(
            x: 16,
            y: 16,
            width: IndustrialDesign.Sizing.boltSize,
            height: IndustrialDesign.Sizing.boltSize
        )
        
        boltDecoration2.frame = CGRect(
            x: frame.width - 24,
            y: 16,
            width: IndustrialDesign.Sizing.boltSize,
            height: IndustrialDesign.Sizing.boltSize
        )
    }
    
    // MARK: - Configuration
    
    func configure(with data: WalletData) {
        // Convert BTC to sats (1 BTC = 100,000,000 sats)
        let satsBalance = Int(data.bitcoinBalance * 100_000_000)
        
        // Format sats balance to show clean integers
        if satsBalance == 0 {
            balanceValueLabel.text = "0"
        } else {
            // Use number formatter for larger amounts with commas
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.groupingSeparator = ","
            balanceValueLabel.text = formatter.string(from: NSNumber(value: satsBalance)) ?? "\(satsBalance)"
        }
        
        usdLabel.text = "≈ $\(String(format: "%.2f", data.usdBalance)) USD"
    }
    
    // MARK: - Actions
    
    @objc private func receiveButtonTapped() {
        delegate?.didTapReceiveButton()
    }
    
    @objc private func sendButtonTapped() {
        delegate?.didTapSendButton()
    }
}

// MARK: - UILabel Extension for Letter Spacing

extension UILabel {
    var letterSpacing: CGFloat {
        get { return 0 }
        set {
            let attributedString = NSMutableAttributedString(string: self.text ?? "")
            attributedString.addAttribute(
                .kern,
                value: newValue,
                range: NSRange(location: 0, length: attributedString.length)
            )
            self.attributedText = attributedString
        }
    }
}