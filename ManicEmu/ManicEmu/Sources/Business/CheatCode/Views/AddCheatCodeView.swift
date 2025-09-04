//
//  AddCheatCodeView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/3/6.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import IQKeyboardManagerSwift
import ManicEmuCore
import ProHUD

class AddCheatCodeView: BaseView {

    private var navigationBlurView: UIView = {
        let view = UIView()
        view.makeBlur()
        return view
    }()
    
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.register(cellWithClass: AddCheatCodeTitleCell.self)
        view.register(cellWithClass: AddCheatCodeContentCell.self)
        view.showsVerticalScrollIndicator = false
        view.dataSource = self
        view.contentInset = UIEdgeInsets(top: Constants.Size.ContentSpaceMax + Constants.Size.ItemHeightMid, left: 0, bottom: Constants.Size.ContentInsetBottom, right: 0)
        return view
    }()
    
    private lazy var confirmButton: HowToButton = {
        let view = HowToButton(title: R.string.localizable.saveTitle()) { [weak self] in
            guard let self = self else { return }
            self.collectionView.endEditing(true)
            if let editGameCheat = self.editGameCheat,
                cheatCode == editGameCheat.code,
                cheatCodeName == editGameCheat.name,
                cheatCodeType == editGameCheat.type {
                //尝试编辑，但是没有任何改动
                didTapClose?()
                return
            }
            
            var isValid = false
            if CheatType(cheatCodeType) == .autoDetect {
                //自动检测模式下需要帮用户做一下检查
                for cheatFormat in supportedCheatFormats.filter({ $0.type != .autoDetect }) {
                    let formatString: String
                    if cheatFormat.type == .cwCheat {
                        formatString = formattedCWCheat(code: cheatCode)
                    } else {
                        formatString = cheatCode.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: ":", with: "").components(separatedBy: .whitespacesAndNewlines).joined().formatted(with: cheatFormat)
                    }
                    
                    var isMatchThisFormat = true
                    for subString in formatString.lines() {
                        if !isCodeMatchingFormat(format: cheatFormat.format, code: subString) {
                            isMatchThisFormat = false
                            break
                        }
                    }
                    if isMatchThisFormat {
                        isValid = true
                        cheatCode = formatString
                        cheatCodeType = cheatFormat.type.rawValue
                        break
                    }
                }
            } else {
                //指定了作弊码类型 且已经通过校验
                isValid = true
            }
            if isValid {
                if let editGameCheat = self.editGameCheat {
                    //修改模式
                    Game.change { realm in
                        editGameCheat.name = self.cheatCodeName
                        editGameCheat.code = self.cheatCode
                        editGameCheat.type = self.cheatCodeType
                    }
                } else {
                    //新增模式
                    let gameCheat = GameCheat()
                    gameCheat.name = self.cheatCodeName
                    gameCheat.code = self.cheatCode
                    gameCheat.type = self.cheatCodeType
                    Game.change { realm in
                        self.game.gameCheats.append(gameCheat)
                    }
                }
                didTapClose?()
            } else {
                UIView.makeToast(message: R.string.localizable.cheatCodeFormatError())
            }
        }
        return view
    }()
    
    private var howToButton: HowToButton = {
        let view = HowToButton(title: R.string.localizable.howToFetch()) {
            topViewController()?.present(WebViewController(url: Constants.URLs.CheatCodesGuide), animated: true)
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
    
    
    private var game: Game
    private let autoDetectCheatFormat = CheatFormat(name: R.string.localizable.autoDetectCheatTypeName(), format: R.string.localizable.autoDetectFormat(), type: .autoDetect)
    private lazy var supportedCheatFormats: [CheatFormat] = {
        var result = [CheatFormat]()
        result.append(autoDetectCheatFormat)
        if let supportCheatFormats = game.gameType.manicEmuCore?.supportCheatFormats {
            result.append(contentsOf: supportCheatFormats)
        }
        return result
    }()
    ///当前选中的作弊码格式
    private var currentCheatFormat: CheatFormat {
        didSet {
            self.cheatCodeType = self.currentCheatFormat.type.rawValue
        }
    }
    private var cheatCodeName: String = ""
    private var cheatCodeType: String = ""
    private var cheatCode: String = ""
    private var editGameCheat: GameCheat? ///如果不传入则是新增 传入则是编辑
    
    var didTapClose: (()->Void)? = nil
    
    init(game: Game, editGameCheat: GameCheat? = nil) {
        self.game = game
        self.editGameCheat = editGameCheat
        currentCheatFormat = autoDetectCheatFormat
        super.init(frame: .zero)
        Log.debug("\(String(describing: Self.self)) init")
        if let editGameCheat = editGameCheat {
            cheatCodeName = editGameCheat.name
            cheatCodeType = editGameCheat.type
            cheatCode = editGameCheat.code
            if let cheatFormat = supportedCheatFormats.first(where: { $0.type == CheatType(cheatCodeType) }) {
                currentCheatFormat = cheatFormat
            }
        } else {
            cheatCodeType = autoDetectCheatFormat.type.rawValue
        }
        
        
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(navigationBlurView)
        navigationBlurView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(Constants.Size.ItemHeightMid)
        }
        
        navigationBlurView.addSubview(confirmButton)
        confirmButton.snp.makeConstraints { make in
            make.leading.equalTo(Constants.Size.ContentSpaceMax)
            make.centerY.equalToSuperview()
            make.height.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
        
        navigationBlurView.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
            make.centerY.equalToSuperview()
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
        
        navigationBlurView.addSubview(howToButton)
        howToButton.snp.makeConstraints { make in
            make.height.equalTo(Constants.Size.ItemHeightUltraTiny)
            make.trailing.equalTo(closeButton.snp.leading).offset(-Constants.Size.ContentSpaceTiny)
            make.centerY.equalTo(closeButton)
        }
        
        IQKeyboardManager.shared.isEnabled = true
        
        validateInput()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
        Task {
            await MainActor.run {
                IQKeyboardManager.shared.isEnabled = false
            }
        }
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, env in
            //item布局
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                 heightDimension: .fractionalHeight(1)))
            //group布局
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(sectionIndex == 0 ? 84 : 154)), subitems: [item])
           
            //section布局
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: sectionIndex == 0 ? 0 : Constants.Size.ContentSpaceHuge, leading: Constants.Size.ContentSpaceMid, bottom: 0, trailing: Constants.Size.ContentSpaceMid)
            return section
        }
        return layout
    }
    
    private func validateInput() {
        var isValid = true
        if cheatCodeName.isEmpty || cheatCodeType.isEmpty || cheatCode.isEmpty  {
            //验证名称 不能为空
            isValid = false
        } else {
            let cheatType = CheatType(rawValue: cheatCodeType)
            if cheatType != .autoDetect {
                let formatString: String
                if currentCheatFormat.type == .cwCheat {
                    formatString = formattedCWCheat(code: cheatCode)
                } else {
                    formatString = cheatCode.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: ":", with: "").components(separatedBy: .whitespacesAndNewlines).joined().formatted(with: currentCheatFormat)
                }
                
                for subString in formatString.lines() {
                    if !isCodeMatchingFormat(format: currentCheatFormat.format, code: subString) {
                        isValid = false
                        break
                    }
                }
                if isValid {
                    cheatCode = formatString
                    cheatCodeType = currentCheatFormat.type.rawValue
                }
            }
        }
        updateConfirmButton(enable: isValid)
    }
    
    private func formattedCWCheat(code: String) -> String {
        var index = 0
        let codes = code.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .whitespacesAndNewlines)
        return codes.reduce("", {
            let newLine = (index%3 == 0)
            let willAddNewLine = (index == codes.count-1) ? false : ((index+1)%3 == 0)
            let s = $0 + (newLine ? "" : " ") + $1.trimmed + (willAddNewLine ? "\n" : "")
            index += 1
            return s
        })
    }
    
    private func isCodeMatchingFormat(format: String, code: String) -> Bool {
        // 将 format 和 code 按空格分割成数组
        let formatComponents = format.components(separatedBy: " ")
        let codeComponents = code.components(separatedBy: " ")
        
        // 如果分割后的数组长度不一致，直接返回 false
        if formatComponents.count != codeComponents.count {
            return false
        }
        
        // 遍历 format 和 code 的每个部分，检查长度是否匹配
        for i in 0..<formatComponents.count {
            if formatComponents[i].count != codeComponents[i].count {
                return false
            }
            
            if formatComponents[i].hasPrefix("0x") {
                if !codeComponents[i].hasPrefix("0X") && !codeComponents[i].hasPrefix("0x") {
                    return false
                }
            }
        }
        
        if let firstformat = formatComponents.first, firstformat == "_L", let firstCode = codeComponents.first, firstCode != "_L" {
            return false
        }
        
        // 如果所有部分都匹配，返回 true
        return true
    }
    
    private func updateConfirmButton(enable: Bool) {
        if enable {
            confirmButton.backgroundColor = Constants.Color.Main
            confirmButton.label.textColor = Constants.Color.LabelPrimary
            confirmButton.isUserInteractionEnabled = true
        } else {
            confirmButton.backgroundColor = Constants.Color.BackgroundSecondary
            confirmButton.label.textColor = Constants.Color.LabelSecondary
            confirmButton.isUserInteractionEnabled = false
        }
    }
}

