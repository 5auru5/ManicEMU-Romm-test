//
//  PlatformSelectionView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/6/9.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit
import ProHUD
import ManicEmuCore

class PlatformSelectionView: BaseView {
    static func show(game: Game, cancelEnable: Bool = true, completion: (()->Void)? = nil ) {
        let gameName = game.aliasName ?? game.name
        let fileExtension = game.fileExtension
        Sheet { sheet in
            sheet.contentMaskView.alpha = 0
            sheet.config.windowEdgeInset = 0
            sheet.onTappedBackground { sheet in
                if cancelEnable {
                    sheet.pop()
                }
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
                        if cancelEnable {
                            // 达到移除的速度
                            sheet.pop()
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
            titleLabel.text = R.string.localizable.platformSelectionTitle()
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
            detailLabel.text = R.string.localizable.platformSelectionDetail(gameName)
            detailLabel.font = Constants.Font.body(size: .m)
            detailLabel.textColor = Constants.Color.LabelPrimary
            containerView.addSubview(detailLabel)
            detailLabel.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceHuge)
                make.top.equalTo(titleLabel.snp.bottom).offset(Constants.Size.ContentSpaceMin)
            }
            
            let platformSelectionView = PlatformSelectionView(fileExtension: fileExtension)
            platformSelectionView.didSelected = { [weak sheet] gameType in
                sheet?.pop {
                    Game.change { realm in
                        game.gameType = gameType
                    }
                    NotificationCenter.default.post(name: Constants.NotificationName.PlatformSelectionChange, object: nil)
                    if !game.hasCoverMatch {
                        OnlineCoverManager.shared.addCoverMatch(OnlineCoverManager.CoverMatch(game: game))
                    }
                    completion?()
                }
            }
            containerView.addSubview(platformSelectionView)
            platformSelectionView.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(detailLabel.snp.bottom).offset(Constants.Size.ContentSpaceMin)
                let count = Double(GameType.gameTypes(multiPlatformFileExtension: fileExtension).count)
                let estimatedHeight = count * Constants.Size.ItemHeightMid + ((count + 1) * Constants.Size.ContentSpaceMax)
                let maxHeight = Constants.Size.WindowHeight/2
                make.height.equalTo(min(estimatedHeight, maxHeight))
                if !cancelEnable {
                    make.bottom.equalToSuperview().offset(-Constants.Size.ContentInsetBottom)
                }
            }
            
            if cancelEnable {
                let cancelLabel = UILabel()
                cancelLabel.isUserInteractionEnabled = true
                cancelLabel.enableInteractive = true
                cancelLabel.text = R.string.localizable.cancelTitle()
                cancelLabel.textAlignment = .center
                cancelLabel.font = Constants.Font.title(size: .s, weight: .regular)
                cancelLabel.textColor = Constants.Color.LabelSecondary
                containerView.addSubview(cancelLabel)
                cancelLabel.snp.makeConstraints { make in
                    make.height.equalTo(Constants.Size.ItemHeightMid)
                    make.leading.trailing.equalToSuperview()
                    make.top.equalTo(platformSelectionView.snp.bottom)
                    make.bottom.equalToSuperview().offset(-Constants.Size.ContentInsetBottom)
                }
                cancelLabel.addTapGesture { [weak sheet] gesture in
                    sheet?.pop()
                }
            }
            
            sheet.set(customView: view).snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
    
    var didSelected: ((_ gameType: GameType)->Void)? = nil
    
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.register(cellWithClass: PlatformSortCollectionViewCell.self)
        view.showsVerticalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.dragInteractionEnabled = true
        return view
    }()
    
    private var gameTypes: [GameType]
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
    }
    
    init(fileExtension: String) {
        self.gameTypes = GameType.gameTypes(multiPlatformFileExtension: fileExtension)
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
        let layout = UICollectionViewCompositionalLayout { sectionIndex, env in
            //item布局
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                 heightDimension: .fractionalHeight(1)))
            
            let itemHeight: CGFloat = Constants.Size.ItemHeightMid
            
            //group布局
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(itemHeight)), subitems: [item])
            group.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                            leading: Constants.Size.ContentSpaceMid * 2,
                                                            bottom: 0,
                                                            trailing: Constants.Size.ContentSpaceMid * 2)
            
            //section布局
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = Constants.Size.ContentSpaceMax
            section.contentInsets = NSDirectionalEdgeInsets(top: Constants.Size.ContentSpaceMax, leading: 0, bottom: Constants.Size.ContentSpaceMax, trailing: 0)
            
            section.decorationItems = [NSCollectionLayoutDecorationItem.background(elementKind: String(describing: PlatformSelectionCollectionReusableView.self))]
            
            
            return section
        }
        layout.register(PlatformSelectionCollectionReusableView.self, forDecorationViewOfKind: String(describing: PlatformSelectionCollectionReusableView.self))
        return layout
    }
    
    class PlatformSelectionCollectionReusableView: UICollectionReusableView {
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

extension PlatformSelectionView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gameTypes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let gameType = gameTypes[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withClass: PlatformSortCollectionViewCell.self, for: indexPath)
        cell.setData(platform: gameType.localizedName, hideIcon: true)
        return cell
    }
}

extension PlatformSelectionView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didSelected?(gameTypes[indexPath.row])
    }
}
