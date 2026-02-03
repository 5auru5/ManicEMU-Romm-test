//
//  FlexSkinSettingViewController.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/4/26.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit
import ManicEmuCore
import ZIPFoundation
import RealmSwift
import IceCream
import Haptica

class FlexSkinSettingViewController: BaseViewController {
    static var isShow = false

    private var containerViews: [UIView] = []
    private var initFrames: [CGRect] = []
    private var initScreens: [ControllerSkin.Screen] = []
    private let minDistanceToEdge: CGFloat = 10
    private let minDistanceToCenter: CGFloat = 15
    private let minDistanceToAnotherView: CGFloat = 10
    
    private let skin: Skin
    private let traits: ControllerSkin.Traits
    private let images: [UIImage?]
    private var initBackground: FlexBackground? = nil
    private var background: FlexBackground? = nil {
        didSet {
            if let background, let image = try? UIImage(url: background.imageUrl) {
                backgroundImage = image
            } else {
                backgroundImage = nil
            }
        }
    }
    private let game: Game
    private var backgroundImage: UIImage? = nil {
        didSet {
            backgroundImageView.image = backgroundImage
        }
    }
    private var backgroundType: FlexBackground.BackgroundType? = nil
    
    private lazy var firstTimeGuideView: UIView = {
        let view = UIView()
        view.backgroundColor = .black.withAlphaComponent(0.3)
        let imageView = UIImageView(image: R.image.flex_guide())
        view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        let label = UILabel()
        label.font = Constants.Font.body(size: .l)
        label.textColor = Constants.Color.LabelPrimary
        label.text = R.string.localizable.flexSkinGuideTitle()
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(imageView.snp.bottom).offset(Constants.Size.ContentSpaceMin)
        }
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            self.firstTimeGuideView.isHidden = true
            self.firstTimeGuideView.removeFromSuperview()
            UserDefaults.standard.set(true, forKey: Constants.DefaultKey.FlexSkinFirstTimeGuide)
        }
        view.addPinchGesture { [weak self] gesture in
            guard let self = self else { return }
            self.firstTimeGuideView.isHidden = true
            self.firstTimeGuideView.removeFromSuperview()
            UserDefaults.standard.set(true, forKey: Constants.DefaultKey.FlexSkinFirstTimeGuide)
        }
        return view
    }()
    
    private lazy var resetButton: SymbolButton = {
        let view = SymbolButton(image: nil,
                                title: R.string.localizable.controllerMappingReset(),
                                titleFont: Constants.Font.body(size: .m),
                                edgeInsets: UIEdgeInsets(top: 0, left: Constants.Size.ContentSpaceTiny, bottom: 0, right: Constants.Size.ContentSpaceTiny),
                                titlePosition: .left,
                                enableGlass: true)
        view.titleLabel.textAlignment = .center
        view.enableRoundCorner = true
        view.addTapGesture { [weak self] gesture in
            self?.resetSettings()
        }
        return view
    }()
    
    private lazy var backgroundContextMenuButton: ContextMenuButton = {
        let view = ContextMenuButton(image: nil, menu: nil)
        return view
    }()
    
    private lazy var backgroundImageButton: SymbolButton = {
        let view = SymbolButton(image: nil,
                                title: R.string.localizable.background(),
                                titleFont: Constants.Font.body(size: .m),
                                edgeInsets: UIEdgeInsets(top: 0, left: Constants.Size.ContentSpaceTiny, bottom: 0, right: Constants.Size.ContentSpaceTiny),
                                titlePosition: .left,
                                enableGlass: true)
        view.titleLabel.textAlignment = .center
        view.enableRoundCorner = true
        view.addTapGesture { [weak self] gesture in
            guard let self else { return }
            var actions: [UIMenuElement] = []
            let isLandScape = self.traits.orientation == .landscape

            let fetchImageActions = [
                UIAction(title: R.string.localizable.readyEditCoverTakePhoto(),
                         image: .symbolImage(.camera),
                         state: .off,
                         handler: { [weak self] _ in
                             guard let self else { return }
                             //拍摄
                             ImageFetcher.capture(preferenceSize: nil, isOpenEditor: false, completion: { [weak self] image in
                                 guard let self, let image else { return }
                                 self.addBackground(isLandScape: isLandScape, image: image)
                             })
                         }),
                UIAction(title: R.string.localizable.readyEditCoverAlbum(),
                         image: .symbolImage(.photoOnRectangleAngled),
                         state: .off,
                         handler: { [weak self] _ in
                             guard let self else { return }
                             //相册
                             ImageFetcher.pick(preferenceSize: nil, isOpenEditor: false, completion: { [weak self] image in
                                 guard let self, let image else { return }
                                 self.addBackground(isLandScape: isLandScape, image: image)
                             })
                         }),
                UIAction(title: R.string.localizable.readyEditCoverFile(),
                         image: .symbolImage(.folder),
                         state: .off,
                         handler: { [weak self] _ in
                             guard let self else { return }
                             //文件
                             ImageFetcher.file(preferenceSize: nil, isOpenEditor: false, completion: { [weak self] image in
                                 guard let self, let image else { return }
                                 self.addBackground(isLandScape: isLandScape, image: image)
                             })
                         }),
            ]
            
            if let background = self.background {
                actions.append(UIMenu(title: isLandScape ? R.string.localizable.addBackgroundForLandscape() : R.string.localizable.addBackgroundForPortrait(), options: .singleSelection, children: fetchImageActions))
                
                if let backgroundImage {
                    actions.append(UIAction(title: R.string.localizable.editTitle() + R.string.localizable.background()) { [weak self] _ in
                        guard let self else { return }
                        //编辑背景
                        ImageFetcher.edit(image: backgroundImage, preferenceSize: nil) { [weak self] image in
                            guard let self, let image else { return }
                            self.background?.update(image: image)
                            self.backgroundImage = image
                        }
                    })
                }
                actions.append(UIMenu(title: R.string.localizable.updateBackground(), options: .singleSelection, children: [
                    UIAction(title: R.string.localizable.updateBackgroundForGame(),
                             state: (self.backgroundType ?? .game) == .game ? .on : .off,
                             handler: { [weak self] _ in
                                 guard let self else { return }
                                 //为当前游戏设定
                                 self.background = background.updateForGame(isLandScape: isLandScape, gameID: self.game.id)
                                 self.backgroundType = .game
                                 
                             }),
                    UIAction(title: R.string.localizable.updateBackgroundForConsole(self.game.gameType.localizedShortName),
                             state: (self.backgroundType ?? .game) == .console ? .on : .off,
                             handler: { [weak self] _ in
                                 guard let self else { return }
                                 //为平台设定
                                 self.background = background.updateForConsole(isLandScape: isLandScape, console: self.game.gameType.localizedShortName, gameID: self.game.id)
                                 self.backgroundType = .console
                             }),
                    UIAction(title: R.string.localizable.updateBackgroundForGlobal(),
                             state: (self.backgroundType ?? .game) == .global ? .on : .off,
                             handler: { [weak self] _ in
                                 guard let self else { return }
                                 //为全局设定
                                 self.background = background.updateForGlobal(isLandScape: isLandScape, console: self.game.gameType.localizedShortName, gameID: self.game.id)
                                 self.backgroundType = .global
                             }),
                ]))
                
                var removeActions = [UIMenuElement]()
                if background.games.contains(self.game.id) {
                    removeActions.append(UIAction(title: R.string.localizable.removeBackgroundForGame(),
                                                  state: .off,
                                                  handler: { [weak self] _ in
                        guard let self else { return }
                        //移除当前游戏背景
                        if let newBg = background.removeForGame(gameID: self.game.id) {
                            if newBg.consoles.contains(self.game.gameType.localizedShortName) {
                                self.background = newBg
                                self.backgroundType = .console
                            } else if newBg.global {
                                self.background = newBg
                                self.backgroundType = .global
                            } else {
                                self.background = nil
                                self.backgroundType = nil
                            }
                        } else {
                            self.background = nil
                            self.backgroundType = nil
                        }
                    }))
                }
                if background.consoles.contains(self.game.gameType.localizedShortName) {
                    removeActions.append(UIAction(title: R.string.localizable.removeBackgroundForConsole(self.game.gameType.localizedShortName),
                                                  state: .off,
                                                  handler: { [weak self] _ in
                        guard let self else { return }
                        //移除平台背景
                        if let newBg = background.removeForConsole(console: self.game.gameType.localizedShortName) {
                            if newBg.games.contains(self.game.id) {
                                self.background = newBg
                                self.backgroundType = .game
                            } else if newBg.global {
                                self.background = newBg
                                self.backgroundType = .global
                            } else {
                                self.background = nil
                                self.backgroundType = nil
                            }
                        } else {
                            self.background = nil
                            self.backgroundType = nil
                        }
                        
                    }))
                }
                if background.global {
                    removeActions.append(UIAction(title: R.string.localizable.removeBackgroundForGlobal(),
                                                  state: .off,
                                                  handler: { [weak self] _ in
                        guard let self else { return }
                        //移除全局背景
                        if let newBg = background.removeForGlobal() {
                            if newBg.games.contains(self.game.id) {
                                self.background = newBg
                                self.backgroundType = .game
                            } else if newBg.consoles.contains(self.game.gameType.localizedShortName) {
                                self.background = newBg
                                self.backgroundType = .console
                            } else {
                                self.background = nil
                                self.backgroundType = nil
                            }
                        } else {
                            self.background = nil
                            self.backgroundType = nil
                        }
                    }))
                }
                
                if removeActions.count > 0 {
                    actions.append(UIMenu(title: R.string.localizable.removeTitle() + R.string.localizable.background(), options: .singleSelection, children: removeActions))
                }
                
            } else {
                actions = fetchImageActions
            }
            self.backgroundContextMenuButton.menu = UIMenu(children: actions)
            self.backgroundContextMenuButton.triggerTapGesture()
        }
        return view
    }()
    
    private lazy var controlView: ControllerView = {
        let view = ControllerView()
        view.controllerSkin = ControllerSkin(fileURL: skin.fileURL)
        view.alpha = 0.3
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private let crosshairGuideView: AuxiliaryLineView = {
        let view = AuxiliaryLineView(enableCrosshair: true, enableBorder: false)
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var backgroundImageView: UIImageView = {
        let view = UIImageView(image: backgroundImage)
        view.contentMode = .scaleAspectFill
        return view
    }()

    private var screenBounds: CGRect {
        return containerView.frame
    }
    
    var didCompletion: (()->Void)? = nil

    init(skin: Skin, traits: ControllerSkin.Traits, images: [UIImage?], game: Game, background: FlexBackground? = nil, backgroundImage: UIImage? = nil, backgroundType: FlexBackground.BackgroundType? = nil) {
        self.skin = skin
        self.traits = traits
        self.images = images
        self.game = game
        self.initBackground = background
        self.background = background
        self.backgroundImage = backgroundImage
        self.backgroundType = backgroundType
        super.init(fullScreen: true)
        FlexSkinSettingViewController.isShow = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        FlexBackground.flushBackgrounds()
        
        view.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        if let controllerSkin = controlView.controllerSkin as? ControllerSkin,
            let frames = controllerSkin.getFrames(),
            let screens = controlView.controllerSkin?.screens(for: traits) {
            
            for (index, screen) in screens.enumerated() {
                if let outputFrame = screen.outputFrame {
                    let scaledFrame = outputFrame.applying(.init(scaleX: frames.skinFrame.width, y: frames.skinFrame.height))
                    let view = createInteractiveView(frame: scaledFrame, image: index < images.count ? images[index] : nil)
                    containerViews.append(view)
                    initFrames.append(scaledFrame)
                    initScreens.append(screen)
                }
            }
            
            containerView.frame = frames.skinFrame
            view.addSubview(containerView)
            containerViews.forEach { containerView.addSubview($0) }
            
            view.addSubview(controlView)
            controlView.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.size.equalTo(frames.skinFrame.size)
            }
        }
        
        view.addSubview(crosshairGuideView)
        crosshairGuideView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        view.addSubview(resetButton)
        resetButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
            make.top.equalToSuperview().offset(Constants.Size.SafeAera.top == 0 ? 20 : Constants.Size.SafeAera.top)
            make.height.equalTo(Constants.Size.ItemHeightUltraTiny)
            make.width.greaterThanOrEqualTo(44)
        }
        
        view.addSubview(backgroundContextMenuButton)
        view.addSubview(backgroundImageButton)
        backgroundImageButton.snp.makeConstraints { make in
            make.leading.equalTo(resetButton.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.centerY.equalTo(resetButton)
            make.height.equalTo(resetButton)
            make.width.greaterThanOrEqualTo(44)
        }
        backgroundContextMenuButton.snp.makeConstraints { make in
            make.edges.equalTo(backgroundImageButton)
        }
        
        if !UserDefaults.standard.bool(forKey: Constants.DefaultKey.FlexSkinFirstTimeGuide) {
            view.addSubview(firstTimeGuideView)
            firstTimeGuideView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        
        view.addSubview(closeButton)
        closeButton.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            self.saveSettings {
                DispatchQueue.main.async {
                    self.dismiss(animated: true)
                }
            }
        }
        closeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
            make.centerY.equalTo(resetButton)
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        FlexSkinSettingViewController.isShow = false
        didCompletion?()
    }
    
    // MARK: - 创建可拖动缩放的子视图
    private func createInteractiveView(frame: CGRect, image: UIImage?) -> UIView {
        let container = AuxiliaryLineView(frame: frame, enableCrosshair: false, enableBorder: true)
        container.isUserInteractionEnabled = true

        let imageView = UIImageView(frame: container.bounds)
        imageView.backgroundColor = Constants.Color.BackgroundPrimary
        imageView.contentMode = .scaleAspectFit
        imageView.image = image
        container.insertSubview(imageView, at: 0)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(1)
        }

        // 添加手势
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))

        container.addGestureRecognizer(pan)
        container.addGestureRecognizer(pinch)
        
        // 为边缘手柄添加拖动手势
        setupEdgeHandleGestures(for: container)

        return container
    }
    
    private func addBackground(isLandScape: Bool, image: UIImage) {
        if let bg = FlexBackground.addBackgound(isLandScape: isLandScape, image: image, gameID: game.id) {
            self.background = bg
            self.backgroundType = .game
        }
    }
    
    // MARK: - 设置边缘手柄手势
    private func setupEdgeHandleGestures(for container: AuxiliaryLineView) {
        let topPan = UIPanGestureRecognizer(target: self, action: #selector(handleEdgePan(_:)))
        container.topHandle.addGestureRecognizer(topPan)
        container.topHandle.tag = 1 // top
        
        let bottomPan = UIPanGestureRecognizer(target: self, action: #selector(handleEdgePan(_:)))
        container.bottomHandle.addGestureRecognizer(bottomPan)
        container.bottomHandle.tag = 2 // bottom
        
        let leftPan = UIPanGestureRecognizer(target: self, action: #selector(handleEdgePan(_:)))
        container.leftHandle.addGestureRecognizer(leftPan)
        container.leftHandle.tag = 3 // left
        
        let rightPan = UIPanGestureRecognizer(target: self, action: #selector(handleEdgePan(_:)))
        container.rightHandle.addGestureRecognizer(rightPan)
        container.rightHandle.tag = 4 // right
    }

    private var lastHapticTime: TimeInterval = 0
    private let hapticThrottleInterval: TimeInterval = 0.3
    private func triggerThrottledHaptic(style: HapticFeedbackStyle = .soft) {
        let now = Date().timeIntervalSince1970
        if now - lastHapticTime >= hapticThrottleInterval {
            lastHapticTime = now
            UIDevice.generateHaptic(style: style)
        }
    }
    
    // MARK: - 拖动
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }

        let translation = gesture.translation(in: self.view)
        view.center = CGPoint(x: view.center.x + translation.x, y: view.center.y + translation.y)
        gesture.setTranslation(.zero, in: self.view)
        
        if gesture.state == .changed {
            let center = view.center
            let screenCenter = CGPoint(x: screenBounds.midX, y: screenBounds.midY)
            
            // 屏幕中心震动
            if abs(center.x - screenCenter.x) <= minDistanceToCenter/2 ||
                abs(center.y - screenCenter.y) <= minDistanceToCenter/2 {
                triggerThrottledHaptic(style: .light)
            }
            
            // 边缘移出检测震动（实时）
            let frame = view.frame
            if frame.minX < 0 || frame.maxX > screenBounds.width ||
                frame.minY < 0 || frame.maxY > screenBounds.height {
                triggerThrottledHaptic(style: .medium)
            }
            
            // 视图间边缘碰撞震动（仅当存在两个视图）
            if containerViews.count == 2 {
                let other = containerViews.first { $0 != view }!
                let f1 = frame
                let f2 = other.frame
                
                let horizontalNear = abs(f1.maxX - f2.minX) <= minDistanceToAnotherView ||
                abs(f1.minX - f2.maxX) <= minDistanceToAnotherView
                
                let verticalOverlap = f1.maxY > f2.minY && f1.minY < f2.maxY
                
                let verticalNear = abs(f1.maxY - f2.minY) <= minDistanceToAnotherView ||
                abs(f1.minY - f2.maxY) <= minDistanceToAnotherView
                
                let horizontalOverlap = f1.maxX > f2.minX && f1.minX < f2.maxX
                
                if (horizontalNear && verticalOverlap) || (verticalNear && horizontalOverlap) {
                    triggerThrottledHaptic()
                }
                
                if f2.contains(f1) || f2.intersects(f1) {
                    let cornerPoints: [CGPoint] = [
                        CGPoint(x: f2.minX + f1.width / 2, y: f2.minY + f1.height / 2), // 左上角
                        CGPoint(x: f2.maxX - f1.width / 2, y: f2.minY + f1.height / 2), // 右上角
                        CGPoint(x: f2.minX + f1.width / 2, y: f2.maxY - f1.height / 2), // 左下角
                        CGPoint(x: f2.maxX - f1.width / 2, y: f2.maxY - f1.height / 2)  // 右下角
                    ]
                    
                    for point in cornerPoints {
                        let dx = abs(center.x - point.x)
                        let dy = abs(center.y - point.y)
                        if dx <= minDistanceToAnotherView {
                            //吸附横向
                            triggerThrottledHaptic()
                            
                        } else if dy <= minDistanceToAnotherView {
                            //吸附纵向
                            triggerThrottledHaptic()
                        }
                    }
                }
            }
        }
        
        if gesture.state == .ended {
            optimizePosition(for: view)
        }
    }

    // MARK: - 缩放
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let view = gesture.view else { return }
        view.transform = view.transform.scaledBy(x: gesture.scale, y: gesture.scale)
        gesture.scale = 1
        
        if gesture.state == .changed {
            // 边缘移出检测震动（实时）
            let frame = view.frame
            if frame.minX < 0 || frame.maxX > screenBounds.width ||
                frame.minY < 0 || frame.maxY > screenBounds.height {
                triggerThrottledHaptic(style: .medium)
            }
        }

        if gesture.state == .ended {
            optimizeScale(for: view)
        }
    }
    
    // MARK: - 边缘拖动（非比例缩放）
    private let minEdgeSize: CGFloat = 50 // 最小尺寸限制
    
    @objc private func handleEdgePan(_ gesture: UIPanGestureRecognizer) {
        guard let handle = gesture.view,
              let gameView = handle.superview else { return }
        
        let translation = gesture.translation(in: self.view)
        var newFrame = gameView.frame
        
        // 根据手柄tag确定调整哪个边
        switch handle.tag {
        case 1: // top
            let newHeight = newFrame.height - translation.y
            let newY = newFrame.origin.y + translation.y
            if newHeight >= minEdgeSize {
                newFrame.origin.y = newY
                newFrame.size.height = newHeight
            }
            
        case 2: // bottom
            let newHeight = newFrame.height + translation.y
            if newHeight >= minEdgeSize {
                newFrame.size.height = newHeight
            }
            
        case 3: // left
            let newWidth = newFrame.width - translation.x
            let newX = newFrame.origin.x + translation.x
            if newWidth >= minEdgeSize {
                newFrame.origin.x = newX
                newFrame.size.width = newWidth
            }
            
        case 4: // right
            let newWidth = newFrame.width + translation.x
            if newWidth >= minEdgeSize {
                newFrame.size.width = newWidth
            }
            
        default:
            break
        }
        
        gameView.frame = newFrame
        gesture.setTranslation(.zero, in: self.view)
        
        if gesture.state == .ended {
            // 执行优化
            optimizeScale(for: gameView)
        }
    }

    // MARK: - 优化缩放（限制最大尺寸不超出屏幕）
    private func optimizeScale(for view: UIView) {
        let currentFrame = view.frame
        
        func fixPosition() {
            let maxWidth = screenBounds.width
            let maxHeight = screenBounds.height
            
            let edgeMinX = UIScreen.main.bounds.minX - screenBounds.minX
            let edgeMaxX = UIScreen.main.bounds.width - screenBounds.maxX
            
            let edgeMinY = UIScreen.main.bounds.minY - screenBounds.minY
            let edgeMaxY = UIScreen.main.bounds.height - screenBounds.maxY
            
            // 保证位置在屏幕范围内
            var newFrame = view.frame
            var newOrigin = newFrame.origin

            if newFrame.minX < edgeMinX {
                newOrigin.x = edgeMinX
            } else if newFrame.maxX > maxWidth + edgeMaxX {
                newOrigin.x = maxWidth - newFrame.width + edgeMaxX
            }
            
            if newFrame.minY < edgeMinY {
                newOrigin.y = edgeMinY
            } else if newFrame.maxY > maxHeight + edgeMaxY {
                newOrigin.y = maxHeight - newFrame.height + edgeMaxY
            }
            
            newFrame.origin = newOrigin
            
            UIView.animate(withDuration: 0.25) {
                view.frame = newFrame
            }
        }
        
        let maxWidth = UIScreen.main.bounds.width
        let maxHeight = UIScreen.main.bounds.height
        
        // 如果视图超出屏幕边界，需要缩小
        if currentFrame.width > maxWidth || currentFrame.height > maxHeight {
            // 计算需要缩放到屏幕宽度和高度的比例
            let widthScale = maxWidth / currentFrame.width
            let heightScale = maxHeight / currentFrame.height
            
            // 取较小的比例，确保视图不会超出任何一边
            let scale = min(widthScale, heightScale)
            
            // 计算目标尺寸
            let targetSize = CGSize(
                width: currentFrame.width * scale,
                height: currentFrame.height * scale
            )
            
            // 计算相对于当前frame的缩放比例
            let scaleX = targetSize.width / currentFrame.width
            let scaleY = targetSize.height / currentFrame.height

            UIView.animate(withDuration: 0.25, animations: {
                view.transform = view.transform.scaledBy(x: scaleX, y: scaleY)
            }, completion: { _ in
                fixPosition()
            })
        } else {
            fixPosition()
        }
    }


    // MARK: - 优化位置（边缘吸附、居中吸附、两个View靠近吸附）
    private func optimizePosition(for view: UIView) {
        let frame = view.frame
        var finalCenter = view.center

        var isFixScreenOutside = false
        
        let edgeMinX = UIScreen.main.bounds.minX - screenBounds.minX
        let edgeMaxX = UIScreen.main.bounds.width - screenBounds.maxX
        
        // Step 1: 超出屏幕边缘 - 调整回可见区域（最高优先）
        if frame.minX < edgeMinX {
            finalCenter.x += (-frame.minX + edgeMinX)
            isFixScreenOutside = true
        } else if frame.maxX > screenBounds.width + edgeMaxX {
            finalCenter.x -= (frame.maxX - screenBounds.width - edgeMaxX)
            isFixScreenOutside = true
        }
        
        let edgeMinY = UIScreen.main.bounds.minY - screenBounds.minY
        let edgeMaxY = UIScreen.main.bounds.height - screenBounds.maxY

        if frame.minY < edgeMinY {
            finalCenter.y += (-frame.minY + edgeMinY)
            isFixScreenOutside = true
        } else if frame.maxY > screenBounds.height + edgeMaxY {
            finalCenter.y -= (frame.maxY - screenBounds.height - edgeMaxY)
            isFixScreenOutside = true
        }

        if !isFixScreenOutside {
            // Step 2: 视图与视图边缘吸附（增强版）
            var isFixViewEdge = false
            if containerViews.count == 2 {
                let otherView = containerViews.first { $0 != view }!
                let f1 = view.frame
                let f2 = otherView.frame

                // --- 横向边缘吸附 ---
                let yOverlap = (f1.maxY > f2.minY || abs(f1.maxY - f2.minY) < minDistanceToAnotherView) && (f1.minY < f2.maxY || abs(f1.minY - f2.maxY) < minDistanceToAnotherView)
                if yOverlap {
                    if abs(f1.maxX - f2.minX) <= minDistanceToAnotherView {
                        finalCenter.x = f2.minX - f1.width / 2
                        isFixViewEdge = true
                    } else if abs(f1.minX - f2.maxX) <= minDistanceToAnotherView {
                        finalCenter.x = f2.maxX + f1.width / 2
                        isFixViewEdge = true
                    } else if abs(f1.maxX - f2.maxX) < minDistanceToAnotherView {
                        finalCenter.x = f2.maxX - f1.width / 2
                        isFixViewEdge = true
                    }  else if abs(f1.minX - f2.minX) < minDistanceToAnotherView {
                        finalCenter.x = f2.minX + f1.width / 2
                        isFixViewEdge = true
                    }
                }

                // --- 纵向边缘吸附 ---
                let xOverlap = (f1.maxX > f2.minX || abs(f1.maxX - f2.minX) < minDistanceToAnotherView) && (f1.minX < f2.maxX || abs(f1.minX - f2.maxX) < minDistanceToAnotherView)
                if xOverlap {
                    if abs(f1.maxY - f2.minY) <= minDistanceToAnotherView {
                        finalCenter.y = f2.minY - f1.height / 2
                        isFixViewEdge = true
                    } else if abs(f1.minY - f2.maxY) <= minDistanceToAnotherView {
                        finalCenter.y = f2.maxY + f1.height / 2
                        isFixViewEdge = true
                    } else if abs(f1.maxY - f2.maxY) < minDistanceToAnotherView {
                        finalCenter.y = f2.maxY - f1.height / 2
                        isFixViewEdge = true
                    }  else if abs(f1.minY - f2.minY) < minDistanceToAnotherView {
                        finalCenter.y = f2.minY + f1.height / 2
                        isFixViewEdge = true
                    }
                }

                // --- 覆盖吸附：如果当前视图在另一个视图内部，则吸附其四角 ---
                if f2.contains(f1) || f2.intersects(f1) {
                    let cornerPoints: [CGPoint] = [
                        CGPoint(x: f2.minX + f1.width / 2, y: f2.minY + f1.height / 2), // 左上角
                        CGPoint(x: f2.maxX - f1.width / 2, y: f2.minY + f1.height / 2), // 右上角
                        CGPoint(x: f2.minX + f1.width / 2, y: f2.maxY - f1.height / 2), // 左下角
                        CGPoint(x: f2.maxX - f1.width / 2, y: f2.maxY - f1.height / 2)  // 右下角
                    ]
                    
                    for point in cornerPoints {
                        let dx = abs(finalCenter.x - point.x)
                        let dy = abs(finalCenter.y - point.y)
                        if dx <= minDistanceToAnotherView {
                            //吸附横向
                            var newPoint = finalCenter
                            newPoint.x = point.x
                            finalCenter = newPoint
                            isFixViewEdge = true
                        } else if dy <= minDistanceToAnotherView {
                            //吸附纵向
                            var newPoint = finalCenter
                            newPoint.y = point.y
                            finalCenter = newPoint
                            isFixViewEdge = true
                        }
                    }
                }
            }

            if !isFixViewEdge {
                // Step 3: 屏幕边缘 & 居中吸附
                let adjustedFrame = CGRect(origin: CGPoint(x: finalCenter.x - frame.width / 2,
                                                           y: finalCenter.y - frame.height / 2),
                                           size: frame.size)

                // 屏幕边缘吸附
                if abs(adjustedFrame.minX) <= minDistanceToEdge {
                    finalCenter.x = frame.width / 2
                } else if abs(adjustedFrame.maxX - screenBounds.width) <= minDistanceToEdge {
                    finalCenter.x = screenBounds.width - frame.width / 2
                }

                if abs(adjustedFrame.minY) <= minDistanceToEdge {
                    finalCenter.y = frame.height / 2
                } else if abs(adjustedFrame.maxY - screenBounds.height) <= minDistanceToEdge {
                    finalCenter.y = screenBounds.height - frame.height / 2
                }

                // 居中吸附
                let screenCenter = CGPoint(x: screenBounds.midX, y: screenBounds.midY)
                if abs(finalCenter.x - screenCenter.x) <= minDistanceToCenter {
                    finalCenter.x = screenCenter.x
                }
                if abs(finalCenter.y - screenCenter.y) <= minDistanceToCenter {
                    finalCenter.y = screenCenter.y
                }
            }
        }
        
        // 执行动画
        UIView.springAnimate {
            view.center = finalCenter
        }
    }
    
    private func resetSettings() {
        if let skinPath = skin.skinData?.filePath {
            do {
                guard let traits = controlView.controllerSkinTraits, initFrames.count == containerViews.count else {
                    UIView.makeToast(message: "重置失败，皮肤文件错误!")
                    return
                }
                Log.debug("开始重置皮肤")
                let archive = try Archive(url: skinPath, accessMode: .update)
                
                //获取备份数据
                if let originalInfoEntry = archive["info_flex.json"] {
                    
                    //获取原始info.json
                    var originalInfoData = Data()
                    try _ = archive.extract(originalInfoEntry) { originalInfoData.append($0) }
                    
                    var resetInfoPath = [String]()
                    resetInfoPath.append("representations")
                    resetInfoPath.append(traits.device == .iphone ? "iphone" : "ipad")
                    resetInfoPath.append(traits.displayType == .standard ? "standard" : "edgeToEdge")
                    resetInfoPath.append(traits.orientation == .portrait ? "portrait" : "landscape")
                    Log.debug("重置路径:\(resetInfoPath)")
                    
                    if let originalDataForCurrentTraits = try getValueFromJSON(originalInfoData, keyPath: resetInfoPath), let currentInfoEntry = archive["info.json"] {
                        //获取当前的info.json
                        var currentInfoData = Data()
                        try _ = archive.extract(currentInfoEntry) { currentInfoData.append($0) }
                        
                        //获取需要重置的数据
                        let resetInfoData = try modifyJSONData(currentInfoData, keyPath: resetInfoPath, newValue: originalDataForCurrentTraits)

                        try archive.remove(currentInfoEntry)
                        try archive.addEntry(with: "info.json", type: .file, uncompressedSize: Int64(resetInfoData.count)) { position, size in
                            return resetInfoData.subdata(in: Data.Index(position)..<Int(position)+size)
                        }
                        
                        let tempUrl = URL(fileURLWithPath: Constants.Path.Temp.appendingPathComponent(skinPath.lastPathComponent))
                        try FileManager.safeCopyItem(at: skinPath, to: tempUrl)
                        
                        Skin.change { realm in
                            skin.skinData?.deleteAndClean(realm: realm)
                            skin.skinData = CreamAsset.create(objectID: skin.id, propName: "skinData", url: tempUrl)
                        }
                        
                        try FileManager.safeRemoveItem(at: tempUrl)
                        
                        if let newSkinPath = skin.skinData?.filePath {
                            controlView.controllerSkin = ControllerSkin(fileURL: newSkinPath)
                            if let screens = controlView.controllerSkin?.screens(for: traits) {
                                initFrames.removeAll()
                                initScreens.removeAll()
                                for (index, screen) in screens.enumerated() {
                                    if let outputFrame = screen.outputFrame,
                                        let controllerSkin = controlView.controllerSkin as? ControllerSkin,
                                       let frames = controllerSkin.getFrames()  {
                                        let scaledFrame = outputFrame.applying(.init(scaleX: frames.skinFrame.width, y: frames.skinFrame.height))
                                        containerViews[index].frame = scaledFrame
                                        initFrames.append(scaledFrame)
                                        initScreens.append(screen)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    Log.debug("还没有修改过，直接恢复视图的frame即可")
                    for (index, view) in containerViews.enumerated() {
                        view.frame = initFrames[index]
                    }
                }
            } catch {
                Log.debug("重置出错了 error:\(error)")
                UIView.makeToast(message: "重置失败，皮肤文件错误!")
                return
            }
        } else {
            UIView.makeToast(message: "重置失败，皮肤文件已被删除!")
            return
        }
    }
    
    private func saveSettings(completion: (()->Void)? = nil) {
        
        //先判断一下有没有修改
        if let skinPath = skin.skinData?.filePath {
            do {
                
                guard let traits = controlView.controllerSkinTraits, initFrames.count == containerViews.count else {
                    UIView.makeToast(message: "修改失败，皮肤文件错误!")
                    completion?()
                    return
                }
                
                //判断一下是否进行了修改
                var isModified = false
                for (index, view) in containerViews.enumerated() {
                    if initFrames[index].rounded() != view.frame.rounded() {
                        Log.debug("初始frame:\(initFrames[index]) view的frame:\(view.frame) 有变更，进行皮肤更新")
                        isModified = true
                    }
                }
                
                guard isModified else {
                    Log.debug("没有有变更，不进行皮肤更新")
                    completion?()
                    return
                }
                
                //开始修改皮肤
                let archive = try Archive(url: skinPath, accessMode: .update)
                
                guard let infoEntry = archive["info.json"] else {
                    UIView.makeToast(message: "修改失败，皮肤文件错误!")
                    completion?()
                    return
                }
                
                //解压info.json
                var infoData = Data()
                try _ = archive.extract(infoEntry) { infoData.append($0) }
                
                if let _ = archive["info_flex.json"] {} else {
                    //备份不存在 先创建一个备份
                    Log.debug("备份info.json为info_flex.json")
                    try archive.addEntry(with: "info_flex.json", type: .file, uncompressedSize: Int64(infoData.count)) { position, size in
                        return infoData.subdata(in: Data.Index(position)..<Int(position)+size)
                    }
                }
                
                var infoPath = [String]()
                infoPath.append("representations")
                infoPath.append(traits.device == .iphone ? "iphone" : "ipad")
                infoPath.append(traits.displayType == .standard ? "standard" : "edgeToEdge")
                infoPath.append(traits.orientation == .portrait ? "portrait" : "landscape")
                Log.debug("生成info.json的访问路径:\(infoPath)")
                
                //需要修改screens和item里面的touchScreen
                var newScreens = [[String: Any]]()
                var touchScreenFrame: CGRect? = nil
                for (index, screen) in initScreens.enumerated() {
                    
                    var inputFrameDict = [String: CGFloat]()
                    var outputFrameDict = [String: CGFloat]()
                    if let inputFrame = screen.inputFrame?.rounded() {
                        inputFrameDict["x"] = inputFrame.origin.x
                        inputFrameDict["y"] = inputFrame.origin.y
                        inputFrameDict["width"] = inputFrame.width
                        inputFrameDict["height"] = inputFrame.height
                    }
                    
                    let modifierView = containerViews[index]
                    
                    if let skinMappingSize = controlView.controllerSkin?.aspectRatio(for: traits) {
                        let outputFrame = modifierView.frame.applying(.init(scaleX: skinMappingSize.width/containerView.width, y: skinMappingSize.height/containerView.height)).rounded()
                        outputFrameDict["x"] = outputFrame.origin.x
                        outputFrameDict["y"] = outputFrame.origin.y
                        outputFrameDict["width"] = outputFrame.width
                        outputFrameDict["height"] = outputFrame.height
                        
                        if screen.isTouchScreen {
                            touchScreenFrame = outputFrame
                        }
                    }
                    if inputFrameDict.count == 0 {
                        newScreens.append(["outputFrame": outputFrameDict])
                    } else {
                        newScreens.append(["inputFrame": inputFrameDict, "outputFrame": outputFrameDict])
                    }
                    
                }
                
                Log.debug("生成screens信息:\(newScreens)")
                
                //修改screen信息
                Log.debug("修改screens的路径是:\(infoPath + ["screens"])")
                var newInfoData = try modifyJSONData(infoData, keyPath: infoPath + ["screens"], newValue: newScreens)
                
                //修改touchScreen信息
                if let touchScreenFrame, var items = try getValueFromJSON(newInfoData, keyPath: infoPath + ["items"]) as? [[String: Any]] {
                    Log.debug("修改触屏信息")
                    for (index , item) in items.enumerated() {
                        if let inputs = item["inputs"] as? [String: String], let x = inputs["x"], x == "touchScreenX", let y = inputs["y"], y == "touchScreenY" {
                            items.remove(at: index)
                            Log.debug("移除旧的触屏信息:\(item)")
                            break
                        }
                    }
                    var frameDict = [String: CGFloat]()
                    frameDict["x"] = touchScreenFrame.origin.x
                    frameDict["y"] = touchScreenFrame.origin.y
                    frameDict["width"] = touchScreenFrame.width
                    frameDict["height"] = touchScreenFrame.height
                    
                    var inputs = [String: String]()
                    inputs["x"] = "touchScreenX"
                    inputs["y"] = "touchScreenY"
                    
                    let newItem = ["frame": frameDict, "inputs": inputs] as [String : Any]
                    items.append(newItem)
                    Log.debug("创建新的触屏信息:\(newItem)")
                    
                    newInfoData = try modifyJSONData(newInfoData, keyPath: infoPath + ["items"], newValue: items)
                    Log.debug("写入触屏信息路径:\(infoPath + ["items"])")
                }
                
                try archive.remove(infoEntry)
                
                try archive.addEntry(with: "info.json", type: .file, uncompressedSize: Int64(newInfoData.count)) { position, size in
                    return newInfoData.subdata(in: Data.Index(position)..<Int(position)+size)
                }
                
                let tempUrl = URL(fileURLWithPath: Constants.Path.Temp.appendingPathComponent(skinPath.lastPathComponent))
                try FileManager.safeCopyItem(at: skinPath, to: tempUrl)
                
                Skin.change { realm in
                    skin.skinData?.deleteAndClean(realm: realm)
                    skin.skinData = CreamAsset.create(objectID: skin.id, propName: "skinData", url: tempUrl)
                }
                
                try FileManager.safeRemoveItem(at: tempUrl)
                
                completion?()
            } catch {
                UIView.makeToast(message: "修改失败，皮肤不可操作!")
            }
            
        } else {
            UIView.makeToast(message: "修改失败，该皮肤不可修改!")
        }
    }
    
    private func modifyJSONData(_ jsonData: Data, keyPath: [String], newValue: Any) throws -> Data {
        // 1. 解析成 Dictionary
        guard var jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw NSError(domain: "Invalid JSON", code: -1)
        }
        
        // 2. 递归修改
        func modify(object: inout [String: Any], keys: ArraySlice<String>, newValue: Any) {
            guard let key = keys.first else { return }
            if keys.count == 1 {
                object[key] = newValue
            } else if var nested = object[key] as? [String: Any] {
                modify(object: &nested, keys: keys.dropFirst(), newValue: newValue)
                object[key] = nested
            }
        }
        
        modify(object: &jsonObject, keys: keyPath[...], newValue: newValue)

        // 3. 转回Data
        let updatedData = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
        return updatedData
    }
    
    private func getValueFromJSON(_ jsonData: Data, keyPath: [String]) throws -> Any? {
        // 1. 解析 JSON 为 Dictionary
        guard let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw NSError(domain: "Invalid JSON", code: -1)
        }

        // 2. 遍历 keyPath
        var current: Any = jsonObject
        for key in keyPath {
            if let dict = current as? [String: Any], let next = dict[key] {
                current = next
            } else {
                return nil
            }
        }

        return current
    }


}
