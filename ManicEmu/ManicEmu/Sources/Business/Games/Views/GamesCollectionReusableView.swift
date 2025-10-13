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
    var titleLabel: UILabel = {
        let view = UILabel()
        view.isHidden = true
        return view
    }()
    
    var brandImageView: UIImageView = {
        let view = UIImageView()
        view.isHidden = true
        return view
    }()
    
    var skinButton: UIButton = {
        let view = UIButton(type: .custom)
        view.titleLabel?.font = Constants.Font.body(weight: .medium)
        view.setTitleColor(Constants.Color.LabelSecondary, for: .normal)
        view.setTitle(R.string.localizable.gamesSpecifySkin(), for: .normal)
        return view
    }()
    
    var didTapPlatform: (()->Void)? = nil
    
    private var highlightString: String? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        if UIDevice.isPad {
            backgroundColor = Constants.Color.Background.withAlphaComponent(0.965)
        } else {
            makeBlur(blurColor: Constants.Color.Background)
        }
        
        
        addSubviews([titleLabel, brandImageView, skinButton])
        
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
        }
        
        brandImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
        }
        
        skinButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
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
    
    func setData(gameType: GameType, highlightString: String? = nil, contentInsets: UIEdgeInsets = .zero) {
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
        skinButton.setTitleColor(Constants.Color.LabelSecondary, for: .normal)
        self.highlightString = highlightString
        if UIDevice.isPhone, UIDevice.isLandscape {
            //隐藏模糊
            if let blurView = subviews.first(where: { $0 is VisualEffectView }) as? VisualEffectView {
                blurView.isHidden = true
            }
        } else {
            if let blurView = subviews.first(where: { $0 is VisualEffectView }) as? VisualEffectView {
                blurView.isHidden = false
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
            }  else if gameType == .nes {
                image = R.image.nes_group_brand(compatibleWith: traitCollection)
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
            }
            Self.brandImageCaches[key] = image
            return image
        }
    }
        
}

