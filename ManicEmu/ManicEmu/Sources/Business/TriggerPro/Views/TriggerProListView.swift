//
//  TriggerProListView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/10/21.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import SwipeCellKit
import RealmSwift
import ManicEmuCore
import ProHUD

class TriggerProListView: BaseView {
    /// 充当导航条
    private var navigationBlurView: UIView = {
        let view = UIView()
        view.makeBlur()
        return view
    }()
    
    private lazy var addButton: ContextMenuButton = {
        let allGameTypes = System.allCases.map { $0.gameType }
        var actions: [UIMenuElement] = []
        for gameType in allGameTypes {
            actions.append(UIAction(title: gameType.localizedShortName) { [weak self] gesture in
                guard let self = self else { return }
                if !PurchaseManager.isMember, self.triggers.count >= Constants.Numbers.NonMemberTriggerProCount {
                    topViewController()?.present(PurchaseViewController(), animated: true)
                    return
                }
                topViewController()?.present(TriggerProPreviewController(gameType: gameType,
                                                                         preferredSkinID: PlayViewController.currentSkinID,
                                                                         hideControls: PlayViewController.isHideControls), animated: true)
            })
        }
        
        let view = ContextMenuButton(image: UIImage(symbol: .plus, font: Constants.Font.body(size: .m, weight: .bold)), menu: UIMenu(children: actions), enableGlass: true)
        view.layerCornerRadius = Constants.Size.IconSizeMid.height/2
        if #available(iOS 26.0, *) {
            view.backgroundColor = .clear
        } else {
            view.backgroundColor = Constants.Color.BackgroundPrimary
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
    
    private lazy var copyImage = UIImage(symbol: .docOnDoc, color: Constants.Color.LabelPrimary.forceStyle(.dark), backgroundColor: Constants.Color.Yellow, imageSize: .init(Constants.Size.ItemHeightMin)).withRoundedCorners()
    
    private lazy var tableView: UITableView = {
        let view = BlankSlateTableView(frame: .zero, style: .grouped)
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.delegate = self
        view.dataSource = self
        view.separatorStyle = .none
        view.showsVerticalScrollIndicator = false
        view.contentInset = UIEdgeInsets(top: Constants.Size.ItemHeightMid, left: 0, bottom: Constants.Size.ContentInsetBottom, right: 0)
        view.register(cellWithClass: TriggerProListCell.self)
        view.register(headerFooterViewClassWith: TriggerProHeaderView.self)
        view.blankSlateView = TriggerProListBlankSlateView()
        view.sectionHeaderTopPadding = 0
        view.sectionHeaderHeight = 46;
        view.sectionFooterHeight = 0;
        return view
    }()
    
    private var triggers: Results<Trigger> = {
        let realm = Database.realm
        let triggers = realm.objects(Trigger.self).where { !$0.isDeleted }
        return triggers
    }()
    
    private var datas: [GameType: [Trigger]] = [:]
    
    var didTapClose: (()->Void)? = nil
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
    }
    
