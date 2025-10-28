//
//  TriggerProListCell.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/10/21.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import SwipeCellKit

class TriggerProListCell: SwipeTableViewCell {
    private var titleLabel: UILabel = {
        let view = UILabel()
        view.font = Constants.Font.body(size: .l)
        view.textColor = Constants.Color.LabelPrimary
        return view
    }()
    
    var chevronIconView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(symbol: .chevronRight, font: Constants.Font.caption(size: .l, weight: .bold), color: Constants.Color.BackgroundSecondary)
        if Locale.isRTLLanguage {
            view.transform = CGAffineTransform(scaleX: -1, y: 1)
        }
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
        
        containerView.addSubview(chevronIconView)
        chevronIconView.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMid)
            make.size.equalTo(CGSize(width: 10, height: 14))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setData(trigger: Trigger?) {
        guard let trigger else { return }
        titleLabel.text = trigger.triggerProName
    }
    
}
