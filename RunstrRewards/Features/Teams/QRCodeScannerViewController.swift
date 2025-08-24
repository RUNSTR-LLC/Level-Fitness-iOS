import UIKit
import AVFoundation

protocol QRCodeScannerDelegate: AnyObject {
    func qrCodeScanned(_ code: String)
    func qrScannerDidCancel()
}

class QRCodeScannerViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: QRCodeScannerDelegate?
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var isScanning = false
    
    // UI Components
    private let closeButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let instructionLabel = UILabel()
    private let scannerFrame = UIView()
    private let scannerCorners = [UIView(), UIView(), UIView(), UIView()]
    private let overlayView = UIView()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        checkCameraPermission()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = IndustrialDesign.Colors.background
        
        // Setup camera preview layer first (will be at the bottom)
        setupCameraPreview()
        
        // Overlay view with cutout
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        
        // Scanner frame (transparent area)
        scannerFrame.backgroundColor = .clear
        scannerFrame.layer.borderColor = IndustrialDesign.Colors.accentText.cgColor
        scannerFrame.layer.borderWidth = 2
        scannerFrame.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scannerFrame)
        
        // Add corner decorations
        for (index, corner) in scannerCorners.enumerated() {
            corner.backgroundColor = IndustrialDesign.Colors.accentText
            corner.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(corner)
            
            // Configure corner based on position
            let cornerSize: CGFloat = 20
            let cornerThickness: CGFloat = 3
            
            NSLayoutConstraint.activate([
                corner.widthAnchor.constraint(equalToConstant: index % 2 == 0 ? cornerSize : cornerThickness),
                corner.heightAnchor.constraint(equalToConstant: index % 2 == 0 ? cornerThickness : cornerSize)
            ])
        }
        
        // Title label
        titleLabel.text = "SCAN TEAM QR CODE"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Instruction label
        instructionLabel.text = "Position the QR code within the frame"
        instructionLabel.font = UIFont.systemFont(ofSize: 16)
        instructionLabel.textColor = IndustrialDesign.Colors.secondaryText
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 0
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionLabel)
        
        // Close button
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = IndustrialDesign.Colors.primaryText
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        let scannerSize: CGFloat = 250
        
        NSLayoutConstraint.activate([
            // Overlay
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Scanner frame
            scannerFrame.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scannerFrame.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            scannerFrame.widthAnchor.constraint(equalToConstant: scannerSize),
            scannerFrame.heightAnchor.constraint(equalToConstant: scannerSize),
            
            // Title
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: scannerFrame.topAnchor, constant: -50),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Instructions
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.topAnchor.constraint(equalTo: scannerFrame.bottomAnchor, constant: 50),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            // Close button
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Corner decorations
            scannerCorners[0].topAnchor.constraint(equalTo: scannerFrame.topAnchor),
            scannerCorners[0].leadingAnchor.constraint(equalTo: scannerFrame.leadingAnchor),
            
            scannerCorners[1].topAnchor.constraint(equalTo: scannerFrame.topAnchor),
            scannerCorners[1].trailingAnchor.constraint(equalTo: scannerFrame.trailingAnchor),
            
            scannerCorners[2].bottomAnchor.constraint(equalTo: scannerFrame.bottomAnchor),
            scannerCorners[2].leadingAnchor.constraint(equalTo: scannerFrame.leadingAnchor),
            
            scannerCorners[3].bottomAnchor.constraint(equalTo: scannerFrame.bottomAnchor),
            scannerCorners[3].trailingAnchor.constraint(equalTo: scannerFrame.trailingAnchor)
        ])
    }
    
    // MARK: - Camera Setup
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupCamera()
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.showCameraPermissionAlert()
                    }
                }
            }
        case .denied, .restricted:
            showCameraPermissionAlert()
        @unknown default:
            break
        }
    }
    
    private func setupCameraPreview() {
        // This will be called before camera is set up to prepare the layer
        let previewLayer = AVCaptureVideoPreviewLayer()
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(previewLayer, at: 0)
        self.previewLayer = previewLayer
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let captureSession = captureSession,
              let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("Failed to get camera device")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: videoCaptureDevice)
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            } else {
                print("Could not add video input")
                return
            }
            
            let metadataOutput = AVCaptureMetadataOutput()
            
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            } else {
                print("Could not add metadata output")
                return
            }
            
            previewLayer?.session = captureSession
            
            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.startRunning()
            }
            
        } catch {
            print("Error setting up camera: \(error)")
        }
    }
    
    private func showCameraPermissionAlert() {
        let alert = UIAlertController(
            title: "Camera Permission Required",
            message: "Please enable camera access in Settings to scan QR codes",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.delegate?.qrScannerDidCancel()
            self?.dismiss(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Actions
    
    @objc private func closeButtonTapped() {
        delegate?.qrScannerDidCancel()
        dismiss(animated: true)
    }
    
    // MARK: - Helpers
    
    private func processQRCode(_ code: String) {
        // Prevent multiple scans
        guard !isScanning else { return }
        isScanning = true
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Flash animation
        UIView.animate(withDuration: 0.2, animations: {
            self.scannerFrame.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                self.scannerFrame.backgroundColor = .clear
            }
        }
        
        // Notify delegate
        delegate?.qrCodeScanned(code)
        
        // Dismiss after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.dismiss(animated: true)
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension QRCodeScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
                  let stringValue = readableObject.stringValue else { return }
            
            processQRCode(stringValue)
        }
    }
}