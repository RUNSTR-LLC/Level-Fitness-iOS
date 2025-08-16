import UIKit
import Foundation

enum TransactionType {
    case earning
    case expense
    
    var amountColor: UIColor {
        switch self {
        case .earning:
            return UIColor(red: 0.29, green: 0.87, blue: 0.5, alpha: 1.0) // #4ade80
        case .expense:
            return UIColor(red: 0.94, green: 0.27, blue: 0.27, alpha: 1.0) // #ef4444
        }
    }
    
    var amountPrefix: String {
        switch self {
        case .earning:
            return "+"
        case .expense:
            return "-"
        }
    }
}

enum TransactionIcon {
    case challenge
    case event
    case streak
    case subscription
    case withdrawal
    case star
    
    var systemImageName: String {
        switch self {
        case .challenge:
            return "checkmark.circle"
        case .event:
            return "trophy"
        case .streak:
            return "target"
        case .subscription:
            return "plus.circle"
        case .withdrawal:
            return "paperplane"
        case .star:
            return "star"
        }
    }
}

struct TransactionData {
    let id: String
    let title: String
    let source: String
    let date: Date
    let bitcoinAmount: Double
    let usdAmount: Double
    let type: TransactionType
    let icon: TransactionIcon
    
    var formattedDate: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
            return "\(formatter.string(from: date).lowercased())"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "h:mm a"
            return "Yesterday, \(formatter.string(from: date))"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
    }
    
    var dateSection: String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let daysDiff = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
            if daysDiff <= 7 {
                return "This Week"
            } else if daysDiff <= 30 {
                return "This Month"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                return formatter.string(from: date)
            }
        }
    }
}

class TransactionCard: UIView {
    
    // MARK: - Properties
    private let transactionData: TransactionData
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let iconView = UIView()
    private let iconImageView = UIImageView()
    private let contentContainer = UIView()
    private let titleLabel = UILabel()
    private let sourceLabel = UILabel()
    private let dateLabel = UILabel()
    private let amountContainer = UIView()
    private let amountLabel = UILabel()
    private let usdLabel = UILabel()
    private let boltDecoration = UIView()
    
    // MARK: - Initialization
    
    init(transactionData: TransactionData) {
        self.transactionData = transactionData
        super.init(frame: .zero)
        setupCard()
        setupConstraints()
        configureWithData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    private func setupCard() {
        backgroundColor = UIColor.clear
        
        // Container view with gradient background
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        containerView.layer.cornerRadius = 10
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0).cgColor
        
        // Icon view
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.backgroundColor = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0)
        iconView.layer.cornerRadius = 20
        iconView.layer.borderWidth = 1
        iconView.layer.borderColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        
        // Icon image
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = UIImage(systemName: transactionData.icon.systemImageName)
        iconImageView.tintColor = IndustrialDesign.Colors.secondaryText
        iconImageView.contentMode = .scaleAspectFit
        
        // Content container
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Title label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.numberOfLines = 1
        
        // Source label
        sourceLabel.translatesAutoresizingMaskIntoConstraints = false
        sourceLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        sourceLabel.textColor = IndustrialDesign.Colors.accentText
        sourceLabel.numberOfLines = 1
        
        // Date label
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        dateLabel.textColor = IndustrialDesign.Colors.secondaryText
        dateLabel.numberOfLines = 1
        dateLabel.letterSpacing = 0.5
        
        // Amount container
        amountContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Amount label
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        amountLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        amountLabel.textAlignment = .right
        amountLabel.numberOfLines = 1
        
        // USD label
        usdLabel.translatesAutoresizingMaskIntoConstraints = false
        usdLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        usdLabel.textColor = IndustrialDesign.Colors.secondaryText
        usdLabel.textAlignment = .right
        usdLabel.numberOfLines = 1
        
        // Bolt decoration
        boltDecoration.backgroundColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0)
        boltDecoration.layer.cornerRadius = 3
        boltDecoration.layer.borderWidth = 1
        boltDecoration.layer.borderColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor
        
        addSubview(containerView)
        containerView.addSubview(iconView)
        containerView.addSubview(contentContainer)
        containerView.addSubview(amountContainer)
        containerView.addSubview(boltDecoration)
        
        iconView.addSubview(iconImageView)
        contentContainer.addSubview(titleLabel)
        contentContainer.addSubview(sourceLabel)
        contentContainer.addSubview(dateLabel)
        amountContainer.addSubview(amountLabel)
        amountContainer.addSubview(usdLabel)
        
        setupHoverEffects()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 80),
            
            // Icon view
            iconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),
            
            // Icon image
            iconImageView.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            // Content container
            contentContainer.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            contentContainer.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            contentContainer.trailingAnchor.constraint(lessThanOrEqualTo: amountContainer.leadingAnchor, constant: -12),
            
            // Title label
            titleLabel.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            
            // Source label
            sourceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            sourceLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            sourceLabel.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            
            // Date label
            dateLabel.topAnchor.constraint(equalTo: sourceLabel.bottomAnchor, constant: 2),
            dateLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            dateLabel.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
            
            // Amount container
            amountContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            amountContainer.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            amountContainer.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            
            // Amount label
            amountLabel.topAnchor.constraint(equalTo: amountContainer.topAnchor),
            amountLabel.leadingAnchor.constraint(equalTo: amountContainer.leadingAnchor),
            amountLabel.trailingAnchor.constraint(equalTo: amountContainer.trailingAnchor),
            
            // USD label
            usdLabel.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 4),
            usdLabel.leadingAnchor.constraint(equalTo: amountContainer.leadingAnchor),
            usdLabel.trailingAnchor.constraint(equalTo: amountContainer.trailingAnchor),
            usdLabel.bottomAnchor.constraint(equalTo: amountContainer.bottomAnchor)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Position bolt decoration
        boltDecoration.frame = CGRect(
            x: containerView.frame.width - 18,
            y: 12,
            width: 6,
            height: 6
        )
    }
    
    private func configureWithData() {
        titleLabel.text = transactionData.title
        sourceLabel.text = transactionData.source
        dateLabel.text = transactionData.formattedDate.uppercased()
        
        // Convert BTC to sats (1 BTC = 100,000,000 sats)
        let satsAmount = Int(transactionData.bitcoinAmount * 100_000_000)
        
        // Format sats amount with proper number formatting
        let formattedSats: String
        if satsAmount == 0 {
            formattedSats = "0"
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.groupingSeparator = ","
            formattedSats = formatter.string(from: NSNumber(value: abs(satsAmount))) ?? "\(abs(satsAmount))"
        }
        
        let amountText = "\(transactionData.type.amountPrefix)\(formattedSats) sats"
        amountLabel.text = amountText
        amountLabel.textColor = transactionData.type.amountColor
        
        usdLabel.text = "$\(String(format: "%.2f", transactionData.usdAmount))"
    }
    
    private func setupHoverEffects() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        addGestureRecognizer(tapGesture)
    }
    
    @objc private func cardTapped() {
        // Animation for tap feedback
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = .identity
            }
        }
        
        // Notify delegate or post notification
        NotificationCenter.default.post(name: .transactionCardTapped, object: transactionData)
    }
}

// MARK: - Notification Names

extension NSNotification.Name {
    static let transactionCardTapped = NSNotification.Name("TransactionCardTapped")
}