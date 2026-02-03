//
//  GameplayManualsView.swift
//  ManicEmu
//
//  Created by Aoshuang on 2025/10/13.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
import PDFKit
import ProHUD
import UniformTypeIdentifiers

class GameplayManualsView: UIView {
    var didTapClose: (()->Void)? = nil
    private var game: Game
    
    private var navigationBlurView: NavigationBlurView = {
        let view = NavigationBlurView()
        view.makeBlur()
        return view
    }()
    
    private var pdfView: PDFView = {
        let view = PDFView()
        view.backgroundColor = Constants.Color.Background
        view.autoScales = true
        return view
    }()
    
    private lazy var moreContextMenuButton: ContextMenuButton = {
        var actions: [UIMenuElement] = []
        actions.append((UIAction(title: R.string.localizable.removeTitle()) { [weak self] _ in
            guard let self = self else { return }
            //移除
            if let manualsPath = game.manualsPath {
                try? FileManager.safeRemoveItem(at: URL(fileURLWithPath: Constants.Path.GameplayManuals.appendingPathComponent(manualsPath)))
                self.game.updateExtra(key: ExtraKey.manualPage.rawValue, value: nil)
                self.game.updateExtra(key: ExtraKey.manualFileName.rawValue, value: nil)
                self.game.updateExtra(key: ExtraKey.manualScaleFactor.rawValue, value: nil)
                self.pdfView.document = PDFDocument()
            }
        }))
        actions.append(UIAction(title: R.string.localizable.reUpload()) { [weak self] _ in
            guard let self = self else { return }
            //重新上传
            FilesImporter.shared.presentImportController(supportedTypes: [UTType.pdf],
                                                         allowsMultipleSelection: false,
                                                         manualHandle: { [weak self] urls in
                guard let self else { return }
                if let pdfUrl = urls.first {
                    do {
                        let pdfName = pdfUrl.lastPathComponent
                        let manualsPath = URL(fileURLWithPath: Constants.Path.GameplayManuals.appendingPathComponent(pdfName))
                        try FileManager.safeCopyItem(at: pdfUrl, to: manualsPath, shouldReplace: true)
                        self.game.updateExtra(key: ExtraKey.manualPage.rawValue, value: nil)
                        self.game.updateExtra(key: ExtraKey.manualScaleFactor.rawValue, value: nil)
                        self.game.updateExtra(key: ExtraKey.manualFileName.rawValue, value: pdfName)
                        self.pdfView.document = PDFDocument(url: manualsPath)
                        self.pdfView.autoScales = true
                    } catch {}
                }
            })
        })
        let view = ContextMenuButton(image: nil, menu: UIMenu(children: actions))
        return view
    }()
    
    private lazy var moreButton: SymbolButton = {
        let view = SymbolButton(symbol: .ellipsis, enableGlass: true)
        view.enableRoundCorner = true
        view.addTapGesture { [weak self] gesture in
            self?.moreContextMenuButton.triggerTapGesture()
        }
        return view
    }()
    
    private lazy var closeButton: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .xmark, font: Constants.Font.body(weight: .bold)), enableGlass: true)
        view.enableRoundCorner = true
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            self.didTapClose?()
            // 记录当前阅读的页数
            if let currentPage = pdfView.currentPage, let document = pdfView.document {
                let pageIndex = document.index(for: currentPage)
                game.updateExtra(key: ExtraKey.manualPage.rawValue, value: pageIndex)
            }
            // 记录当前的缩放比例
            game.updateExtra(key: ExtraKey.manualScaleFactor.rawValue, value: pdfView.scaleFactor)
        }
        return view
    }()
    
    init(game: Game) {
        self.game = game
        super.init(frame: .zero)
        backgroundColor = Constants.Color.Background
        
        addSubview(navigationBlurView)
        navigationBlurView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalTo(self.safeAreaLayoutGuide)
            make.height.equalTo(Constants.Size.ItemHeightMid)
        }
        
        navigationBlurView.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
            make.centerY.equalToSuperview()
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
        
        navigationBlurView.addSubview(moreContextMenuButton)
        moreContextMenuButton.snp.makeConstraints { make in
            make.trailing.equalTo(closeButton.snp.leading).offset(-Constants.Size.ContentSpaceMid)
            make.centerY.equalToSuperview()
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
        
        navigationBlurView.addSubview(moreButton)
        moreButton.snp.makeConstraints { make in
            make.edges.equalTo(moreContextMenuButton)
        }
        
        let lastScaleFactor = game.getExtraDouble(key: ExtraKey.manualScaleFactor.rawValue)
        
        addSubview(pdfView)
        if lastScaleFactor != nil {
            pdfView.autoScales = false
        }
        pdfView.snp.makeConstraints { make in
            make.top.equalTo(navigationBlurView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-Constants.Size.ContentInsetBottom)
        }
        
        if let manualsPath = game.manualsPath {
            pdfView.document = PDFDocument(url: URL(fileURLWithPath: manualsPath))
        }
        
        // 加载到上一次读取的位置和缩放比例
        if let lastReadPage = game.getExtraInt(key: ExtraKey.manualPage.rawValue),
           let document = pdfView.document,
           lastReadPage < document.pageCount,
           let page = document.page(at: lastReadPage) {
            pdfView.isHidden = true
            DispatchQueue.main.asyncAfter(delay: 0.5, execute: { [weak self] in
                guard let self else { return }
                self.pdfView.isHidden = false
                self.pdfView.go(to: page)
                
                // 恢复上一次的缩放比例
                if let lastScaleFactor {
                    self.pdfView.scaleFactor = CGFloat(lastScaleFactor)
                }
            })
        } else {
            // 如果没有保存的页数，但有保存的缩放比例，也要恢复
            if let lastScaleFactor {
                DispatchQueue.main.asyncAfter(delay: 0.5, execute: { [weak self] in
                    guard let self else { return }
                    self.pdfView.scaleFactor = CGFloat(lastScaleFactor)
                })
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension GameplayManualsView {
    static var isShow: Bool {
        Sheet.find(identifier: String(describing: GameplayManualsView.self)).count > 0 ? true : false
    }
    
    static func show(game: Game, hideCompletion: (()->Void)? = nil) {
        Sheet { sheet in
            sheet.configGamePlayingStyle(hideCompletion: hideCompletion)
            
            let view = UIView()
            let containerView = RoundAndBorderView(roundCorner: (UIDevice.isPad || UIDevice.isLandscape || PlayViewController.menuInsets != nil) ? .allCorners : [.topLeft, .topRight])
            containerView.backgroundColor = Constants.Color.Background
            view.addSubview(containerView)
            containerView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                if let maxHeight = sheet.config.cardMaxHeight {
                    make.height.equalTo(maxHeight)
                }
            }
            
            let manualView = GameplayManualsView(game: game)
            manualView.didTapClose = { [weak sheet] in
                sheet?.pop()
            }
            containerView.addSubview(manualView)
            manualView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            sheet.set(customView: view).snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
}
