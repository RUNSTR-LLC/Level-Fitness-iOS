import UIKit

protocol TransactionHistoryViewDelegate: AnyObject {
    func didTapTransaction(_ transaction: TransactionData)
    func didTapFilterButton()
}

class TransactionHistoryView: UIView {
    
    // MARK: - Properties
    weak var delegate: TransactionHistoryViewDelegate?
    private var transactions: [TransactionData] = []
    private var groupedTransactions: [(String, [TransactionData])] = []
    
    // MARK: - UI Components
    private let headerView = UIView()
    private let historyTitleLabel = UILabel()
    private let filterButton = UIButton(type: .custom)
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
        setupNotifications()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup Methods
    
    private func setupView() {
        backgroundColor = UIColor.clear
        
        // Header view
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        
        // Add bottom border to header
        let borderLayer = CALayer()
        borderLayer.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
        borderLayer.frame = CGRect(x: 0, y: 55, width: UIScreen.main.bounds.width, height: 1)
        headerView.layer.addSublayer(borderLayer)
        
        // History title
        historyTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        historyTitleLabel.text = "TRANSACTION HISTORY"
        historyTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        historyTitleLabel.textColor = IndustrialDesign.Colors.accentText
        historyTitleLabel.letterSpacing = 1
        
        // Filter button
        filterButton.translatesAutoresizingMaskIntoConstraints = false
        filterButton.setTitle("Filter ↓", for: .normal)
        filterButton.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
        filterButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        filterButton.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
        
        // Scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.indicatorStyle = .white
        scrollView.backgroundColor = UIColor.clear
        
        // Content view
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = UIColor.clear
        
        addSubview(headerView)
        addSubview(scrollView)
        
        headerView.addSubview(historyTitleLabel)
        headerView.addSubview(filterButton)
        
        scrollView.addSubview(contentView)
        
        // Configure scroll view indicators
        scrollView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Header view
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 56),
            
