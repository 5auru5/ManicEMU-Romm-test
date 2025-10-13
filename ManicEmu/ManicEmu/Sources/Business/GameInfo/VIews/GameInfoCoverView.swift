//
//  GameInfoCoverView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/2/14.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit
import IceCream
import Kingfisher

class GameInfoCoverView: BaseView {
    var maskTopView: UIView = {
        let view = UIView()
        view.backgroundColor = Constants.Color.BackgroundPrimary
        view.alpha = 0
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private var backgroundGradientView: UIView = {
        let view = GradientView()
        view.setupGradient(colors: [.clear, Constants.Color.Background], locations: [0.0, 1.0], direction: .topToBottom)
        return view
    }()
    
    private var coverContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Constants.Size.CornerRadiusMax
        view.makeShadow(ofColor: Constants.Color.BackgroundPrimary, radius: 30)
        return view
    }()
    
    private var coverImageView: GameCoverView = {
        let view = GameCoverView()
        return view
    }()
    
    lazy var editCoverButton: ContextMenuButton = {
        let view = ContextMenuButton(image: UIImage(symbol: .ellipsis), menu: generateMenu(), enableGlass: true)
        view.layerCornerRadius = Constants.Size.IconSizeMid.height/2
        if #available(iOS 26.0, *) {
            view.backgroundColor = .clear
        } else {
            view.backgroundColor = Constants.Color.BackgroundSecondary
        }
        return view
    }()
    
    private var game: Game
    
    private var CoverImageSize: CGSize = .init(UIDevice.isPhone ? 236.0 : 200.0)
    
    var didCoverUpdate: ((UIImage?) -> Void)? = nil
    
    private lazy var coverUpdation: (UIImage?) -> Void = { [weak self] image in
        guard let self = self else { return }
        guard let image = image else { return }
        
        self.coverImageView.imageView.image = image
        self.backgroundGradientView.backgroundColor = image.dominantBackground
        self.didCoverUpdate?(image)
        
        let data = image.jpegData(compressionQuality: 0.7)
        guard let data = data else { return }
        Game.change(action: { realm in
            self.game.gameCover?.deleteAndClean(realm: realm)
            self.game.gameCover = CreamAsset.create(objectID: self.game.id, propName: "gameCover", data: data)
        })
    }
    
    init(game: Game) {
        self.game = game
        super.init(frame: .zero)
        backgroundColor = Constants.Color.BackgroundPrimary
        
        addSubview(backgroundGradientView)
        backgroundGradientView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(378)
            make.bottom.equalToSuperview()
        }
        
         
        if Constants.Size.GameCoverStyle == .style1 {
            let ratio = Constants.Size.GameCoverRatio(gameType: game.gameType)
            if ratio == 1.0 {
                //正方形
            } else if ratio < 1.0 {
                //竖大于横
                CoverImageSize = CGSize(width: CoverImageSize.height * ratio, height: CoverImageSize.height)
            } else {
                //横大于竖
                CoverImageSize = CGSize(width: CoverImageSize.width, height: CoverImageSize.width/ratio)
            }
        }
        
        addSubview(coverContainerView)
        coverContainerView.snp.makeConstraints { make in
            make.size.equalTo(CoverImageSize)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-Constants.Size.ItemHeightUltraTiny)
        }
        
        coverContainerView.addSubview(coverImageView)
        coverImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        coverImageView.setData(game: game, coverSize: CoverImageSize, style: Constants.Size.GameCoverStyle, scalePlatform: false)
        coverImageView.imageView.setGameCover(game: game, size: CoverImageSize) { [weak self] image in
            self?.backgroundGradientView.backgroundColor = image.dominantBackground
        }
        coverImageView.layoutSubviews()
        
        addSubview(editCoverButton)
        editCoverButton.snp.makeConstraints { make in
            make.size.equalTo(Constants.Size.IconSizeMid)
            make.top.trailing.equalTo(coverContainerView).inset(Constants.Size.ContentSpaceMin)
        }
        
        addSubview(maskTopView)
        maskTopView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func generateMenu() -> UIMenu {
        //点击选择封面照片
        var titles = [R.string.localizable.readyEditCoverTakePhoto(),
                          R.string.localizable.readyEditCoverAlbum(),
                          R.string.localizable.readyEditCoverFile(),
                      R.string.localizable.readyEditCoverSearch()]
        
        var symbols: [SFSymbol] = [.camera, .photoOnRectangleAngled, .folder, .magnifyingglass]
        
        if let _ = game.gameCover?.storedData() {
            titles.append(R.string.localizable.editTitle())
            symbols.append(.pencil)
        } else if let _ = game.onlineCoverUrl {
            titles.append(R.string.localizable.editTitle())
            symbols.append(.pencil)
        }
        
        var actions: [UIMenuElement] = []
        for (index, title) in titles.enumerated() {
            let action = UIAction(title: title, image: .symbolImage(symbols[index])) { [weak self] _ in
                guard let self = self else { return }
                if index == 0 {
                    //拍摄
                    ImageFetcher.capture(completion: self.coverUpdation)
                } else if index == 1 {
                    //相册
                    ImageFetcher.pick(completion: self.coverUpdation)
                } else if index == 2 {
                    //文件
                    ImageFetcher.file(completion: self.coverUpdation)
                } else if index == 3 {
                    //搜索
                    topViewController()?.present(GameCoverSearchViewController(game: game, completion: self.coverUpdation), animated: true)
                } else if index == 4 {
                    //编辑
                    if let imageData = game.gameCover?.storedData(), let image = UIImage(data: imageData) {
                        ImageFetcher.edit(image: image, completion: self.coverUpdation)
                    } else if let onlineCoverUrl = game.onlineCoverUrl, let url = URL(string: onlineCoverUrl) {
                        KingfisherManager.shared.retrieveImage(with: url) { [weak self] result in
                            guard let self = self else { return }
                            switch result {
                            case .success(let imageResult):
                                Task { @MainActor in
                                    ImageFetcher.edit(image: imageResult.image, completion: self.coverUpdation)
                                }
                            case .failure(_):
                                Task { @MainActor in
                                    UIView.makeToast(message: R.string.localizable.onlineCoverFetchFailed())
                                }
                            }
                        }
                    }
                }
            }
            actions.append(action)
        }

        return UIMenu(children: actions)
    }
}
