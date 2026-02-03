//
//  CheatCodeListView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/3/6.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import SwipeCellKit
import RealmSwift
import ProHUD
import UniformTypeIdentifiers
import ManicEmuCore

class CheatCodeListView: BaseView {
    /// 充当导航条
    private var navigationBlurView: NavigationBlurView = {
        let view = NavigationBlurView()
        view.makeBlur()
        return view
    }()
    
    private lazy var addButton: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .plus, font: Constants.Font.body(size: .m, weight: .bold)), enableGlass: true)
        view.enableRoundCorner = true
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            if !PurchaseManager.isMember, self.gameCheats.count >= Constants.Numbers.NonMemberCheatCodeCount {
                topViewController()?.present(PurchaseViewController(), animated: true)
                return
            }
            self.didTapAdd?()
        }
        return view
    }()
    
    private lazy var moreContextMenuButton: ContextMenuButton = {
        var actions: [UIMenuElement] = []
        actions.append(UIMenu(title: R.string.localizable.gameSortType(),
                              image: UIImage(symbol: .arrowUpArrowDown),
                              options: .singleSelection,
                              children: GameCheatSortType.allCases.map({ type in
            let currentType = GameCheatSortType(rawValue: Settings.defalut.getExtraInt(key: ExtraKey.cheatSort.rawValue) ?? 0) ?? .dateAscending
            return UIAction(title: type.title,
                            state: currentType == type ? .on : .off,
                            handler: { [weak self] _ in
                guard let self = self else { return }
                Settings.defalut.updateExtra(key: ExtraKey.cheatSort.rawValue, value: type.rawValue)
                self.reloadCheats()
                self.tableView.reloadData()
            })
        })))
        actions.append((UIAction(title: R.string.localizable.removeAllCheats(), image: UIImage(symbol: .trash)) { [weak self] _ in
            guard let self = self else { return }
            //移除所有作弊码
            UIView.makeAlert(detail: R.string.localizable.removeAllCheatsAlert(),
                             confirmTitle: R.string.localizable.removeTitle(),
                             confirmAction: {
                Game.change { realm in
                    if Settings.defalut.iCloudSyncEnable {
                        self.gameCheatsResults.forEach({ $0.isDeleted = true })
                    } else {
                        realm.delete(self.gameCheatsResults)
                    }
                }
                self.reloadCheats()
                self.tableView.reloadData()
            })
            
        }))
        actions.append((UIAction(title: R.string.localizable.howToFetch(), image: UIImage(symbol: .book)) { [weak self] _ in
            guard let self = self else { return }
            //如何获取
            topViewController()?.present(WebViewController(url: Constants.URLs.CheatCodesGuide), animated: true)
        }))
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
        }
        return view
    }()
    
    private lazy var deleteImage = UIImage(symbol: .trash, color: Constants.Color.LabelPrimary.forceStyle(.dark), backgroundColor: Constants.Color.Red, imageSize: .init(Constants.Size.ItemHeightMin)).withRoundedCorners()
    
    private lazy var editImage = UIImage(symbol: .squareAndPencil, color: Constants.Color.LabelPrimary.forceStyle(.dark), backgroundColor: Constants.Color.Yellow, imageSize: .init(Constants.Size.ItemHeightMin)).withRoundedCorners()
    
    private lazy var tableView: UITableView = {
        let view = BlankSlateTableView()
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.delegate = self
        view.dataSource = self
        view.separatorStyle = .none
        view.showsVerticalScrollIndicator = false
        view.contentInset = UIEdgeInsets(top: Constants.Size.ItemHeightMid, left: 0, bottom: Constants.Size.ContentInsetBottom, right: 0)
        view.register(cellWithClass: CheatCodeCollectionViewCell.self)
        view.blankSlateView = CheatCodeBlankSlateView()
        return view
    }()
    
    private lazy var appendButton: SymbolButton = {
        var cheatFileExtension = ""
        var supportFileExtensions: [UTType] = []
        if game.gameType == ._3ds {
            cheatFileExtension = ".txt"
            supportFileExtensions.append(UTType(filenameExtension: "txt")!)
        } else if game.gameType == .psp {
            cheatFileExtension = ".db .ini"
            supportFileExtensions.append(UTType(filenameExtension: "db")!)
            supportFileExtensions.append(UTType(filenameExtension: "ini")!)
        }
        let view = SymbolButton(image: nil, title: R.string.localizable.tabbarTitleImport() + " \(cheatFileExtension)", titleFont: Constants.Font.body(size: .l, weight: .medium), titleColor: Constants.Color.LabelPrimary.forceStyle(.dark), horizontalContian: true, titlePosition: .right)
        view.enableRoundCorner = true
        view.backgroundColor = Constants.Color.Red
        view.addTapGesture { [weak self] gesture in
            guard let self else { return }
            FilesImporter.shared.presentImportController(supportedTypes: supportFileExtensions) { [weak self] urls in
                guard let self else { return }
                self.parseImportCheatFiles(urls: urls)
            }
        }
        return view
    }()
    
    ///游戏
    private var gameCheatsResults: Results<GameCheat>
    private var gameCheats: [GameCheat] = []
    private var game: Game
    
    var didTapAdd: (()->Void)? = nil
    var didTapClose: (()->Void)? = nil
    var didTapEdt: ((GameCheat)->Void)? = nil
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
    }
    
    private var gamesCheatsUpdateToken: NotificationToken? = nil
    init(game: Game) {
        self.game = game
        self.gameCheatsResults = game.gameCheats.where({ !$0.isDeleted })
        super.init(frame: .zero)
        Log.debug("\(String(describing: Self.self)) init")
        
        gamesCheatsUpdateToken = gameCheatsResults.observe { [weak self] changes in
            guard let self = self else { return }
            switch changes {
            case .update(_, let deletions, let insertions, let modifications):
                if !deletions.isEmpty || !insertions.isEmpty || !modifications.isEmpty {
                    Log.debug("作弊码列表更新")
                    reloadCheats()
                    DispatchQueue.main.asyncAfter(delay: 0.4) {
                        self.tableView.reloadData()
                    }
                }
            default:
                break
            }
        }
        
        reloadCheats()
        
        addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(navigationBlurView)
        navigationBlurView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalTo(self.safeAreaLayoutGuide)
            make.height.equalTo(Constants.Size.ItemHeightMid)
        }
        
        navigationBlurView.addSubview(addButton)
        addButton.snp.makeConstraints { make in
            make.leading.equalTo(Constants.Size.ContentSpaceMax)
            make.centerY.equalToSuperview()
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
        
        let titleLabel = UILabel()
        titleLabel.font = Constants.Font.title(size: .s)
        titleLabel.textColor = Constants.Color.LabelPrimary
        titleLabel.text = R.string.localizable.gamesCheatCode()
        navigationBlurView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(addButton.snp.trailing).offset(Constants.Size.ContentSpaceTiny)
            make.centerY.equalToSuperview()
        }
        
        navigationBlurView.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
            make.centerY.equalToSuperview()
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
        
        navigationBlurView.addSubview(moreContextMenuButton)
        navigationBlurView.addSubview(moreButton)
        moreButton.snp.makeConstraints { make in
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
            make.trailing.equalTo(closeButton.snp.leading).offset(-Constants.Size.ContentSpaceMid)
            make.centerY.equalTo(closeButton)
        }
        moreContextMenuButton.snp.makeConstraints { make in
            make.edges.equalTo(moreButton)
        }
        
        if game.gameType == ._3ds || game.gameType == .psp {
            //table底部缩进
            var tableContentInset = tableView.contentInset
            tableContentInset.bottom = tableContentInset.bottom + Constants.Size.ItemHeightMid + Constants.Size.ContentSpaceMid
            tableView.contentInset = tableContentInset
            
            addSubview(appendButton)
            appendButton.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceHuge)
                make.bottom.equalToSuperview().inset(Constants.Size.ContentInsetBottom)
                make.height.equalTo(Constants.Size.ItemHeightMid)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func reloadCheats() {
        let sortType = GameCheatSortType(rawValue: Settings.defalut.getExtraInt(key: ExtraKey.cheatSort.rawValue) ?? 0) ?? .dateAscending
        gameCheats = gameCheatsResults.sorted(by: {
            switch sortType {
            case .nameAscending:
                return $0.name <= $1.name
            case .nameDescending:
                return $0.name > $1.name
            case .dateAscending:
                return $0.id <= $1.id
            case .dateDescending:
                return $0.id > $1.id
            case .status:
                if $0.activate, !$1.activate {
                    return true
                } else {
                    return false
                }
            }
        })
    }
    
    private func parseImportCheatFiles(urls: [URL]) {
        if game.gameType == ._3ds {
            UIView.makeLoading()
            //解析txt
            var newCheats: [GameCheat] = []
            let supportedCheatFormats = Array(game.gameType.manicEmuCore?.supportCheatFormats ?? Set())
            var index: Int = 0
            for url in urls {
                if let txt = try? String(contentsOf: url, encoding: .utf8) {
                    let cheats = ThreeDS.parseCheatFile(txt)
                    for cheat in cheats {
                        if !gameCheats.contains(where: { $0.code == cheat.code }),
                           !newCheats.contains(where: { $0.code == cheat.code }),
                           let result = AddCheatCodeView.checkCheat(cheatCode: cheat.code, supportedCheatFormats: supportedCheatFormats) {
                            let gameCheat = GameCheat()
                            gameCheat.id += index
                            gameCheat.name = cheat.name
                            gameCheat.code = result.formatString
                            gameCheat.type = result.cheatFormat.type.rawValue
                            newCheats.append(gameCheat)
                            index += 1
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                UIView.hideLoading()
            }
            if newCheats.count > 0 {
                Game.change { realm in
                    game.gameCheats.append(objectsIn: newCheats)
                }
            } else {
                UIView.makeToast(message: R.string.localizable.cheatImportFailed())
            }
            
        } else if game.gameType == .psp {
            guard let gameCodeForPSP = game.gameCodeForPSP else {
                UIView.makeToast(message: R.string.localizable.cheatImportFailed())
                return
            }
            UIView.makeLoading()
            var cheats: [PSP.GameCheat] = []
            for url in urls {
                if let txt = try? String(contentsOf: url, encoding: .utf8) {
                    cheats.append(contentsOf: PSP.parseCheatFiles(content: txt))
                }
            }
            if cheats.count > 0 {
                for cheat in cheats {
                    if cheat.gameCode.trimedExceptNumberAndLetters() == gameCodeForPSP {
                        var newCheats: [GameCheat] = []
                        var index = 0
                        for c in cheat.cheats {
                            if !gameCheats.contains(where: { $0.code == c.code }),
                               !newCheats.contains(where: { $0.code == c.code }) {
                                let gameCheat = GameCheat()
                                gameCheat.id += index
                                gameCheat.name = c.name
                                gameCheat.code = c.code
                                gameCheat.type = CheatType.cwCheat.rawValue
                                newCheats.append(gameCheat)
                                index += 1
                            }
                        }
                        if newCheats.count > 0 {
                            Game.change { realm in
                                game.gameCheats.append(objectsIn: newCheats)
                            }
                        }
                        
                        break
                    }
                }
            }
            
            DispatchQueue.main.async {
                UIView.hideLoading()
            }
            if cheats.count == 0 {
                UIView.makeToast(message: R.string.localizable.cheatImportFailed())
            }
        }
    }
}

extension CheatCodeListView: SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        let cheatCode = gameCheats[indexPath.row]
        UIDevice.generateHaptic()
        if orientation == .right {
            let delete = SwipeAction(style: .default, title: nil) { action, indexPath in
                UIDevice.generateHaptic()
                action.fulfill(with: .reset)
                Game.change { realm in
                    if Settings.defalut.iCloudSyncEnable {
                        cheatCode.isDeleted = true
                    } else {
                        realm.delete(cheatCode)
                    }
                }
            }
            delete.backgroundColor = .clear
            delete.image = deleteImage
            let edit = SwipeAction(style: .default, title: nil) { [weak self] action, indexPath in
                guard let self = self else { return }
                self.didTapEdt?(cheatCode)
            }
            edit.hidesWhenSelected = true
            edit.backgroundColor = .clear
            edit.image = editImage
            return [delete, edit]
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = SwipeExpansionStyle(target: .percentage(0.6),
                                                     elasticOverscroll: true,
                                                     completionAnimation: .fill(.manual(timing: .with)))
        options.expansionDelegate = self
        options.transitionStyle = .border
        options.backgroundColor = Constants.Color.Background
        options.maximumButtonWidth = Constants.Size.ItemHeightMin + Constants.Size.ContentSpaceTiny*2
        return options
    }
}

extension CheatCodeListView: SwipeExpanding {
    func animationTimingParameters(buttons: [UIButton], expanding: Bool) -> SwipeCellKit.SwipeExpansionAnimationTimingParameters {
        ScaleAndAlphaExpansion.default.animationTimingParameters(buttons: buttons, expanding: expanding)
    }
    
    func actionButton(_ button: UIButton, didChange expanding: Bool, otherActionButtons: [UIButton]) {
        ScaleAndAlphaExpansion.default.actionButton(button, didChange: expanding, otherActionButtons: otherActionButtons)
        if expanding {
            UIDevice.generateHaptic()
        }
    }
}

extension CheatCodeListView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        gameCheats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cheatCode = gameCheats[indexPath.row]
        let cell = tableView.dequeueReusableCell(withClass: CheatCodeCollectionViewCell.self)
        cell.setData(cheatCode: cheatCode)
        cell.switchButton.onChange { value in
            if !UserDefaults.standard.bool(forKey: Constants.DefaultKey.HasShowCheatCodeWarning) {
                UIView.makeAlert(title: R.string.localizable.enableCheatCodeAlertTitle(),
                                 detail: R.string.localizable.enableCheatCodeAlertDetail(),
                                 cancelTitle: R.string.localizable.confirmTitle(),
                                 hideAction: {
                    UserDefaults.standard.setValue(true, forKey: Constants.DefaultKey.HasShowCheatCodeWarning)
                    Game.change { _ in
                        cheatCode.activate = value
                    }
                })
            } else {
                Game.change { _ in
                    cheatCode.activate = value
                }
            }
        }
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}

extension CheatCodeListView {
    static var isShow: Bool {
        Sheet.find(identifier: String(describing: CheatCodeListView.self)).count > 0 ? true : false
    }
    
    static func show(game: Game, hideCompletion: (()->Void)? = nil, didTapClose: (()->Void)? = nil) {
        Sheet.lazyPush(identifier: String(describing: CheatCodeListView.self)) { sheet in
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
            
            let listView = CheatCodeListView(game: game)
            listView.didTapAdd = {
                AddCheatCodeView.show(game: game)
            }
            listView.didTapEdt = { gameCheat in
                AddCheatCodeView.show(game: game, gameCheat: gameCheat)
            }
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
