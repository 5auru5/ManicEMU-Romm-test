//
//  TriggerProPreviewController.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/10/21.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import UIKit
import ManicEmuCore
import AVFoundation
import RealmSwift
import IQKeyboardManagerSwift

class TriggerProPreviewController: BaseViewController {
    
    private var skin: ControllerSkin {
        didSet {
            controlView.controllerSkin = skin
        }
    }
    private let defaultSkin: ControllerSkin
    private let traits: ControllerSkin.Traits
    private let trigger: Trigger ///不是真正的数据库对象
    private let isNewTrigger: Bool
    
    private lazy var supportSkins: [ControllerSkin] = {
        let realm = Database.realm
        let skins = realm.objects(Skin.self).where({ $0.gameType == self.skin.gameType })
        let controllerSkins = skins.compactMap({
            if let cs = ControllerSkin(fileURL: $0.fileURL), cs.supports(self.traits) {
                return cs
            }
            return nil
        })
        return Array(controllerSkins)
    }()
    
    private lazy var controlView: ControllerView = {
        let view = ControllerView()
        view.customControllerSkinTraits = traits
        view.controllerSkin = skin
        view.alpha = hideControls ? 0 : 1
        return view
    }()
    
    private var gameViewBackgroundView: UIImageView = {
        let view = UIImageView(image: R.image.triggerPro_bg())
        view.contentMode = .scaleAspectFill
        view.masksToBounds = true
        return view
    }()
    
    private var switchPreviewSkinMenuButton: ContextMenuButton = {
        let view = ContextMenuButton()
        return view
    }()
    
