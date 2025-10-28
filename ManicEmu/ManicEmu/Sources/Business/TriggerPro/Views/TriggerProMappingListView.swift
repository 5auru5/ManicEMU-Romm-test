//
//  TriggerProMappingListView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/10/22.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import ProHUD
import ManicEmuCore

class TriggerProMappingListView: UIView {
    class TriggerProMappingEditCell: UICollectionViewCell {
        let titleLabel: UILabel = {
            let view = UILabel()
            view.textColor = Constants.Color.LabelPrimary
            view.font = Constants.Font.body(size: .s)
            return view
        }()
        
        lazy var deleteButton: SymbolButton = {
            let view = SymbolButton(image: UIImage(symbol: .minusCircleFill, font: UIFont.systemFont(ofSize: 20), colors: [Constants.Color.LabelPrimary.forceStyle(.dark), Constants.Color.Red]), enableGlass: true)
            view.enableRoundCorner = true
            view.addTapGesture { [weak self] gesture in
                guard let self else { return }
                self.didDeleteItem?()
            }
            return view
        }()
        
        var didDeleteItem: (()->Void)? = nil
        
        
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear
            
            let containerView = RoundAndBorderView(roundCorner: .allCorners, radius: Constants.Size.CornerRadiusMin)
            containerView.backgroundColor = Constants.Color.BackgroundPrimary
            addSubview(containerView)
            containerView.snp.makeConstraints { make in
                make.leading.equalToSuperview()
                make.top.bottom.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
                make.height.equalTo(40)
            }
            
            containerView.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            }
            
            addSubview(deleteButton)
            deleteButton.snp.makeConstraints { make in
                make.size.equalTo(20)
                make.trailing.equalTo(containerView).offset(10)
                make.top.equalTo(containerView).offset(-10)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class TriggerProMappingNormalCell: UICollectionViewCell {
        let titleLabel: UILabel = {
            let view = UILabel()
            view.textColor = Constants.Color.LabelPrimary
            view.font = Constants.Font.body(size: .s)
            return view
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            enableInteractive = true
            delayInteractiveTouchEnd = true
            
            let containerView = RoundAndBorderView(roundCorner: .allCorners, radius: Constants.Size.CornerRadiusMin)
            containerView.backgroundColor = Constants.Color.BackgroundPrimary
            addSubview(containerView)
            containerView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                make.height.equalTo(40)
            }
            
            containerView.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class SeperatorHeader: UICollectionReusableView {
        override init(frame: CGRect) {
            super.init(frame: frame)
            let sparkleSeperatorView = SparkleSeperatorView(starSize: 16)
            addSubview(sparkleSeperatorView)
            sparkleSeperatorView.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceHuge)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.register(cellWithClass: TriggerProMappingEditCell.self)
        view.register(cellWithClass: TriggerProMappingNormalCell.self)
        view.register(supplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withClass: SeperatorHeader.self)
        view.showsVerticalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.dragInteractionEnabled = isEditMode
        view.dragDelegate = self
        view.dropDelegate = self
        view.alwaysBounceHorizontal = isEditMode ? true : false
        view.alwaysBounceVertical = isEditMode ? false : true
        return view
    }()
    
    var inputs: [[String]] {
        didSet {
            collectionView.reloadData()
        }
    }
    private var isHorizontalScroll: Bool
    private var isEditMode: Bool
    var didSelectInput: ((String)->Void)? = nil
    var didDeleteInput: ((_ index: Int)->Void)? = nil
    var didChangeInputIndex: ((_ fromIndex: Int, _ toIndex: Int)->Void)? = nil
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
    }
    
    init(inputs: [[String]], isHorizontalScroll: Bool = false, isEditMode: Bool = false) {
        self.inputs = inputs
        self.isHorizontalScroll = isHorizontalScroll
        self.isEditMode = isEditMode
        super.init(frame: .zero)
        Log.debug("\(String(describing: Self.self)) init")
        
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, env in
            guard let self else { return nil }
            if self.isEditMode {
                //item布局
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .estimated(56),
                                                                                     heightDimension: .estimated(72)))
                

                
                //group布局
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .estimated(56), heightDimension: .estimated(72)), subitems: [item])
                group.interItemSpacing = NSCollectionLayoutSpacing.fixed(0)
                group.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                              leading: 0,
                                                              bottom: 0,
                                                              trailing: 0)
                
                //section布局
                let section = NSCollectionLayoutSection(group: group)
                if self.isHorizontalScroll {
                    section.orthogonalScrollingBehavior = .continuous
                }
                section.interGroupSpacing = 0
                

                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: Constants.Size.ContentSpaceMid, bottom: 0, trailing: Constants.Size.ContentSpaceMid)
                
                return section
            } else {
                //item布局
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .estimated(40),
                                                                                     heightDimension: .estimated(40)))
                

                
                //group布局
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(40)), subitems: [item])
                group.interItemSpacing = NSCollectionLayoutSpacing.fixed(Constants.Size.ContentSpaceMin)
                group.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                              leading: Constants.Size.ContentSpaceMid,
                                                              bottom: 0,
                                                              trailing: Constants.Size.ContentSpaceMid)
                
                //section布局
                let section = NSCollectionLayoutSection(group: group)
                if self.isHorizontalScroll {
                    section.orthogonalScrollingBehavior = .continuous
                }
                section.interGroupSpacing = Constants.Size.ContentSpaceMin
                

                let isLastSection = sectionIndex == (self.inputs.count - 1)
                section.contentInsets = NSDirectionalEdgeInsets(top: sectionIndex == 0 ? Constants.Size.ContentSpaceMin : Constants.Size.ContentSpaceHuge, leading: 0, bottom: Constants.Size.ContentSpaceHuge + (isLastSection ? Constants.Size.SafeAera.bottom : 0), trailing: 0)
                
                //header
                if sectionIndex != 0 {
                    let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                                                    heightDimension: .absolute(16)),
                                                                                 elementKind: UICollectionView.elementKindSectionHeader,
                                                                                 alignment: .top)
                    section.boundarySupplementaryItems = [headerItem]
                }
                
                return section
            }
        }
        return layout
    }
}