    private var triggersUpdateToken: NotificationToken? = nil
    init(showClose: Bool = true) {
        super.init(frame: .zero)
        Log.debug("\(String(describing: Self.self)) init")
        
        datas = Dictionary(grouping: triggers, by: { $0.gameType })
        
        triggersUpdateToken = triggers.observe { [weak self] changes in
            guard let self = self else { return }
            switch changes {
            case .update(_, _, _, _):
                self.datas = Dictionary(grouping: self.triggers, by: { $0.gameType })
                self.tableView.reloadData()
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
        titleLabel.text = "TriggerPro"
        navigationBlurView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(addButton.snp.trailing).offset(Constants.Size.ContentSpaceTiny)
            make.centerY.equalToSuperview()
        }
        
        if showClose {
            navigationBlurView.addSubview(closeButton)
            closeButton.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
                make.centerY.equalToSuperview()
                make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TriggerProListView: SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard let trigger = getTrigger(at: indexPath) else { return nil }
        UIDevice.generateHaptic()
        if orientation == .right {
            let delete = SwipeAction(style: .default, title: nil) { action, indexPath in
                UIDevice.generateHaptic()
                action.fulfill(with: .reset)
                Trigger.change { realm in
                    if Settings.defalut.iCloudSyncEnable {
                        trigger.isDeleted = true
                        trigger.items.forEach({
                            $0.customImage?.deleteAndClean(realm: realm)
                            $0.isDeleted = true
                        })
                    } else {
                        trigger.items.forEach({
                            $0.customImage?.deleteAndClean(realm: realm)
                        })
                        realm.delete(trigger.items)
                        realm.delete(trigger)
                    }
                }
            }
            delete.backgroundColor = .clear
            delete.image = deleteImage
            let edit = SwipeAction(style: .default, title: nil) { action, indexPath in
                let newTrigger = trigger.copyTrigger(newId: true)
                if let name = newTrigger.name {
                    newTrigger.name = name + "_copy"
                }
                Trigger.change { realm in
                    realm.add(newTrigger)
                }
            }
            edit.hidesWhenSelected = true
            edit.backgroundColor = .clear
            edit.image = copyImage
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

extension TriggerProListView: SwipeExpanding {
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

extension TriggerProListView: UITableViewDataSource, UITableViewDelegate {
    private func sortDatasKeys() -> [GameType] {
        var predefinedOrder: [GameType]
        if let customPlatformOrder = Constants.Config.PlatformOrder {
            predefinedOrder = customPlatformOrder.compactMap { GameType(shortName: $0) }
        } else {
            predefinedOrder = System.allCases.map { $0.gameType }
        }
        let sortedKeys: [GameType] = predefinedOrder.filter { datas.keys.contains($0) }
        return sortedKeys
    }
    
    private func getTriggers(at section: Int) -> [Trigger] {
        let gameTypes = sortDatasKeys()
        let gameType = gameTypes[section]
        if let results = datas[gameType] {
            return results
        }
        return []
    }
    
    private func getTrigger(at indexPath: IndexPath) -> Trigger? {
        let triggers = getTriggers(at: indexPath.section)
        if triggers.count > indexPath.row {
            return triggers[indexPath.row]
        }
        return nil
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        sortDatasKeys().count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        getTriggers(at: section).count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: TriggerProListCell.self)
        cell.setData(trigger: getTrigger(at: indexPath))
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let trigger = getTrigger(at: indexPath) else { return }
        topViewController()?.present(TriggerProPreviewController(gameType: trigger.gameType,
                                                                 trigger: trigger,
                                                                 preferredSkinID: PlayViewController.currentSkinID,
                                                                 hideControls: PlayViewController.isHideControls), animated: true)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withClass: TriggerProHeaderView.self)
        header.titleLabel.attributedText = NSAttributedString(string: sortDatasKeys()[section].localizedName, attributes: [.foregroundColor: Constants.Color.LabelSecondary, .font: Constants.Font.body(size: .s)])
        return header
    }
}

class TriggerProHeaderView: UITableViewHeaderFooterView {
    let titleLabel: UILabel = {
        let titleLabel = UILabel()
        return titleLabel
    }()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.Size.SafeAera.left + Constants.Size.ContentSpaceMid)
            make.bottom.equalToSuperview().offset(-Constants.Size.ContentSpaceUltraTiny)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.snp.updateConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.Size.SafeAera.left + Constants.Size.ContentSpaceMid)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TriggerProListView {
    static var isShow: Bool {
        Sheet.find(identifier: String(describing: TriggerProListView.self)).count > 0 ? true : false
    }
    
    static func show(game: Game, gameViewRect: CGRect, menuInsets: UIEdgeInsets? = nil, hideCompletion: (()->Void)? = nil, didTapClose: (()->Void)? = nil) {
        Sheet.lazyPush(identifier: String(describing: TriggerProListView.self)) { sheet in
            sheet.configGamePlayingStyle(gameViewRect: gameViewRect, menuInsets: menuInsets, hideCompletion: hideCompletion)
            
            let view = UIView()
            let containerView = RoundAndBorderView(roundCorner: (UIDevice.isPad || UIDevice.isLandscape || menuInsets != nil) ? .allCorners : [.topLeft, .topRight])
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
            
            let listView = TriggerProListView()
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
