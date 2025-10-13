//
//  PlayHistoryView.swift
//  ManicEmu
//
//  Created by Max on 2025/1/24.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit
import RealmSwift
import UniformTypeIdentifiers
import VisualEffectView

class PlayHistoryView: BaseView {
    
    private var topBlurView: UIView = {
        let view = UIView()
        if UIDevice.isPad {
            view.backgroundColor = UIColor(.dm, light: .white, dark: .black)
        } else {
            view.makeBlur(blurColor: UIColor(.dm, light: .white, dark: .black))
        }
        return view
    }()
    
    private lazy var collectionView: UICollectionView = {
        let view = BlankSlateCollectionView(frame: .zero, collectionViewLayout: createLayout())
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.register(cellWithClass: PlayHistoryFavouriteCollectionCell.self)
        view.register(cellWithClass: PlayHistoryItemCollectionCell.self)
        view.showsVerticalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.contentInset = UIEdgeInsets(top: Constants.Size.ContentInsetTop + Constants.Size.ItemHeightMid, left: 0, bottom: Constants.Size.ContentInsetBottom, right: 0)
        view.blankSlateView = PlayHistoryBlankSlateView(tapAction: { [weak self] type in
            guard let self = self else { return }
            if type == .importGame {
                FilesImporter.shared.presentImportController(supportedTypes: UTType.gameTypes)
            } else if type == .startGame {
                self.needToHideSideMenu?()
            }
        })
        return view
    }()
    
    
    private var histories: [Game] = []
    private var favouriteGame: Game? = nil
    var needToHideSideMenu: (()->Void)? = nil
    var didTapGame:((Game)->Void)? = nil
    var didTapGameRetro:((Game)->Void)? = nil
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        Log.debug("\(String(describing: Self.self)) init")
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(topBlurView)
        topBlurView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(Constants.Size.ContentInsetTop + Constants.Size.ItemHeightMid)
        }
        
        let headerTitleLabel = UILabel()
        headerTitleLabel.text = R.string.localizable.historyHeaderTitle()
        headerTitleLabel.textColor = Constants.Color.LabelPrimary
        headerTitleLabel.font = Constants.Font.title(size: .s)
        topBlurView.addSubview(headerTitleLabel)
        headerTitleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Constants.Size.ContentSpaceMax)
            make.top.equalToSuperview().offset(Constants.Size.ContentInsetTop)
            make.bottom.equalToSuperview()
            make.height.equalTo(Constants.Size.ItemHeightMid)
        }
        
        updateGames()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout  { sectionIndex, env in
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                 heightDimension: .fractionalHeight(1)))
            //group布局
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                              heightDimension: .absolute(sectionIndex == 0 ? 238*(UIDevice.isPad ? 0.8 : 1) : 64)),
                                                           subitems: [item])
            group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: Constants.Size.ContentSpaceMax, bottom: 0, trailing: Constants.Size.ContentSpaceMax)
            //section布局
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = Constants.Size.ContentSpaceMax
            section.contentInsets = NSDirectionalEdgeInsets(top: Constants.Size.ContentSpaceMin,
                                                            leading: 0,
                                                            bottom: 0,
                                                            trailing: 0)
            return section
            
        }
        return layout
    }
    
    private var gamesUpdateToken: NotificationToken? = nil
    private func updateGames() {
        let realm = Database.realm
        let games = realm.objects(Game.self).where { $0.totalPlayDuration > 0 && !$0.isDeleted }
        //监听数据的变化
        gamesUpdateToken = games.observe(keyPaths: [\Game.aliasName, \Game.gameCover, \Game.onlineCoverUrl, \Game.latestPlayDate, \Game.latestPlayDuration, \Game.totalPlayDuration]) { [weak self] changes in
            guard let self = self else { return }
            if case .update(_, let deletes, let insertions, let modifications) = changes {
                if !deletes.isEmpty || !insertions.isEmpty || !modifications.isEmpty {
                    Log.debug("游戏历史 游戏更新")
                    //刷新视图
                    self.updateDatas(games: games)
                }
            }
        }
        updateDatas(games: games)
    }
    
    ///构造符合UI展示的数据源
    private func updateDatas(games: Results<Game>) {
        let datas = games.sorted {
            if let date1 = $0.latestPlayDate, let date2 = $1.latestPlayDate {
                return date1 > date2
            }
            return true
        }
        histories = datas
        favouriteGame = games.sorted(by: { $0.totalPlayDuration > $1.totalPlayDuration }).first
        collectionView.reloadData()
    }
    
}

extension PlayHistoryView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return favouriteGame == nil ? 0 : 1
        } else {
            return histories.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withClass: PlayHistoryFavouriteCollectionCell.self, for: indexPath)
            cell.setData(game: favouriteGame!) { [weak self] in
                if let game = self?.favouriteGame {
                    self?.didTapGameRetro?(game)
                }
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withClass: PlayHistoryItemCollectionCell.self, for: indexPath)
            let game = histories[indexPath.row]
            cell.setData(game: game) { [weak self] in
                self?.didTapGameRetro?(game)
            }
            return cell
        }
    }
}

extension PlayHistoryView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let game = indexPath.section == 0 ? favouriteGame : histories[indexPath.row] {
            didTapGame?(game)
        }
    }
}
