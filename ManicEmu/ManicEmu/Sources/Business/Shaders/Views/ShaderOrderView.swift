//
//  ShaderOrderView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/12/14.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import SwipeCellKit
import ProHUD

class ShaderOrderView: BaseView {
    
    class DescHaderReusableView: UICollectionReusableView {
        private let iconImage: IconView = {
            let view = IconView()
            view.image = UIImage(symbol: .infoCircleFill, size: 14, color: Constants.Color.LabelSecondary)
            return view
        }()
        
        var titleLabel: UILabel = {
            let view = UILabel()
            view.textColor = Constants.Color.LabelSecondary
            view.font = Constants.Font.caption(size: .l)
            view.text = R.string.localizable.shaderOrderDesc()
            return view
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubviews([iconImage, titleLabel])
            makeBlur(blurColor: Constants.Color.Background)
            
            iconImage.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.leading.equalTo(Constants.Size.ContentSpaceHuge)
            }
            
            titleLabel.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.leading.equalTo(iconImage.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    private var navigationBlurView: NavigationBlurView = {
        let view = NavigationBlurView()
        view.makeBlur()
        return view
    }()
    
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.register(cellWithClass: ShaderOrderCell.self)
        view.register(supplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withClass: DescHaderReusableView.self)
        view.showsVerticalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.dragInteractionEnabled = true
        view.dragDelegate = self
        view.dropDelegate = self
        view.contentInset = UIEdgeInsets(top: 60, left: 0, bottom: Constants.Size.ContentInsetBottom + Constants.Size.ItemHeightMid + Constants.Size.ContentSpaceMid, right: 0)
        return view
    }()
    
    private lazy var closeButton: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .xmark, font: Constants.Font.body(weight: .bold)), enableGlass: true)
        view.enableRoundCorner = true
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            if self.isShaderModified {
                self.shader.appendedShaders.removeAll(where: { $0.isBase })
                self.didTapClose?(self.shader)
            } else {
                self.didTapClose?(nil)
            }
            
        }
        return view
    }()
    
    private lazy var appendButton: SymbolButton = {
        let view = SymbolButton(image: nil, title: R.string.localizable.appendShadersTitle(), titleFont: Constants.Font.body(size: .l, weight: .medium), titleColor: Constants.Color.LabelPrimary.forceStyle(.dark), horizontalContian: true, titlePosition: .right)
        view.enableRoundCorner = true
        view.backgroundColor = Constants.Color.Red
        view.addTapGesture { [weak self] gesture in
            guard let self else { return }
            let isGlsl = self.shader.relativePath.pathExtension.lowercased() == "glslp"
            ShadersListView.show(initType: .preview, isGlsl: isGlsl, ignoreShaderConfig: true, didSelectShader: { [weak self] shader in
                guard let self else { return }
                self.shader.appendedShaders.append(shader)
                self.isShaderModified = true
                self.collectionView.reloadData()
            })
        }
        return view
    }()
    
    private var shader: Shader
    private var isShaderModified: Bool = false
    
    ///点击关闭按钮回调
    var didTapClose: ((Shader?)->Void)? = nil
    
    private lazy var deleteImage = UIImage(symbol: .trash, color: Constants.Color.LabelPrimary.forceStyle(.dark), backgroundColor: Constants.Color.Red, imageSize: .init(Constants.Size.ItemHeightMin)).withRoundedCorners()
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
    }
    
    init(shader: Shader) {
        self.shader = shader
        self.shader.appendedShaders.insert(shader, at: shader.indexInAppendage)
        super.init(frame: .zero)
        Log.debug("\(String(describing: Self.self)) init")
        backgroundColor = Constants.Color.Background
        
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(navigationBlurView)
        navigationBlurView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalTo(self.safeAreaLayoutGuide)
            make.height.equalTo(Constants.Size.ItemHeightMid)
        }
        
        addSubview(appendButton)
        appendButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceHuge)
            make.bottom.equalToSuperview().inset(Constants.Size.ContentInsetBottom)
            make.height.equalTo(Constants.Size.ItemHeightMid)
        }
        
        let icon = UIImageView(image: UIImage(symbol: .sparklesRectangleStackFill))
        navigationBlurView.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
            make.size.equalTo(Constants.Size.IconSizeMin)
            make.centerY.equalToSuperview()
        }
        let headerTitleLabel = UILabel()
        headerTitleLabel.text = R.string.localizable.shadersOrder()
        headerTitleLabel.textColor = Constants.Color.LabelPrimary
        headerTitleLabel.font = Constants.Font.title(size: .s)
        navigationBlurView.addSubview(headerTitleLabel)
        headerTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
            make.centerY.equalTo(icon)
        }
        
        navigationBlurView.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
            make.centerY.equalToSuperview()
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
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
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(50)), subitems: [item])
            group.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                            leading: Constants.Size.ContentSpaceMid,
                                                            bottom: 0,
                                                            trailing: Constants.Size.ContentSpaceMid)
            
            //section布局
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = Constants.Size.ContentSpaceMax
            section.contentInsets = NSDirectionalEdgeInsets(top: Constants.Size.ContentSpaceMin, leading: 0, bottom: 0, trailing: 0)
            
            let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                                            heightDimension: .absolute(20)),
                                                                         elementKind: UICollectionView.elementKindSectionHeader,
                                                                         alignment: .top)
            section.boundarySupplementaryItems = [headerItem]
            
            return section
        }
        return layout
    }
}

