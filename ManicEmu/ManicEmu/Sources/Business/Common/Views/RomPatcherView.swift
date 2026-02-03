//
//  RomPatcherView.swift
//  ManicEmu
//
//  Created by Daiuno on 2026/1/21.
//  Copyright © 2026 Manic EMU. All rights reserved.
//

import WebKit

class RomPatcherViewController: BaseViewController {
    private lazy var romPatcherView: RomPatcherView = {
        let view = RomPatcherView()
        view.didTapClose = {[weak self] in
            self?.dismiss(animated: true)
        }
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(romPatcherView)
        romPatcherView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
}

class RomPatcherView: BaseView {
    /// 充当导航条
    private var navigationBlurView: NavigationBlurView = {
        let view = NavigationBlurView()
        return view
    }()
    
    private lazy var closeButton: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .xmark, font: Constants.Font.body(weight: .bold)), enableGlass: true)
        view.enableRoundCorner = true
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            self.didTapClose?()
        }
        return view
    }()
    
    private lazy var webView: WKWebView = {
        let view: WKWebView
        let js = """
        // 拦截blob下载并获取文件名
        var originalCreateObjectURL = URL.createObjectURL;
        var romFileName = '';
        var patchFileName = '';
        var originalFileName = '';
        var modifiedFileName = '';
        var patchFileExtension = 'ips';
        var mode = 'patch';
        
        function removeFileRestrictions() {
            // 移除ROM文件上传限制
            var romInput = document.getElementById('rom-patcher-input-file-rom');
            if (romInput) {
                romInput.removeAttribute('accept');
                
                // 监听ROM文件选择，获取文件名
                romInput.addEventListener('change', function(e) {
                    if (e.target.files && e.target.files[0]) {
                        romFileName = e.target.files[0].name;
                    }
                });
            }
            
            // 移除补丁文件上传限制
            var patchInput = document.getElementById('rom-patcher-input-file-patch');
            if (patchInput) {
                patchInput.removeAttribute('accept');
                
                patchInput.addEventListener('change', function(e) {
                    if (e.target.files && e.target.files[0]) {
                        patchFileName = e.target.files[0].name;
                    }
                });
            }
            
            //移除创建补丁Original Rom上传限制
            var originalInput = document.getElementById('patch-builder-input-file-original');
            if (originalInput) {
                originalInput.removeAttribute('accept');
                
                // 监听ROM文件选择，获取文件名
                originalInput.addEventListener('change', function(e) {
                    if (e.target.files && e.target.files[0]) {
                        originalFileName = e.target.files[0].name;
                    }
                });
            }

            //移除创建补丁Modified Rom上传限制
            var modifiedInput = document.getElementById('patch-builder-input-file-modified');
            if (modifiedInput) {
                modifiedInput.removeAttribute('accept');
                
                // 监听ROM文件选择，获取文件名
                modifiedInput.addEventListener('change', function(e) {
                    if (e.target.files && e.target.files[0]) {
                        modifiedFileName = e.target.files[0].name;
                    }
                });
            } 

            //监听Patch后缀
            var patchTypeSelect = document.getElementById('patch-builder-select-patch-type');
            if (patchTypeSelect) {
                patchTypeSelect.addEventListener('change', function (e) {
                    patchFileExtension = e.target.value;
                });
            }
        
            //监听Segment的切换
            var switchContainer = document.getElementById('switch-create-button');
            if (switchContainer) {
                switchContainer.addEventListener('click', function (e) {
                    var btn = e.target.closest('.mode-segment');
                    if (!btn) return;
            
                    // 当前模式
                    mode = btn.dataset.mode; // "patch" / "creator"
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
                    patchFileName: patchFileName,
                    originalFileName: originalFileName,
                    modifiedFileName: modifiedFileName,
                    patchFileExtension: patchFileExtension,
                    mode: mode
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
        
        
        let userContentController = WKUserContentController()
        let proxy = WeakScriptMessageHandler(target: self)
        let script = WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        userContentController.addUserScript(script)
        userContentController.add(proxy, name: "downloadHandler")
        
        let config = WKWebViewConfiguration()
        config.userContentController = userContentController
        
        view = WKWebView(frame: CGRect.zero, configuration: config)
        view.navigationDelegate = self
        view.isOpaque = false
        view.backgroundColor = Constants.Color.Background
        view.scrollView.backgroundColor = Constants.Color.Background
        
        return view
    }()
    
    var didTapClose: (()->Void)? = nil
    
    private lazy var localServer: LocalWebServer = {
        let server = LocalWebServer()
        try? server.start(serverType: .RomPatcher)
        return server
    }()
    
    deinit {
        webView.navigationDelegate = nil
        localServer.stop()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(webView)
        webView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(Constants.Size.ItemHeightMid)
            make.bottom.equalTo(-Constants.Size.ContentInsetBottom)
        }
        if let url = localServer.getURL() {
            webView.load(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData))
        }
        
        addSubview(navigationBlurView)
        navigationBlurView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalTo(self.safeAreaLayoutGuide)
            make.height.equalTo(Constants.Size.ItemHeightMid)
        }
        
        let icon = IconView()
        icon.image = R.image.rompatcher_logo()
        navigationBlurView.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
            make.size.equalTo(Constants.Size.IconSizeMin)
            make.centerY.equalToSuperview()
        }
        
        let titleLabel = UILabel()
        titleLabel.font = Constants.Font.title(size: .s)
        titleLabel.textColor = Constants.Color.LabelPrimary
        titleLabel.text = "RomPatcher"
        navigationBlurView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(Constants.Size.ContentSpaceTiny)
            make.centerY.equalToSuperview()
        }
        
        navigationBlurView.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
            make.centerY.equalToSuperview()
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension RomPatcherView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, let host = url.host, host != "localhost" {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
}

extension RomPatcherView: WKScriptMessageHandler {
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
        
        let mode = messageDict["mode"] as? String ?? "patch"
        if mode == "patch" {
            // 从JS获取生成的文件名
            let romFileName = messageDict["romFileName"] as? String ?? ""
            let patchFileName = messageDict["patchFileName"] as? String ?? ""
            // 保存文件
            saveDownloadedFile(data: data, fileName: romFileName.deletingPathExtension + " (\(patchFileName.deletingPathExtension))." + romFileName.pathExtension, isPatch: false)
        } else {
            // 从JS获取生成的文件名
            let patchFileExtension = messageDict["patchFileExtension"] as? String ?? "ips"
            var patchFileName = messageDict["modifiedFileName"] as? String ?? messageDict["originalFileName"] as? String ?? "\(Date.now.timeIntervalSince1970)"
            patchFileName = patchFileName.deletingPathExtension + ".\(patchFileExtension)"
            // 保存文件
            saveDownloadedFile(data: data, fileName: patchFileName, isPatch: true)
        }
        
        
    }
    
    private func saveDownloadedFile(data: Data, fileName: String, isPatch: Bool) {
        let fileUrl = URL(fileURLWithPath: Constants.Path.Cache.appendingPathComponent(fileName))
        
        
        if FileManager.default.fileExists(atPath: fileUrl.path) {
            try? FileManager.default.removeItem(at: fileUrl)
        }
        
        do {
            try data.writeWithCompletePath(to: fileUrl)
            DispatchQueue.main.async {
                UIView.makeAlert(title: R.string.localizable.downloadCompletion(), detail: fileName, cancelTitle: R.string.localizable.gamesShareRom(), confirmTitle: isPatch ? nil : R.string.localizable.m3uFileImport(), cancelAction: {
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