    private lazy var switchPreviewSkinButton: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .chevronUpChevronDown, font: Constants.Font.caption(weight: .bold)),
                                title: R.string.localizable.switchPreviewSkin(),
                                titleFont: Constants.Font.title(size: .s),
                                titleColor: Constants.Color.LabelPrimary.forceStyle(.dark),
                                edgeInsets: .zero,
                                titlePosition: .left,
                                imageAndTitlePadding: Constants.Size.ContentSpaceUltraTiny)
        view.layerCornerRadius = 0
        view.backgroundColor = .clear
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            let itemTitles = self.supportSkins.map { $0.name }
            var items: [UIAction] = []
            let currentSkinName = self.skin.name
            for (index, title) in itemTitles.enumerated() {
                items.append(UIAction(title: title,
                                      image: currentSkinName == title && !self.hideControls ? UIImage(symbol: .checkmarkCircleFill) : nil,
                                      handler: { [weak self] _ in
                    guard let self = self else { return }
                    self.skin = self.supportSkins[index]
                    self.hideControls = false
                }))
            }
            self.switchPreviewSkinMenuButton.menu = UIMenu(children: [
                UIMenu(options: .displayInline,
                       children: items),
                UIMenu(options: .displayInline,
                       children: [UIAction(title: R.string.localizable.hideControlsTitle(),
                                           image: self.hideControls ? UIImage(symbol: .checkmarkCircleFill) : nil,
                                           handler: { [weak self] _ in
                                               guard let self = self else { return }
                                               self.hideControls = true
                                           })])
            ])
            self.switchPreviewSkinMenuButton.triggerTapGesture()
        }
        return view
    }()
    
    private lazy var addButton: UIView = {
        let view = UIView()
        view.enableInteractive = true
        let iconContainerView = RoundAndBorderView(roundCorner: .allCorners, radius: Constants.Size.CornerRadiusMid)
        iconContainerView.backgroundColor = Constants.Color.Background
        view.addSubview(iconContainerView)
        iconContainerView.snp.makeConstraints { make in
            make.size.equalTo(64)
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        
        let iconView = UIImageView(image: UIImage(symbol: .plusCircleFill, font: Constants.Font.body(weight: .bold), colors: [Constants.Color.Background, Constants.Color.LabelPrimary]))
        iconContainerView.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(35)
        }
        
        let label = UILabel()
        label.font = Constants.Font.body(size: .l, weight: .semibold)
        label.textColor = Constants.Color.LabelPrimary.forceStyle(.dark)
        label.text = R.string.localizable.addButton()
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalTo(iconContainerView.snp.bottom).offset(Constants.Size.ContentSpaceMin)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        view.addTapGesture { [weak self] gesture in
            guard let self else { return }
            let item = TriggerItem()
            self.trigger.items.append(item)
            let vc = AddTriggerButtonController(triggerItem: item, gameType: self.trigger.gameType, inputs: self.getInputs())
            vc.didPageClose = { [weak self] in
                guard let self else { return }
                self.triggerProView.reloadButtons()
            }
            topViewController()?.present(vc, animated: true)
            self.triggerProView.reloadButtons()
        }
        
        return view
    }()
    
    private lazy var titleTextField: UITextField = {
        let view = UITextField()
        view.textColor = Constants.Color.LabelPrimary
        view.font = Constants.Font.body(size: .l)
        view.clearButtonMode = .always
        view.text = trigger.name ?? ""
        view.onReturnKeyPress { [weak self] in
            guard let self = self else { return }
            self.trigger.name = self.titleTextField.text
        }
        view.attributedPlaceholder = NSAttributedString(string: trigger.defaultName, attributes: [.font: Constants.Font.body(size: .l), .foregroundColor: Constants.Color.LabelTertiary])
        view .returnKeyType = .done
        return view
    }()
    
    private lazy var triggerProView: TriggerProView = {
        let view = TriggerProView(trigger: trigger, isEditMode: true)
        view.didTapButton = { [weak self] item in
            guard let self else { return }
            UIView.makeAlert(title: R.string.localizable.buttonInfo(),
                             detail: item.desc,
                             detailAlignment: .left,
                             cancelTitle: R.string.localizable.editTitle(),
                             confirmTitle: R.string.localizable.removeTitle(),
                             cancelAction: { [weak self] in
                guard let self else { return }
                //编辑
                let vc = AddTriggerButtonController(triggerItem: item, gameType: self.trigger.gameType, inputs: self.getInputs())
                vc.didPageClose = { [weak self] in
                    guard let self else { return }
                    self.triggerProView.reloadButtons()
                }
                DispatchQueue.main.asyncAfter(delay: 0.15, execute: {
                    topViewController()?.present(vc, animated: true)
                })
            }, confirmAction: { [weak self] in
                guard let self else { return }
                if let index = self.trigger.items.firstIndex(of: item) {
                    self.trigger.items.remove(at: index)
                    self.triggerProView.reloadButtons()
                }
            })
        }
        return view
    }()
    
    deinit {
        Task { @MainActor in
            IQKeyboardManager.shared.isEnabled = false
        }
    }

    private var hideControls: Bool {
        didSet {
            controlView.alpha = hideControls ? 0 : 1
        }
    }
    
    init(gameType: GameType, trigger: Trigger? = nil, preferredSkinID: String? = nil, hideControls: Bool = false) {
        let realm = Database.realm
        self.defaultSkin = ControllerSkin.standardControllerSkin(for: gameType)!
        if let preferredSkinID,
            let preferredSkin = realm.objects(Skin.self).where({ $0.id == preferredSkinID}).first,
            let preferredControllerSkin = ControllerSkin(fileURL: preferredSkin.fileURL) {
            self.skin = preferredControllerSkin
        } else {
            self.skin = self.defaultSkin
        }
        self.traits = ControllerSkin.Traits.defaults(for: UIWindow.applicationWindow ?? UIWindow(frame: .init(origin: .zero, size: Constants.Size.WindowSize)))
        if let trigger {
            //将数据库实例转换为临时实例 为了更方便的修改 保存的时候统一修改数据库
            self.trigger = trigger.copyTrigger()
            self.isNewTrigger = false
        } else {
            self.trigger = Trigger()
            self.trigger.gameType = gameType
            self.isNewTrigger = true
        }
        self.hideControls = hideControls
        super.init(fullScreen: true)
        
        view.addSubview(controlView)
        
        var needToRotate = false
        if traits.orientation == .portrait && (UIDevice.currentOrientation == .landscapeLeft || UIDevice.currentOrientation == .landscapeRight) {
            needToRotate = true
        } else if traits.orientation == .landscape && (UIDevice.currentOrientation == .portrait || UIDevice.currentOrientation == .portraitUpsideDown) {
            needToRotate = true
        }
        
        if needToRotate {
            controlView.snp.makeConstraints { make in
                make.center.equalToSuperview()
                if let aspectRatio = skin.aspectRatio(for: traits) {
                    let frame = AVMakeRect(aspectRatio: aspectRatio, insideRect: CGRect(origin: .zero, size: CGSize(width: Constants.Size.WindowHeight, height: Constants.Size.WindowWidth)))
                    make.size.equalTo(frame.size)
                }
            }
            controlView.transform = .init(rotationAngle: .pi/2)
        } else {
            controlView.snp.makeConstraints { make in
                make.center.equalToSuperview()
                if let aspectRatio = skin.aspectRatio(for: traits) {
                    let frame = AVMakeRect(aspectRatio: aspectRatio, insideRect: CGRect(origin: .zero, size: Constants.Size.WindowSize))
                    make.size.equalTo(frame.size)
                }
            }
        }
        
        view.addSubview(closeButton)
        closeButton.addTapGesture { [weak self] gesture in
            self?.dismiss(animated: true)
            self?.storeTrigger()
        }
        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Constants.Size.SafeAera.top == 0 ? 20 : Constants.Size.SafeAera.top)
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
        
        view.addSubview(switchPreviewSkinButton)
        switchPreviewSkinButton.snp.makeConstraints { make in
            make.leading.equalTo(Constants.Size.ContentSpaceMax)
            make.centerY.equalTo(closeButton)
        }
        
        view.insertSubview(switchPreviewSkinMenuButton, belowSubview: switchPreviewSkinButton)
        switchPreviewSkinMenuButton.snp.makeConstraints { make in
            make.edges.equalTo(switchPreviewSkinButton)
        }
        
        if let skinFrames = skin.getFrames() {
            controlView.addSubview(gameViewBackgroundView)
            gameViewBackgroundView.snp.makeConstraints { make in
                make.leading.equalTo(skinFrames.mainGameViewFrame.minX)
                make.top.equalTo(skinFrames.mainGameViewFrame.minY)
                make.size.equalTo(skinFrames.mainGameViewFrame.size)
            }
            
            view.addSubview(addButton)
            addButton.snp.makeConstraints { make in
                make.center.equalTo(gameViewBackgroundView)
            }
            
            let titleEditTextContainerView = UIView()
            titleEditTextContainerView.layerCornerRadius = Constants.Size.CornerRadiusMid
            titleEditTextContainerView.backgroundColor = Constants.Color.Background
            view.addSubview(titleEditTextContainerView)
            titleEditTextContainerView.snp.makeConstraints { make in
                make.top.equalTo(addButton.snp.bottom).offset(40)
                if UIDevice.isPhone {
                    make.leading.trailing.equalTo(gameViewBackgroundView).inset(Constants.Size.ContentSpaceMid)
                } else {
                    make.width.equalTo(380)
                    make.centerX.equalTo(addButton)
                }
            }
            
            let titleEditLabel = UILabel()
            titleEditLabel.text = R.string.localizable.triggerProName()
            titleEditLabel.font = Constants.Font.body(size: .l, weight: .semibold)
            titleEditLabel.textColor = Constants.Color.LabelPrimary
            titleEditTextContainerView.addSubview(titleEditLabel)
            titleEditLabel.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMax)
                make.top.equalToSuperview().inset(Constants.Size.ContentSpaceMin)
            }
            
            let textFieldContainer = RoundAndBorderView(roundCorner: .allCorners, radius: Constants.Size.CornerRadiusMid)
            textFieldContainer.backgroundColor = Constants.Color.InputBackground
            titleEditTextContainerView.addSubview(textFieldContainer)
            textFieldContainer.snp.makeConstraints { make in
                make.top.equalTo(titleEditLabel.snp.bottom).offset(Constants.Size.ContentSpaceTiny)
                make.leading.bottom.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMin)
                make.height.equalTo(Constants.Size.ItemHeightTiny)
            }
            
            textFieldContainer.addSubview(titleTextField)
            titleTextField.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            }
        }
        
        view.addSubview(triggerProView)
        triggerProView.snp.makeConstraints { make in
            make.edges.equalTo(controlView)
        }
        
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardManager.shared.keyboardDistance = Constants.Size.ContentSpaceHuge
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        switch UIDevice.currentOrientation {
        case .portrait:
            AppDelegate.orientation = .portrait
        case .portraitUpsideDown:
            AppDelegate.orientation = .portraitUpsideDown
        case .landscapeLeft:
            AppDelegate.orientation = .landscapeLeft
        case .landscapeRight:
            AppDelegate.orientation = .landscapeRight
        default: break
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AppDelegate.orientation = Constants.Config.DefaultOrientation
    }
    
    private func getInputs() -> [String] {
        if let items = defaultSkin.items(for: traits) {
            var result: [String] = []
            for item in items {
                switch item.kind {
                case .button:
                    //不支持组合键
                    if let input = item.inputs.allInputs.first {
                        result.append(input.stringValue)
                    }
                case .dPad, .thumbstick:
                    if case .directional(let up, let down, let left, let right) = item.inputs {
                        result.append(contentsOf: [up.stringValue, down.stringValue, left.stringValue, right.stringValue])
                    }
                default: break
                }
            }
            return result
        }
        return []
    }
    
    private func storeTrigger() {
        if isNewTrigger {
            //新增Trigger
            if trigger.items.count > 0 {
                Trigger.change { realm in
                    realm.add(trigger)
                }
            }
        } else {
            //更新已有Trigger
            let realm = Database.realm
            if let originTrigger = realm.objects(Trigger.self).where({ $0.id == trigger.id }).first {
                if originTrigger.isCompleteEqual(trigger: trigger) {
                    Log.debug("Trigger没有变更!!!")
                } else {
                    originTrigger.update(realm: realm, trigger: trigger)
                }
            }
        }
    }
}
