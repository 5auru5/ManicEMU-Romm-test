//
//  ShadersListCell.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/12/13.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import SwipeCellKit

class ShadersListCell: SwipeTableViewCell {
    private var titleLabel: UILabel = {
        let view = UILabel()
        return view
    }()
    
    var chevronIconView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(symbol: .chevronRight, font: Constants.Font.caption(size: .l, weight: .bold), color: Constants.Color.BackgroundSecondary)
        if Locale.isRTLLanguage {
            view.transform = CGAffineTransform(scaleX: -1, y: 1)
        }
        view.isHidden = true
        return view
    }()
    
    private var selectImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .center
        view.layerCornerRadius = Constants.Size.CornerRadiusMin
        view.layer.shadowColor = Constants.Color.Shadow.cgColor
        view.layer.shadowOpacity = 0.5
        view.layer.shadowRadius = 2
        view.image = UIImage(symbol: .checkmarkCircleFill, weight: .bold, colors: [Constants.Color.LabelPrimary.forceStyle(.dark), Constants.Color.Main])
        view.isHidden = true
        return view
    }()
    
    private var mainColorChangeNotification: Any? = nil
    
    deinit {
        if let mainColorChangeNotification = mainColorChangeNotification {
            NotificationCenter.default.removeObserver(mainColorChangeNotification)
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        enableInteractive = true
        delayInteractiveTouchEnd = true
        
        let containerView = UIView()
        contentView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.top.bottom.equalToSuperview().inset(10)
        }
        containerView.layerCornerRadius = Constants.Size.CornerRadiusMid
        containerView.backgroundColor = Constants.Color.BackgroundPrimary
        
        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
        }
        
        containerView.addSubview(chevronIconView)
        chevronIconView.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMid)
            make.size.equalTo(CGSize(width: 10, height: 14))
        }
        
        containerView.addSubview(selectImageView)
        selectImageView.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMid)
            make.size.equalTo(Constants.Size.IconSizeMin)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            selectImageView.layer.shadowColor = Constants.Color.Shadow.cgColor
        }
    }
    
    func setData(shader: Shader?, initType: ShadersListView.InitType) {
        
        let matt = NSMutableAttributedString(string: shader?.title ?? "", attributes: [.font: Constants.Font.body(size: .l), .foregroundColor: Constants.Color.LabelPrimary])
        if let alert = shader?.configAlert {
            titleLabel.numberOfLines = 2
            matt.append(NSAttributedString(string: "\n\(alert)", attributes: [.font: Constants.Font.caption(size: .m), .foregroundColor: Constants.Color.LabelSecondary]))
            let style = NSMutableParagraphStyle()
            style.lineSpacing = Constants.Size.ContentSpaceUltraTiny/2
            style.lineBreakMode = .byTruncatingTail
            titleLabel.attributedText = matt.applying(attributes: [.paragraphStyle: style])
        } else {
            titleLabel.numberOfLines = 1
            titleLabel.attributedText = matt
        }
        
        switch initType {
        case .normal:
            chevronIconView.isHidden = false
            selectImageView.isHidden = true
        case .gamePlay:
            chevronIconView.isHidden = true
            selectImageView.isHidden = !(shader?.isSelected ?? false)
        case .preview:
            chevronIconView.isHidden = true
            selectImageView.isHidden = true
        }
    }
    
}
