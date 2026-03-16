//
//  GameCoverView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/5/4.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import ManicEmuCore
import Kingfisher

class GameCoverView: UIView {
    private var gameCoverChangeNotification: Any? = nil
    
    var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.backgroundColor = Constants.Color.BackgroundPrimary
        return view
    }()
    
    private var platformView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .center
        view.backgroundColor = .white
        view.isHidden = true
        return view
    }()
    
    private var barShadowView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.isHidden = true
        view.addShadow(ofColor: Constants.Color.Background, radius: 10, offset: CGSize(width: 5, height: 0))
        return view
    }()
    
    private var style: CoverStyle = .style1
    private var autoCornerRadius: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Constants.Color.BackgroundPrimary
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(barShadowView)
        
        addSubview(platformView)
        
        gameCoverChangeNotification = NotificationCenter.default.addObserver(forName: Constants.NotificationName.GameCoverChange, object: nil, queue: .main) { [weak self] notification in
            guard let self = self else { return }
            DispatchQueue.main.asyncAfter(delay: 0.35) {
                self.updateCornerRadius(self.layerCornerRadius)
            }
        }
    }
    
    deinit {
        if let gameCoverChangeNotification {
            NotificationCenter.default.removeObserver(gameCoverChangeNotification)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if style == .style3 {
            imageView.roundCorners([.topLeft, .topRight], radius: layerCornerRadius - 6)
        } else {
            imageView.roundCorners([], radius: 0)
        }
        if autoCornerRadius {
            layerCornerRadius = Constants.Size.GameCoverCornerRatio * style.maxCornerRadius(frameHeight: height)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    ///设置游戏封面
    func setData(game: Game, coverSize: CGSize, style: CoverStyle, scalePlatform: Bool = true) {
        if height > 0 {
            autoCornerRadius = false
            let gameCoverCornerRatio = Constants.Size.GameCoverCornerRatio
            let maxCornerRadius = style.maxCornerRadius(frameHeight: coverSize.height)
            let cornerRadius = gameCoverCornerRatio * maxCornerRadius
            layerCornerRadius = cornerRadius
        } else {
            autoCornerRadius = true
        }
        imageView.setGameCover(game: game, size: coverSize)
        updateStyle(style, gameType: game.gameType, scalePlatform: scalePlatform)
    }
    
    ///主题圆角配置时使用
    func setData(gameType: GameType, image: UIImage?, style: CoverStyle, cornerRadius: CGFloat, scalePlatform: Bool = true) {
        autoCornerRadius = false
        layerCornerRadius = cornerRadius
        imageView.image = image
        imageView.contentMode = .center
        updateStyle(style, gameType: gameType, scalePlatform: scalePlatform)
    }
    
    func updateStyle(_ style: CoverStyle, gameType: GameType, scalePlatform: Bool = true) {
        self.style = style
        platformView.image = Self.getPlatformImage(gameType: gameType, style: style, scalePlatform: scalePlatform)
        switch style {
        case .style1:
            imageView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
            platformView.isHidden = true
            barShadowView.isHidden = true
            backgroundColor = Constants.Color.BackgroundPrimary
        case .style2:
            imageView.snp.remakeConstraints { make in
                make.top.trailing.bottom.equalToSuperview()
                make.leading.equalTo(platformView.snp.trailing)
            }
            platformView.snp.remakeConstraints { make in
                make.leading.top.bottom.equalToSuperview()
                make.width.equalToSuperview().multipliedBy(0.1298)
            }
            barShadowView.snp.remakeConstraints { make in
                make.edges.equalTo(platformView)
            }
            platformView.isHidden = false
            barShadowView.isHidden = false
            backgroundColor = Constants.Color.BackgroundPrimary
        case .style3:
            imageView.snp.remakeConstraints { make in
                make.leading.top.trailing.equalToSuperview().inset(6)
                make.bottom.equalTo(platformView.snp.top)
            }
            platformView.snp.remakeConstraints { make in
                make.leading.bottom.trailing.equalToSuperview()
                make.height.equalToSuperview().multipliedBy(0.2077)
            }
            platformView.isHidden = false
            barShadowView.isHidden = true
            backgroundColor = .white
        }
    }
    
    func updateCornerRadius(_ radius: CGFloat) {
        layerCornerRadius = radius
        if style == .style3 {
            imageView.roundCorners([.topLeft, .topRight], radius: layerCornerRadius - 6)
        } else {
            imageView.roundCorners([], radius: 0)
        }
    }
    
    private static var platformImageCaches = [String: UIImage?]()
    static func getPlatformImage(gameType: GameType, style: CoverStyle, scalePlatform: Bool = true) -> UIImage? {
        guard style != .style1 else { return nil }
        let key = gameType.rawValue + "_\(style.rawValue)" + (UIDevice.isPhone && !UIDevice.isLandscape && scalePlatform ? "_\(Constants.Size.GamesPerRow)" : "")
        if let image = GameCoverView.platformImageCaches[key] {
            return image
        } else {
            var image: UIImage? = nil
            if gameType == ._3ds {
                image = style == .style2 ? R.image.sds_cover_v() : R.image.sds_cover_h()
            } else if gameType == .ds {
                image = style == .style2 ? R.image.ds_cover_v() : R.image.ds_cover_h()
            } else if gameType == .gba {
                image = style == .style2 ? R.image.gba_cover_v() : R.image.gba_cover_h()
            } else if gameType == .gbc {
                image = style == .style2 ? R.image.gbc_cover_v() : R.image.gbc_cover_h()
            } else if gameType == .gb {
                image = style == .style2 ? R.image.gb_cover_v() : R.image.gb_cover_h()
            } else if gameType == .nes {
                image = style == .style2 ? R.image.nes_cover_v() : R.image.nes_cover_h()
            } else if gameType == .fds {
                image = style == .style2 ? R.image.fds_cover_v() : R.image.fds_cover_h()
            } else if gameType == .snes {
                image = style == .style2 ? R.image.snes_cover_v() : R.image.snes_cover_h()
            } else if gameType == .psp {
                image = style == .style2 ? R.image.psp_cover_v() : R.image.psp_cover_h()
            } else if gameType == .md {
                if Locale.prefersUS {
                    image = style == .style2 ? R.image.md_cover_v_us() : R.image.md_cover_h_us()
                } else {
                    image = style == .style2 ? R.image.md_cover_v() : R.image.md_cover_h()
                }
            } else if gameType == .mcd {
                if Locale.prefersUS {
                    image = style == .style2 ? R.image.mcd_cover_v_us() : R.image.mcd_cover_h_us()
                } else {
                    image = style == .style2 ? R.image.mcd_cover_v() : R.image.mcd_cover_h()
                }
            } else if gameType == ._32x {
                if Locale.prefersUS {
                    image = style == .style2 ? R.image.s2x_cover_v_us() : R.image.s2x_cover_h_us()
                } else {
                    image = style == .style2 ? R.image.s2x_cover_v() : R.image.s2x_cover_h()
                }
            } else if gameType == .ss {
                image = style == .style2 ? R.image.ss_cover_v() : R.image.ss_cover_h()
            } else if gameType == .sg1000 {
                image = style == .style2 ? R.image.sg1000_cover_v() : R.image.sg1000_cover_h()
            } else if gameType == .gg {
                image = style == .style2 ? R.image.gg_cover_v() : R.image.gg_cover_h()
            } else if gameType == .ms {
                image = style == .style2 ? R.image.ms_cover_v() : R.image.ms_cover_h()
            } else if gameType == .n64 {
                image = style == .style2 ? R.image.n64_cover_v() : R.image.n64_cover_h()
            } else if gameType == .vb {
                image = style == .style2 ? R.image.vb_cover_v() : R.image.vb_cover_h()
            } else if gameType == .pm {
                image = style == .style2 ? R.image.pm_cover_v() : R.image.pm_cover_h()
            } else if gameType == .ps1 {
                image = style == .style2 ? R.image.ps1_cover_v() : R.image.ps1_cover_h()
            } else if gameType == .dc {
                image = style == .style2 ? R.image.dc_cover_v() : R.image.dc_cover_h()
            } else if gameType == .doom {
                image = style == .style2 ? R.image.arcade_cover_v() : R.image.arcade_cover_h()
            } else if gameType == .arcade {
                image = style == .style2 ? R.image.arcade_cover_v() : R.image.arcade_cover_h()
            } else if gameType == .ns {
                image = style == .style2 ? R.image.ns_cover_v() : R.image.ns_cover_h()
            } else if gameType == .a2600 {
                image = style == .style2 ? R.image.a2600_cover_v() : R.image.a2600_cover_h()
            } else if gameType == .a5200 {
                image = style == .style2 ? R.image.a5200_cover_v() : R.image.a5200_cover_h()
            } else if gameType == .a7800 {
                image = style == .style2 ? R.image.a7800_cover_v() : R.image.a7800_cover_h()
            } else if gameType == .jaguar {
                image = style == .style2 ? R.image.jaguar_cover_v() : R.image.jaguar_cover_h()
            } else if gameType == .lynx {
                image = style == .style2 ? R.image.lynx_cover_v() : R.image.lynx_cover_h()
            }
            if UIDevice.isPhone, !UIDevice.isLandscape, scalePlatform, Constants.Size.GamesPerRow != 2, let unwrapImage = image {
                image = unwrapImage.scaled(toWidth: unwrapImage.size.width * (1/(Constants.Size.GamesPerRow-1)))
            }
            GameCoverView.platformImageCaches[key] = image
            return image
        }
    }
    
}
