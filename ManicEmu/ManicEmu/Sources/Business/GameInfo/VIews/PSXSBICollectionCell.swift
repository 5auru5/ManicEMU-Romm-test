//
//  PSXSBICollectionCell.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/8/4.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

class PSXSBICollectionCell: UICollectionViewCell {
    
    private var titleLabel: UILabel = {
        let view = UILabel()
        view.lineBreakMode = .byTruncatingMiddle
        return view
    }()
    
    let addFileButton = SymbolButton(image: nil, title: R.string.localizable.multiDiscAddFile(".sbi"), titleFont: Constants.Font.body(size: .m), titleColor: Constants.Color.Main, titleAlignment: .right, horizontalContian: true)
    
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
        
        addSubview(addFileButton)
        addFileButton.backgroundColor = Constants.Color.Background
        addFileButton.snp.makeConstraints { make in
            make.leading.bottom.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.height.equalTo(Constants.Size.ItemHeightMin)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setData(filePath: String) {
        itemViews.forEach { $0.removeFromSuperview() }
        itemViews.removeAll()

        let style = NSMutableParagraphStyle()
        style.lineSpacing = Constants.Size.ContentSpaceUltraTiny
        style.lineBreakMode = .byTruncatingMiddle
        let matt = NSMutableAttributedString(string: filePath.lastPathComponent, attributes: [.foregroundColor: Constants.Color.LabelPrimary, .font: Constants.Font.title(size: .s), .paragraphStyle: style])
        titleLabel.attributedText = matt
        
       
        let itemView = BIOSCollectionViewCell.ItemView(enableButton: false)
        itemView.titleLabel.text = filePath.deletingPathExtension.lastPathComponent + ".sbi"
        itemView.titleLabel.lineBreakMode = .byTruncatingMiddle
        itemView.optionButton.setTitle("(\(R.string.localizable.sbiUnImport()))", for: .normal)
        itemView.optionButton.setTitleColor(Constants.Color.Red, for: .normal)
        itemView.optionButton.setTitle("(\(R.string.localizable.biosImported()))", for: .selected)
        itemView.optionButton.setTitleColor(Constants.Color.Green, for: .selected)
        itemView.optionButton.isSelected = FileManager.default.fileExists(atPath: filePath.deletingPathExtension + ".sbi")
        itemView.button.isHidden = true
        itemViews.append(itemView)
        addSubview(itemView)
        itemView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.height.equalTo(Constants.Size.ItemHeightMid)
            make.top.equalTo(titleLabel.snp.bottom).offset(Constants.Size.ContentSpaceMid)
        }
        
    }
    
    static func CellHeight() -> Double {
        let deleteButtonHeight = Constants.Size.ItemHeightMin + Constants.Size.ContentSpaceMid
        let titleLabelHeight = 21.0
        return Constants.Size.ContentSpaceMid + titleLabelHeight + Constants.Size.ItemHeightMid + (2 * Constants.Size.ContentSpaceMid) + deleteButtonHeight
    }
}
