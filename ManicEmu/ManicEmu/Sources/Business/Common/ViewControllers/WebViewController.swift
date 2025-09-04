//
//  WebViewController.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/3/9.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import WebKit
import MessageUI

class WebViewController: BaseViewController {
    static var isShow = false
    
    private var navigationBlurView: UIView = {
        let view = UIView()
        view.makeBlur(blurColor: Constants.Color.Background)
        return view
    }()
    
    private let url: URL
    private lazy var webView: WKWebView = {
        let view = WKWebView(frame: CGRect.zero)
        view.navigationDelegate = self
        view.uiDelegate = self
        view.isOpaque = false
        view.backgroundColor = Constants.Color.Background
        view.scrollView.backgroundColor = Constants.Color.Background
        if self.loadUrlWhenInit {
            view.load(URLRequest(url: url))
        }
        var bottomInset = Constants.Size.ContentInsetBottom
        if let prefferdBottomInset = self.bottomInset, bottomInset < prefferdBottomInset {
            bottomInset = prefferdBottomInset
        }
        view.scrollView.contentInset = UIEdgeInsets(top: Constants.Size.ItemHeightMid, left: 0, bottom: bottomInset, right: 0)
        return view
    }()
    
    private lazy var backButton: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .chevronLeft, font: Constants.Font.body(weight: .bold)))
        view.enableRoundCorner = true
        view.backgroundColor = Constants.Color.BackgroundPrimary
        view.addTapGesture { [weak self] gesture in
            guard let self else { return }
            self.webView.goBack()
        }
        return view
    }()
    
    private lazy var refreshButton: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .arrowClockwise, font: Constants.Font.body(weight: .bold)))
        view.enableRoundCorner = true
        view.backgroundColor = Constants.Color.BackgroundPrimary
        view.addTapGesture { [weak self] gesture in
            guard let self else { return }
            self.webView.reload()
        }
        return view
    }()
    
    private lazy var searchButton: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .magnifyingglass, font: Constants.Font.body(weight: .bold)))
        view.enableRoundCorner = true
        view.backgroundColor = Constants.Color.BackgroundPrimary
        view.addTapGesture { [weak self] gesture in
            guard let self else { return }
            LimitedTextInputView.show(title: R.string.localizable.readyEditCoverSearch(), detail: nil, text: nil, limitedType: .normal(textSize: 2083), keyboadType: .URL) { [weak self] result in
                guard let self else { return }
                if let result = result as? String {
                    if self.isValidURL(result) {
                        //是URL则直接访问
                        self.webView.loadURLString(result)
                    } else {
                        //非URL则使用搜索引擎进行搜索
                        var searchUrl = "https://www.google.com/search?q=\(result)"
                        if Locale.prefersCN {
                            searchUrl = "https://www.baidu.com/s?wd=\(result)"
                        }
                        self.webView.loadURLString(searchUrl)
                    }
                }
            }
        }
        return view
    }()
    
    private var downloadManageButton: DownloadButton = {
        let view = DownloadButton()
        view.backgroundColor = Constants.Color.BackgroundPrimary
        view.addTapGesture { gesture in
            topViewController()?.present(DownloadViewController(), animated: true)
        }
        return view
    }()
    
    private let showClose: Bool
    
    var didClose: (()->Void)? = nil
    
    private var downloadingUrls = [String: String]()
    
    private var loadUrlWhenInit: Bool
    
    private var bottomInset: CGFloat? = nil
    
    deinit {
        webView.navigationDelegate = nil
    }

    init(url: URL = URL(string: Constants.URLs.ManicEMU)!, showClose: Bool = true, isShow: Bool? = nil, bottomInset: CGFloat? = nil) {
        self.url = url
        self.showClose = showClose
        self.loadUrlWhenInit = true
        if let isShow = isShow {
            Self.isShow = isShow
        }
        super.init(nibName: nil, bundle: nil)
        self.bottomInset = bottomInset
    }
    
    init(searchGame: Game) {
        self.url = Constants.URLs.MobyGames
        self.showClose = true
        self.loadUrlWhenInit = false
        super.init(nibName: nil, bundle: nil)
        UIView.makeLoading()
        MobyGamesKit.getGameInfoUrl(game: searchGame) { url in
            UIView.hideLoading()
            self.webView.loadURL(url)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Constants.Color.Background
        view.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.leading.bottom.trailing.equalTo(view)
            make.top.equalTo(view).offset(Constants.Size.ContentSpaceMid)
        }
        
        view.addSubview(navigationBlurView)
        navigationBlurView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(Constants.Size.ItemHeightMid)
        }
        
        navigationBlurView.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.leading.equalTo(Constants.Size.ContentSpaceMax)
            make.centerY.equalToSuperview()
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
        
        navigationBlurView.addSubview(refreshButton)
        refreshButton.snp.makeConstraints { make in
            make.leading.equalTo(backButton.snp.trailing).offset(Constants.Size.ContentSpaceMid)
            make.centerY.equalToSuperview()
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
        
        navigationBlurView.addSubview(searchButton)
        searchButton.snp.makeConstraints { make in
            make.leading.equalTo(refreshButton.snp.trailing).offset(Constants.Size.ContentSpaceMid)
            make.centerY.equalToSuperview()
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
        
        navigationBlurView.addSubview(downloadManageButton)
        downloadManageButton.snp.makeConstraints { make in
            make.leading.equalTo(searchButton.snp.trailing).offset(Constants.Size.ContentSpaceMid)
            make.centerY.equalToSuperview()
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
        
        if showClose {
            addCloseButton(makeConstraints:  { make in
                make.size.equalTo(Constants.Size.IconSizeMid)
                make.centerY.equalTo(self.backButton)
                make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax-Constants.Size.ContentSpaceUltraTiny)
            })
            closeButton.backgroundColor = Constants.Color.BackgroundPrimary
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Self.isShow = false
        didClose?()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func isValidURL(_ string: String) -> Bool {
        let types: NSTextCheckingResult.CheckingType = .link
        guard let detector = try? NSDataDetector(types: types.rawValue) else { return false }
        
        let range = NSRange(location: 0, length: string.utf16.count)
        let matches = detector.matches(in: string, options: [], range: range)
        
        // 确保整个字符串是链接而不是只包含链接的一部分
        return matches.contains { $0.range.length == string.utf16.count }
    }
}

extension WebViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, url.string.hasPrefix("mailto:") {
            if MFMailComposeViewController.canSendMail() {
                if url.string.hasSuffix("support@manicemu.site") {
                    //发送给Manic
                    let mailController = MFMailComposeViewController()
                    mailController.setToRecipients([Constants.Strings.SupportEmail])
                    mailController.mailComposeDelegate = self
                    topViewController(appController: true)?.present(mailController, animated: true)
                } else {
                    let mailController = MFMailComposeViewController()
                    mailController.setToRecipients([url.string.replacingOccurrences(of: "mailto:", with: "")])
                    mailController.mailComposeDelegate = self
                    topViewController(appController: true)?.present(mailController, animated: true)
                }
            } else {
                UIView.makeToast(message: R.string.localizable.noEmailSetting())
            }
            decisionHandler(.cancel)
            return
        }
        
        if navigationAction.shouldPerformDownload {
            decisionHandler(.download)
        } else {
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping @MainActor (WKNavigationResponsePolicy) -> Void) {
        if navigationResponse.canShowMIMEType {
            decisionHandler(.allow)
        } else {
            decisionHandler(.download)
        }
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        UIView.makeLoading(timeout: 3)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        UIView.hideLoading()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        Log.debug("WebView错误:\(error)")
        UIView.hideLoading()
//        UIView.makeToast(message: R.string.localizable.lodingFailedTitle())
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
        Log.debug("didFailProvisionalNavigation:\(error)")
        UIView.hideLoading()
    }
    
    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }
    
    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }
}

extension WebViewController: WKDownloadDelegate {
    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping @MainActor @Sendable (URL?) -> Void) {
        if let downloadUrl = download.originalRequest?.url {
            UIView.makeToast(message: R.string.localizable.webViewDownloadBegin())
            DownloadManager.shared.downloads(urls: [downloadUrl], fileNames: [suggestedFilename])
        }
        completionHandler(nil)
    }
}

extension WebViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: (any Error)?) {
        switch result {
        case .sent:
            UIView.makeToast(message: R.string.localizable.sendEmailSuccess())
            controller.dismiss(animated: true)
        case .failed:
            var errorMsg = ""
            if let error = error {
                errorMsg += "\n" + error.localizedDescription
            }
            UIView.makeToast(message: R.string.localizable.sendEmailFailed(errorMsg))
        default:
            controller.dismiss(animated: true)
        }
    
    }
}
