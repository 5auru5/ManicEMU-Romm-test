//
//  GameSaveMatchGameView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/3/3.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit
import RealmSwift

import ProHUD
import ManicEmuCore


/// 导入存档匹配游戏画面
class GameSaveMatchGameView: BaseView {
    static func show(gameSaveUrl: URL, showGames: [Game]? = nil, title: String, detail: String, cancelTitle: String, completion: @escaping ()->Void) {
        Sheet { sheet in
            sheet.contentMaskView.alpha = 0
            sheet.config.windowEdgeInset = 0
            sheet.onTappedBackground { sheet in }
            sheet.config.backgroundViewMask { mask in
                mask.backgroundColor = .black.withAlphaComponent(0.2)
            }
            
            let view = UIView()
            let grabber = UIImageView(image: R.image.grabber_icon())
            grabber.isUserInteractionEnabled = true
            grabber.contentMode = .center
            view.addPanGesture { [weak view, weak sheet] gesture in
                guard let view = view, let sheet = sheet else { return }
                let point = gesture.translation(in: gesture.view)
                view.transform = .init(translationX: 0, y: point.y <= 0 ? 0 : point.y)
                if gesture.state == .recognized {
                    let v = gesture.velocity(in: gesture.view)
                    if (view.y > view.height*2/3 && v.y > 0) || v.y > 1200 {
                        // 达到移除的速度
                        sheet.pop(completon: completion)
                    }
                    UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.5, options: [.allowUserInteraction, .curveEaseOut], animations: {
                        view.transform = .identity
                    })
                }
            }
            view.addSubview(grabber)
            grabber.snp.makeConstraints { make in
                make.leading.top.trailing.equalToSuperview()
                make.height.equalTo(Constants.Size.ContentSpaceTiny*3)
            }
            
            let containerView = RoundAndBorderView(roundCorner: (UIDevice.isPad || UIDevice.isLandscape) ? .allCorners : [.topLeft, .topRight])
            containerView.backgroundColor = Constants.Color.Background
            containerView.makeBlur()
            view.addSubview(containerView)
            containerView.snp.makeConstraints { make in
                make.top.equalTo(grabber.snp.bottom)
                make.leading.bottom.trailing.equalToSuperview()
            }
            
            let titleLabel = UILabel()
            titleLabel.textAlignment = .center
            titleLabel.text = title
            titleLabel.font = Constants.Font.title(size: .s, weight: .semibold)
            titleLabel.textColor = Constants.Color.LabelPrimary
            containerView.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview().offset(30)
            }
            
