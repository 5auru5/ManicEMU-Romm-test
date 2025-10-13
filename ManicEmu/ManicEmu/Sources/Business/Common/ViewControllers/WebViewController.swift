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
        view.makeBlur()
        return view
    }()
    
    private var isRomPatcher = false
    private let url: URL
    private lazy var webView: WKWebView = {
        let view: WKWebView
        if isRomPatcher {
            let config = WKWebViewConfiguration()
            let userContentController = WKUserContentController()
            let js = """
            // 拦截blob下载并获取文件名
            var originalCreateObjectURL = URL.createObjectURL;
            var romFileName = '';
            var patchFileName = '';
            
            function removeFileRestrictions() {
                // 移除ROM文件上传限制
                var romInput = document.getElementById('rom-patcher-input-file-rom');
                if (romInput) {
                    romInput.removeAttribute('accept');
                    console.log('ROM文件限制已移除');
                    
                    // 监听ROM文件选择，获取文件名
                    romInput.addEventListener('change', function(e) {
                        if (e.target.files && e.target.files[0]) {
                            romFileName = e.target.files[0].name;
                            console.log('ROM文件名:', romFileName);
                        }
                    });
                }
                
                // 移除补丁文件上传限制
                var patchInput = document.getElementById('rom-patcher-input-file-patch');
                if (patchInput) {
                    patchInput.removeAttribute('accept');
                    console.log('补丁文件限制已移除');
                    
                    // 监听补丁文件选择，获取文件名
                    patchInput.addEventListener('change', function(e) {
                        if (e.target.files && e.target.files[0]) {
                            patchFileName = e.target.files[0].name;
                            console.log('补丁文件名:', patchFileName);
                        }
                    });
                }
            }
            
            // 重写URL.createObjectURL来拦截blob下载
            URL.createObjectURL = function(blob) {
                console.log('Blob下载被拦截:', blob);
                
                // 生成下载文件名
                var downloadFileName = generatePatchedFileName(romFileName, patchFileName);
                
                // 读取blob内容
                var reader = new FileReader();
                reader.onload = function(e) {
                    var base64Data = e.target.result;
                    // 发送给iOS
                    window.webkit.messageHandlers.downloadHandler.postMessage({
                        type: 'blob_download',
                        data: base64Data,
                        size: blob.size,
                        mimeType: blob.type,
                        fileName: downloadFileName,
                        romFileName: romFileName,
                        patchFileName: patchFileName
                    });
                };
                reader.readAsDataURL(blob);
                
                // 继续原始下载流程
                return originalCreateObjectURL.call(this, blob);
            };
            
            // 生成补丁后的文件名
            function generatePatchedFileName(romName, patchName) {
                if (!romName) return 'patched_rom.bin';
                
                // 移除扩展名
                var nameWithoutExt = romName.replace(/\\.[^/.]+$/, '');
                var romExt = romName.split('.').pop() || 'bin';
                
                // 如果有补丁文件名，尝试从中提取描述信息
                var patchInfo = '';
                if (patchName) {
                    // 移除补丁文件扩展名
                    var patchWithoutExt = patchName.replace(/\\.[^/.]+$/, '');
                    // 如果补丁名不包含在ROM名中，添加到文件名
                    if (!nameWithoutExt.toLowerCase().includes(patchWithoutExt.toLowerCase())) {
                        patchInfo = '_' + patchWithoutExt;
                    }
                }
                
                return nameWithoutExt + patchInfo + '_patched.' + romExt;
            }
            
            // 立即执行一次
            removeFileRestrictions();
            
            // DOM完全加载后再执行一次
            document.addEventListener('DOMContentLoaded', removeFileRestrictions);
            
            // 使用MutationObserver监听DOM变化
            var observer = new MutationObserver(function(mutations) {
                removeFileRestrictions();
            });
            observer.observe(document.body || document.documentElement, {
                childList: true,
                subtree: true
            });
            
            // 延时执行，确保页面完全加载
            setTimeout(removeFileRestrictions, 1000);
            setTimeout(removeFileRestrictions, 3000);
            """
            let script = WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: true)
            userContentController.addUserScript(script)
            
            // 添加消息处理器来接收JS消息
            userContentController.add(self, name: "downloadHandler")
            
            config.userContentController = userContentController
            view = WKWebView(frame: CGRect.zero, configuration: config)
        } else {
            view = WKWebView(frame: CGRect.zero)
        }
        
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
        let view = SymbolButton(image: UIImage(symbol: .chevronLeft, font: Constants.Font.body(weight: .bold)), enableGlass: true)
        view.enableRoundCorner = true
        view.backgroundColor = Constants.Color.BackgroundPrimary
        view.addTapGesture { [weak self] gesture in
            guard let self else { return }
            self.webView.goBack()
        }
        return view
    }()
    
    private lazy var refreshButton: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .arrowClockwise, font: Constants.Font.body(weight: .bold)), enableGlass: true)
        view.enableRoundCorner = true
        view.backgroundColor = Constants.Color.BackgroundPrimary
        view.addTapGesture { [weak self] gesture in
            guard let self else { return }
            self.webView.reload()
        }
        return view
    }()
    
    private lazy var searchButton: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .magnifyingglass, font: Constants.Font.body(weight: .bold)), enableGlass: true)
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
        if isRomPatcher {
            webView.configuration.userContentController.removeScriptMessageHandler(forName: "downloadHandler")
        }
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
        if url == Constants.URLs.RomPatcher {
            isRomPatcher = true
        }
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
        if let downloadUrl = download.originalRequest?.url, !downloadUrl.string.lowercased().hasPrefix("blob") {
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

extension WebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "downloadHandler" {
            if let messageDict = message.body as? [String: Any] {
                if let type = messageDict["type"] as? String {
                    switch type {
                    case "blob_download":
                        handleBlobDownload(messageDict)
                    default:
                        break
                    }
                }
            }
        }
    }
    
    
    private func handleBlobDownload(_ messageDict: [String: Any]) {
        guard let base64Data = messageDict["data"] as? String,
              let size = messageDict["size"] as? Int else {
            Log.debug("无效的blob下载数据")
            return
        }
        
        Log.debug("接收到blob下载，大小: \(size) bytes")
        
        // 移除data:前缀并解码base64
        guard let commaRange = base64Data.range(of: ","),
              let data = Data(base64Encoded: String(base64Data[commaRange.upperBound...])) else {
            Log.debug("base64数据解码失败")
            return
        }
        
        // 从JS获取生成的文件名
        let romFileName = messageDict["romFileName"] as? String ?? ""
        let patchFileName = messageDict["patchFileName"] as? String ?? ""

        // 保存文件
        saveDownloadedFile(data: data, fileName: romFileName.deletingPathExtension + " (\(patchFileName.deletingPathExtension))." + romFileName.pathExtension)
    }
    
    
    private func saveDownloadedFile(data: Data, fileName: String) {
        let fileUrl = URL(fileURLWithPath: Constants.Path.Cache.appendingPathComponent(fileName))
        
        
        if FileManager.default.fileExists(atPath: fileUrl.path) {
            try? FileManager.default.removeItem(at: fileUrl)
        }
        
        do {
            try data.write(to: fileUrl)
            DispatchQueue.main.async {
                UIView.makeAlert(title: R.string.localizable.downloadCompletion(), detail: fileName, cancelTitle: R.string.localizable.gamesShareRom(), confirmTitle: R.string.localizable.m3uFileImport(), cancelAction: {
                    //分享
                    ShareManager.shareFile(fileUrl: fileUrl)
                }, confirmAction: {
                    //导入
                    FilesImporter.importFiles(urls: [fileUrl])
                })
            }
        } catch {
            DispatchQueue.main.async {
                UIView.makeToast(message: "文件保存失败: \(error.localizedDescription)")
            }
            Log.debug("文件保存失败: \(error)")
        }
    }
}
