//
//  RetroAchievementsListViewController.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/8/19.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

class RetroAchievementsListViewController: BaseViewController {
    
    private var quitGamingNotification: Any? = nil
    
    private let backgroundImageView: UIImageView = {
        let view = UIImageView(image: R.image.retro_bg())
        return view
    }()
    
    private lazy var listView: RetroAchievementListView = {
        let view = RetroAchievementListView(game: self.game, bottomInset: self.bottomInset)
        return view
    }()
    
    static var isShow = false
    
    var didClose: (()->Void)? = nil
    
    private let game: Game
    
    private var bottomInset: CGFloat? = nil
    
    deinit {
        if let quitGamingNotification {
            NotificationCenter.default.removeObserver(quitGamingNotification)
        }
    }
    
    init(game: Game, bottomInset: CGFloat? = nil) {
        self.game = game
        super.init(nibName: nil, bundle: nil)
        self.bottomInset = bottomInset
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Self.isShow = true

        view.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
        }
        
        view.addSubview(listView)
        listView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addCloseButton()
        
        //退出游戏
        quitGamingNotification = NotificationCenter.default.addObserver(forName: Constants.NotificationName.QuitGaming, object: nil, queue: .main, using: { [weak self] notification in
            guard let self else { return }
            self.dismiss(animated: true)
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Self.isShow = false
        didClose?()
    }
}