            // History title
            historyTitleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 24),
            historyTitleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            // Filter button
            filterButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -24),
            filterButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(transactionCardTapped(_:)),
            name: .transactionCardTapped,
            object: nil
        )
    }
    
    // MARK: - Public Methods
    
    func loadSampleTransactions() {
        let calendar = Calendar.current
        let now = Date()
        
        transactions = [
            // Today
            TransactionData(
                id: "1",
                title: "Weekend Warrior 10K",
                source: "Steel City Runners",
                date: calendar.date(byAdding: .hour, value: -2, to: now)!,
                bitcoinAmount: 0.0003,
                usdAmount: 9.05,
                type: .earning,
                icon: .challenge
            ),
            TransactionData(
                id: "2",
                title: "Daily Streak Bonus",
                source: "Level Fitness Rewards",
                date: calendar.date(byAdding: .hour, value: -8, to: now)!,
                bitcoinAmount: 0.0001,
                usdAmount: 3.02,
                type: .earning,
                icon: .streak
            ),
            
            // Yesterday
            TransactionData(
                id: "3",
                title: "Speed Demon Challenge",
                source: "Bitcoin Marathoners",
                date: calendar.date(byAdding: .day, value: -1, to: now)!,
                bitcoinAmount: 0.0005,
                usdAmount: 15.08,
                type: .earning,
                icon: .star
            ),
            TransactionData(
                id: "4",
                title: "Team Subscription",
                source: "Steel City Runners",
                date: calendar.date(byAdding: .day, value: -1, to: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now)!)!,
                bitcoinAmount: 0.0001,
                usdAmount: 3.02,
                type: .expense,
                icon: .subscription
            ),
            
            // This week
            TransactionData(
                id: "5",
                title: "Elevation Master",
                source: "Chain Breakers Cycling",
                date: calendar.date(byAdding: .day, value: -3, to: now)!,
                bitcoinAmount: 0.0008,
                usdAmount: 24.13,
                type: .earning,
                icon: .challenge
            ),
            TransactionData(
                id: "6",
                title: "Withdrawal",
                source: "To Lightning Address",
                date: calendar.date(byAdding: .day, value: -4, to: now)!,
                bitcoinAmount: 0.0020,
                usdAmount: 60.32,
                type: .expense,
                icon: .withdrawal
            ),
            TransactionData(
                id: "7",
                title: "New Year Marathon",
                source: "Proof of Work Fitness",
                date: calendar.date(byAdding: .day, value: -7, to: now)!,
                bitcoinAmount: 0.0015,
                usdAmount: 45.24,
                type: .earning,
                icon: .event
            )
        ]
        
        groupTransactionsByDate()
        buildTransactionViews()
    }
    
    private func groupTransactionsByDate() {
        let grouped = Dictionary(grouping: transactions) { $0.dateSection }
        
        // Sort sections in chronological order (most recent first)
        let sortOrder = ["Today", "Yesterday", "This Week", "This Month"]
        
        groupedTransactions = grouped.keys.sorted { section1, section2 in
            if let index1 = sortOrder.firstIndex(of: section1),
               let index2 = sortOrder.firstIndex(of: section2) {
                return index1 < index2
            }
            return section1 < section2
        }.map { section in
            let sectionTransactions = grouped[section]?.sorted { $0.date > $1.date } ?? []
            return (section, sectionTransactions)
        }
    }
    
    private func buildTransactionViews() {
        // Clear existing views
        contentView.subviews.forEach { $0.removeFromSuperview() }
        
        var lastView: UIView?
        
        for (sectionTitle, sectionTransactions) in groupedTransactions {
            // Create date separator
            let separator = createDateSeparator(title: sectionTitle)
            contentView.addSubview(separator)
            
            // Position separator
            NSLayoutConstraint.activate([
                separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
                separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24)
            ])
            
            if let lastView = lastView {
                separator.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 20).isActive = true
            } else {
                separator.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16).isActive = true
            }
            
            lastView = separator
            
            // Add transaction cards for this section
            for transaction in sectionTransactions {
                let card = TransactionCard(transactionData: transaction)
                card.translatesAutoresizingMaskIntoConstraints = false
                contentView.addSubview(card)
                
                NSLayoutConstraint.activate([
                    card.topAnchor.constraint(equalTo: lastView!.bottomAnchor, constant: 12),
                    card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
                    card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24)
                ])
                
                lastView = card
            }
        }
        
        // Set content view height
        if let lastView = lastView {
            contentView.bottomAnchor.constraint(greaterThanOrEqualTo: lastView.bottomAnchor, constant: 24).isActive = true
        }
    }
    
    private func createDateSeparator(title: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = title.uppercased()
        label.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = IndustrialDesign.Colors.secondaryText
        label.textAlignment = .center
        label.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 1.0)
        label.letterSpacing = 1
        
        let leftLine = UIView()
        leftLine.translatesAutoresizingMaskIntoConstraints = false
        leftLine.backgroundColor = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0)
        
        let rightLine = UIView()
        rightLine.translatesAutoresizingMaskIntoConstraints = false
        rightLine.backgroundColor = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0)
        
        container.addSubview(leftLine)
        container.addSubview(label)
        container.addSubview(rightLine)
        
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 20),
            
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            label.widthAnchor.constraint(lessThanOrEqualToConstant: 120),
            
            leftLine.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            leftLine.trailingAnchor.constraint(equalTo: label.leadingAnchor, constant: -12),
            leftLine.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            leftLine.heightAnchor.constraint(equalToConstant: 1),
            
            rightLine.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 12),
            rightLine.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            rightLine.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            rightLine.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        return container
    }
    
    // MARK: - Actions
    
    @objc private func filterButtonTapped() {
        delegate?.didTapFilterButton()
    }
    
    @objc private func transactionCardTapped(_ notification: Notification) {
        if let transaction = notification.object as? TransactionData {
            delegate?.didTapTransaction(transaction)
        }
    }
}