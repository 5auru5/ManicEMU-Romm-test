//
//  SkinSettingsView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/3/6.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit
import ManicEmuCore

import RealmSwift
import BetterSegmentedControl
import UniformTypeIdentifiers
import ProHUD

class SkinSettingsView: BaseView {
    /// 充当导航条
    private var navigationBlurView: UIView = {
        let view = UIView()
        view.makeBlur()
        return view
    }()
    
    private var contextMenuButton: ContextMenuButton = {
        let view = ContextMenuButton()
        return view
    }()
    
    private lazy var navigationSymbolTitle: SymbolButton = {
        let defaultTitle = (game?.gameType ?? gameType).localizedShortName
        let view = SymbolButton(image: game == nil ? UIImage(symbol: .chevronUpChevronDown, font: Constants.Font.caption(weight: .bold)) : nil,
                                title: defaultTitle,
                                titleFont: Constants.Font.title(size: .s),
                                edgeInsets: .zero,
                                titlePosition: .left,
                                imageAndTitlePadding: Constants.Size.ContentSpaceUltraTiny)
        view.layerCornerRadius = 0
        view.backgroundColor = .clear
        if isSettingForGame {
            view.enableInteractive = false
        } else {
            view.addTapGesture { [weak self] gesture in
                guard let self = self else { return }
                let allGameTypes = System.allCases.map { $0.gameType }
                let itemTitles = System.allCases.map { $0.gameType.localizedShortName }
                var items: [UIAction] = []
                let currentGameTypeName = self.gameType.localizedShortName
                for (index, title) in itemTitles.enumerated() {
                    items.append(UIAction(title: title,
                                          image: currentGameTypeName == title ? UIImage(symbol: .checkmarkCircleFill) : nil,
                                          handler: { [weak self] _ in
                        guard let self = self else { return }
                        self.gameType = allGameTypes[index]
                        self.navigationSymbolTitle.titleLabel.text = itemTitles[index]
                        self.landscapeInitialSelectedIndex = nil
                        self.portraitInitialSelectedIndex = nil
                        self.updateDatas()
                    }))
                }
                self.contextMenuButton.menu = UIMenu(children: items)
                self.contextMenuButton.triggerTapGesture()
            }
        }
        return view
    }()
    
