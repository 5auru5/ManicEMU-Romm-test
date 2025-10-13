//
//  ImportServiceListCollectionViewCell.swift
//  ManicEmu
//
//  Created by Max on 2025/1/20.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit

class ImportServiceListCollectionViewCell: UICollectionViewCell {
    private var iconView: ServiceIconView = {
        let view = ServiceIconView(roundCorner: .allCorners)
        return view
    }()
    
    private var titleLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        return view
    }()
    
    var switchButton: DisabledTapSwitch = {
        let view = DisabledTapSwitch()
        view.onTintColor = Constants.Color.Main
        view.tintColor = Constants.Color.BackgroundSecondary
        view.alpha = 0
        return view
    }()
    
    private var mainColorChangeNotification: Any? = nil
    
    deinit {
        if let mainColorChangeNotification = mainColorChangeNotification {
            NotificationCenter.default.removeObserver(mainColorChangeNotification)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        enableInteractive = true
        delayInteractiveTouchEnd = true
        backgroundColor = Constants.Color.BackgroundPrimary
        layerCornerRadius = Constants.Size.CornerRadiusMax

        addSubviews([iconView, titleLabel, switchButton])
        
        iconView.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.size.equalTo(40)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Constants.Size.ContentSpaceHuge)
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.bottom.lessThanOrEqualTo(iconView.snp.top).offset(-Constants.Size.ContentSpaceUltraTiny)
        }
        
        switchButton.snp.makeConstraints { make in
            make.centerY.equalTo(iconView)
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
            if #available(iOS 26.0, *) {
                make.size.equalTo(CGSize(width: 63, height: 28))
            } else {
                make.size.equalTo(CGSize(width: 51, height: 31))
            }
        }
        if #available(iOS 26.0, *) {} else {
            switchButton.transform = CGAffineTransformMakeScale(0.9, 0.9)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //TODO: 需要处理图片的尺寸
    func setData(service: ImportService) {
        
        iconView.imageView.image = service.iconImage
        iconView.backgroundColor = service.iconBackgroundColor
        iconView.borderColor = service.iconBorderColor
        iconView.radius = service.iconCornerRadius
        titleLabel.text = service.title
        
        var matt = NSMutableAttributedString(string: service.title, attributes: [.font: Constants.Font.title(size: .s, weight: .semibold), .foregroundColor: Constants.Color.LabelPrimary])
        if let detail = service.detail {
            matt.append(NSAttributedString(string: "\n" + detail, attributes: [.font: Constants.Font.body(), .foregroundColor: Constants.Color.LabelSecondary]))
            let style = NSMutableParagraphStyle()
            style.lineSpacing = Constants.Size.ContentSpaceUltraTiny/2
            matt = matt.applying(attributes: [.paragraphStyle: style]) as! NSMutableAttributedString
        }
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byTruncatingTail
        matt = matt.applying(attributes: [.paragraphStyle: style]) as! NSMutableAttributedString
        titleLabel.attributedText = matt
        
        if service.type == .wifi {
            switchButton.alpha = 1
            switchButton.setOn(WebServer.shard.isRunning, animated: false)
        } else {
            switchButton.alpha = 0
            switchButton.setOn(false, animated: false)
        }
    }
    
}
