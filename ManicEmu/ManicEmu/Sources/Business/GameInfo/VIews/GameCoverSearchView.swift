//
//  GameCoverSearchView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/5/9.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit
import ManicEmuCore
import Kingfisher

class GameCoverSearchView: BaseView {
    static var GameCoverHeight: CGFloat = 0
    
    private var topBlurView: UIView = {
        let view = UIView()
        view.makeBlur()
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
    
    private var textField: UITextField = {
        let view = UITextField()
        view.textColor = Constants.Color.LabelPrimary
        view.font = Constants.Font.body(size: .l)
        view.clearButtonMode = .whileEditing
        view.returnKeyType = .search
        view.attributedPlaceholder = NSAttributedString(string: R.string.localizable.gamesSearchPlaceHolder(), attributes: [.font: Constants.Font.body(size: .l), .foregroundColor: Constants.Color.LabelSecondary])
        return view
    }()
    
    lazy var collectionView: BlankSlateCollectionView = {
        let view = BlankSlateCollectionView(frame: .zero, collectionViewLayout: createLayout())
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.register(cellWithClass: GameCollectionViewCell.self)
        view.showsVerticalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.allowsMultipleSelection = true
        view.contentInset = UIEdgeInsets(top: Constants.Size.ItemHeightMid + Constants.Size.ItemHeightMin + Constants.Size.ContentSpaceMin, left: 0, bottom: Constants.Size.ContentInsetBottom, right: 0)
        view.blankSlateView = BlankSlateEmptyView(title: R.string.localizable.noGameCoverResult())
        return view
    }()

    private var datas = [Game]()
    
    private var coverSizes = [GameType: CGSize]()
    
    ///点击关闭按钮回调
    var didTapClose: (()->Void)? = nil
    
    var didSelectIamge: ((UIImage?)->Void)? = nil
    
    var game: Game
    
    init(game: Game) {
        self.game = game
        super.init(frame: .zero)
        Log.debug("\(String(describing: Self.self)) init")
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(topBlurView)
        topBlurView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(Constants.Size.ItemHeightMid + Constants.Size.ItemHeightMin + Constants.Size.ContentSpaceMin )
        }
        
        topBlurView.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
            make.top.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
        
        let textFieldContainer = RoundAndBorderView(roundCorner: .allCorners, radius: Constants.Size.CornerRadiusMid)
        textFieldContainer.backgroundColor = Constants.Color.BackgroundSecondary
        topBlurView.addSubview(textFieldContainer)
        textFieldContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Constants.Size.ItemHeightMid)
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMax)
            make.height.equalTo(Constants.Size.ItemHeightMin)
        }
        
        textFieldContainer.addSubview(textField)
        textField.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
        }
        textField.onReturnKeyPress { [weak self] in
            guard let self = self else { return }
            self.textField.resignFirstResponder()
            if let text = self.textField.text?.trimmed, !PurchaseManager.isMember, !text.isEnglishLanguage() {
                UIView.makeAlert(identifier: Constants.Strings.PlayPurchaseAlertIdentifier,
                                 detail: R.string.localizable.aiCoverSearchDesc(),
                                 confirmTitle: R.string.localizable.goToUpgrade(),
                                 confirmAutoHide: false,
                                 confirmAction: {
                    topViewController()?.present(PurchaseViewController(), animated: true)
                })
            } else {
                self.searchCover(text: self.textField.text)
            }
        }
        
        DispatchQueue.main.asyncAfter(delay: 1) {
            self.textField.text = game.aliasName ?? game.name
            self.textField.becomeFirstResponder()
        }
    }
    
    private func searchCover(text: String?) {
        if let text = text?.trimmed {
            UIView.makeLoading()
            OnlineCoverManager.MatchOperation.searchCovers(coverMatch: OnlineCoverManager.CoverMatch(gameType: self.game.gameType,
                                                                                                     gameID: self.game.id,
                                                                                                     gameName: text,
                                                                                                     fileExtension: self.game.fileExtension),
                                                           persistentedTranslation: false,
                                                           isCallBackMain: true) { [weak self] urls, _ in
                UIView.hideLoading()
                guard let self = self else { return }
                let games = urls.map {
                    let game = Game()
                    game.name = $0.lastPathComponent.deletingPathExtension
                    game.gameType = self.game.gameType
                    game.fileExtension = self.game.fileExtension
                    game.onlineCoverUrl = $0.absoluteString
                    return game
                }
                
                self.datas = games
                self.collectionView.reloadData()
                self.collectionView.scrollToTop()
            }
        } else {
            self.datas = []
            self.collectionView.reloadData()
            self.collectionView.scrollToTop()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout  { [weak self] sectionIndex, env in
            guard let self = self else { return nil }
            //section的边距
            let sectionInset = Constants.Size.ContentSpaceHuge
            let itemSpacing = Constants.Size.ContentSpaceMax - Constants.Size.GamesListSelectionEdge*2
            let column = 2.0
            let widthDimension: NSCollectionLayoutDimension = .fractionalWidth(1/column)
            //item布局
            let totleSpacing = (Constants.Size.ContentSpaceHuge-Constants.Size.GamesListSelectionEdge)*2 + itemSpacing*(column-1)//横向间距总和
            let itemEstimatedWidth = (env.container.contentSize.width - totleSpacing)/column //一个item的宽
            let coverWidth = itemEstimatedWidth-Constants.Size.GamesListSelectionEdge*2
            let coverHeight = (itemEstimatedWidth-Constants.Size.GamesListSelectionEdge*2)/Constants.Size.GameCoverRatio(gameType: self.game.gameType) //书籍封面的高度
            //一个item的高度 = 间距 + 封面高度 + 间距 + title高度 + 间距 + subtitle高度 + 间距
            let itemEstimatedHeight = Constants.Size.GamesListSelectionEdge + coverHeight + Constants.Size.ContentSpaceMin + Constants.Font.body().lineHeight + Constants.Size.GamesListSelectionEdge
            let coverSize = CGSize(width: coverWidth, height: coverHeight)
            if let size =  self.coverSizes[self.game.gameType] {
                //尺寸存在
                if size != coverSize {
                    self.coverSizes[self.game.gameType] = coverSize
                }
            } else {
                //尺寸不存在
                self.coverSizes[self.game.gameType] = coverSize
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
                                                            bottom: 0,
                                                            trailing: 0)
            return section
            
        }
        return layout
    }
}

extension GameCoverSearchView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return datas.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClass: GameCollectionViewCell.self, for: indexPath)
        let game = datas[indexPath.row]
        cell.setData(game: game, coverSize: coverSizes[game.gameType] ?? .zero, indexPath: indexPath)
        return cell
    }
}

extension GameCoverSearchView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let game = self.datas[indexPath.row]
        if let url = URL(string: game.onlineCoverUrl) {
            KingfisherManager.shared.retrieveImage(with: url) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let imageResult):
                    ImageFetcher.edit(image: imageResult.image) { [weak self] image in
                        guard let self = self else { return }
                        Task { @MainActor in
                            self.didSelectIamge?(image)
                        }
                    }
                case .failure(_):
                    Task { @MainActor in
                        UIView.makeToast(message: R.string.localizable.onlineCoverFetchFailed())
                    }
                }
            }
        } else {
            UIView.makeToast(message: R.string.localizable.onlineCoverFetchFailed())
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        textField.resignFirstResponder()
    }
}