    private lazy var navigationSubTitle: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .megaphone, font: Constants.Font.caption(), color: Constants.Color.LabelSecondary),
                                title: game == nil ? R.string.localizable.skinNavigationSubTitleCommon() : R.string.localizable.skinNavigationSubTitleSpecifiedGame(game?.aliasName ?? game!.name),
                                titleFont: Constants.Font.caption(),
                                titleColor: Constants.Color.LabelSecondary,
                                titleAlignment: .left,
                                edgeInsets: .zero,
                                titlePosition: .right,
                                imageAndTitlePadding: Constants.Size.ContentSpaceUltraTiny)
        view.layerCornerRadius = 0
        view.backgroundColor = .clear
        view.enableInteractive = false
        view.titleLabel.lineBreakMode = .byTruncatingMiddle
        return view
    }()
    
    private lazy var moreContextMenuButton: ContextMenuButton = {
        var actions: [UIMenuElement] = []
        actions.append((UIAction(title: R.string.localizable.howToFetch()) { _ in
            //how to
            topViewController()?.present(WebViewController(url: Constants.URLs.SkinUsageGuide), animated: true)
        }))
        actions.append((UIAction(title: R.string.localizable.skinResetForAll()) { [weak self] _ in
            guard let self = self else { return }
            //重置所有平台皮肤
            self.resetSkin()
        }))
        actions.append(UIAction(title: R.string.localizable.skinResetForPlatform(self.gameType.localizedShortName)) { [weak self] _ in
            guard let self = self else { return }
            //重置当前平台皮肤
            self.resetSkin(gameType: self.gameType)
        })
        actions.append((UIAction(title: R.string.localizable.skinDebug()) { [weak self] _ in
            guard let self = self else { return }
            UIView.makeToast(message: "Coming Soon...")
        }))
        let view = ContextMenuButton(image: nil, menu: UIMenu(title: R.string.localizable.skinRestDesc(), children: actions))
        return view
    }()
    
    private lazy var moreButton: SymbolButton = {
        let view = SymbolButton(symbol: .ellipsis)
        view.enableRoundCorner = true
        view.addTapGesture { [weak self] gesture in
            self?.moreContextMenuButton.triggerTapGesture()
        }
        return view
    }()
    
    private lazy var closeButton: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .xmark, font: Constants.Font.body(weight: .bold)))
        view.enableRoundCorner = true
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            self.didTapClose?()
        }
        return view
    }()
    
    private lazy var segmentView: BetterSegmentedControl = {
        let titles = [R.string.localizable.skinSegmentPortraitTitle(), R.string.localizable.skinSegmentLandscapeTitle()]
        let segments = LabelSegment.segments(withTitles: titles,
                                             normalFont: Constants.Font.body(),
                                             normalTextColor: Constants.Color.LabelSecondary,
                                            selectedTextColor: Constants.Color.LabelPrimary)
        let options: [BetterSegmentedControl.Option] = [
            .backgroundColor(Constants.Color.BackgroundSecondary),
            .indicatorViewInset(5),
            .indicatorViewBackgroundColor(Constants.Color.BackgroundTertiary),
            .cornerRadius(16)
        ]
        let view = BetterSegmentedControl(frame: .zero,
                                          segments: segments,
                                          options: options)
        
        view.on(.valueChanged) { [weak self] sender, forEvent in
            guard let self = self, let index = (sender as? BetterSegmentedControl)?.index else { return }
            UIDevice.generateHaptic()
            self.isPortraitSkinPage = index == 0
            self.reloadDataAndSelectSkin()
        }
        return view
    }()
    
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.register(cellWithClass: SkinCollectionViewCell.self)
        view.register(cellWithClass: AddSkinCollectionViewCell.self)
        view.showsVerticalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.allowsSelection = true
        view.allowsMultipleSelection = false
        view.contentInset = UIEdgeInsets(top: 150, left: 0, bottom: Constants.Size.ContentInsetBottom, right: 0)
        return view
    }()

    ///游戏
    private var game: Game? = nil
    ///游戏类型
    private var gameType: GameType = .gba
    ///是否是单独为某一个游戏设置
    private var isSettingForGame: Bool { game != nil }
    ///数据库中存储的用户皮肤
    private var allSkins: Results<Skin>
    //cell的数据源
    private var portraitSkins: [ControllerSkin] = []
    private var landscapeSkins: [ControllerSkin] = []
    ///竖屏默认选择序号 用于初始化cell
    private var portraitInitialSelectedIndex: Int?
    ///横屏默认选择序号 用于初始化cell
    private var landscapeInitialSelectedIndex: Int?
    ///是否是竖屏页面
    private var isPortraitSkinPage: Bool = true
    ///默认特性
    private let defaultTraits: ControllerSkin.Traits = ControllerSkin.Traits.defaults(for: UIWindow.applicationWindow ?? UIWindow(frame: .init(origin: .zero, size: Constants.Size.WindowSize)))
    ///竖屏特性
    private lazy var portraitTraits: ControllerSkin.Traits = {
        ControllerSkin.Traits(device: self.defaultTraits.device, displayType: self.defaultTraits.displayType, orientation: .portrait)
    }()
    ///横屏特性
    private lazy var landscapeTraits: ControllerSkin.Traits = {
        ControllerSkin.Traits(device: self.defaultTraits.device, displayType: self.defaultTraits.displayType, orientation: .landscape)
    }()
    ///监听数据库skin的变化
    private var skinsUpdateToken: NotificationToken? = nil
    ///点击关闭按钮回调
    var didTapClose: (()->Void)? = nil
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
    }
    
    /// 初始化控制器 如果game和gameType都不传入 则使用默认规则展示 默认优先展示GBA的skin 两个都传入只读取game
    /// - Parameters:
    ///   - game: 游戏 如果传入一个确定的游戏 则只为这个游戏设置皮肤 不能切换或设置别的平台的skin
    ///   - gameType: 传入游戏类型 则有限展示次类型的skin 可以切换其他平台
    init(game: Game? = nil, gameType: GameType? = nil) {
        //查询数据库
        let realm = Database.realm
        allSkins = realm.objects(Skin.self).where({ !$0.isDeleted })
        super.init(frame: .zero)
        Log.debug("\(String(describing: Self.self)) init")
        //监听数据的变化
        skinsUpdateToken = allSkins.observe { [weak self] changes in
            guard let self = self else { return }
            if case .update(_, let deletions, let insertions, _) = changes {
                Log.debug("皮肤更新")
                //新增数据
                if !insertions.isEmpty || !deletions.isEmpty {
                    self.updateDatas()
                }
            }
        }
        
        if let game = game {
            self.game = game
            self.gameType = game.gameType
        } else if let gameType = gameType {
            self.gameType = gameType
        }
        
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(navigationBlurView)
        navigationBlurView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(130)
        }
        
        navigationBlurView.addSubview(navigationSymbolTitle)
        navigationSymbolTitle.snp.makeConstraints { make in
            make.leading.equalTo(Constants.Size.ContentSpaceMax)
            make.top.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
        }
        
        if !isSettingForGame {
            navigationBlurView.insertSubview(contextMenuButton, belowSubview: navigationSymbolTitle)
            contextMenuButton.snp.makeConstraints { make in
                make.edges.equalTo(navigationSymbolTitle)
            }
        }
        
        navigationBlurView.addSubview(navigationSubTitle)
        navigationSubTitle.imageView.setContentHuggingPriority(.required, for: .horizontal)
        navigationSubTitle.imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        navigationSubTitle.titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        navigationSubTitle.titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        navigationSubTitle.snp.makeConstraints { make in
            make.leading.equalTo(navigationSymbolTitle)
            make.top.equalTo(navigationSymbolTitle.snp.bottom).offset(Constants.Size.ContentSpaceUltraTiny/2)
            make.trailing.equalTo(-Constants.Size.ContentSpaceMax)
        }
        
        navigationBlurView.addSubview(segmentView)
        segmentView.snp.makeConstraints { make in
            make.top.equalTo(navigationSubTitle.snp.bottom).offset(Constants.Size.ContentSpaceMin)
            make.height.equalTo(Constants.Size.ItemHeightMid)
            make.leading.equalTo(Constants.Size.ContentSpaceMid)
            make.trailing.equalTo(-Constants.Size.ContentSpaceMid)
        }
        //如果是横屏状态则切换到横屏皮肤
        if UIDevice.isLandscape {
            segmentView.setIndex(1, animated: false, shouldSendValueChangedEvent: true)
        }
        
        navigationBlurView.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
            make.top.equalToSuperview().offset(10)
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
        
        navigationBlurView.addSubview(moreContextMenuButton)
        moreContextMenuButton.snp.makeConstraints { make in
            make.trailing.equalTo(closeButton.snp.leading).offset(-Constants.Size.ContentSpaceMid)
            make.centerY.equalTo(closeButton)
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
        
        navigationBlurView.addSubview(moreButton)
        moreButton.snp.makeConstraints { make in
            make.edges.equalTo(moreContextMenuButton)
        }
        
        updateDatas()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout  { [weak self] sectionIndex, env in
            guard let self = self else { return nil }

            let column = self.isPortraitSkinPage ? 2.0 : 1.0
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/column), heightDimension: .fractionalHeight(1)))
            
            let screenRation = Constants.Size.WindowSize.maxDimension/Constants.Size.WindowSize.minDimension
            let itemWidth = (env.container.contentSize.width - Constants.Size.ContentSpaceMid*4 - ((column-1)*Constants.Size.ContentSpaceMid))/column
            let itemHeight = self.isPortraitSkinPage ? itemWidth*screenRation : itemWidth/screenRation
            
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(itemHeight)), subitem: item, count: Int(column))
            group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: Constants.Size.ContentSpaceMid, bottom: 0, trailing: Constants.Size.ContentSpaceMid)
            group.interItemSpacing = NSCollectionLayoutSpacing.fixed(Constants.Size.ContentSpaceMid)
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = Constants.Size.ContentSpaceMid

            section.decorationItems = [NSCollectionLayoutDecorationItem.background(elementKind: String(describing: SkinDecorationCollectionReusableView.self))]
            section.contentInsets = NSDirectionalEdgeInsets(top: Constants.Size.ContentSpaceMid, leading: Constants.Size.ContentSpaceMid, bottom: Constants.Size.ContentSpaceMid, trailing: Constants.Size.ContentSpaceMid)
            
            return section
        }
        layout.register(SkinDecorationCollectionReusableView.self, forDecorationViewOfKind: String(describing: SkinDecorationCollectionReusableView.self))
        return layout
    }
    
    class SkinDecorationCollectionReusableView: UICollectionReusableView {
        var backgroundView: UIView = {
            let view = UIView()
            view.layerCornerRadius = Constants.Size.CornerRadiusMax
            view.backgroundColor = Constants.Color.BackgroundSecondary
            return view
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            addSubview(backgroundView)
            backgroundView.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    private func updateDatas() {
        portraitSkins.removeAll()
        landscapeSkins.removeAll()
        //添加皮肤
        let reuseSkinGameType = self.gameType.reuseSkinGameType
        let skins = allSkins.filter({
            if !$0.isFileExtsts {
                return false
            }
            if reuseSkinGameType.contains([$0.gameType]) {
                if $0.gameType != self.gameType && ($0.skinType == .default || $0.skinType == .buildIn) {
                    //皮肤的游戏类型与当前选中的游戏类型不一致 则需要排除掉default和manic的皮肤
                    return false
                } else {
                    return true
                }
            }
            return false
        }).sorted {
            if $0.skinType == .default {
                return true
            } else if $1.skinType == .default {
                return false
            } else if $0.skinType == .buildIn {
                return true
            } else if $1.skinType == .buildIn {
                return false
            }
            return true
        }
        
        for skin in skins {
            if let controllerSkin = ControllerSkin(fileURL: skin.fileURL) {
                if controllerSkin.supports(portraitTraits) {
                    portraitSkins.append(controllerSkin)
                }
                if controllerSkin.supports(landscapeTraits) {
                    landscapeSkins.append(controllerSkin)
                }
            }
        }
        
        //内部函数 寻找skin的index
        func getIndex(for skin: Skin, in controllerSkins: [ControllerSkin]) -> Int? {
            for (index, controllerSkin) in controllerSkins.enumerated() {
                if controllerSkin.fileURL == skin.fileURL {
                    return index
                }
            }
            return nil
        }
        
        //设置默认选中
        if isSettingForGame, let game = game {
            //如果是为游戏设置的皮肤 则判断一下游戏中有没有配置过皮肤
            if let storedSkin = game.portraitSkin {
                portraitInitialSelectedIndex = getIndex(for: storedSkin, in: portraitSkins)
            }
            if let storedSkin = game.landscapeSkin {
                landscapeInitialSelectedIndex = getIndex(for: storedSkin, in: landscapeSkins)
            }
        }
        
        //去总设置中去寻找有没有配置过皮肤 如果都没有配置过皮肤则默认选中自带默认的皮肤
        if portraitInitialSelectedIndex == nil {
            if let storedSkin = SkinConfig.prefferedPortraitSkin(gameType: gameType) {
                portraitInitialSelectedIndex = getIndex(for: storedSkin, in: portraitSkins) ?? 0
            } else {
                portraitInitialSelectedIndex = 0
            }
        }
        
        if landscapeInitialSelectedIndex == nil {
            if let storedSkin = SkinConfig.prefferedLandscapeSkin(gameType: gameType) {
                landscapeInitialSelectedIndex = getIndex(for: storedSkin, in: landscapeSkins) ?? 0
            } else {
                landscapeInitialSelectedIndex = 0
            }
        }
        
        self.reloadDataAndSelectSkin()
    }
    
    private func reloadDataAndSelectSkin() {
        collectionView.reloadData { [weak self] in
            guard let self = self else { return }
            if isPortraitSkinPage, let portraitInitialSelectedIndex = portraitInitialSelectedIndex {
                //默认为竖屏选中已经选中的选项
                self.collectionView.selectItem(at: IndexPath(row: portraitInitialSelectedIndex, section: 0), animated: true, scrollPosition: .top)
            }
            if !isPortraitSkinPage, let landscapeInitialSelectedIndex = landscapeInitialSelectedIndex {
                //默认为横屏选中已经选中的选项
                self.collectionView.selectItem(at: IndexPath(row: landscapeInitialSelectedIndex, section: 0), animated: true, scrollPosition: .top)
            }
        }
    }
}

extension SkinSettingsView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        (isPortraitSkinPage ? portraitSkins.count : landscapeSkins.count) + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let skins = (isPortraitSkinPage ? portraitSkins : landscapeSkins)
        if indexPath.row == skins.count {
            return collectionView.dequeueReusableCell(withClass: AddSkinCollectionViewCell.self, for: indexPath)
        } else {
            let cell = collectionView.dequeueReusableCell(withClass: SkinCollectionViewCell.self, for: indexPath)
            //设置数据
            let skin = skins[indexPath.row]
            let traits = isPortraitSkinPage ? portraitTraits : landscapeTraits
            cell.setData(controllerSkin: skin, traits: traits, subscriptTitle: skin.gameType == gameType ? nil : skin.gameType.localizedShortName)
            cell.previewButton.addTapGesture { gesture in
                topViewController()?.present(SkinPreviewViewController(skin: skin, traits: traits), animated: true)
            }
            return cell
        }
    }
}

