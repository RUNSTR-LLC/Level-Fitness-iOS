import UIKit

// MARK: - Payment Progress States

enum PaymentProgress {
    case preparing
    case invoiceCreated
    case processing
    case verifying
    case updatingTeams
    case complete
    case failed(String)
    
    var title: String {
        switch self {
        case .preparing:
            return "Preparing payment..."
        case .invoiceCreated:
            return "Payment ready"
        case .processing:
            return "Processing payment..."
        case .verifying:
            return "Verifying payment..."
        case .updatingTeams:
            return "Updating team membership..."
        case .complete:
            return "Payment complete!"
        case .failed:
            return "Payment failed"
        }
    }
    
    var subtitle: String {
        switch self {
        case .preparing:
            return "Setting up exit fee payment"
        case .invoiceCreated:
            return "2000 sats to RUNSTR@coinos.io"
        case .processing:
            return "Lightning Network processing..."
        case .verifying:
            return "Confirming RUNSTR received payment"
        case .updatingTeams:
            return "Finalizing team changes"
        case .complete:
            return "Team exit successful"
        case .failed(let message):
            return message
        }
    }
    
    var icon: String {
        switch self {
        case .preparing:
            return "hourglass.circle"
        case .invoiceCreated:
            return "bolt.circle.fill"
        case .processing:
            return "arrow.triangle.2.circlepath.circle"
        case .verifying:
            return "checkmark.shield.fill"
        case .updatingTeams:
            return "person.2.circle.fill"
        case .complete:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        }
    }
    
    var iconColor: UIColor {
        switch self {
        case .complete:
            return .systemGreen
        case .failed:
            return .systemRed
        case .verifying, .updatingTeams:
            return .systemBlue
        default:
            return IndustrialDesign.Colors.bitcoin
        }
    }
    
    var progressValue: Float {
        switch self {
        case .preparing:
            return 0.1
        case .invoiceCreated:
            return 0.25
        case .processing:
            return 0.5
        case .verifying:
            return 0.75
        case .updatingTeams:
            return 0.9
        case .complete:
            return 1.0
        case .failed:
            return 0.0
        }
    }
    
    var shouldAnimateIcon: Bool {
        switch self {
        case .processing, .verifying, .updatingTeams:
            return true
        default:
            return false
        }
    }
}

// MARK: - Payment Progress View Controller

class PaymentProgressViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let backgroundView = UIView()
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let amountLabel = UILabel()
    private let progressView = UIProgressView()
    private let cancelButton = UIButton(type: .custom)
    
    // MARK: - State
    
    private var currentProgress: PaymentProgress = .preparing
    private var onCancel: (() -> Void)?
    private var canCancel: Bool = true
    
    // MARK: - Initialization
    
    init(onCancel: (() -> Void)? = nil) {
        self.onCancel = onCancel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateProgress(.preparing)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // Background
        view.backgroundColor = UIColor.clear
        
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundView)
        
        // Container with industrial design
        containerView.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)
        containerView.layer.cornerRadius = 20
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0).cgColor
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 12
        containerView.layer.shadowOpacity = 0.3
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Icon
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = IndustrialDesign.Colors.bitcoin
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconImageView)
        
        // Title
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // Subtitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = IndustrialDesign.Colors.secondaryText
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 2
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(subtitleLabel)
        
        // Amount
        amountLabel.text = "2000 sats"
        amountLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        amountLabel.textColor = IndustrialDesign.Colors.bitcoin
        amountLabel.textAlignment = .center
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(amountLabel)
        
        // Progress bar
        progressView.progressTintColor = IndustrialDesign.Colors.bitcoin
        progressView.trackTintColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
        progressView.layer.cornerRadius = 3
        progressView.clipsToBounds = true
        progressView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(progressView)
        
        // Cancel button (initially hidden)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cancelButton.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
        cancelButton.backgroundColor = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0)
        cancelButton.layer.cornerRadius = 8
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.alpha = 0.0 // Initially hidden
        containerView.addSubview(cancelButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            // Background
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Container
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            containerView.widthAnchor.constraint(equalToConstant: 320),
            containerView.heightAnchor.constraint(equalToConstant: 300),
            
            // Icon
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 30),
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 64),
            iconImageView.heightAnchor.constraint(equalToConstant: 64),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Amount
            amountLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            amountLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            // Progress
            progressView.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 25),
            progressView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 30),
            progressView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -30),
            progressView.heightAnchor.constraint(equalToConstant: 6),
            
            // Cancel button
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            cancelButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            cancelButton.widthAnchor.constraint(equalToConstant: 100),
            cancelButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    // MARK: - Public Methods
    
    func updateProgress(_ progress: PaymentProgress) {
        DispatchQueue.main.async {
            self.currentProgress = progress
            
            // Update text content
            self.titleLabel.text = progress.title
            self.subtitleLabel.text = progress.subtitle
            
            // Update icon
            self.iconImageView.image = UIImage(systemName: progress.icon)
            
            // Animate icon color change
            UIView.animate(withDuration: 0.3) {
                self.iconImageView.tintColor = progress.iconColor
            }
            
            // Update progress bar
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut) {
                self.progressView.setProgress(progress.progressValue, animated: true)
            }
            
            // Handle cancel button visibility
            self.updateCancelButtonVisibility()
            
            // Handle icon animation
            if progress.shouldAnimateIcon {
                self.startIconAnimation()
            } else {
                self.stopIconAnimation()
            }
            
            // Handle completion or failure
            if case .complete = progress {
                self.handleCompletion()
            } else if case .failed = progress {
                self.handleFailure()
            }
        }
    }
    
    func setCancelable(_ cancelable: Bool) {
        canCancel = cancelable
        updateCancelButtonVisibility()
    }
    
    // MARK: - Private Methods
    
    private func updateCancelButtonVisibility() {
        let shouldShowCancel = canCancel && !currentProgress.progressValue.isEqual(to: 1.0)
        
        UIView.animate(withDuration: 0.3) {
            self.cancelButton.alpha = shouldShowCancel ? 1.0 : 0.0
        }
    }
    
    private func startIconAnimation() {
        guard iconImageView.layer.animation(forKey: "rotation") == nil else { return }
        
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = Double.pi * 2
        rotation.duration = 1.5
        rotation.repeatCount = .infinity
        rotation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        iconImageView.layer.add(rotation, forKey: "rotation")
    }
    
    private func stopIconAnimation() {
        iconImageView.layer.removeAnimation(forKey: "rotation")
    }
    
    private func animateIn() {
        containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        containerView.alpha = 0.0
        
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0) {
            self.containerView.transform = .identity
            self.containerView.alpha = 1.0
        }
    }
    
    private func handleCompletion() {
        // Add success pulse animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIView.animate(withDuration: 0.2, animations: {
                self.iconImageView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }) { _ in
                UIView.animate(withDuration: 0.2) {
                    self.iconImageView.transform = .identity
                }
            }
        }
    }
    
    private func handleFailure() {
        // Add failure shake animation
        let shake = CAKeyframeAnimation(keyPath: "transform.translation.x")
        shake.timingFunction = CAMediaTimingFunction(name: .linear)
        shake.duration = 0.6
        shake.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0]
        containerView.layer.add(shake, forKey: "shake")
        
        // Show cancel button for retry option
        setCancelable(true)
    }
    
    @objc private func cancelButtonTapped() {
        // Animate out
        UIView.animate(withDuration: 0.3, animations: {
            self.containerView.alpha = 0.0
            self.containerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            self.onCancel?()
        }
    }
    
    // MARK: - Public Dismissal
    
    func dismissWithAnimation(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.4, animations: {
            self.backgroundView.alpha = 0.0
            self.containerView.alpha = 0.0
            self.containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            completion?()
        }
    }
}

// MARK: - Static Factory Methods

extension PaymentProgressViewController {
    
    static func presentExitFeePayment(
        on presenter: UIViewController, 
        onCancel: (() -> Void)? = nil
    ) -> PaymentProgressViewController {
        let progressVC = PaymentProgressViewController(onCancel: onCancel)
        progressVC.modalPresentationStyle = .overFullScreen
        progressVC.modalTransitionStyle = .crossDissolve
        
        presenter.present(progressVC, animated: true)
        return progressVC
    }
}