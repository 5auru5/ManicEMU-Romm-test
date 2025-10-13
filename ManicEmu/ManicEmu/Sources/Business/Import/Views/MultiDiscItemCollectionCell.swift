//
//  MultiDiscItemCollectionCell.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/7/3.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

class MultiDiscItemCollectionCell: UICollectionViewCell {
    
    private var titleLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 2
        view.lineBreakMode = .byTruncatingMiddle
        return view
    }()
    
    let deleteIcon = SymbolButton(image: nil, title: R.string.localizable.removeTitle(), titleFont: Constants.Font.body(size: .m), titleColor: Constants.Color.Main, titleAlignment: .right, horizontalContian: true)
    
    private let sortIcon = SymbolButton(image: .init(symbol: .line3Horizontal, font: Constants.Font.title(size: .s), color: Constants.Color.BackgroundSecondary))
    
    private var itemViews: [BIOSCollectionViewCell.ItemView] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layerCornerRadius = Constants.Size.CornerRadiusMax
        backgroundColor = Constants.Color.BackgroundPrimary
        
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceHuge)
        }
        
        sortIcon.backgroundColor = .clear
        addSubview(sortIcon)
        sortIcon.snp.makeConstraints { make in
            make.size.equalTo(Constants.Size.IconSizeMin)
            make.top.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
        }
        
        addSubview(deleteIcon)
        deleteIcon.backgroundColor = Constants.Color.Background
        deleteIcon.snp.makeConstraints { make in
            make.leading.bottom.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.height.equalTo(Constants.Size.ItemHeightMin)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setData(index: Int, item: MultiDiscBuilderViewController.M3uItem) {
        itemViews.forEach { $0.removeFromSuperview() }
        itemViews.removeAll()
        let matt = NSMutableAttributedString(string: "Disc \(index)", attributes: [.foregroundColor: Constants.Color.LabelPrimary, .font: Constants.Font.title(size: .s)])
        if item.files.count > 0 {
            matt.append(NSAttributedString(string: "\n" + item.url.lastPathComponent, attributes: [.foregroundColor: Constants.Color.LabelSecondary, .font: Constants.Font.body(size: .l)]))
            item.files.forEach { url in
                let itemView = BIOSCollectionViewCell.ItemView(enableButton: false, enableOptionButton: false)
                itemView.titleLabel.text = url.lastPathComponent
                itemView.titleLabel.lineBreakMode = .byTruncatingMiddle
                itemView.optionButton.isHidden = true
                itemView.button.isHidden = true
                itemViews.append(itemView)
                addSubview(itemView)
            }
            for (index, view) in itemViews.enumerated() {
                view.snp.makeConstraints { make in
                    make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
                    make.height.equalTo(Constants.Size.ItemHeightMid)
                    if index == 0 {
                        make.top.equalTo(titleLabel.snp.bottom).offset(Constants.Size.ContentSpaceMid)
                    } else {
                        make.top.equalTo(itemViews[index-1].snp.bottom).offset(Constants.Size.ContentSpaceMid)
                    }
                }
            }
        } else {
            let itemView = BIOSCollectionViewCell.ItemView(enableButton: false, enableOptionButton: false)
            itemView.titleLabel.text = item.url.lastPathComponent
            itemView.titleLabel.lineBreakMode = .byTruncatingMiddle
            itemView.optionButton.isHidden = true
            itemView.button.isHidden = true
            itemViews.append(itemView)
            addSubview(itemView)
            itemView.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
                make.height.equalTo(Constants.Size.ItemHeightMid)
                make.top.equalTo(titleLabel.snp.bottom).offset(Constants.Size.ContentSpaceMid)
            }
        }
        let style = NSMutableParagraphStyle()
        style.lineSpacing = Constants.Size.ContentSpaceUltraTiny
        style.lineBreakMode = .byTruncatingMiddle
        titleLabel.attributedText = matt.applying(attributes: [.paragraphStyle: style])
    }
    
    static func CellHeight(itemCount: Int) -> Double {
        let deleteButtonHeight = Constants.Size.ContentSpaceMid + Constants.Size.ItemHeightMin
        let titleLabelHeight = itemCount == 0 ? 21 : 43.0
        let itemCount = itemCount == 0 ? 1 : itemCount
        return Constants.Size.ContentSpaceMid + titleLabelHeight + (Double(itemCount) * Constants.Size.ItemHeightMid) + (Double(itemCount + 1) * Constants.Size.ContentSpaceMid) + deleteButtonHeight
    }
}
