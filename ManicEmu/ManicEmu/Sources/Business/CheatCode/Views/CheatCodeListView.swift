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

class CheatCodeListView: BaseView {
    /// 充当导航条
    private var navigationBlurView: UIView = {
        let view = UIView()
        view.makeBlur()
        return view
    }()
    
    private lazy var addButton: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .plus, font: Constants.Font.body(size: .m, weight: .bold)))
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
    
    private lazy var deleteImage = UIImage(symbol: .trash, backgroundColor: Constants.Color.Red, imageSize: .init(Constants.Size.ItemHeightMin)).withRoundedCorners()
    
    private lazy var editImage = UIImage(symbol: .squareAndPencil, backgroundColor: Constants.Color.Yellow, imageSize: .init(Constants.Size.ItemHeightMin)).withRoundedCorners()
    
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
    
    ///游戏
    private var gameCheats: Results<GameCheat>
    
    var didTapAdd: (()->Void)? = nil
    var didTapClose: (()->Void)? = nil
    var didTapEdt: ((GameCheat)->Void)? = nil
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
    }
    
    private var gamesCheatsUpdateToken: NotificationToken? = nil
    init(game: Game) {
        self.gameCheats = game.gameCheats.where({ !$0.isDeleted })
        super.init(frame: .zero)
        Log.debug("\(String(describing: Self.self)) init")
        
        gamesCheatsUpdateToken = gameCheats.observe { [weak self] changes in
            guard let self = self else { return }
            switch changes {
            case .update(_, let deletions, let insertions, _):
                if !deletions.isEmpty || !insertions.isEmpty {
                    Log.debug("作弊码列表更新")
                    DispatchQueue.main.asyncAfter(delay: 0.4) {
                        self.tableView.reloadData()
                    }
                }
            default:
                break
            }
        }
        
        addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(navigationBlurView)
        navigationBlurView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
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
        
        navigationBlurView.addSubview(howToButton)
        howToButton.snp.makeConstraints { make in
            make.height.equalTo(Constants.Size.ItemHeightUltraTiny)
            make.trailing.equalTo(closeButton.snp.leading).offset(-Constants.Size.ContentSpaceTiny)
            make.centerY.equalTo(closeButton)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        options.backgroundColor = Constants.Color.BackgroundPrimary
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
    
    static func show(game: Game, gameViewRect: CGRect, menuInsets: UIEdgeInsets? = nil, hideCompletion: (()->Void)? = nil, didTapClose: (()->Void)? = nil) {
        Sheet.lazyPush(identifier: String(describing: CheatCodeListView.self)) { sheet in
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
            
            let listView = CheatCodeListView(game: game)
            listView.didTapAdd = {
                AddCheatCodeView.show(game: game, gameViewRect: gameViewRect, menuInsets: menuInsets)
            }
            listView.didTapEdt = { gameCheat in
                AddCheatCodeView.show(game: game, gameCheat: gameCheat, gameViewRect: gameViewRect, menuInsets: menuInsets)
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
