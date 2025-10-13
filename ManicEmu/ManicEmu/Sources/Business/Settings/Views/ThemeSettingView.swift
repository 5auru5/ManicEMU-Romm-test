//
//  ThemeSettingView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/5/3.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit
import RealmSwift

class ThemeSettingView: BaseView {
    
    private enum SectionIndex: Int, CaseIterable {
        case desktopIcon, themeColor, coverStyle, gameList, platformOrder
        var title: String {
            switch self {
            case .desktopIcon:
                R.string.localizable.themeDesktopIconTitle()
            case .themeColor:
                R.string.localizable.themeThemeColorTitle()
            case .coverStyle:
                R.string.localizable.themeCoverStyleTitle()
            case .gameList:
                R.string.localizable.gamesThemeTitle()
            case .platformOrder:
                R.string.localizable.themePlatformOrderTitle()
            }
        }
    }
    
    private var topBlurView: UIView = {
        let view = UIView()
        view.makeBlur()
        return view
    }()
    
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.register(cellWithClass: DesktopIconCollectionViewCell.self)
        view.register(cellWithClass: ThemeColorCollectionViewCell.self)
        view.register(cellWithClass: CoverStyleCollectionViewCell.self)
        view.register(cellWithClass: GameListStyleCollectionViewCell.self)
        view.register(cellWithClass: PlatformSortCollectionViewCell.self)
        view.register(supplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withClass: BackgroundColorHaderReusableView.self)
        view.showsVerticalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.dragInteractionEnabled = true
        view.dragDelegate = self
        view.dropDelegate = self
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
    
    private var platformOrder: [String] = {
        return Theme.defalut.platformOrder.map { $0 }
    }()
    
    ///点击关闭按钮回调
    var didTapClose: (()->Void)? = nil
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
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
        
