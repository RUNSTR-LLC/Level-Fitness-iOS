import UIKit

class TeamWalletPaymentService {
    
    // MARK: - Singleton
    static let shared = TeamWalletPaymentService()
    
    // MARK: - Properties
    weak var delegate: TeamWalletPaymentDelegate?
    private let coinOSService = CoinOSService.shared
    
    private init() {}
    
    // MARK: - Payment Processing
    
    func processBitcoinPayment(invoice: String, amount: Int) async {
        do {
            await MainActor.run {
                delegate?.didStartPayment()
            }
            
            // Basic invoice validation
            guard !invoice.isEmpty, invoice.starts(with: "ln") else {
                throw PaymentError.invalidInvoice
            }
            
            // Process payment through CoinOS
            let paymentResult = try await coinOSService.payInvoice(invoice: invoice)
            
            if paymentResult.success {
                await MainActor.run {
                    delegate?.didCompletePayment(hash: paymentResult.paymentHash, amount: amount)
                }
                print("✅ TeamWalletPaymentService: Payment successful")
            } else {
                await MainActor.run {
                    delegate?.didFailPayment(PaymentError.transactionFailed)
                }
                print("❌ TeamWalletPaymentService: Payment failed")
            }
            
        } catch {
            print("❌ TeamWalletPaymentService: Payment error: \(error)")
            await MainActor.run {
                delegate?.didFailPayment(error)
            }
        }
    }
    
    func showSendBitcoinInterface(from viewController: UIViewController) {
        let alert = UIAlertController(
            title: "Send Bitcoin",
            message: "Enter Lightning invoice to send Bitcoin from team wallet",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Lightning Invoice (lnbc...)"
            textField.keyboardType = .default
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Amount (sats)"
            textField.keyboardType = .numberPad
        }
        
        let sendAction = UIAlertAction(title: "Send", style: .default) { [weak self] _ in
            guard let invoice = alert.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  let amountText = alert.textFields?[1].text,
                  let amount = Int(amountText),
                  !invoice.isEmpty else {
                self?.delegate?.didFailPayment(PaymentError.invalidInvoice)
                return
            }
            
            // Confirm payment
            self?.confirmPayment(invoice: invoice, amount: amount, from: viewController)
        }
        
        alert.addAction(sendAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        viewController.present(alert, animated: true)
    }
    
    private func confirmPayment(invoice: String, amount: Int, from viewController: UIViewController) {
        let confirmAlert = UIAlertController(
            title: "Confirm Payment",
            message: "Send \(amount) sats from team wallet?",
            preferredStyle: .alert
        )
        
        confirmAlert.addAction(UIAlertAction(title: "Confirm", style: .default) { [weak self] _ in
            Task {
                await self?.processBitcoinPayment(invoice: invoice, amount: amount)
            }
        })
        
        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        viewController.present(confirmAlert, animated: true)
    }
    
    func showReceiveBitcoinInterface(for teamData: TeamData, from viewController: UIViewController) {
        let alert = UIAlertController(
            title: "Receive Bitcoin",
            message: "Generate invoice for team wallet funding",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Amount (sats)"
            textField.keyboardType = .numberPad
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Description (optional)"
            textField.text = "Team \(teamData.name) funding"
        }
        
        let generateAction = UIAlertAction(title: "Generate Invoice", style: .default) { [weak self] _ in
            guard let amountText = alert.textFields?[0].text,
                  let amount = Int(amountText),
                  amount > 0 else {
                self?.delegate?.didFailPayment(PaymentError.invalidAmount)
                return
            }
            
            let memo = alert.textFields?[1].text ?? "Team funding"
            self?.generateInvoice(amount: amount, memo: memo, from: viewController)
        }
        
        alert.addAction(generateAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        viewController.present(alert, animated: true)
    }
    
    private func generateInvoice(amount: Int, memo: String, from viewController: UIViewController) {
        Task {
            do {
                let invoice = try await coinOSService.addInvoice(amount: amount, memo: memo)
                
                await MainActor.run {
                    self.delegate?.didGenerateInvoice(invoice)
                    self.showInvoiceDetails(invoice, from: viewController)
                }
                
            } catch {
                await MainActor.run {
                    self.delegate?.didFailPayment(error)
                }
            }
        }
    }
    
    private func showInvoiceDetails(_ invoice: LightningInvoice, from viewController: UIViewController) {
        let alert = UIAlertController(
            title: "Lightning Invoice Generated",
            message: "Share this invoice to receive Bitcoin:\n\n\(invoice.paymentRequest)",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Copy", style: .default) { _ in
            UIPasteboard.general.string = invoice.paymentRequest
        })
        
        alert.addAction(UIAlertAction(title: "Share", style: .default) { _ in
            let activityVC = UIActivityViewController(
                activityItems: [invoice.paymentRequest],
                applicationActivities: nil
            )
            
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = viewController.view
                popover.sourceRect = CGRect(
                    x: viewController.view.bounds.midX,
                    y: viewController.view.bounds.midY,
                    width: 0,
                    height: 0
                )
            }
            
            viewController.present(activityVC, animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "Done", style: .cancel))
        
        viewController.present(alert, animated: true)
    }
}

// MARK: - Delegate Protocol

protocol TeamWalletPaymentDelegate: AnyObject {
    func didStartPayment()
    func didCompletePayment(hash: String, amount: Int)
    func didFailPayment(_ error: Error)
    func didGenerateInvoice(_ invoice: LightningInvoice)
}

// MARK: - Payment Error

enum PaymentError: LocalizedError {
    case invalidInvoice
    case insufficientFunds
    case networkError
    case invalidAmount
    case transactionFailed
    case notAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .invalidInvoice:
            return "Invalid Lightning invoice format"
        case .insufficientFunds:
            return "Insufficient funds in team wallet"
        case .networkError:
            return "Network error during payment"
        case .notAuthenticated:
            return "User not authenticated"
        case .invalidAmount:
            return "Please enter a valid amount"
        case .transactionFailed:
            return "Payment failed - please try again"
        }
    }
}