extension TriggerProMappingListView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return inputs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return inputs[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if isEditMode {
            let cell = collectionView.dequeueReusableCell(withClass: TriggerProMappingEditCell.self, for: indexPath)
            cell.titleLabel.text = inputs[indexPath.section][indexPath.row]
            cell.didDeleteItem = { [weak self, weak cell] in
                guard let self, let cell else { return }
                collectionView.performBatchUpdates({
                    if let indexPath = collectionView.indexPath(for: cell) {
                        self.inputs[indexPath.section].remove(at: indexPath.row)
                        self.collectionView.deleteItems(at: [indexPath])
                        self.didDeleteInput?(indexPath.row)
                    }
                }) { _ in
                    
                }
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withClass: TriggerProMappingNormalCell.self, for: indexPath)
            cell.titleLabel.text = inputs[indexPath.section][indexPath.row]
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: SeperatorHeader.self, for: indexPath)
        return header
    }
}

extension TriggerProMappingListView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if !isEditMode {
            didSelectInput?(inputs[indexPath.section][indexPath.row])
        }
    }
}

extension TriggerProMappingListView: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: any UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let input = inputs[indexPath.section][indexPath.row]
        let itemProvider = NSItemProvider(object: input as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = input
        return [dragItem]
    }
    
    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        if let cell = collectionView.cellForItem(at: indexPath) {
            let parameters = UIDragPreviewParameters()
            parameters.backgroundColor = .clear
            parameters.visiblePath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: Constants.Size.CornerRadiusMid)
            return parameters
        }
        return nil
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath else { return }
        
        coordinator.items.forEach { dropItem in
            guard let sourceIndexPath = dropItem.sourceIndexPath,
                  let input = dropItem.dragItem.localObject as? String else { return }
            
            collectionView.performBatchUpdates({
                inputs[sourceIndexPath.section].remove(at: sourceIndexPath.item)
                inputs[destinationIndexPath.section].insert(input, at: destinationIndexPath.item)
                collectionView.deleteItems(at: [sourceIndexPath])
                collectionView.insertItems(at: [destinationIndexPath])
                didChangeInputIndex?(sourceIndexPath.item, destinationIndexPath.item)
            }) { _ in
                
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
        guard let _ = destinationIndexPath else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
}

extension TriggerProMappingListView {
    static func show(inputs:[String], gameType: GameType, didSelectInput: ((String)->Void)? = nil) {
        Sheet { sheet in
            
            let mappingOnlyTypes = GameSetting.MappingOnlyType.allCases.compactMap({
                if $0.enable(for: gameType, defaultCore: 0) {
                    return $0.inputKey
                } else {
                    return nil
                }
            })
            
            let gameSettingTypes = GameSetting.ItemType.allCases.compactMap({
                let gameSetting = GameSetting(type: $0)
                if gameSetting.enable(for: gameType, defaultCore: 0) {
                    return gameSetting.inputKey
                } else {
                    return nil
                }
            })
            
            let listView = TriggerProMappingListView(inputs: [inputs, gameSettingTypes + mappingOnlyTypes])
            listView.didSelectInput = { [weak sheet] input in
                sheet?.pop()
                didSelectInput?(input)
            }
            
            sheet.contentMaskView.alpha = 0
            sheet.config.windowEdgeInset = 0
            sheet.onTappedBackground { sheet in
                sheet.pop()
            }
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
                        sheet.pop()
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
            titleLabel.text = R.string.localizable.mapping()
            titleLabel.font = Constants.Font.title(size: .s, weight: .semibold)
            titleLabel.textColor = Constants.Color.LabelPrimary
            containerView.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
                make.top.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
            }
            
            let closeButton = SymbolButton(image: UIImage(symbol: .xmark, font: Constants.Font.body(weight: .bold)))
            closeButton.addTapGesture { [weak sheet] gesture in
                sheet?.pop()
            }
            closeButton.enableRoundCorner = true
            containerView.addSubview(closeButton)
            closeButton.snp.makeConstraints { make in
                make.leading.equalTo(titleLabel.snp.trailing).offset(Constants.Size.ContentSpaceMid)
                make.centerY.equalTo(titleLabel)
                make.size.equalTo(Constants.Size.IconSizeMid)
                make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
            }
            
            containerView.addSubview(listView)
            listView.snp.makeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(Constants.Size.ContentSpaceMax)
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(Constants.Size.WindowHeight/2 - Constants.Size.ItemHeightMid)
                make.bottom.equalToSuperview()
            }
            
            sheet.set(customView: view).snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
}
