
//
//  PlayHistoryItemCollectionCell.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/2/23.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import MarqueeLabel

class PlayHistoryItemCollectionCell: UICollectionViewCell {
    private let iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleToFill
        view.layerCornerRadius = Constants.Size.CornerRadiusTiny
        return view
    }()
    
    private let titleLabel: UILabel = {
        let view = MarqueeLabel()
        view.font = Constants.Font.body()
        view.textColor = Constants.Color.LabelPrimary
        view.type = .leftRight
        return view
    }()
    
    private let subTitleLabel: UILabel = {
        let view = MarqueeLabel()
        view.font = Constants.Font.caption()
        view.textColor = Constants.Color.LabelSecondary
        view.type = .leftRight
        return view
    }()
    
    private let retroView: RetroAchievementCountView = {
        let view = RetroAchievementCountView(count: 0)
        view.isHidden = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = Constants.Color.Background
        layerCornerRadius = Constants.Size.CornerRadiusMid
        enableInteractive = true
        delayInteractiveTouchEnd = true

        addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMin)
            make.centerY.equalToSuperview()
            make.size.equalTo(50)
        }
        
        addSubview(retroView)
        retroView.snp.makeConstraints { make in
            make.height.equalTo(24)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMin)
        }
        
        let titleContainerView = UIView()
        addSubview(titleContainerView)
        titleContainerView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(iconView.snp.trailing).offset(Constants.Size.ContentSpaceTiny)
            make.trailing.equalTo(retroView.snp.leading).offset(-Constants.Size.ContentSpaceTiny)
        }
        
        titleContainerView.addSubviews([titleLabel, subTitleLabel])
        titleLabel.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }
        subTitleLabel.snp.makeConstraints { make in
            make.leading.bottom.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(Constants.Size.ContentSpaceUltraTiny)
        }
        
        retroView.countLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        retroView.countLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleContainerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleContainerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //TODO: 需要处理图片的尺寸
    func setData(game: Game, didTapRetro: (()->Void)? = nil) {
        let estimated = iconView.size == .zero ? .init(40) : iconView.size
        iconView.setGameCover(game: game, size: estimated)
        if Constants.Size.GameCoverRatio(gameType: game.gameType) != 1.0 {
            iconView.contentMode = .scaleAspectFill
        } else {
            iconView.contentMode = .scaleToFill
        }
        titleLabel.text = game.aliasName ?? game.name
        if let timeAgo = game.latestPlayDate?.timeAgo() {
            subTitleLabel.text = R.string.localizable.readyGameInfoSubTitle(timeAgo, Date.timeDuration(milliseconds: Int(game.totalPlayDuration)))
        } else {
            subTitleLabel.text = ""
        }
        
        if game.enableAchievements {
            retroView.isHidden = false
            retroView.countLabel.text = ""
            retroView.removeGestureRecognizers()
            retroView.addTapGesture { gesture in
                didTapRetro?()
            }
        } else {
            retroView.isHidden = true
        }
    }
}