extension ShaderOrderView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return shader.appendedShaders.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let shader = shader.appendedShaders[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withClass: ShaderOrderCell.self, for: indexPath)
        cell.delegate = self
        cell.setData(platform: shader.title + (shader.isBase ? " (\(R.string.localizable.base()))" : ""))
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: DescHaderReusableView.self, for: indexPath)
        return header
    }
}

extension ShaderOrderView: UICollectionViewDelegate {
    
}

extension ShaderOrderView: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: any UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let shader = shader.appendedShaders[indexPath.row]
        let itemProvider = NSItemProvider(object: shader.relativePath as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = shader
        return [dragItem]
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath else { return }
        
        coordinator.items.forEach { dropItem in
            guard let sourceIndexPath = dropItem.sourceIndexPath else { return }
            
            collectionView.performBatchUpdates({ [weak self] in
                guard let self else { return }
                let lipShader = self.shader.appendedShaders[sourceIndexPath.item]
                self.shader.appendedShaders.remove(at: sourceIndexPath.item)
                self.shader.appendedShaders.insert(lipShader, at: destinationIndexPath.item)
                collectionView.deleteItems(at: [sourceIndexPath])
                collectionView.insertItems(at: [destinationIndexPath])
            }) { [weak self] isSuccess in
                guard let self else { return }
                if let indexInAppendage = self.shader.appendedShaders.firstIndex(where: { $0.isBase }) {
                    self.shader.indexInAppendage = indexInAppendage
                    self.isShaderModified = true
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
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
}

extension ShaderOrderView: SwipeCollectionViewCellDelegate {
    func collectionView(_ collectionView: UICollectionView, editActionsForItemAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        let shader = shader.appendedShaders[indexPath.row]
        if shader.isBase {
            return nil
        }
        UIDevice.generateHaptic()
        if orientation == .right {
            let delete = SwipeAction(style: .default, title: nil) { [weak self] action, indexPath in
                guard let self else { return }
                UIDevice.generateHaptic()
                action.fulfill(with: .reset)
                self.shader.appendedShaders.remove(at: indexPath.row)
                if let indexInAppendage = self.shader.appendedShaders.firstIndex(where: { $0.isBase }) {
                    self.shader.indexInAppendage = indexInAppendage
                }
                self.collectionView.reloadData()
                self.isShaderModified = true
            }
            delete.backgroundColor = .clear
            delete.image = deleteImage
            return [delete]
        } else {
            return nil
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, editActionsOptionsForItemAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = SwipeExpansionStyle(target: .percentage(1),
                                                     elasticOverscroll: true,
                                                     completionAnimation: .fill(.manual(timing: .with)))
        options.expansionDelegate = self
        options.transitionStyle = .border
        options.backgroundColor = Constants.Color.Background
        options.maximumButtonWidth = Constants.Size.ItemHeightMin + Constants.Size.ContentSpaceTiny*2
        return options
    }
}

extension ShaderOrderView: SwipeExpanding {
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

extension ShaderOrderView {
    static func show(shader: Shader, hideCompletion: (()->Void)? = nil, didChangeShader: ((Shader?)->Void)? = nil) {
        Sheet { sheet in
            sheet.configGamePlayingStyle(hideCompletion: hideCompletion)
            
            let view = UIView()
            let containerView = RoundAndBorderView(roundCorner: (UIDevice.isPad || UIDevice.isLandscape || PlayViewController.menuInsets != nil) ? .allCorners : [.topLeft, .topRight])
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
            
            let listView = ShaderOrderView(shader: shader)
            listView.didTapClose = { [weak sheet] shader in
                didChangeShader?(shader)
                sheet?.pop()
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
