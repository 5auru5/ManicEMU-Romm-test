//
//  OnlinePlaySettingView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/7/16.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit
import ManicEmuCore

class OnlinePlaySettingView: BaseView {
    
    class HaderReusableView: UICollectionReusableView {
        var titleLabel: UILabel = {
            let view = UILabel()
            view.textColor = Constants.Color.LabelSecondary
            view.font = Constants.Font.body(size: .s, weight: .semibold)
            return view
        }()
        
        var button: SymbolButton = {
            let view = SymbolButton(image: R.image.customArrowTrianglehead2Clockwise()?.applySymbolConfig(font: Constants.Font.body(size: .s, weight: .semibold), color: Constants.Color.LabelSecondary))
            view.enableRoundCorner = true
            view.backgroundColor = Constants.Color.Background
            return view
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubviews([titleLabel, button])
            makeBlur()
            
            titleLabel.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
            }
            
            button.snp.makeConstraints { make in
                make.centerY.equalTo(titleLabel)
                make.leading.equalTo(titleLabel.snp.trailing)
                make.size.equalTo(Constants.Size.ItemHeightTiny)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
            
    }
    
    private enum SectionIndex: Int, CaseIterable {
        case desc, ds
        var title: String {
            switch self {
            case .desc: ""
            case .ds: "Nintendo WFC"
            }
        }
        
        var gameType: GameType {
            switch self {
            case .desc: return .notSupport
            case .ds: return .ds
            }
        }
    }
    
    private let datas: [SectionIndex]
    private lazy var wfcs: [WFC] = {
        return WFC.getList()
    }()
    
    private var topBlurView: UIView = {
        let view = UIView()
        view.makeBlur()
        return view
    }()
    
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.register(cellWithClass: DSOnlinePlaySettingCell.self)
        view.register(cellWithClass: SettingDescriptionCollectionViewCell.self)
        view.register(supplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withClass: HaderReusableView.self)
        view.showsVerticalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.contentInset = UIEdgeInsets(top: Constants.Size.ItemHeightMid, left: 0, bottom: UIDevice.isPad ? (Constants.Size.ContentInsetBottom + Constants.Size.HomeTabBarSize.height + Constants.Size.ContentSpaceMax) : Constants.Size.ContentInsetBottom, right: 0)
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
    
    ///点击关闭按钮回调
    var didTapClose: (()->Void)? = nil
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
    }
    
    init(gameType: GameType? = nil, showClose: Bool = true) {
        if let gameType, gameType == .ds {
            self.datas = [.desc, .ds]
        } else {
            self.datas = [.desc, .ds]
        }
        super.init(frame: .zero)
        Log.debug("\(String(describing: Self.self)) init")
        backgroundColor = Constants.Color.Background
        
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(topBlurView)
        topBlurView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(Constants.Size.ItemHeightMid)
        }
        
        let icon = UIImageView(image: UIImage(symbol: .person2Wave2, font: Constants.Font.body(weight: .bold)))
        icon.contentMode = .scaleAspectFit
        topBlurView.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
            make.size.equalTo(Constants.Size.IconSizeMin)
            make.centerY.equalToSuperview()
        }
        let headerTitleLabel = UILabel()
        headerTitleLabel.text = R.string.localizable.onlinePlaySetting()
        headerTitleLabel.textColor = Constants.Color.LabelPrimary
        headerTitleLabel.font = Constants.Font.title(size: .s)
        topBlurView.addSubview(headerTitleLabel)
        headerTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
            make.centerY.equalTo(icon)
        }
        
        if showClose {
            topBlurView.addSubview(closeButton)
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
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, env in
            guard let self else { return nil }
            //item布局
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                 heightDimension: .fractionalHeight(1)))
            
            
            let sectionType = self.datas[sectionIndex]
            var itemHeight: CGFloat = 0
            switch sectionType {
            case .desc:
                itemHeight = 120
            case .ds:
                itemHeight = DSOnlinePlaySettingCell.CellHeight(wfcCount: self.wfcs.count)
            }
            
            //group布局
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: sectionType == .desc ? .estimated(itemHeight) : .absolute(itemHeight)), subitems: [item])
            group.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                            leading: Constants.Size.ContentSpaceMid,
                                                            bottom: 0,
                                                            trailing: Constants.Size.ContentSpaceMid)
            
            //section布局
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: Constants.Size.ContentSpaceMin, trailing: 0)
            
            if sectionType != .desc {
                //header布局
                let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                                                heightDimension: .absolute(44)),
                                                                             elementKind: UICollectionView.elementKindSectionHeader,
                                                                             alignment: .top)
                headerItem.pinToVisibleBounds = true
                section.boundarySupplementaryItems = [headerItem]
            }
            
            return section
        }
        return layout
    }
}

extension OnlinePlaySettingView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return datas.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = datas[indexPath.section]
        switch section {
        case .desc:
            let cell = collectionView.dequeueReusableCell(withClass: SettingDescriptionCollectionViewCell.self, for: indexPath)
            cell.descLabel.text = R.string.localizable.onlinePlaySettingDesc()
            return cell
        case .ds:
            let cell = collectionView.dequeueReusableCell(withClass: DSOnlinePlaySettingCell.self, for: indexPath)
            cell.setData(wfcs: wfcs) { [weak self] index in
                guard let self else { return }
                self.wfcs = WFC.selectWFC(self.wfcs[index])
                self.collectionView.reloadData()
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: HaderReusableView.self, for: indexPath)
        let section = datas[indexPath.section]
        header.titleLabel.text = section.title
        header.button.addTapGesture { [weak self] gesture in
            guard let self else { return }
            UIView.makeLoading()
            WFC.refreshList { [weak self] wfs in
                UIView.hideLoading()
                guard let self else { return }
                self.wfcs = wfs
                self.collectionView.reloadData()
            }
        }
        return header
    }
}

extension OnlinePlaySettingView: UICollectionViewDelegate {
    
}
