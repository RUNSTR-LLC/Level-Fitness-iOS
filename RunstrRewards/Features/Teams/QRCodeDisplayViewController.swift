import UIKit

class QRCodeDisplayViewController: UIViewController {
    
    // MARK: - Properties
    private let qrImage: UIImage
    private let teamName: String
    private let teamId: String
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let qrImageView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let shareButton = UIButton(type: .custom)
    private let closeButton = UIButton(type: .custom)
    
    // MARK: - Initialization
    
    init(qrImage: UIImage, teamName: String, teamId: String) {
        self.qrImage = qrImage
        self.teamName = teamName
        self.teamId = teamId
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = .pageSheet
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.preferredCornerRadius = 20
            sheet.prefersGrabberVisible = true
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        view.backgroundColor = IndustrialDesign.Colors.background
        
        // Container view
        containerView.backgroundColor = IndustrialDesign.Colors.cardBackground
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // QR Code Image
        qrImageView.image = qrImage
        qrImageView.contentMode = .scaleAspectFit
        qrImageView.backgroundColor = .white
        qrImageView.layer.cornerRadius = 12
        qrImageView.clipsToBounds = true
        qrImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title Label
        titleLabel.text = "Join \(teamName)"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Description Label
        descriptionLabel.text = "Scan this QR code with your camera to join the team and start earning Bitcoin rewards!"
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textColor = IndustrialDesign.Colors.secondaryText
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Share Button
        shareButton.setTitle("Share QR Code", for: .normal)
        shareButton.setTitleColor(.white, for: .normal)
        shareButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        shareButton.backgroundColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0) // Bitcoin orange
        shareButton.layer.cornerRadius = 12
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        
        // Close Button
        closeButton.setTitle("Close", for: .normal)
        closeButton.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        closeButton.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.6)
        closeButton.layer.cornerRadius = 12
        closeButton.layer.borderWidth = 1
        closeButton.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        // Add subviews
        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(qrImageView)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(shareButton)
        containerView.addSubview(closeButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            
            // QR Code Image
            qrImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            qrImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            qrImageView.widthAnchor.constraint(equalToConstant: 200),
            qrImageView.heightAnchor.constraint(equalToConstant: 200),
            
            // Description
            descriptionLabel.topAnchor.constraint(equalTo: qrImageView.bottomAnchor, constant: 24),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            
            // Share Button
            shareButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 32),
            shareButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            shareButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            shareButton.heightAnchor.constraint(equalToConstant: 56),
            
            // Close Button
            closeButton.topAnchor.constraint(equalTo: shareButton.bottomAnchor, constant: 12),
            closeButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            closeButton.heightAnchor.constraint(equalToConstant: 48),
            closeButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func shareButtonTapped() {
        print("🏗️ RunstrRewards: Share QR code button tapped")
        
        let teamInviteURL = "https://runstrrewards.app/join/\(teamId)"
        let shareText = "Join my RunstrRewards team '\(teamName)'! Compete in fitness challenges and earn Bitcoin rewards. \(teamInviteURL)"
        
        let activityItems: [Any] = [shareText, qrImage]
        let activityViewController = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        
        // Configure for iPad
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = shareButton
            popover.sourceRect = shareButton.bounds
        }
        
        present(activityViewController, animated: true) {
            print("🏗️ RunstrRewards: QR code shared successfully")
        }
    }
    
    @objc private func closeButtonTapped() {
        print("🏗️ RunstrRewards: Close QR code display")
        dismiss(animated: true)
    }
}