extension SkinSettingsView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        if let indexPaths = collectionView.indexPathsForSelectedItems, indexPaths.contains(where: { $0 == indexPath }) {
            //不允许取消选择 只允许更换选择
            return false
        }
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let skins = (isPortraitSkinPage ? portraitSkins : landscapeSkins)
        if indexPath.row == skins.count {
            //新增皮肤cell
            UIView.makeAlert(title: R.string.localizable.skinAddTitle(), detail: R.string.localizable.newSkinDesc(), cancelTitle: R.string.localizable.visitSite("DELTASTYLES"), confirmTitle: R.string.localizable.openFile(), cancelAction: { [weak self] in
                guard let self else { return }
                //打开网页
                if let vc = SkinSettingsView.skinSettingsViewSheet {
                    vc.present(WebViewController(url: Constants.URLs.DeltaStyles(gameType: self.gameType)), animated: true)
                } else {
                    topViewController(appController: true)?.present(WebViewController(url: Constants.URLs.DeltaStyles(gameType: self.gameType)), animated: true)
                }
            }, confirmAction: {
                //打开文件管理器
                FilesImporter.shared.presentImportController(supportedTypes: UTType.skinTypes, appControllerPresent: true)
            })
            return false
        }
        
        //更新选中index
        if isPortraitSkinPage {
            portraitInitialSelectedIndex = indexPath.row
        } else {
            landscapeInitialSelectedIndex = indexPath.row
        }
        
        //如果目前已经选中该cell 则不再进行数据库更新
        if let indexPaths = collectionView.indexPathsForSelectedItems, !indexPaths.contains(where: { $0 == indexPath }) {
            if let skin = allSkins.first(where: { $0.fileURL == skins[indexPath.row].fileURL }) {
                if let game = game {
                    Game.change { realm in
                        if isPortraitSkinPage {
                            game.portraitSkin = skin
                        } else {
                            game.landscapeSkin = skin
                        }
                    }
                } else {
                    SkinConfig.setDefaultSkin(skin, isLandscape: !isPortraitSkinPage)
                }
            }
        }
        
        return true
    }
    
    private func resetSkin(gameType: GameType? = nil) {
        SkinConfig.resetDefaultSkin(gameType: gameType)
        let realm = Database.realm
        let games: Results<Game>
        if let gameType {
            games = realm.objects(Game.self).where({ !$0.isDeleted && ($0.portraitSkin != nil || $0.landscapeSkin != nil) && $0.gameType == gameType })
        } else {
            games = realm.objects(Game.self).where({ !$0.isDeleted && ($0.portraitSkin != nil || $0.landscapeSkin != nil) })
        }
        Game.change { realm in
            games.forEach { game in
                game.landscapeSkin = nil
                game.portraitSkin = nil
            }
        }
        landscapeInitialSelectedIndex = 0
        portraitInitialSelectedIndex = 0
        reloadDataAndSelectSkin()
    }
    
    //长按弹出可交互菜单
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        guard let indexPath = indexPaths.first else { return nil }
        let skins = (isPortraitSkinPage ? portraitSkins : landscapeSkins)
        if indexPath.row == skins.count {
            //新增皮肤cell 不允许弹
            return nil
        }
        
        if indexPath.row == 0 {
            //自带的skin 不允许删除
            UIView.makeToast(message: R.string.localizable.defaultSkinCannotEdit())
            return nil
        }
        
        if let skin = allSkins.first(where: { $0.fileURL == skins[indexPath.row].fileURL }) {
            
            if FileManager.default.fileExists(atPath: Constants.Path.Resource.appendingPathComponent(skin.fileName)) {
                //自带的skin 不允许删除
                UIView.makeToast(message: R.string.localizable.defaultSkinCannotEdit())
                return nil
            }
            
            return UIContextMenuConfiguration(actionProvider:  { [weak self] _ in
                UIMenu(children: [UIAction(title: R.string.localizable.skinDelete(), image: UIImage(systemSymbol: .trash), attributes: .destructive, handler: { _ in
                    UIView.makeAlert(title: R.string.localizable.skinDelete(),
                                     detail: R.string.localizable.deleteSkinAlertDetail(),
                                     confirmTitle: R.string.localizable.confirmDelte(),
                                     confirmAction: { [weak self] in
                        Skin.change { realm in
                            skin.skinData?.deleteAndClean(realm: realm)
                            if Settings.defalut.iCloudSyncEnable {
                                skin.isDeleted = true
                            } else {
                                realm.delete(skin)
                            }
                        }
                        if let self = self {
                            if self.isPortraitSkinPage {
                                self.portraitInitialSelectedIndex = nil
                            } else {
                                self.landscapeInitialSelectedIndex = nil
                            }
                        }
                    })
                })])
            })
        }

        return nil
    }
}