        let icon = UIImageView(image: UIImage(symbol: .paintpaletteFill))
        topBlurView.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
            make.size.equalTo(Constants.Size.IconSizeMin)
            make.centerY.equalToSuperview()
        }
        let headerTitleLabel = UILabel()
        headerTitleLabel.text = R.string.localizable.themeSettingTitle()
        headerTitleLabel.textColor = Constants.Color.LabelPrimary
        headerTitleLabel.font = Constants.Font.title(size: .s)
        topBlurView.addSubview(headerTitleLabel)
        headerTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
            make.centerY.equalTo(icon)
        }
        
        if UIDevice.isPhone {
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
        let layout = UICollectionViewCompositionalLayout { sectionIndex, env in
            //item布局
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                 heightDimension: .fractionalHeight(1)))
            
            var itemHeight: CGFloat = 0
            if sectionIndex == SectionIndex.desktopIcon.rawValue {
                itemHeight = 130
            } else if sectionIndex == SectionIndex.themeColor.rawValue {
                itemHeight = 100
            } else if sectionIndex == SectionIndex.coverStyle.rawValue {
                itemHeight = 370 + 76
            }  else if sectionIndex == SectionIndex.gameList.rawValue {
                itemHeight = 205 + 76 + 220
            }  else if sectionIndex == SectionIndex.platformOrder.rawValue {
                itemHeight = 50
            }
            
            //group布局
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(itemHeight)), subitems: [item])
            if sectionIndex == SectionIndex.platformOrder.rawValue {
                group.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                                leading: Constants.Size.ContentSpaceMid * 2,
                                                                bottom: 0,
                                                                trailing: Constants.Size.ContentSpaceMid * 2)
            } else {
                group.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                                leading: Constants.Size.ContentSpaceMid,
                                                                bottom: 0,
                                                                trailing: Constants.Size.ContentSpaceMid)
            }
            
            //section布局
            let section = NSCollectionLayoutSection(group: group)
            if sectionIndex == SectionIndex.platformOrder.rawValue {
                section.interGroupSpacing = Constants.Size.ContentSpaceMax
                section.contentInsets = NSDirectionalEdgeInsets(top: Constants.Size.ContentSpaceMax + Constants.Size.ContentSpaceHuge, leading: 0, bottom: Constants.Size.ContentSpaceMax, trailing: 0)
            } else {
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: Constants.Size.ContentSpaceMin, trailing: 0)
            }
            
            //header布局
            let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                                            heightDimension: .absolute(44)),
                                                                         elementKind: UICollectionView.elementKindSectionHeader,
                                                                         alignment: .top)
            headerItem.pinToVisibleBounds = true
            section.boundarySupplementaryItems = [headerItem]
            
            if sectionIndex == SectionIndex.platformOrder.rawValue {
                section.decorationItems = [NSCollectionLayoutDecorationItem.background(elementKind: String(describing: PlatformOrderCollectionReusableView.self))]
            }
            
            
            return section
        }
        layout.register(PlatformOrderCollectionReusableView.self, forDecorationViewOfKind: String(describing: PlatformOrderCollectionReusableView.self))
        return layout
    }
    
    class PlatformOrderCollectionReusableView: UICollectionReusableView {
        var descLabel: UILabel = {
            let label = UILabel()
            label.font = Constants.Font.caption()
            label.textColor = Constants.Color.LabelSecondary
            label.text = R.string.localizable.themePlatformOrderDetail()
            return label
        }()
        
        var backgroundView: UIView = {
            let view = UIView()
            view.layerCornerRadius = Constants.Size.CornerRadiusMax
            view.backgroundColor = Constants.Color.BackgroundPrimary
            return view
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            addSubview(descLabel)
            descLabel.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMax)
                make.top.equalToSuperview().offset(Constants.Size.ItemHeightMin)
            }
            
            addSubview(backgroundView)
            backgroundView.snp.makeConstraints { make in
                make.top.equalTo(descLabel.snp.bottom).offset(Constants.Size.ContentSpaceMin)
                make.bottom.equalToSuperview()
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

extension ThemeSettingView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return SectionIndex.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let section = SectionIndex(rawValue: section) {
            if section == .platformOrder {
                return platformOrder.count
            }
        }
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = SectionIndex(rawValue: indexPath.section)!
        switch section {
        case .desktopIcon:
            let cell = collectionView.dequeueReusableCell(withClass: DesktopIconCollectionViewCell.self, for: indexPath)
            return cell
        case .themeColor:
            let cell = collectionView.dequeueReusableCell(withClass: ThemeColorCollectionViewCell.self, for: indexPath)
            return cell
        case .coverStyle:
            let cell = collectionView.dequeueReusableCell(withClass: CoverStyleCollectionViewCell.self, for: indexPath)
            return cell
        case .gameList:
            let cell = collectionView.dequeueReusableCell(withClass: GameListStyleCollectionViewCell.self, for: indexPath)
            return cell
        case .platformOrder:
            let platform = platformOrder[indexPath.row]
            let cell = collectionView.dequeueReusableCell(withClass: PlatformSortCollectionViewCell.self, for: indexPath)
            cell.setData(platform: platform)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: BackgroundColorHaderReusableView.self, for: indexPath)
        let section = SectionIndex(rawValue: indexPath.section)!
        header.titleLabel.text = section.title
        return header
    }
}

extension ThemeSettingView: UICollectionViewDelegate {
    
}

extension ThemeSettingView: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: any UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard indexPath.section == SectionIndex.platformOrder.rawValue else { return [] }
        let pf = platformOrder[indexPath.row]
        let itemProvider = NSItemProvider(object: pf as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = pf
        return [dragItem]
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath,
              destinationIndexPath.section == SectionIndex.platformOrder.rawValue else { return }
        
        coordinator.items.forEach { dropItem in
            guard let sourceIndexPath = dropItem.sourceIndexPath,
                  sourceIndexPath.section == SectionIndex.platformOrder.rawValue,
                  let console = dropItem.dragItem.localObject as? String else { return }
            
            collectionView.performBatchUpdates({
                platformOrder.remove(at: sourceIndexPath.item)
                platformOrder.insert(console, at: destinationIndexPath.item)
                collectionView.deleteItems(at: [sourceIndexPath])
                collectionView.insertItems(at: [destinationIndexPath])
            }) { [weak self] isSuccess in
                if isSuccess {
                    self?.updatePlatformOrder()
                }
            }
            
            coordinator.drop(dropItem.dragItem, toItemAt: destinationIndexPath)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        canHandle session: UIDropSession) -> Bool {
        return session.localDragSession != nil
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        dropSessionDidUpdate session: UIDropSession,
                        withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard let indexPath = destinationIndexPath, indexPath.section == SectionIndex.platformOrder.rawValue else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
    
    private func updatePlatformOrder() {
        let theme = Theme.defalut
        guard theme.platformOrder.map({ $0 }) != platformOrder else { return }
        Theme.change { realm in
            theme.platformOrder.removeAll()
            theme.platformOrder.append(objectsIn: platformOrder)
        }
    }
}
