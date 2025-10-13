//
//  GameCollectionViewCell.swift
//  ManicReader
//
//  Created by Max on 2025/1/2.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit
import MarqueeLabel
import ManicEmuCore

class GameCollectionViewCell: UICollectionViewCell {
    
    private var gameType: GameType? = nil
    private var lastFrame: CGRect? = nil
    private var indexPath: IndexPath = IndexPath(row: 0, section: 0)
    
    var imageView: GameCoverView = {
        let view = GameCoverView()
        return view
    }()
    
    private var titleLabel: MarqueeLabel = {
        let view = MarqueeLabel()
        view.textAlignment = .center
        return view
    }()
    
    private var selectImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.layerCornerRadius = Constants.Size.IconSizeMin.height/2
        view.layer.shadowColor = Constants.Color.Shadow.cgColor
        view.layer.shadowOpacity = 0.5
        view.layer.shadowRadius = 2
        return view
    }()
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            selectImageView.layer.shadowColor = Constants.Color.Shadow.cgColor
        }
    }
    
    private var selectedBackground: UIView = {
        let view = UIView()
        view.backgroundColor = Constants.Color.BackgroundSecondary
        view.layerCornerRadius = Constants.Size.CornerRadiusMax
        return view
    }()
    
    override var isSelected: Bool {
        willSet {
            if newValue {
                self.selectImageView.image = UIImage(symbol: .checkmarkCircleFill,
                                                     size: Constants.Size.IconSizeMin.height,
                                                     weight: .bold,
                                                     colors: [Constants.Color.LabelPrimary, Constants.Color.Main])
                self.selectedBackground.alpha = 1
                if UIDevice.isPhone, UIDevice.isLandscape, ExternalGameControllerUtils.shared.linkedControllers.count > 0 {
                    UIView.springAnimate(animations: {
                        self.selectedBackground.backgroundColor = .white
                        self.transform = .identity
                    }) { _ in
                        if self.transform != .identity && self.isSelected {
                            self.transform = .identity
                        }
                    }
                } else {
                    self.selectedBackground.backgroundColor = Constants.Color.BackgroundSecondary
                }
            } else {
                self.selectImageView.image = UIImage(symbol: .circle,
                                                     size: Constants.Size.IconSizeMin.height,
                                                     color: Constants.Color.LabelPrimary.forceStyle(.dark))
                self.selectedBackground.alpha = 0
                if UIDevice.isPhone, UIDevice.isLandscape, ExternalGameControllerUtils.shared.linkedControllers.count > 0 {
                    UIView.springAnimate(animations: {
                        self.selectedBackground.backgroundColor = Constants.Color.BackgroundSecondary
                        self.transform = CGAffineTransformMakeScale(0.8, 0.8)
                    })
                } else {
                    self.selectedBackground.backgroundColor = Constants.Color.BackgroundSecondary
                }
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        enableInteractive = true
        delayInteractiveTouchEnd = true
        
        contentView.addSubview(selectedBackground)
        selectedBackground.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        selectedBackground.alpha = 0
        
        contentView.addSubview(imageView)
        
        imageView.addSubview(selectImageView)
        selectImageView.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceTiny)
            make.size.equalTo(Constants.Size.IconSizeMin)
        }
        selectImageView.alpha = 0
        self.isSelected = false
        
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.Size.GamesListSelectionEdge)
            make.bottom.equalToSuperview().offset(-Constants.Size.GamesListSelectionEdge).priority(.required)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setData(game: Game, isSelect: Bool = false, highlightString: String? = nil, coverSize: CGSize, showTitle: Bool = true, indexPath: IndexPath) {
        self.indexPath = indexPath
        gameType = game.gameType
        titleLabel.isHidden = !showTitle
        titleLabel.attributedText = NSAttributedString(string: game.aliasName ?? game.name, attributes: [.font: Constants.Font.body(), .foregroundColor: Constants.Color.LabelSecondary]).highlightString(highlightString)
        imageView.setData(game: game,
                          coverSize: coverSize,
                          style: Constants.Size.GameCoverStyle)
        imageView.frame = CGRect(origin: CGPoint(x: Constants.Size.GamesListSelectionEdge, y: Constants.Size.GamesListSelectionEdge), size: coverSize)
        updateViews(isSelect: isSelect)
    }
    
    func updateViews(isSelect: Bool) {
        self.selectImageView.alpha = isSelect ? 1 : 0
        if UIDevice.isPhone, UIDevice.isLandscape, ExternalGameControllerUtils.shared.linkedControllers.count > 0 {
            if isSelect {
                self.transform = .identity
            } else {
                self.transform = CGAffineTransformMakeScale(0.8, 0.8)
            }
        } else {
            self.transform = .identity
        }
    }
}
