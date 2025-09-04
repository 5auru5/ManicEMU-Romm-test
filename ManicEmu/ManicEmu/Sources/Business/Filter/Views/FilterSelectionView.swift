//
//  FilterSelectionView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/3/7.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit
import ManicEmuCore

import RealmSwift
import BetterSegmentedControl
import UniformTypeIdentifiers
import ProHUD

class FilterSelectionView: BaseView {
    /// 充当导航条
    private var navigationBlurView: UIView = {
        let view = UIView()
        view.makeBlur()
        return view
    }()
    
    private var howToFetchButton: HowToButton = {
        let view = HowToButton(title: R.string.localizable.howToFetch()) {
            topViewController()?.present(WebViewController(url: Constants.URLs.GameImportGuide), animated: true)
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
    
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.register(cellWithClass: FilterCollectionViewCell.self)
        view.register(cellWithClass: FilterNameOnlyCollectionCell.self)
        view.showsVerticalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.allowsSelection = true
        view.allowsMultipleSelection = false
        view.contentInset = UIEdgeInsets(top: Constants.Size.ItemHeightMid + Constants.Size.ContentSpaceMax, left: 0, bottom: Constants.Size.ContentInsetBottom, right: 0)
        return view
    }()

    ///游戏
    private var game: Game
    private var snapshot: UIImage
    ///数据源
    private var filters = [CIFilter]() {
        didSet {
            self.collectionView.reloadData()
        }
    }
    
    //当前选中的滤镜
    private var currentSelected: CIFilter = OriginFilter()
    
    ///点击关闭按钮回调
    var didTapClose: (()->Void)? = nil
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
    }
    
    init(game: Game, snapshot: UIImage?) {
        self.game = game
        self.snapshot = snapshot ?? UIImage.placeHolder(preferenceSize: game.gameType.manicEmuCore?.videoFormat.dimensions ?? .zero)
        super.init(frame: .zero)
        Log.debug("\(String(describing: Self.self)) init")
        
        if !game.gameType.isLibretroType {
            UIView.makeLoading()
        }
        
        if game.gameType.isLibretroType {
            FilterManager.allLibretroPreviews(origin: self.snapshot, isGlsl: game.gameType == .n64 ? true : false) { [weak self] results in
                if !game.gameType.isLibretroType {
                    UIView.hideLoading()
                }
                
                guard let self = self else { return }
                self.filters = results
                if let filterName = self.game.filterName?.deletingPathExtension.lastPathComponent, let filter = self.filters.first(where: { $0.name == filterName }) {
                    self.currentSelected = filter
                }
                for (index, filter) in self.filters.enumerated() {
                    if filter.name == self.currentSelected.name {
                        collectionView.selectItem(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: [])
                        break
                    }
                }
            }
            
        } else {
            FilterManager.allFilters { [weak self] results in
                if !game.gameType.isLibretroType {
                    UIView.hideLoading()
                }
                guard let self = self else { return }
                self.filters = results
                if let filterName = self.game.filterName, let filter = self.filters.first(where: { $0.name == filterName }) {
                    self.currentSelected = filter
                }
                for (index, filter) in self.filters.enumerated() {
                    if filter.name == self.currentSelected.name {
                        collectionView.selectItem(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: [])
                        break
                    }
                }
            }
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
        
        let headerLabel = UILabel()
        headerLabel.font = Constants.Font.title(size: .s, weight: .bold)
        headerLabel.textColor = Constants.Color.LabelPrimary
        headerLabel.text = R.string.localizable.filterSectionHeaderTitle()
        navigationBlurView.addSubview(headerLabel)
        headerLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
        }
        
        navigationBlurView.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
            make.centerY.equalToSuperview()
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
        
        //暂时不支持导入滤镜 所以不需要教程
//        navigationBlurView.addSubview(howToFetchButton)
//        howToFetchButton.snp.makeConstraints { make in
//            make.height.equalTo(Constants.Size.ItemHeightUltraTiny)
//            make.trailing.equalTo(closeButton.snp.leading).offset(-Constants.Size.ContentSpaceMax)
//            make.centerY.equalTo(closeButton)
//        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout  { [weak self] sectionIndex, env in
            guard let self = self else { return nil }
            
            var group: NSCollectionLayoutGroup
            if self.game.gameType.isLibretroType {
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
                group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(50)), subitem: item, count: Int(1))
            } else {
                let column = 2.0
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/column), heightDimension: .fractionalHeight(1)))
                
                var gameVideoSize = self.game.gameType.manicEmuCore?.videoFormat.dimensions ?? CGSize(width: 100, height: 100)
                if self.game.gameType == .ds {
                    gameVideoSize = CGSize(width: gameVideoSize.width, height: gameVideoSize.height/2)
                }
                let screenRation = gameVideoSize.width/gameVideoSize.height
                let itemWidth = (env.container.contentSize.width - Constants.Size.ContentSpaceMid*4 - ((column-1)*Constants.Size.ContentSpaceMid))/column
                let itemHeight = itemWidth/screenRation + Constants.Size.ItemHeightMin
                
                group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(itemHeight)), subitem: item, count: Int(column))
            }
            
            
            group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: Constants.Size.ContentSpaceMid, bottom: 0, trailing: Constants.Size.ContentSpaceMid)
            group.interItemSpacing = NSCollectionLayoutSpacing.fixed(Constants.Size.ContentSpaceMid)
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = Constants.Size.ContentSpaceMid

            section.decorationItems = [NSCollectionLayoutDecorationItem.background(elementKind: String(describing: FilterDecorationCollectionReusableView.self))]
            section.contentInsets = NSDirectionalEdgeInsets(top: Constants.Size.ContentSpaceMid, leading: Constants.Size.ContentSpaceMid, bottom: Constants.Size.ContentSpaceMid, trailing: Constants.Size.ContentSpaceMid)
            
            return section
        }
        layout.register(FilterDecorationCollectionReusableView.self, forDecorationViewOfKind: String(describing: FilterDecorationCollectionReusableView.self))
        return layout
    }
    
    class FilterDecorationCollectionReusableView: UICollectionReusableView {
        var backgroundView: UIView = {
            let view = UIView()
            view.layerCornerRadius = Constants.Size.CornerRadiusMax
            view.backgroundColor = Constants.Color.BackgroundSecondary
            return view
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            addSubview(backgroundView)
            backgroundView.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}


extension FilterSelectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filters.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let filter = filters[indexPath.row]
        if game.gameType.isLibretroType {
            let cell = collectionView.dequeueReusableCell(withClass: FilterNameOnlyCollectionCell.self, for: indexPath)
            cell.setData(title: filter.name)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withClass: FilterCollectionViewCell.self, for: indexPath)
            cell.setData(image: filter.preview(image: snapshot), title: filter.name)
            return cell
        }
    }
}