extension AddCheatCodeView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withClass: AddCheatCodeTitleCell.self, for: indexPath)
            cell.editTextField.text = cheatCodeName
            cell.shouldGoNext = { [weak self] in
                guard let self = self else { return }
                if let cell = self.collectionView.cellForItem(at: IndexPath(row: indexPath.row + 1, section: indexPath.section)) as? AddCheatCodeContentCell {
                    cell.editTextView.becomeFirstResponder()
                }
            }
            cell.editTextField.onChange { [weak self] string in
                guard let self = self else { return }
                self.cheatCodeName = string
                self.validateInput()
            }
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withClass: AddCheatCodeContentCell.self, for: indexPath)
            cell.didTextChange = { [weak self] string in
                guard let self = self else { return }
                self.cheatCode = string
                self.validateInput()
            }
            cell.setData(supportedCheatFormats: supportedCheatFormats, currentCheatFormat: currentCheatFormat, cheatCode: cheatCode)
            cell.didChangeCheatFormat = { [weak self] cheatFormat in
                self?.currentCheatFormat = cheatFormat
                self?.validateInput()
            }
            return cell
        }
        
    }
}

extension AddCheatCodeView {
    static func show(game: Game, gameCheat: GameCheat? = nil, gameViewRect: CGRect, menuInsets: UIEdgeInsets? = nil, hideCompletion: (()->Void)? = nil) {
        Sheet { sheet in
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
            
            let listView = AddCheatCodeView(game: game, editGameCheat: gameCheat)
            listView.didTapClose = { [weak sheet] in
                sheet?.pop()
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