            let detailLabel = UILabel()
            detailLabel.numberOfLines = 0
            detailLabel.textAlignment = .center
            detailLabel.text = detail
            detailLabel.font = Constants.Font.body(size: .m)
            detailLabel.textColor = Constants.Color.LabelPrimary
            containerView.addSubview(detailLabel)
            detailLabel.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceHuge)
                make.top.equalTo(titleLabel.snp.bottom).offset(Constants.Size.ContentSpaceMin)
            }
            
            let gameListView = GameSaveMatchGameView(frame: .zero, games: showGames)
            gameListView.didSelected = { [weak sheet] game in
                func copyGameSave() {
                    try? FileManager.safeCopyItem(at: gameSaveUrl, to: game.gameSaveUrl, shouldReplace: true)
                    SyncManager.upload(localFilePath: game.gameSaveUrl.path)
                    sheet?.pop(completon: completion)
                    UIView.makeToast(message: R.string.localizable.importGameSaveSuccessTitle())
                }
                
                if game.isSaveExtsts {
                    UIView.makeAlert(title: R.string.localizable.gameSaveAlreadyExistTitle(),
                                     detail: R.string.localizable.filesImporterErrorSaveAlreadyExist(gameSaveUrl.lastPathComponent),
                                     confirmTitle: R.string.localizable.confirmTitle(),
                                     enableForceHide: false,
                                     confirmAction: {
                        copyGameSave()
                    })
                } else {
                    copyGameSave()
                }
            }
            containerView.addSubview(gameListView)
            gameListView.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(detailLabel.snp.bottom).offset(Constants.Size.ContentSpaceMin)
                make.height.equalTo(Constants.Size.WindowHeight/2)
            }
            
            let cancelLabel = UILabel()
            cancelLabel.isUserInteractionEnabled = true
            cancelLabel.enableInteractive = true
            cancelLabel.text = cancelTitle
            cancelLabel.textAlignment = .center
            cancelLabel.font = Constants.Font.title(size: .s, weight: .regular)
            cancelLabel.textColor = Constants.Color.LabelSecondary
            containerView.addSubview(cancelLabel)
            cancelLabel.snp.makeConstraints { make in
                make.height.equalTo(Constants.Size.ItemHeightMid)
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(gameListView.snp.bottom)
                make.bottom.equalToSuperview().offset(-Constants.Size.ContentInsetBottom)
            }
            cancelLabel.addTapGesture { [weak sheet] gesture in
                sheet?.pop(completon: completion)
            }
            
            sheet.set(customView: view).snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
    
    static func show(showGames: [Game]? = nil, title: String, detail: String, cancelTitle: String, completion: @escaping (Game?)->Void) {
        Sheet { sheet in
            sheet.contentMaskView.alpha = 0
            sheet.config.windowEdgeInset = 0
            sheet.onTappedBackground { sheet in }
            sheet.config.backgroundViewMask { mask in
                mask.backgroundColor = .black.withAlphaComponent(0.2)
            }
            
            let view = UIView()
            let grabber = UIImageView(image: R.image.grabber_icon())
            grabber.isUserInteractionEnabled = true
            grabber.contentMode = .center
            view.addPanGesture { [weak view, weak sheet] gesture in
                guard let view = view, let sheet = sheet else { return }
                let point = gesture.translation(in: gesture.view)
                view.transform = .init(translationX: 0, y: point.y <= 0 ? 0 : point.y)
                if gesture.state == .recognized {
                    let v = gesture.velocity(in: gesture.view)
                    if (view.y > view.height*2/3 && v.y > 0) || v.y > 1200 {
                        // 达到移除的速度
                        sheet.pop {
                            completion(nil)
                        }
                    }
                    UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.5, options: [.allowUserInteraction, .curveEaseOut], animations: {
                        view.transform = .identity
                    })
                }
            }
            view.addSubview(grabber)
            grabber.snp.makeConstraints { make in
                make.leading.top.trailing.equalToSuperview()
                make.height.equalTo(Constants.Size.ContentSpaceTiny*3)
            }
            
            let containerView = RoundAndBorderView(roundCorner: (UIDevice.isPad || UIDevice.isLandscape) ? .allCorners : [.topLeft, .topRight])
            containerView.backgroundColor = Constants.Color.Background
            containerView.makeBlur()
            view.addSubview(containerView)
            containerView.snp.makeConstraints { make in
                make.top.equalTo(grabber.snp.bottom)
                make.leading.bottom.trailing.equalToSuperview()
            }
            
            let titleLabel = UILabel()
            titleLabel.textAlignment = .center
            titleLabel.text = title
            titleLabel.font = Constants.Font.title(size: .s, weight: .semibold)
            titleLabel.textColor = Constants.Color.LabelPrimary
            containerView.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview().offset(30)
            }
            
            let detailLabel = UILabel()
            detailLabel.numberOfLines = 0
            detailLabel.textAlignment = .center
            detailLabel.text = detail
            detailLabel.font = Constants.Font.body(size: .m)
            detailLabel.textColor = Constants.Color.LabelPrimary
            containerView.addSubview(detailLabel)
            detailLabel.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceHuge)
                make.top.equalTo(titleLabel.snp.bottom).offset(Constants.Size.ContentSpaceMin)
            }
            
            let gameListView = GameSaveMatchGameView(frame: .zero, games: showGames)
            gameListView.didSelected = { [weak sheet] game in
                sheet?.pop {
                    completion(game)
                }
            }
            containerView.addSubview(gameListView)
            gameListView.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(detailLabel.snp.bottom).offset(Constants.Size.ContentSpaceMin)
                make.height.equalTo(Constants.Size.WindowHeight/2)
            }
            
            let cancelLabel = UILabel()
            cancelLabel.isUserInteractionEnabled = true
            cancelLabel.enableInteractive = true
            cancelLabel.text = cancelTitle
            cancelLabel.textAlignment = .center
            cancelLabel.font = Constants.Font.title(size: .s, weight: .regular)
            cancelLabel.textColor = Constants.Color.LabelSecondary
            containerView.addSubview(cancelLabel)
            cancelLabel.snp.makeConstraints { make in
                make.height.equalTo(Constants.Size.ItemHeightMid)
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(gameListView.snp.bottom)
                make.bottom.equalToSuperview().offset(-Constants.Size.ContentInsetBottom)
            }
            cancelLabel.addTapGesture { [weak sheet] gesture in
                sheet?.pop {
                    completion(nil)
                }
            }
            
            sheet.set(customView: view).snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
    
    var didSelected: ((_ game: Game)->Void)? = nil
    
    private lazy var collectionView: BlankSlateCollectionView = {
        let view = BlankSlateCollectionView(frame: .zero, collectionViewLayout: createLayout())
        view.backgroundColor = Constants.Color.Background
        view.contentInsetAdjustmentBehavior = .never
        view.register(cellWithClass: GameCollectionViewCell.self)
        view.register(supplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withClass: GamesCollectionReusableView.self)
        view.showsVerticalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: Constants.Size.ContentInsetBottom, right: 0)
        return view
    }()
    
    private var normalDatas: [GameType: [Game]] = [:]
    
    private var coverSizes = [GameType: CGSize]()
    
    init(frame: CGRect, games: [Game]? = nil) {
        super.init(frame: frame)
        Log.debug("\(String(describing: Self.self)) init")
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        //更新游戏
        updateGames(games: games)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if UIDevice.isPad {
            DispatchQueue.main.asyncAfter(delay: 0.35) {
                self.collectionView.reloadData()
            }
        }
    }
    
    private func updateGames(games: [Game]? = nil) {
        if let games = games {
            updateDatas(games: games)
            if games.count > 0 {
                //更新视图
                collectionView.reloadData()
            }
        } else {
            //查询数据库
            let realm = Database.realm
            let games = realm.objects(Game.self).where { !$0.isDeleted }
            //查询结束更新数据库
            updateDatas(games: games)
            if games.count > 0 {
                //更新视图
                collectionView.reloadData()
            }
        }
    }
    
    ///构造符合UI展示的数据源
    private func updateDatas(games: Results<Game>) {
        updateDatas(games: games.map({ $0 }))
    }
    
    private func updateDatas(games: [Game]) {
        let groupGames = Dictionary(grouping: games, by: { $0.gameType })
        normalDatas = groupGames.mapValues { $0.sorted(by: { $0.name < $1.name }) } // 数据结果 [GameType: [Game]]
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout  { [weak self] sectionIndex, env in
            guard let self = self else { return nil }
            //section的边距
            let sectionInset = Constants.Size.ContentSpaceHuge
            let itemSpacing = Constants.Size.ContentSpaceMax - Constants.Size.GamesListSelectionEdge*2
            var column = 2.0
            if UIDevice.isPad {
                column = 3
            }
            let widthDimension: NSCollectionLayoutDimension = .fractionalWidth(1/column)
            //item布局
            let totleSpacing = (Constants.Size.ContentSpaceHuge-Constants.Size.GamesListSelectionEdge)*2 + itemSpacing*(column-1)//横向间距总和
            let itemEstimatedWidth = (env.container.contentSize.width - totleSpacing)/column //一个item的宽
            let gameType = self.sortDatasKeys()[sectionIndex]
            let coverWidth = itemEstimatedWidth-Constants.Size.GamesListSelectionEdge*2
            let coverHeight = coverWidth/Constants.Size.GameCoverRatio(gameType: gameType) //书籍封面的高度
            //一个item的高度 = 间距 + 封面高度 + 间距 + title高度 + 间距 + subtitle高度 + 间距
            let itemEstimatedHeight = Constants.Size.GamesListSelectionEdge + coverHeight + Constants.Size.ContentSpaceMin + Constants.Font.body().lineHeight + Constants.Size.GamesListSelectionEdge
            let coverSize = CGSize(width: coverWidth, height: coverHeight)
            if let size =  self.coverSizes[gameType] {
                //尺寸存在
                if size != coverSize {
                    self.coverSizes[gameType] = coverSize
                }
            } else {
                //尺寸不存在
                self.coverSizes[gameType] = coverSize
            }
            
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: widthDimension,
                                                                                 heightDimension: .absolute(itemEstimatedHeight)))
            //group布局
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                              heightDimension: .absolute(itemEstimatedHeight)),
                                                           subitem: item, count: Int(column))
            group.interItemSpacing = NSCollectionLayoutSpacing.fixed(itemSpacing)
            group.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                          leading: sectionInset-Constants.Size.GamesListSelectionEdge,
                                                          bottom: 0,
                                                          trailing: sectionInset-Constants.Size.GamesListSelectionEdge)
            
            //section布局
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = itemSpacing
            section.contentInsets = NSDirectionalEdgeInsets(top: Constants.Size.ContentSpaceUltraTiny,
                                                            leading: 0,
                                                            bottom: (sectionIndex != (self.normalDatas.count - 1)) ? Constants.Size.ContentSpaceHuge : 0,
                                                            trailing: 0)
            //header布局
            let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                                            heightDimension: .estimated(Constants.Size.ItemHeightMin)),
                                                                         elementKind: UICollectionView.elementKindSectionHeader,
                                                                         alignment: .top)
            headerItem.pinToVisibleBounds = true
            section.boundarySupplementaryItems = [headerItem]
            
            return section
            
        }
        return layout
    }
}

