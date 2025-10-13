//
//  ControllerMappingView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/4/24.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later
import ManicEmuCore
import RealmSwift

class ControllerMappingView: UIView {
    /// 充当导航条
    private var navigationBlurView: UIView = {
        let view = UIView()
        return view
    }()
    
    private var contextMenuButton: ContextMenuButton = {
        let view = ContextMenuButton()
        return view
    }()
    
    private lazy var navigationSymbolTitle: SymbolButton = {
        let defaultTitle = self.gameType.localizedShortName
        let view = SymbolButton(image: UIImage(symbol: .chevronUpChevronDown, font: Constants.Font.caption(weight: .bold), color: Constants.Color.LabelPrimary.forceStyle(.dark)),
                                title: defaultTitle,
                                titleFont: Constants.Font.title(size: .s),
                                titleColor: Constants.Color.LabelPrimary.forceStyle(.dark),
                                edgeInsets: .zero,
                                titlePosition: .left,
                                imageAndTitlePadding: Constants.Size.ContentSpaceUltraTiny)
        view.layerCornerRadius = 0
        view.backgroundColor = .clear
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
                    self.updateDatas()
                    var titleColor = Constants.Color.LabelPrimary
                    if #available(iOS 26.0, *), self.gameType != .psp {
                        titleColor = Constants.Color.LabelPrimary.forceStyle(.dark)
                    }
                    self.closeButton.imageView.image = UIImage(symbol: .xmark, font: Constants.Font.body(weight: .bold), color: titleColor)
                    self.resetButton.titleLabel.textColor = titleColor
                }))
            }
            self.contextMenuButton.menu = UIMenu(children: items)
            self.contextMenuButton.triggerTapGesture()
        }
        return view
    }()
    
    private lazy var closeButton: SymbolButton = {
        var titleColor = Constants.Color.LabelPrimary
        if #available(iOS 26.0, *), gameType != .psp {
            titleColor = Constants.Color.LabelPrimary.forceStyle(.dark)
        }
        let view = SymbolButton(image: UIImage(symbol: .xmark, font: Constants.Font.body(weight: .bold), color: titleColor), enableGlass: true)
        view.enableRoundCorner = true
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            self.saveMappings()
            self.didTapClose?()
        }
        return view
    }()
    
    private lazy var resetButton: SymbolButton = {
        var titleColor = Constants.Color.LabelPrimary
        if #available(iOS 26.0, *), gameType != .psp {
            titleColor = Constants.Color.LabelPrimary.forceStyle(.dark)
        }
        let view = SymbolButton(image: nil,
                                title: R.string.localizable.controllerMappingReset(),
                                titleFont: Constants.Font.body(size: .m),
                                titleColor: titleColor,
                                edgeInsets: UIEdgeInsets(top: 0, left: Constants.Size.ContentSpaceTiny+3, bottom: 0, right: Constants.Size.ContentSpaceTiny),
                                titlePosition: .left,
                                enableGlass: true)
        view.titleLabel.textAlignment = .center
        view.enableRoundCorner = true
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            self.resetMapping()
            self.updateDatas()
        }
        return view
    }()
    
    private func resetMapping() {
        modifiedControllerMappings.removeValue(forKey: self.gameType)
        let realm = Database.realm
        if let object = realm.objects(ControllerMapping.self).first(where: { $0.controllerName == gameController.name && $0.gameType == gameType && !$0.isDeleted }) {
            //删除数据
            ControllerMapping.change { realm in
                if Settings.defalut.iCloudSyncEnable {
                    //iCloud同步删除
                    object.isDeleted = true
                } else {
                    //本地删除
                    realm.delete(object)
                }
            }
            NotificationCenter.default.post(name: Constants.NotificationName.ControllerMapping, object: nil)
        }
        stopMapping()
    }
    
    
    private lazy var controllerView: ControllerView = {
        let view = ControllerView()
        view.layerCornerRadius = Constants.Size.CornerRadiusMid
        view.addReceiver(self)
        return view
    }()
    
    private var mappingTipView = MappingTipView()
    
    private var guideTitleLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.textAlignment = .center
        view.textColor = Constants.Color.LabelPrimary.forceStyle(.dark)
        view.font = Constants.Font.body(size: .l, weight: .semibold)
        view.text = R.string.localizable.controllerMappingGuideTitle()
        return view
    }()
    
    private lazy var cancelButton: SymbolButton = {
        let view = SymbolButton(image: nil,
                                title: R.string.localizable.cancelTitle(),
                                titleFont: Constants.Font.body(size: .m),
                                edgeInsets: UIEdgeInsets(top: 0, left: Constants.Size.ContentSpaceTiny+3, bottom: 0, right: Constants.Size.ContentSpaceTiny),
                                titlePosition: .left)
        view.titleLabel.textAlignment = .center
        view.backgroundColor = Constants.Color.Red
        view.enableRoundCorner = true
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            self.stopMapping()
        }
        view.isHidden = true
        return view
    }()
    
    private lazy var gameSettingView: GameSettingView = {
        let game = Game()
        game.gameType = self.gameType
        let view = GameSettingView(game: game, isEditingMode: false, isMappingMode: true)
        view.didSelectItem = { [weak self] item in
            guard let self, !self.isKeyMapping else { return }
            Log.debug("点击了功能键:\(item.title)")
            self.startMapping(input: SomeInput(stringValue: item.inputKey, intValue: nil, type: .controller(.standard)))
        }
        return view
    }()
    
    private var gameType: GameType {
        didSet {
            let deltaCore = ManicEmu.core(for: gameType)
            let fileURL = deltaCore!.resourceBundle.url(forResource: deltaCore!.name, withExtension: "keymapping")
            skinInputMapping = try! GameControllerInputMapping(fileURL: fileURL!)
        }
    }
    
    private var gameController: GameController
    
    private var selectedSkinInput: Input? = nil
    
    private var modifiedList = [GameType]()
    
    private var isKeyMapping = false
    
    ///修改过的控制器映射
    private var modifiedControllerMappings: [GameType: GameControllerInputMapping] = [:]
    
    ///默认控制器映射
    private lazy var defaultControllerMapping: GameControllerInputMapping = {
        return (gameController.defaultInputMapping as! GameControllerInputMapping)
    }()
    
    ///获取当前gameType的控制器映射
    private var modifiedControllerMapping: GameControllerInputMapping {
        if let inputMapping = modifiedControllerMappings[gameType] {
            return inputMapping
        } else {
            let realm = Database.realm
            if let object = realm.objects(ControllerMapping.self).first(where: { $0.controllerName == gameController.name && $0.gameType == gameType && !$0.isDeleted }), let inputMapping = try? GameControllerInputMapping(mapping: object.mapping) {
                modifiedControllerMappings[gameType] = inputMapping
                return inputMapping
            } else {
                let inputMapping = gameController.defaultInputMapping! as! GameControllerInputMapping
                modifiedControllerMappings[gameType] = inputMapping
                return inputMapping
            }
        }
    }
    
    private lazy var skinInputMapping: GameControllerInputMapping = {
        let deltaCore = ManicEmu.core(for: gameType)
        let fileURL = deltaCore!.resourceBundle.url(forResource: deltaCore!.name, withExtension: "keymapping")
        let mapping = try! GameControllerInputMapping(fileURL: fileURL!)
        return mapping
    }()
    
    ///点击关闭按钮回调
    var didTapClose: (()->Void)? = nil
    
    deinit {
        gameController.removeReceiver(self)
    }
    
    private func mapKeyboard(pressKey: String) {
        //进行键盘映射
        if let selectedSkinInput,
            !isKeyMapping {
            //记录修改过
            if !modifiedList.contains([gameType]) {
                modifiedList.append(gameType)
            }
            
            isKeyMapping = true
            defer {
                DispatchQueue.main.asyncAfter(delay: 0.1) {
                    self.isKeyMapping = false
                    self.stopMapping()
                }
            }
            
            guard let skinInputTuple = getSkinInput(selectedSkinInput) else {
                Log.debug("皮肤键位没有找到")
                UIView.makeToast(message: R.string.localizable.controllerMappingNoFouond())
                return
            }
            
            if var controllerInputMapping = modifiedControllerMappings[gameType] {
                //如果将要映射的按键，已经被使用，需要将使用中的映射移除
                var deleteKeys = [String]()
                for (key, value) in controllerInputMapping.inputMappings {
                    if value.stringValue == skinInputTuple.key {
                        deleteKeys.append(key)
                    }
                }
                if deleteKeys.count > 0 {
                    var inputMappings = controllerInputMapping.inputMappings
                    inputMappings.removeAll(keys: deleteKeys)
                    controllerInputMapping.inputMappings = inputMappings
                    Log.debug("\n控制器的\(skinInputTuple.key)被\(deleteKeys)占用 删除:\(deleteKeys)")
                }
                
                controllerInputMapping.inputMappings[pressKey] = SomeInput(stringValue: skinInputTuple.key, intValue: nil, type: .controller(.standard))
                
                modifiedControllerMappings[gameType] = controllerInputMapping

                setupMappingBubble()
            }
        }
    }
    
    init(gameType: GameType = .dc, controller: GameController) {
        self.gameType = gameType
        self.gameController = controller
        super.init(frame: .zero)
        self.backgroundColor = .black
        
        if gameController.inputType == .keyboard, let keyboardController = gameController as? KeyboardGameController {
            //如果是键盘的话 需要特殊处理 监听键盘的按键
            keyboardController.keyboardPress = { [weak self] pressKey in
                guard let self = self else { return }
                Log.debug("点击键盘:\(pressKey)")
                self.mapKeyboard(pressKey: pressKey)
            }
        } else {
            gameController.addReceiver(self)
        }
        
        
        addSubview(controllerView)
        controllerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        controllerView.addSubview(guideTitleLabel)
        
        
        addSubview(mappingTipView)
        mappingTipView.snp.makeConstraints { make in
            make.edges.equalTo(controllerView)
        }
        
        addSubview(cancelButton)
        cancelButton.snp.makeConstraints { make in
            make.centerX.equalTo(guideTitleLabel)
            make.top.equalTo(guideTitleLabel.snp.bottom).offset(Constants.Size.ContentSpaceMin)
            make.height.equalTo(Constants.Size.ItemHeightTiny)
            make.width.greaterThanOrEqualTo(Constants.Size.ItemHeightMid)
        }
        
        addSubview(navigationBlurView)
        navigationBlurView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Constants.Size.SafeAera.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }
        
        navigationBlurView.addSubview(navigationSymbolTitle)
        navigationSymbolTitle.snp.makeConstraints { make in
            make.leading.equalTo(Constants.Size.ContentSpaceMax)
            make.centerY.equalToSuperview()
        }
        
        navigationBlurView.insertSubview(contextMenuButton, belowSubview: navigationSymbolTitle)
        contextMenuButton.snp.makeConstraints { make in
            make.edges.equalTo(navigationSymbolTitle)
        }
        
        navigationBlurView.addSubview(resetButton)
        resetButton.snp.makeConstraints { make in
            make.leading.equalTo(navigationSymbolTitle.snp.trailing).offset(Constants.Size.ContentSpaceMid)
            make.centerY.equalToSuperview()
            make.height.equalTo(Constants.Size.ItemHeightUltraTiny)
            make.width.greaterThanOrEqualTo(44)
        }
        
        navigationBlurView.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
            make.centerY.equalToSuperview()
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
        
        addSubview(gameSettingView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateDatas() {
        if let controlerSkin = ControllerSkin.standardControllerSkin(for: gameType),
            let frames = controlerSkin.getFrames() {
            controllerView.controllerSkin = controlerSkin
            controllerView.snp.remakeConstraints { make in
                make.center.equalToSuperview()
                make.size.equalTo(frames.skinFrame.size)
            }
            
            if gameController.inputType == .keyboard {
                controllerView.becomeFirstResponder()
            }
            
            setupMappingBubble()
            guideTitleLabel.snp.remakeConstraints { make in
                make.top.equalTo(frames.mainGameViewFrame.maxY + Constants.Size.ContentSpaceTiny)
                make.centerX.equalTo(frames.mainGameViewFrame.center.x)
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMax)
            }
            gameSettingView.updateMappingMode(gameType: gameType)
            let navigationBottom = navigationBlurView.frame.maxY
            let controllerViewTop = frames.mainGameViewFrame.minY + controllerView.frame.minY
            let y = max(navigationBottom, controllerViewTop)
            var height = frames.mainGameViewFrame.height
            if navigationBottom > controllerViewTop {
                height -= (navigationBottom - controllerViewTop)
            }
            gameSettingView.frame = CGRect(x: frames.mainGameViewFrame.minX + controllerView.frame.minX, y: y, width: frames.mainGameViewFrame.width, height: height)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateDatas()
    }
    
    private func getSkinInput(_ skinInput: Input) -> (key: String, input: SomeInput)? {
        if let input = skinInputMapping.inputMappings[skinInput.stringValue] {
            return (skinInput.stringValue, input)
        } else {
            for (key, value) in skinInputMapping.inputMappings {
                if value.stringValue == skinInput.stringValue {
                    return (key, value)
                }
            }
        }
        if skinInput.stringValue.lowercased() == "menu" {
            return ("menu", SomeInput(skinInput))
        }
        //检查是否是功能按键
        if GameSetting.isValidInputKey(skinInput.stringValue) {
            return (skinInput.stringValue, SomeInput(skinInput))
        }
        return nil
    }
    
    private func getControllerInput(_ controllerInput: Input,
                                    isModifiedSource: Bool = true,
                                    onlySearchValue: Bool = false,
                                    includeSearchValue: Bool = true) -> (key: String, input: SomeInput)? {
        if onlySearchValue {
            for (key, value) in (isModifiedSource ? modifiedControllerMapping : defaultControllerMapping).inputMappings {
                if value.stringValue == controllerInput.stringValue {
                    return (key, value)
                }
            }
        } else {
            if let input = (isModifiedSource ? modifiedControllerMapping : defaultControllerMapping).inputMappings[controllerInput.stringValue] {
                return (controllerInput.stringValue, input)
            } else if includeSearchValue {
                for (key, value) in (isModifiedSource ? modifiedControllerMapping : defaultControllerMapping).inputMappings {
                    if value.stringValue == controllerInput.stringValue {
                        return (key, value)
                    }
                }
            }
        }
        return nil
    }
    
    private func getControllerInputString(skinInput: Input) -> String? {
        if let skinInputTuple = getSkinInput(skinInput),
           let controllerInputTuple = getControllerInput(SomeInput(stringValue: skinInputTuple.key, intValue: nil, type: .controller(.standard)), onlySearchValue: true) {
            return shortName(for: controllerInputTuple.key)
        }
        return nil
    }
    
    private func shortName(for controllerInputString: String) -> String {
        if controllerInputString == "leftShoulder" {
            return "L1"
        } else if controllerInputString == "leftThumbstickDown" {
            return "L↓"
        } else if controllerInputString == "leftThumbstickLeft" {
            return "L←"
        } else if controllerInputString == "leftThumbstickRight" {
            return "L→"
        } else if controllerInputString == "leftThumbstickUp" {
            return "L↑"
        } else if controllerInputString == "leftTrigger" {
            return "L2"
        } else if controllerInputString == "leftThumbstickButton" {
            return "L3"
        }  else if controllerInputString == "rightShoulder" {
            return "R1"
        } else if controllerInputString == "rightThumbstickDown" {
            return "R↓"
        } else if controllerInputString == "rightThumbstickLeft" {
            return "R←"
        } else if controllerInputString == "rightThumbstickRight" {
            return "R→"
        } else if controllerInputString == "rightThumbstickUp" {
            return "R↑"
        } else if controllerInputString == "rightTrigger" {
            return "R2"
        } else if controllerInputString == "rightThumbstickButton" {
            return "R3"
        }  else {
//            if gameController.name.contains("DualShock", caseSensitive: false) ||  gameController.name.contains("DualSense", caseSensitive: false) {
//                //索尼的手柄 a->× y->△ b->○ x->□
//                if controllerInputString == "a" {
//                    return "×"
//                } else if controllerInputString == "b" {
//                    return "○"
//                } else if controllerInputString == "x" {
//                    return "□"
//                } else if controllerInputString == "y" {
//                    return "△"
//                }
//            }
            
            if let firstUppercased = controllerInputString.first?.uppercased() {
                return firstUppercased + controllerInputString.dropFirst()
            }
        }
        return controllerInputString
    }
    
    private func setupMappingBubble() {
        mappingTipView.subviews.forEach { $0.removeFromSuperview() }
        let traits = ControllerSkin.Traits.defaults(for: UIWindow.applicationWindow ?? UIWindow(frame: .init(origin: .zero, size: Constants.Size.WindowSize)))
        if let items = controllerView.controllerSkin?.items(for: traits) {
            for item in items {
                let scaledFrame = item.frame.applying(.init(scaleX: mappingTipView.width, y: mappingTipView.height))
                
                switch item.kind {
                case .button:
                    //不支持组合键
                    if let input = item.inputs.allInputs.first {
                        mappingTipView.updateTip(kind: item.kind, inputString: getControllerInputString(skinInput: input), position: CGPoint(x: scaledFrame.center.x, y: scaledFrame.center.y))
                    }
                case .dPad, .thumbstick:
                    if case .directional(let up, let down, let left, let right) = item.inputs {
                        let minSize = CGSize(width: Constants.Size.ItemHeightMid, height: Constants.Size.ItemHeightTiny)
                        let upFrame = CGRect(center: CGPoint(x: scaledFrame.midX, y: scaledFrame.minY), size: minSize)
                        let downFrame = CGRect(center: CGPoint(x: scaledFrame.midX, y: scaledFrame.maxY), size: minSize)
                        let leftFrame = CGRect(center: CGPoint(x: scaledFrame.minX, y: scaledFrame.midY), size: minSize)
                        let rightFrame = CGRect(center: CGPoint(x: scaledFrame.maxX, y: scaledFrame.midY), size: minSize)
                        let adjustFrames = adjustFrames(up: upFrame, down: downFrame, left: leftFrame, right: rightFrame)
                        mappingTipView.updateTip(kind: item.kind, inputString: getControllerInputString(skinInput: up), position: adjustFrames.up.center)
                        mappingTipView.updateTip(kind: item.kind, inputString: getControllerInputString(skinInput: down), position: adjustFrames.down.center)
                        mappingTipView.updateTip(kind: item.kind, inputString: getControllerInputString(skinInput: left), position: adjustFrames.left.center)
                        mappingTipView.updateTip(kind: item.kind, inputString: getControllerInputString(skinInput: right), position: adjustFrames.right.center)
                    }
                default: break
                }
            }
        }
    }
    
    func adjustFrames(up: CGRect, down: CGRect, left: CGRect, right: CGRect) -> (up: CGRect, down: CGRect, left: CGRect, right: CGRect) {
        var upFrame = up
        var downFrame = down
        var leftFrame = left
        var rightFrame = right
        
        let minSpacing: CGFloat = Constants.Size.ItemHeightUltraTiny

        // 垂直方向
        let verticalDistance = downFrame.minY - upFrame.maxY
        if verticalDistance < minSpacing {
            let move = (minSpacing - verticalDistance) / 2
            upFrame.origin.y -= move
            downFrame.origin.y += move
        }

        // 水平方向
        let horizontalDistance = rightFrame.minX - leftFrame.maxX
        if horizontalDistance < minSpacing {
            let move = (minSpacing - horizontalDistance) / 2
            leftFrame.origin.x -= move
            rightFrame.origin.x += move
        }

        return (up: upFrame, down: downFrame, left: leftFrame, right: rightFrame)
    }
    
    private func saveMappings() {
        let realm = Database.realm
        var needToNotify = false
        for (gameType, mapping) in modifiedControllerMappings {
            guard modifiedList.contains([gameType]) else { continue }
            
            if let object = realm.objects(ControllerMapping.self).first(where: { $0.controllerName == gameController.name && $0.gameType == gameType && !$0.isDeleted }) {
                //更新数据库
                ControllerMapping.change { realm in
                    object.mapping = mapping.genMapping()
                }
                needToNotify = true
            } else {
                //插入数据库
                let storeObject = ControllerMapping()
                storeObject.controllerName = gameController.name
                storeObject.gameType = gameType
                storeObject.mapping = mapping.genMapping()
                ControllerMapping.change { realm in
                    realm.add(storeObject)
                }
                needToNotify = true
            }
        }
        if needToNotify {
            NotificationCenter.default.post(name: Constants.NotificationName.ControllerMapping, object: nil)
        }
    }
    
    private func startMapping(input: ManicEmuCore.Input) {
        selectedSkinInput = input
        guideTitleLabel.text = R.string.localizable.controllerMappingGuideBegin(input.stringValue)
        controllerView.isUserInteractionEnabled = false
        if gameController.inputType == .keyboard {
            controllerView.becomeFirstResponder()
        }
        cancelButton.isHidden = false
    }
    
    private func stopMapping() {
        self.selectedSkinInput = nil
        controllerView.isUserInteractionEnabled = true
        guideTitleLabel.text = R.string.localizable.controllerMappingGuideTitle()
        cancelButton.isHidden = true
    }
}

