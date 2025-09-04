//
//  ControllersSettingView.swift
//  ManicEmu
//
//  Created by Max on 2025/1/24.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit
import ManicEmuCore
import VisualEffectView
import ProHUD

class ControllersSettingView: BaseView {
    private let asSideMenu: Bool
    private let initGameType: GameType
    
    var topBlurView: UIView = {
        let view = UIView()
        if UIDevice.isPad {
            view.backgroundColor = .black
        } else {
            view.makeBlur(blurColor: .black)
        }
        return view
    }()
    
    private var iconImageView: UIImageView = {
        let view = UIImageView()
        view.image = R.image.controller_background()
        return view
    }()
    
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.register(cellWithClass: ControllersCollectionViewCell.self)
        view.register(supplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withClass: BlackHaderReusableView.self)
        view.showsVerticalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.contentInset = UIEdgeInsets(top: asSideMenu ? Constants.Size.ContentInsetTop : 0, left: 0, bottom: Constants.Size.ContentInsetBottom, right: 0)
        return view
    }()
    
    private lazy var controllers: [GameController] = {
        var controllers: [GameController] = []
        //获取已连接的游戏控制器
        for gameController in ExternalGameControllerUtils.shared.linkedControllers {
            controllers.append(gameController)
        }
        //屏幕控制器默认排在第一位
        let touch = TouchController()
        touch.playerIndex = PlayViewController.skinControllerPlayerIndex
        controllers.insert(touch, at: 0)
        return controllers
    }()
    
    private var gameControllerDidConnectNotification: Any? = nil
    private var gameControllerDidDisConnectNotification: Any? = nil
    private var keyboardDidConnectNotification: Any? = nil
    private var keyboardDidDisConnectNotification: Any? = nil
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
        if let gameControllerDidConnectNotification = gameControllerDidConnectNotification {
            NotificationCenter.default.removeObserver(gameControllerDidConnectNotification)
        }
        if let gameControllerDidDisConnectNotification = gameControllerDidDisConnectNotification {
            NotificationCenter.default.removeObserver(gameControllerDidDisConnectNotification)
        }
        if let keyboardDidConnectNotification = keyboardDidConnectNotification {
            NotificationCenter.default.removeObserver(keyboardDidConnectNotification)
        }
        if let keyboardDidDisConnectNotification = keyboardDidDisConnectNotification {
            NotificationCenter.default.removeObserver(keyboardDidDisConnectNotification)
        }
    }
    
    init(asSideMenu: Bool = true, gameType: GameType = ._3ds) {
        self.asSideMenu = asSideMenu
        self.initGameType = gameType
        super.init(frame: .zero)
        Log.debug("\(String(describing: Self.self)) init")
        addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        if asSideMenu {
            addSubview(topBlurView)
            topBlurView.snp.makeConstraints { make in
                make.leading.top.trailing.equalToSuperview()
                make.height.equalTo(Constants.Size.ContentInsetTop)
            }
        }

        gameControllerDidConnectNotification = NotificationCenter.default.addObserver(forName: .externalGameControllerDidConnect, object: nil, queue: .main) { [weak self] notification in
            //手柄连接
            self?.updateExtenalControllers()
        }
        gameControllerDidDisConnectNotification = NotificationCenter.default.addObserver(forName: .externalGameControllerDidDisconnect, object: nil, queue: .main) { [weak self] notification in
            //手柄断开连接
            self?.updateExtenalControllers()
        }
        keyboardDidConnectNotification = NotificationCenter.default.addObserver(forName: .externalKeyboardDidConnect, object: nil, queue: .main) { [weak self] notification in
            //键盘连接
            self?.updateExtenalControllers()
        }
        keyboardDidDisConnectNotification = NotificationCenter.default.addObserver(forName: .externalKeyboardDidDisconnect, object: nil, queue: .main) { [weak self] notification in
            //键盘断开连接
            self?.updateExtenalControllers()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout  { [weak self] sectionIndex, env in
            guard let self = self else { return nil }
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                 heightDimension: .absolute(Constants.Size.ItemHeightMax)))
            //group布局
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                              heightDimension: .absolute(Constants.Size.ItemHeightMax)),
                                                           subitems: [item])
            group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: Constants.Size.ContentSpaceMax, bottom: 0, trailing: Constants.Size.ContentSpaceMax)
            //section布局
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = Constants.Size.ContentSpaceMax
            section.contentInsets = NSDirectionalEdgeInsets(top: Constants.Size.ContentSpaceMin,
                                                            leading: 0,
                                                            bottom: 0,
                                                            trailing: 0)
            if self.asSideMenu {
                //header布局
                let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                                                heightDimension: .estimated(Constants.Size.ItemHeightMid)),
                                                                             elementKind: UICollectionView.elementKindSectionHeader,
                                                                             alignment: .top)
                headerItem.pinToVisibleBounds = true
                section.boundarySupplementaryItems = [headerItem]
            }
            
            return section
            
        }
        return layout
    }
    
    private func updateExtenalControllers() {
        controllers.removeAll { $0.inputType != .controllerSkin }
        controllers.append(contentsOf: ExternalGameControllerUtils.shared.linkedControllers)
        collectionView.reloadData()
    }
    
    private func showPlayerIndexSelection(at view: ContextMenuButton?, controller: GameController) {
        var actions: [UIMenuElement] = []
        for playerIndex in PlayerIndex.playerCases {
            var image: UIImage? = nil
            if let currentPlayerIndex = controller.playerIndex, currentPlayerIndex == playerIndex.rawValue {
                image = .symbolImage(.checkmarkCircleFill)
            }
            let action = UIAction(title: R.string.localizable.controllersPlayerIndex(playerIndex.rawValue+1),
                                  image: image) { [weak self] _ in
                guard let self = self else { return }
                
                if !PurchaseManager.isMember {
                    topViewController()?.present(PurchaseViewController(featuresType: .controler), animated: true)
                    return
                }
                
                if controller.playerIndex != playerIndex.rawValue {
                    if controller.inputType != .controllerSkin {
                        self.controllers.forEach {
                            if $0.playerIndex == playerIndex.rawValue && $0.inputType != .controllerSkin {
                                $0.playerIndex = nil
                            }
                        }
                    }
                    controller.playerIndex = playerIndex.rawValue
                    self.collectionView.reloadData()
                    if controller.inputType == .controllerSkin {
                        PlayViewController.skinControllerPlayerIndex = playerIndex.rawValue
                    }
                }
            }
            actions.append(action)
        }
        view?.menu = UIMenu(children: actions)
        view?.triggerTapGesture()
    }
}