extension GameSaveMatchGameView: UICollectionViewDataSource {
    private func sortDatasKeys() -> [GameType] {
        let predefinedOrder: [GameType] = System.allCases.map { $0.gameType }
        let sortedKeys: [GameType] = predefinedOrder.filter { normalDatas.keys.contains($0) }
        return sortedKeys
    }
    
    private func getGames(at section: Int) -> [Game] {
        let gameTypes = sortDatasKeys()
        let gameType = gameTypes[section]
        if let results = normalDatas[gameType] {
            return results
        }
        return []
    }
    
    private func getGame(at indexPath: IndexPath) -> Game? {
        let games = getGames(at: indexPath.section)
        if games.count > indexPath.row {
            return games[indexPath.row]
        }
        return nil
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        normalDatas.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return getGames(at: section).count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClass: GameCollectionViewCell.self, for: indexPath)
        if let game = getGame(at: indexPath) {
            cell.setData(game: game, coverSize: coverSizes[game.gameType] ?? .zero, indexPath: indexPath)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        //header
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: GamesCollectionReusableView.self, for: indexPath)
        let gameType = sortDatasKeys()[indexPath.section]
        header.setData(gameType: gameType)
        header.skinButton.isHidden = true
        return header
    }
}

extension GameSaveMatchGameView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let game = getGame(at: indexPath) {
            didSelected?(game)
        }
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
