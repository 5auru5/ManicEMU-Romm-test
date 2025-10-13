//
//  RetroAchievementsDetailViewController.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/8/19.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

class RetroAchievementsDetailViewController: BaseViewController {
    
    private let containerView = UIView()
    
    private var shareImageView: UIView? = nil
    
    init(achievement: CheevosAchievement) {
        super.init(fullScreen: true)
        view.backgroundColor = .clear
        
        view.addSubview(containerView)
        containerView.makeBlur()
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let detailView = RetroAchievementsDetailView(achievement: achievement) { [weak self] in
            self?.dismiss(animated: true)
        }
        containerView.addSubview(detailView)
        detailView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }
        
        let shareButton = SymbolButton(image: UIImage(symbol: .squareAndArrowUp, font: Constants.Font.body(weight: .bold)), enableGlass: true)
        shareButton.enableRoundCorner = true
        shareButton.addTapGesture { [weak self] gesture in
            guard let self else { return }
            UIView.makeLoading()
            self.generateShareImage(achievement: achievement) { image in
                ShareManager.shareImage(image: image)
                UIView.hideLoading()
                self.shareImageView?.removeFromSuperview()
                self.shareImageView = nil
            }
        }
        view.addSubview(shareButton)
        shareButton.snp.makeConstraints { make in
            make.size.equalTo(Constants.Size.IconSizeMid)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(Constants.Size.ContentSpaceMin)
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
        }
    }
    
    func generateShareImage(achievement: CheevosAchievement, completion: ((UIImage)->Void)? = nil) {
        let shareImageView = UIView()
        view.insertSubview(shareImageView, belowSubview: containerView)
        shareImageView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.width.equalToSuperview()
            make.leading.equalTo(view.snp.trailing)
        }

        let backgroundImageView = UIImageView(image: R.image.launch_bg())
        backgroundImageView.contentMode = .scaleAspectFill
        shareImageView.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            if UIDevice.isPhone, UIDevice.isLandscape {
                make.leading.trailing.equalToSuperview()
            } else {
                make.top.bottom.equalToSuperview()
            }
        }
        
        let detailView = RetroAchievementsDetailView(achievement: achievement, shareMode: true) { }
        shareImageView.addSubview(detailView)
        detailView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }
        
        self.shareImageView = shareImageView
        
        DispatchQueue.main.asyncAfter(delay: 0.5) {
            completion?(shareImageView.asImage())
        }
        
        return
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