extension ControllersSettingView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        controllers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClass: ControllersCollectionViewCell.self, for: indexPath)
        let controller = controllers[indexPath.row]
        cell.setData(controller: controller)
        cell.selectButton.addTapGesture { [weak self, weak cell] gesture in
            self?.showPlayerIndexSelection(at: cell?.contextMenuButton, controller: controller)
        }
        if !asSideMenu {
            cell.backgroundColor = Constants.Color.BackgroundSecondary
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: BlackHaderReusableView.self, for: indexPath)
        header.titleLabel.text = R.string.localizable.controllersHeaderTitle()
        if !header.subviews.contains(where: { $0 is SymbolButton }) {
            let moreContextMenuButton: ContextMenuButton = {
                var actions: [UIMenuElement] = []
                actions.append((UIAction(title: R.string.localizable.controllersHowToConnect()) { _ in
                    topViewController()?.present(WebViewController(url: Constants.URLs.ControllerUsageGuide), animated: true)
                }))
                actions.append(UIAction(title: R.string.localizable.deadZoneSetting()) { _ in
                    DeadZoneControl.show()
                })
                let view = ContextMenuButton(image: nil, menu: UIMenu(children: actions))
                return view
            }()
            
            let moreButton: SymbolButton = {
                let view = SymbolButton(symbol: .ellipsis)
                view.enableRoundCorner = true
                return view
            }()
            moreButton.addTapGesture { [weak moreContextMenuButton] gesture in
                moreContextMenuButton?.triggerTapGesture()
            }
            header.addSubview(moreContextMenuButton)
            header.addSubview(moreButton)
            moreButton.snp.makeConstraints { make in
                make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
                make.centerY.equalToSuperview()
                make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
            }
            moreContextMenuButton.snp.makeConstraints { make in
                make.edges.equalTo(moreButton)
            }
        }
        if !asSideMenu {
            if let blurView = header.subviews.first(where: { $0 is VisualEffectView }) as? VisualEffectView {
                blurView.colorTint = Constants.Color.BackgroundPrimary
            }
        }
        if UIDevice.isPad {
            header.backgroundColor = .black
        }
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let controller = controllers[indexPath.row]
        guard controller.inputType != .controllerSkin else {
            return
        }
        topViewController()?.present(ControllerMappingViewController(gameType: initGameType, controller: controller), animated: true)
    }
}

extension ControllersSettingView: UICollectionViewDelegate {

}

extension ControllersSettingView {
    static var isShow: Bool {
        Sheet.find(identifier: String(describing: ControllersSettingView.self)).count > 0 ? true : false
    }
    
    static func show(gameType: GameType, gameViewRect: CGRect, menuInsets: UIEdgeInsets? = nil, hideCompletion: (()->Void)? = nil, didTapClose: (()->Void)? = nil) {
        Sheet.lazyPush(identifier: String(describing: ControllersSettingView.self)) { sheet in
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
            
            let topView = UIView()
            containerView.addSubview(topView)
            topView.snp.makeConstraints { make in
                make.leading.top.trailing.equalToSuperview()
                make.height.equalTo(Constants.Size.ItemHeightMid)
            }
            
            let closeButton = SymbolButton(image: UIImage(symbol: .xmark, font: Constants.Font.body(weight: .bold)))
            closeButton.addTapGesture { [weak sheet] gesture in
                sheet?.pop()
                didTapClose?()
            }
            closeButton.enableRoundCorner = true
            topView.addSubview(closeButton)
            closeButton.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.size.equalTo(Constants.Size.IconSizeMid)
                make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
            }
            
            let settingView = ControllersSettingView(asSideMenu: false, gameType: gameType)
            containerView.addSubview(settingView)
            settingView.snp.makeConstraints { make in
                make.leading.bottom.trailing.equalToSuperview()
                make.top.equalTo(topView.snp.bottom)
            }
            
            sheet.set(customView: view).snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
}
