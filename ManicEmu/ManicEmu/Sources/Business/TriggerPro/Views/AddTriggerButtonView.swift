//
//  AddTriggerButtonView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/10/21.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import UIKit
import RealmSwift
import ManicEmuCore

class AddTriggerButtonView: BaseView {
    
    private enum SectionIndex: Int, CaseIterable {
        case style, mapping, action
        var title: String {
            switch self {
            case .style:
                R.string.localizable.buttonStyle()
            case .mapping:
                R.string.localizable.mapping()
            case .action:
                R.string.localizable.action()
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
        view.register(cellWithClass: AddTriggerButtonStyleCell.self)
        view.register(cellWithClass: AddTriggerMappingCell.self)
        view.register(cellWithClass: AddTriggerActionCell.self)
        view.register(supplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withClass: BackgroundColorHaderReusableView.self)
        view.register(supplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withClass: BackgroundColorTitleAndButtonHaderReusableView.self)
        view.register(supplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withClass: BackgroundColorTitleAndDetailHaderReusableView.self)
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
            if self.triggerItem.mappings.count == 0 {
                UIView.makeAlert(title: R.string.localizable.fatalErrorTitle(),
                                 detail: R.string.localizable.noMappingAlert(),
                                 confirmTitle: R.string.localizable.multiDiscContinueClose(),
                                 confirmAction: {
                    self.didTapClose?()
                })
                return
            }
            self.didTapClose?()
        }
        return view
    }()
    
    ///点击关闭按钮回调
    var didTapClose: (()->Void)? = nil
    
    private var triggerItem: TriggerItem
    private let gameType: GameType
    private let inputs: [String]
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
    }
    
    init(triggerItem: TriggerItem, gameType: GameType, inputs: [String]) {
        self.triggerItem = triggerItem
        self.gameType = gameType
        self.inputs = inputs
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
        
        let icon = UIImageView(image: R.image.customXmarkTriangleCircleSquare()?.applySymbolConfig(color: Constants.Color.LabelPrimary))
        topBlurView.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
            make.size.equalTo(Constants.Size.IconSizeMin)
            make.centerY.equalToSuperview()
        }
        let headerTitleLabel = UILabel()
        headerTitleLabel.text = "TriggerPro"
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
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, env in
            guard let self else { return nil }
            //item布局
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                 heightDimension: .fractionalHeight(1)))
            
            var itemHeight: CGFloat = 0
            if sectionIndex == SectionIndex.style.rawValue {
                itemHeight = self.triggerItem.style.cellHeight
            } else if sectionIndex == SectionIndex.mapping.rawValue {
                itemHeight = 72
            } else if sectionIndex == SectionIndex.action.rawValue {
                itemHeight = 222
            }
            
            //group布局
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(itemHeight)), subitems: [item])
            group.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                            leading: Constants.Size.ContentSpaceMid,
                                                            bottom: 0,
                                                            trailing: Constants.Size.ContentSpaceMid)
            
            //section布局
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: Constants.Size.ContentSpaceMin, trailing: 0)
            
            //header布局
            let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                                            heightDimension: .absolute(sectionIndex == SectionIndex.action.rawValue ? 72 : 44)),
                                                                         elementKind: UICollectionView.elementKindSectionHeader,
                                                                         alignment: .top)
            headerItem.pinToVisibleBounds = true
            section.boundarySupplementaryItems = [headerItem]
            
            return section
        }
        return layout
    }
}

extension AddTriggerButtonView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return SectionIndex.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = SectionIndex(rawValue: indexPath.section)!
        switch section {
        case .style:
            let cell = collectionView.dequeueReusableCell(withClass: AddTriggerButtonStyleCell.self, for: indexPath)
            cell.needToUpdateCellHeight = { [weak self] in
                guard let self else { return }
                self.collectionView.reloadSections(IndexSet([section.rawValue]))
            }
            cell.setData(item: triggerItem)
            return cell
        case .mapping:
            let cell = collectionView.dequeueReusableCell(withClass: AddTriggerMappingCell.self, for: indexPath)
            cell.setDatas(inputs: triggerItem.mappings.map({ $0 }))
            cell.mappingListView.didDeleteInput = { [weak self] index in
                guard let self else { return }
                if self.triggerItem.mappings.count > index {
                    self.triggerItem.mappings.remove(at: index)
                }
            }
            cell.mappingListView.didChangeInputIndex = { [weak self] fromIndex, toIndex in
                guard let self else { return }
                if self.triggerItem.mappings.count > fromIndex, self.triggerItem.mappings.count > toIndex {
                    self.triggerItem.mappings.move(from: fromIndex, to: toIndex)
                }
            }
            return cell
        case .action:
            let cell = collectionView.dequeueReusableCell(withClass: AddTriggerActionCell.self, for: indexPath)
            cell.setData(triggerItem: triggerItem)
            cell.didActionTypeChange = { [weak self] action in
                guard let self else { return }
                self.triggerItem.action = action
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let section = SectionIndex(rawValue: indexPath.section)!
        switch section {
        case .style:
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: BackgroundColorHaderReusableView.self, for: indexPath)
            let section = SectionIndex(rawValue: indexPath.section)!
            header.titleLabel.text = section.title
            return header
        case .mapping:
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: BackgroundColorTitleAndButtonHaderReusableView.self, for: indexPath)
            let section = SectionIndex(rawValue: indexPath.section)!
            header.titleLabel.text = section.title
            header.didTapButton = { [weak self] in
                guard let self else { return }
                TriggerProMappingListView.show(inputs: self.inputs, gameType: self.gameType) { [weak self] input in
                    guard let self else { return }
                    self.triggerItem.mappings.append(input)
                    self.collectionView.reloadSections(IndexSet([section.rawValue]))
                }
            }
            return header
        case .action:
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: BackgroundColorTitleAndDetailHaderReusableView.self, for: indexPath)
            let section = SectionIndex(rawValue: indexPath.section)!
            header.titleLabel.text = section.title
            header.detailLabel.text = triggerItem.action.desc
            return header
        }
        
    }
}

extension AddTriggerButtonView: UICollectionViewDelegate {
    
}