extension FilterSelectionView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        if let indexPaths = collectionView.indexPathsForSelectedItems, indexPaths.contains(where: { $0 == indexPath }) {
            //不允许取消选择 只允许更换选择
            return false
        }
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        currentSelected = filters[indexPath.row]
        //如果目前已经选中该cell 则不再进行数据库更新
        if let indexPaths = collectionView.indexPathsForSelectedItems, !indexPaths.contains(where: { $0 == indexPath }) {
            if !PurchaseManager.isMember {
                topViewController()?.present(PurchaseViewController(), animated: true)
                return false
            }
            Game.change { [weak self] realm in
                guard let self = self else { return }
                if currentSelected is OriginFilter {
                    self.game.filterName = nil
                } else {
                    if self.game.gameType.isLibretroType {
                        if let filter = currentSelected as? LibretroPreViewFilter {
                            if let shaderPath = filter.shaderPath, let range = shaderPath.range(of: "shaders/") {
                                self.game.filterName = String(shaderPath[range.upperBound...])
                            } else {
                                self.game.filterName = nil
                            }
                        }
                    } else {
                        self.game.filterName = self.currentSelected.name
                    }
                }
            }
        }
        return true
    }
}

extension FilterSelectionView {
    static var isShow: Bool {
        Sheet.find(identifier: String(describing: FilterSelectionView.self)).count > 0 ? true : false
    }
    
    static func show(game: Game, snapshot: UIImage?, gameViewRect: CGRect, menuInsets: UIEdgeInsets? = nil, hideCompletion: (()->Void)? = nil, didTapClose: (()->Void)? = nil) {
        Sheet.lazyPush(identifier: String(describing: FilterSelectionView.self)) { sheet in
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
            
            let listView = FilterSelectionView(game: game, snapshot: snapshot)
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
