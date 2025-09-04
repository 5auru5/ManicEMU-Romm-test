//
//  RetroAchievementListView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/8/19.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

class RetroAchievementListView: BaseView {
    private lazy var collectionView: BlankSlateCollectionView = {
        let view = BlankSlateCollectionView(frame: .zero, collectionViewLayout: createLayout())
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.register(cellWithClass: RetroAchievementsListCell.self)
        view.showsVerticalScrollIndicator = false
        view.dataSource = self
        var bottomInset = Constants.Size.ContentInsetBottom
        if let prefferdBottomInset = self.bottomInset, bottomInset < prefferdBottomInset {
            bottomInset = prefferdBottomInset
        }
        view.contentInset = UIEdgeInsets(top: 90, left: 0, bottom: bottomInset, right: 0)
        let blankView = BlankSlateEmptyView(image: .symbolImage(.gamecontrollerFill).applySymbolConfig(size: 70, color: Constants.Color.LabelSecondary), title: R.string.localizable.achievementsNotSupport(game.aliasName ?? game.name))
        blankView.label.isHidden = true
        view.blankSlateView = blankView
        
        return view
    }()
    
    private var game: Game
    private var cheevosGame: CheevosGame? = nil
    private var bottomInset: CGFloat? = nil
    
    init(game: Game, bottomInset: CGFloat? = nil) {
        self.game = game
        super.init(frame: .zero)
        self.bottomInset = bottomInset
        backgroundColor = .clear
        
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        UIView.makeLoading()
        CheevosBridge.getCheevosGameInfo(game.romUrl.path) { [weak self] result, cheevosGame in
            guard let self else { return }
            UIView.hideLoading()
            self.cheevosGame = cheevosGame
            self.collectionView.reloadData()
            if self.cheevosGame == nil, let blankView = self.collectionView.blankSlateView as? BlankSlateEmptyView {
                blankView.label.isHidden = false
                if result == GetGameInfoResult.noLoaded {
                    //游戏不支持RetroAchievements
                    blankView.label.text = R.string.localizable.achievementsNotSupport(self.game.aliasName ?? self.game.name)
                } else if result == GetGameInfoResult.noLogin {
                    //登录失效
                    blankView.label.text = R.string.localizable.achievementsLoginFail()
                } else if result == GetGameInfoResult.serverError {
                    //服务器错误
                    blankView.label.text = R.string.localizable.achievementsServerError()
                } else if result == GetGameInfoResult.unknown {
                    //未知错误
                    blankView.label.text = R.string.localizable.errorUnknown()
                }
                
                if let _ = AchievementsUser.getUser(),
                    result != GetGameInfoResult.serverError,
                   self.game.getExtraBool(key: ExtraKey.enableAchievements.rawValue) ?? false {
                    //获取数据失败，但是当前游戏启用了RetroAchievements，对用户进行询问是否需要关闭
                    UIView.makeAlert(detail: R.string.localizable.achievementsDataLoadFail() + "\n" + R.string.localizable.disableAchievementsAlert(),
                                     confirmTitle: R.string.localizable.confirmTitle(),
                                     confirmAction: {
                        if PlayViewController.isGaming {
                            UIView.makeAlert(detail: R.string.localizable.toggleAchievementsAlert(),
                                             confirmTitle: R.string.localizable.confirmTitle(),
                                             confirmAction: {
                                self.game.updateExtra(key: ExtraKey.enableAchievements.rawValue, value: false)
                                NotificationCenter.default.post(name: Constants.NotificationName.QuitGaming, object: nil)
                            })
                        } else {
                            self.game.updateExtra(key: ExtraKey.enableAchievements.rawValue, value: false)
                        }
                    })
                }
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, env in
            //item布局
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                 heightDimension: .fractionalHeight(1)))
            //group布局
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(978)), subitems: [item])
            group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            //section布局
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            
            return section
        }
        return layout
    }
}

extension RetroAchievementListView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cheevosGame == nil ? 0 : 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClass: RetroAchievementsListCell.self, for: indexPath)
        cell.setDatas(game: game, retroGame: cheevosGame)
        cell.enableSwitchButton.onChange { [weak self] value in
            guard let self else { return }
            if PlayViewController.isGaming {
                UIView.makeAlert(detail: R.string.localizable.toggleAchievementsAlert(),
                                 confirmTitle: R.string.localizable.confirmTitle(),
                                 enableForceHide: false, cancelAction: {
                    self.collectionView.reloadData()
                }, confirmAction: {
                    self.game.updateExtra(key: ExtraKey.enableAchievements.rawValue, value: value)
                    NotificationCenter.default.post(name: Constants.NotificationName.QuitGaming, object: nil)
                })
            } else {
                self.game.updateExtra(key: ExtraKey.enableAchievements.rawValue, value: value)
            }
        }
        cell.hardcoreSwitchButton.onChange { [weak self] value in
            guard let self else { return }
            if PlayViewController.isGaming {
                //游戏中
                let enableAchievements = self.game.getExtraBool(key: ExtraKey.enableAchievements.rawValue) ?? false
                if value {
                    //开启硬核
                    if enableAchievements {
                        //从软核切换到硬核 需要重置游戏
                        UIView.makeAlert(detail: R.string.localizable.toggleHardcoreAlert(),
                                         confirmTitle: R.string.localizable.confirmTitle(),
                                         enableForceHide: false, cancelAction: {
                            self.collectionView.reloadData()
                        }, confirmAction: {
                            self.game.updateExtra(key: ExtraKey.achievementsHardcore.rawValue, value: value)
                            NotificationCenter.default.post(name: Constants.NotificationName.QuitGaming, object: nil)
                        })
                    } else {
                        //未启用RetroAchievements
                        UIView.makeAlert(detail: R.string.localizable.toggleAchievementsAlert(),
                                         confirmTitle: R.string.localizable.confirmTitle(),
                                         enableForceHide: false, cancelAction: {
                            self.collectionView.reloadData()
                        }, confirmAction: {
                            self.game.updateExtra(key: ExtraKey.enableAchievements.rawValue, value: value)
                            NotificationCenter.default.post(name: Constants.NotificationName.QuitGaming, object: nil)
                        })
                    }
                } else {
                    //关闭硬核
                    self.game.updateExtra(key: ExtraKey.achievementsHardcore.rawValue, value: value)
                    NotificationCenter.default.post(name: Constants.NotificationName.TurnOffHardcore, object: nil)
                }
            } else {
                self.game.updateExtra(key: ExtraKey.achievementsHardcore.rawValue, value: value)
                let enableAchievements = self.game.getExtraBool(key: ExtraKey.enableAchievements.rawValue) ?? false
                if !enableAchievements, value {
                    self.game.updateExtra(key: ExtraKey.enableAchievements.rawValue, value: true)
                    self.collectionView.reloadData()
                }
            }
        }
        return cell
    }
}
