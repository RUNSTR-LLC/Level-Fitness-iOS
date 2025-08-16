import UIKit
import WebKit

class WebViewController: UIViewController {
    
    // MARK: - UI Components
    private let headerView = UIView()
    private let backButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    private let webView = WKWebView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    private let pageTitle: String
    private let url: URL?
    private let htmlContent: String?
    
    // MARK: - Initialization
    
    init(title: String, url: URL) {
        self.pageTitle = title
        self.url = url
        self.htmlContent = nil
        super.init(nibName: nil, bundle: nil)
    }
    
    init(title: String, htmlContent: String) {
        self.pageTitle = title
        self.url = nil
        self.htmlContent = htmlContent
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🌐 WebView: Loading \(pageTitle)")
        
        setupIndustrialBackground()
        setupHeader()
        setupWebView()
        setupConstraints()
        loadContent()
        
        print("🌐 WebView: \(pageTitle) loaded successfully")
    }
    
    // MARK: - Setup Methods
    
    private func setupIndustrialBackground() {
        view.backgroundColor = IndustrialDesign.Colors.background
        
        // Add grid pattern background
        let gridView = GridPatternView()
        gridView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gridView)
        
        NSLayoutConstraint.activate([
            gridView.topAnchor.constraint(equalTo: view.topAnchor),
            gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Back button
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = IndustrialDesign.Colors.primaryText
        backButton.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        backButton.layer.cornerRadius = 20
        backButton.layer.borderWidth = 1
        backButton.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        // Title
        titleLabel.text = pageTitle
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(backButton)
        headerView.addSubview(titleLabel)
        view.addSubview(headerView)
    }
    
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.dataDetectorTypes = [.link, .phoneNumber]
        
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        // Loading indicator
        loadingIndicator.color = IndustrialDesign.Colors.primaryText
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        
        view.addSubview(webView)
        view.addSubview(loadingIndicator)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Header
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            headerView.heightAnchor.constraint(equalToConstant: 44),
            
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            // WebView
            webView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func loadContent() {
        loadingIndicator.startAnimating()
        
        if let url = url {
            let request = URLRequest(url: url)
            webView.load(request)
        } else if let htmlContent = htmlContent {
            let styledHTML = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    body {
                        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                        background-color: #0a0a0a;
                        color: #ffffff;
                        padding: 20px;
                        margin: 0;
                        line-height: 1.6;
                    }
                    h1 { color: #f7931a; font-size: 24px; margin-bottom: 20px; }
                    h2 { color: #ffffff; font-size: 18px; margin-top: 24px; margin-bottom: 12px; }
                    h3 { color: #cccccc; font-size: 16px; margin-top: 20px; margin-bottom: 8px; }
                    p { margin-bottom: 16px; }
                    ul { margin-bottom: 16px; }
                    li { margin-bottom: 8px; }
                    a { color: #f7931a; text-decoration: none; }
                    a:hover { text-decoration: underline; }
                    .section { margin-bottom: 32px; }
                    .highlight { background-color: #1a1a1a; padding: 16px; border-radius: 8px; margin: 16px 0; }
                </style>
            </head>
            <body>
                \(htmlContent)
            </body>
            </html>
            """
            
            webView.loadHTMLString(styledHTML, baseURL: nil)
        }
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        print("🌐 WebView: Back button tapped for \(pageTitle)")
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - WKNavigationDelegate

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingIndicator.stopAnimating()
        print("🌐 WebView: Finished loading \(pageTitle)")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadingIndicator.stopAnimating()
        print("🌐 WebView: Failed to load \(pageTitle) - \(error.localizedDescription)")
        
        let alert = UIAlertController(
            title: "Loading Error",
            message: "Unable to load \(pageTitle). Please check your internet connection and try again.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Handle external links
        if let url = navigationAction.request.url,
           navigationAction.navigationType == .linkActivated,
           url.scheme == "http" || url.scheme == "https" {
            
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
}