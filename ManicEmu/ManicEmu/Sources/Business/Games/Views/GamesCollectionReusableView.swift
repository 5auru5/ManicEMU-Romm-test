//
//  GamesCollectionReusableView.swift
//  ManicReader
//
//  Created by Max on 2025/1/3.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit
import ManicEmuCore
import VisualEffectView

class GamesCollectionReusableView: UICollectionReusableView {
    private var titleLabel: UILabel = {
        let view = UILabel()
        view.isHidden = true
        return view
    }()
    
    private var brandImageView: UIImageView = {
        let view = UIImageView()
        view.isHidden = true
        return view
    }()
    
    var gamesCountButton: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .chevronUp,
                                               font: Constants.Font.caption(size: .l, weight: .bold),
                                               color: Constants.Color.LabelSecondary),
                                title: "",
                                titleFont: Constants.Font.body(size: .s, weight: .semibold),
                                titleColor: Constants.Color.LabelSecondary,
                                edgeInsets: .zero,
                                titlePosition: .left,
                                imageAndTitlePadding: Constants.Size.ContentSpaceUltraTiny)
        view.layerCornerRadius = 0
        view.backgroundColor = .clear
        return view
    }()
    
    var didTapPlatform: (()->Void)? = nil
    
    var didTapGameCount: (()->Void)? = nil
    
    private var highlightString: String? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        if UIDevice.isPad {
            backgroundColor = Constants.Color.Background.forceStyle(UIDevice.isDarkMode ? .dark : .light).withAlphaComponent(0.965)
        } else {
            makeBlur(blurColor: Constants.Color.Background)
        }
        
        
        addSubviews([titleLabel, brandImageView, gamesCountButton])
        
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
        }
        
        brandImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
        }
        
        gamesCountButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax-Constants.Size.ContentSpaceTiny)
        }
        
        titleLabel.isUserInteractionEnabled = true
        titleLabel.addTapGesture { [weak self] gesture in
            guard let self else { return }
            self.didTapPlatform?()
        }
        
        brandImageView.isUserInteractionEnabled = true
        brandImageView.addTapGesture { [weak self] gesture in
            guard let self else { return }
            self.didTapPlatform?()
        }
    }
    
    func setData(gameType: GameType, highlightString: String? = nil, contentInsets: UIEdgeInsets = .zero, forceHideBlur: Bool = false, gamesCount: Int = 0, isFolded: Bool = false) {
        if Constants.Size.GamesGroupTitleStyle == .brand && gameType != .unknown {
            titleLabel.isHidden = true
            brandImageView.isHidden = false
            brandImageView.image = Self.getBrandImage(gameType: gameType)
        } else {
            titleLabel.isHidden = false
            brandImageView.isHidden = true
            var title: String = ""
            if Constants.Size.GamesGroupTitleStyle == .abbr {
                title = gameType.localizedShortName
            } else if Constants.Size.GamesGroupTitleStyle == .fullName {
                title = gameType.localizedName
            } else {
                title = gameType.localizedShortName
            }
            titleLabel.attributedText = NSAttributedString(string: title, attributes: [.font: Constants.Font.title(), .foregroundColor: Constants.Color.LabelPrimary]).highlightString(highlightString)
        }
        gamesCountButton.titleLabel.text = "\(gamesCount) \(R.string.localizable.tabbarTitleGames())"
        if UIDevice.isPhone, UIDevice.isLandscape {
            gamesCountButton.imageView.image = nil
        } else {
            gamesCountButton.imageView.image = UIImage(symbol: isFolded ? .chevronDown : .chevronUp,
                                                       font: Constants.Font.caption(size: .l, weight: .bold),
                                                       color: Constants.Color.LabelSecondary)
        }
        self.highlightString = highlightString
        if (UIDevice.isPhone && UIDevice.isLandscape) || forceHideBlur {
            //隐藏模糊
            if UIDevice.isPhone {
                if let blurView = subviews.first(where: { $0 is VisualEffectView }) as? VisualEffectView {
                    blurView.isHidden = true
                }
            } else {
                backgroundColor = .clear
            }
        } else {
            if UIDevice.isPhone {
                if let blurView = subviews.first(where: { $0 is VisualEffectView }) as? VisualEffectView {
                    blurView.isHidden = false
                }
            } else {
                backgroundColor = Constants.Color.Background.withAlphaComponent(0.965)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private static var brandImageCaches = [String: UIImage?]()
    static func getBrandImage(gameType: GameType) -> UIImage? {
        let traitCollection = ApplicationSceneDelegate.applicationWindow?.traitCollection
        let userInterfaceStyle = traitCollection?.userInterfaceStyle
        let key = gameType.rawValue + (userInterfaceStyle == nil ? "" : "\(userInterfaceStyle!.rawValue)")
        if let image = Self.brandImageCaches[key] {
            return image
        } else {
            var image: UIImage? = nil
            if gameType == ._3ds {
                image = R.image.sds_group_brand(compatibleWith: traitCollection)
            } else if gameType == .ds {
                image = R.image.ds_group_brand(compatibleWith: traitCollection)
            } else if gameType == .gba {
                image = R.image.gba_group_brand(compatibleWith: traitCollection)
            } else if gameType == .gbc {
                image = R.image.gbc_group_brand(compatibleWith: traitCollection)
            } else if gameType == .gb {
                image = R.image.gb_group_brand(compatibleWith: traitCollection)
            } else if gameType == .nes {
                image = R.image.nes_group_brand(compatibleWith: traitCollection)
            } else if gameType == .fds {
                image = R.image.fds_group_brand(compatibleWith: traitCollection)
            } else if gameType == .snes {
                image = R.image.snes_group_brand(compatibleWith: traitCollection)
            } else if gameType == .psp {
                image = R.image.psp_group_brand(compatibleWith: traitCollection)
            } else if gameType == .md {
                if Locale.prefersUS {
                    image = R.image.md_group_brand_us(compatibleWith: traitCollection)
                } else {
                    image = R.image.md_group_brand(compatibleWith: traitCollection)
                }
            } else if gameType == .mcd {
                if Locale.prefersUS {
                    image = R.image.mcd_group_brand_us(compatibleWith: traitCollection)
                } else {
                    image = R.image.mcd_group_brand(compatibleWith: traitCollection)
                }
            } else if gameType == ._32x {
                if Locale.prefersUS {
                    image = R.image.s2x_group_brand_us(compatibleWith: traitCollection)
                } else {
                    image = R.image.s2x_group_brand(compatibleWith: traitCollection)
                }
            } else if gameType == .ss {
                image = R.image.ss_group_brand(compatibleWith: traitCollection)
            } else if gameType == .sg1000 {
                image = R.image.sg1000_group_brand(compatibleWith: traitCollection)
            } else if gameType == .gg {
                image = R.image.gg_group_brand(compatibleWith: traitCollection)
            } else if gameType == .ms {
                image = R.image.ms_group_brand(compatibleWith: traitCollection)
            } else if gameType == .n64 {
                image = R.image.n64_group_brand(compatibleWith: traitCollection)
            } else if gameType == .vb {
                image = R.image.vb_group_brand(compatibleWith: traitCollection)
            } else if gameType == .pm {
                image = R.image.pm_group_brand(compatibleWith: traitCollection)
            } else if gameType == .ps1 {
                image = R.image.ps1_group_brand(compatibleWith: traitCollection)
            } else if gameType == .dc {
                image = R.image.dc_group_brand(compatibleWith: traitCollection)
            } else if gameType == .arcade {
                image = R.image.arcade_group_brand(compatibleWith: traitCollection)
            } else if gameType == .ns {
                image = R.image.ns_group_brand(compatibleWith: traitCollection)
            } else if gameType == .a2600 {
                image = R.image.a2600_group_brand(compatibleWith: traitCollection)
            } else if gameType == .a5200 {
                image = R.image.a5200_group_brand(compatibleWith: traitCollection)
            } else if gameType == .a7800 {
                image = R.image.a7800_group_brand(compatibleWith: traitCollection)
            } else if gameType == .jaguar {
                image = R.image.jaguar_group_brand(compatibleWith: traitCollection)
            } else if gameType == .lynx {
                image = R.image.lynx_group_brand(compatibleWith: traitCollection)
            } else if gameType == .xbox360 {
                image = R.image.xbox360_group_brand(compatibleWith: traitCollection)
            } else if gameType == .j2me {
                image = R.image.j2me_group_brand(compatibleWith: traitCollection)
            } else if gameType == .doom {
                image = R.image.doom_group_brand(compatibleWith: traitCollection)
            }
            Self.brandImageCaches[key] = image
            return image
        }
    }
        
    //完全搞不懂为什么UICollectionView的滚动会导致UIColor的dynamicColor错乱，只能这样处理了
    //发现了仅仅在iOS26上会出现 当系统是darkmode 应用设置为lightmode的时候会发生
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.userInterfaceStyle.rawValue != previousTraitCollection?.userInterfaceStyle.rawValue {
            if UIDevice.isPad {
                backgroundColor = Constants.Color.Background.forceStyle(UIDevice.isDarkMode ? .dark : .light).withAlphaComponent(0.965)
            } else {
                if let blurView = subviews.first(where: { $0 is VisualEffectView }) as? VisualEffectView {
                    blurView.colorTint = Constants.Color.Background.forceStyle(UIDevice.isDarkMode ? .dark : .light)
                    blurView.colorTintAlpha = 0.9
                }
            }
        }
    }
}