extension ControllerMappingView: ControllerReceiverProtocol {
    //这里只处理mfi控制器
    func gameController(_ gameController: any ManicEmuCore.GameController, didActivate input: any ManicEmuCore.Input, value: Double) {
        guard gameController.inputType != .keyboard else { return }
        if gameController.inputType == .controllerSkin, selectedSkinInput == nil {
            if input.stringValue.contains("touchScreenX", caseSensitive: false) ||
                input.stringValue.contains("touchScreenY", caseSensitive: false) {
                return
            }
            Log.debug("点击皮肤:\(input)")
            startMapping(input: input)
        } else if let selectedSkinInput, gameController.inputType != .controllerSkin, !isKeyMapping {
            
            let isThumbStick = (input.stringValue == "leftThumbstickLeft" ||
                                input.stringValue == "leftThumbstickRight" ||
                                input.stringValue == "leftThumbstickUp" ||
                                input.stringValue == "leftThumbstickDown" ||
                                input.stringValue == "rightThumbstickLeft" ||
                                input.stringValue == "rightThumbstickRight" ||
                                input.stringValue == "rightThumbstickUp" ||
                                input.stringValue == "rightThumbstickDown")
            if isThumbStick, value < 0.5 {
                return
            }
            
            //记录修改过
            if !modifiedList.contains([gameType]) {
                modifiedList.append(gameType)
            }
            
            isKeyMapping = true
            defer {
                DispatchQueue.main.asyncAfter(delay: 0.1) {
                    self.isKeyMapping = false
                    self.stopMapping()
                }
            }
            Log.debug("点击控制器:\(input)")
            
            //这里输出的是处理后的input，需要找到映射前的input
            guard let skinInputTuple = getSkinInput(selectedSkinInput) else {
                Log.debug("皮肤键位没有找到")
                UIView.makeToast(message: R.string.localizable.controllerMappingNoFouond())
                return
            }
            
            var controllerInputTuple: (key: String, input: SomeInput)?
            if let tuple = getControllerInput(input, includeSearchValue: false) {
                Log.debug("从修改的映射中找到映射")
                controllerInputTuple = tuple
            } else if let tuple = getControllerInput(input, isModifiedSource: false) {
                Log.debug("从默认的映射中找到映射")
                controllerInputTuple = tuple
            }
            
            guard let controllerInputTuple else {
                Log.debug("没有找到控制器键位")
                UIView.makeToast(message: R.string.localizable.controllerMappingNoFouond())
                return
            }
            
            if var controllerInputMapping = modifiedControllerMappings[gameType] {
                //如果将要映射的按键，已经被使用，需要将使用中的映射移除
                var deleteKeys = [String]()
                for (key, value) in controllerInputMapping.inputMappings {
                    if value.stringValue == skinInputTuple.key {
                        deleteKeys.append(key)
                    }
                }
                if deleteKeys.count > 0 {
                    var inputMappings = controllerInputMapping.inputMappings
                    inputMappings.removeAll(keys: deleteKeys)
                    controllerInputMapping.inputMappings = inputMappings
                    Log.debug("\n控制器的\(skinInputTuple.key)被\(deleteKeys)占用 删除:\(deleteKeys)")
                }
                
                //找到了控制器和皮肤的真实的按键
                if let beforeInput = controllerInputMapping.inputMappings[controllerInputTuple.key] {
                    Log.debug("修改映射:从\(controllerInputTuple.key) -> \(beforeInput.stringValue) 到 \(controllerInputTuple.key) -> \(skinInputTuple.key)")
                } else {
                    Log.debug("添加映射:\(controllerInputTuple.key) -> \(skinInputTuple.key)")
                }
                controllerInputMapping.inputMappings[controllerInputTuple.key] = SomeInput(stringValue: skinInputTuple.key, intValue: nil, type: controllerInputTuple.input.type, isContinuous: controllerInputTuple.input.isContinuous)
                modifiedControllerMappings[gameType] = controllerInputMapping

                setupMappingBubble()
            }
        } else {
            Log.debug("点击:\(input)")
        }
    }
    
    func gameController(_ gameController: any ManicEmuCore.GameController, didDeactivate input: any ManicEmuCore.Input) {
        
    }
}
