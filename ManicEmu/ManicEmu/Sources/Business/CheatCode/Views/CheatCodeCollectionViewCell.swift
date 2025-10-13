//
//  CheatCodeCollectionViewCell.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/3/6.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import SwipeCellKit

class CheatCodeCollectionViewCell: SwipeTableViewCell {
    private var titleLabel: UILabel = {
        let view = UILabel()
        view.font = Constants.Font.body(size: .l)
        view.textColor = Constants.Color.LabelPrimary
        return view
    }()
    
    var switchButton: DisabledTapSwitch = {
        let view = DisabledTapSwitch()
        view.onTintColor = Constants.Color.Main
        view.tintColor = Constants.Color.BackgroundSecondary
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
        
        containerView.addSubview(switchButton)
        switchButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMid)
            make.leading.equalTo(titleLabel.snp.trailing).offset(Constants.Size.ContentSpaceTiny)
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
    
    func setData(cheatCode: GameCheat) {
        titleLabel.text = cheatCode.name
        switchButton.setOn(cheatCode.activate, animated: false)
    }
    
}
