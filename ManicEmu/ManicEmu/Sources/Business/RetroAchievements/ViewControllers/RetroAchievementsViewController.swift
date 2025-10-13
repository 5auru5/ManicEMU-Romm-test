//
//  RetroAchievementsViewController.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/8/19.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

class RetroAchievementsViewController: BaseViewController {
    private let backgroundImageView: UIImageView = {
        let view = UIImageView(image: R.image.retro_bg())
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    private lazy var loginView: RetroAchievementsLoginView = {
        let view = RetroAchievementsLoginView()
        view.loginSuccess = { [weak self] in
            guard let self else { return }
            if let dismiss = self.dismissAfterLoginSuccess {
                self.dismiss(animated: true) {
                    dismiss()
                }
                return
            }
            self.loginView.removeFromSuperview()
            self.achievementsUser = AchievementsUser.getUser()
            if UIDevice.isPhone {
                self.view.insertSubview(self.profileView, belowSubview: self.closeButton)
            } else {
                self.view.addSubview(self.profileView)
            }
            self.profileView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        return view
    }()
    
    private lazy var profileView: RetroAchievementsProfileView = {
        let view = RetroAchievementsProfileView(username: self.achievementsUser?.username ?? "")
        view.logoutSuccess = { [weak self] in
            guard let self else { return }
            UIView.makeAlert(detail: R.string.localizable.achievementsLogoutAlert(), confirmTitle: R.string.localizable.confirmTitle(), confirmAction: {
                CheevosBridge.logoutCheevos()
                Settings.defalut.updateExtra(key: ExtraKey.achievementsUser.rawValue, value: "")
                self.profileView.removeFromSuperview()
                self.achievementsUser = nil
                self.view.insertSubview(self.loginView, belowSubview: self.closeButton)
                self.loginView.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
            })
        }
        return view
    }()
    
    private var achievementsUser = AchievementsUser.getUser()
    
    var dismissAfterLoginSuccess: (()->Void)? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
        }
        
        if let _ = achievementsUser {
            //已登录
            view.addSubview(profileView)
            profileView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else {
            //未登录
            view.addSubview(loginView)
            loginView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        
        if UIDevice.isPhone {
            addCloseButton()
        }
    }
}
