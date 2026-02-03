//
//  MAMEBiosView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/11/19.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import UIKit
import ManicEmuCore

class MAMEBiosView: BaseView {
    
    class MAMEBiosViewCell: UICollectionViewCell {
        private let itemViews: [BIOSCollectionViewCell.ItemView] = {
            var views = [BIOSCollectionViewCell.ItemView]()
            let mameBios = Constants.BIOS.MAMEBiosMap.map({
                BIOSItem(fileName: $0.key, imported: false, desc: $0.value, required: false)
            }).sorted(by: {
                $0.fileName < $1.fileName
            })
            for b in mameBios {
                let itemView = BIOSCollectionViewCell.ItemView()
                itemView.titleLabel.text = b.fileName
                itemView.detailLabel.text = b.desc
                itemView.optionButton.isSelected = b.required
                itemView.button.isSelected = true
                itemView.button.isUserInteractionEnabled = false
                if FileManager.default.fileExists(atPath: Constants.Path.Data.appendingPathComponent(b.fileName)) {
                    itemView.button.isHidden = false
                } else {
                    itemView.button.isHidden = true
                }
                views.append(itemView)
            }
            return views
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            layerCornerRadius = Constants.Size.CornerRadiusMax
            backgroundColor = Constants.Color.BackgroundPrimary
            
            addSubviews(itemViews)
            for (index, view) in itemViews.enumerated() {
                view.snp.makeConstraints { make in
                    make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
                    make.height.equalTo(Constants.Size.ItemHeightMax)
                    if index == 0 {
                        make.top.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
                    } else {
                        make.top.equalTo(itemViews[index-1].snp.bottom).offset(Constants.Size.ContentSpaceMid)
                    }
                }
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
        view.register(cellWithClass: MAMEBiosViewCell.self)
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
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
        
        let icon = UIImageView(image: UIImage(symbol: .cpu))
        navigationBlurView.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
            make.size.equalTo(Constants.Size.IconSizeMin)
            make.centerY.equalToSuperview()
        }
        let headerTitleLabel = UILabel()
        headerTitleLabel.text = Constants.Strings.MAMEBiosTitle
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
            
            
            let itemCount = Constants.BIOS.MAMEBiosMap.count
            let itemHeight = (Double(itemCount) * Constants.Size.ItemHeightMax) + (Double(itemCount + 1) * Constants.Size.ContentSpaceMid)
            
            //group布局
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(itemHeight)), subitems: [item])
            group.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                            leading: Constants.Size.ContentSpaceMid,
                                                            bottom: 0,
                                                            trailing: Constants.Size.ContentSpaceMid)
            
            //section布局
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: Constants.Size.ContentSpaceMin, trailing: 0)
            
            return section
        }
        return layout
    }
}

extension MAMEBiosView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClass: MAMEBiosViewCell.self, for: indexPath)
        return cell
    }
}

extension MAMEBiosView: UICollectionViewDelegate {

}