extension SkinSettingsView {
    static var skinSettingsViewSheet: UIViewController? {
        return Sheet.find(identifier: String(describing: SkinSettingsView.self)).first
    }
    
    static var isShow: Bool {
        Sheet.find(identifier: String(describing: SkinSettingsView.self)).count > 0 ? true : false
    }
    
    static func show(game: Game, gameViewRect: CGRect, menuInsets: UIEdgeInsets? = nil, hideCompletion: (()->Void)? = nil, didTapClose: (()->Void)? = nil) {
        Sheet.lazyPush(identifier: String(describing: SkinSettingsView.self)) { sheet in
            sheet.configGamePlayingStyle(gameViewRect: gameViewRect, menuInsets: menuInsets, hideCompletion: hideCompletion)
            
            let view = UIView()
            let containerView = RoundAndBorderView(roundCorner: (UIDevice.isPad || UIDevice.isLandscape || menuInsets != nil) ? .allCorners : [.topLeft, .topRight])
            containerView.backgroundColor = Constants.Color.BackgroundPrimary
            view.addSubview(containerView)
            containerView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                if let maxHeight = sheet.config.cardMaxHeight {
                    make.height.equalTo(maxHeight)
                }
            }
            view.addPanGesture { [weak view, weak sheet] gesture in
                guard let view = view, let sheet = sheet else { return }
                let point = gesture.translation(in: gesture.view)
                view.transform = .init(translationX: 0, y: point.y <= 0 ? 0 : point.y)
                if gesture.state == .recognized {
                    let v = gesture.velocity(in: gesture.view)
                    if (view.y > view.height*2/3 && v.y > 0) || v.y > 1200 {
                        // 达到移除的速度
                        sheet.pop()
                    }
                    UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.5, options: [.allowUserInteraction, .curveEaseOut], animations: {
                        view.transform = .identity
                    })
                }
            }
            
            let listView = SkinSettingsView(game: game)
            listView.didTapClose = { [weak sheet] in
                sheet?.pop()
                didTapClose?()
            }
            containerView.addSubview(listView)
            listView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            sheet.set(customView: view).snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
}
