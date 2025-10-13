//
//  DownloadButton.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/4/29.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

class DownloadButton: SymbolButton {
    
    private var beginDownloadNotification: Any? = nil
    private var stopDownloadNotification: Any? = nil
    
    deinit {
        if let beginDownloadNotification = beginDownloadNotification {
            NotificationCenter.default.removeObserver(beginDownloadNotification)
        }
        if let stopDownloadNotification = stopDownloadNotification {
            NotificationCenter.default.removeObserver(stopDownloadNotification)
        }
    }
    
    init(enableGlass: Bool = true) {
        super.init(image: UIImage(symbol: .arrowDownToLine, font: Constants.Font.body(weight: .bold)), enableGlass: enableGlass)
        enableRoundCorner = true
        detectDownloadStatus()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func detectDownloadStatus() {
        if DownloadManager.shared.hasDownloadTask {
            self.startSymbolAnimation()
        }
        
        beginDownloadNotification = NotificationCenter.default.addObserver(forName: Constants.NotificationName.BeginDownload, object: nil, queue: .main) { [weak self] notification in
            self?.startSymbolAnimation()
        }
        stopDownloadNotification = NotificationCenter.default.addObserver(forName: Constants.NotificationName.StopDownload, object: nil, queue: .main) { [weak self] notification in
            self?.stopSymbolAnimation()
        }
    }
    
    func startSymbolAnimation() {
        if #available(iOS 18.0, *) {
            imageView.addSymbolEffect(.pulse, options: .repeat(.continuous))
        }
    }
    
    func stopSymbolAnimation() {
        if #available(iOS 18.0, *) {
            imageView.removeSymbolEffect(ofType: .pulse)
        }
    }
}
