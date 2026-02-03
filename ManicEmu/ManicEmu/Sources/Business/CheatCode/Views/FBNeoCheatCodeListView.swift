//
//  FBNeoCheatCodeListView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/11/20.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
import ProHUD

class FBNeoCheatCodeListView: BaseView {
    /// 充当导航条
    private var navigationBlurView: NavigationBlurView = {
        let view = NavigationBlurView()
        view.makeBlur()
        return view
    }()
    
    private lazy var closeButton: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .xmark, font: Constants.Font.body(weight: .bold)), enableGlass: true)
        view.enableRoundCorner = true
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            self.didTapClose?()
        }
        return view
    }()
    
    private lazy var tableView: UITableView = {
        let view = BlankSlateTableView()
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.delegate = self
        view.dataSource = self
        view.separatorStyle = .none
        view.showsVerticalScrollIndicator = false
        view.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: Constants.Size.ContentInsetBottom, right: 0)
        view.register(cellWithClass: CheatCodeCollectionViewCell.self)
        view.blankSlateView = FBNeoBlankSlateView()
        return view
    }()
    
    ///游戏
    private var gameCheats: [GameCheat]
    
    var didTapClose: (()->Void)? = nil
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
    }
    
    init(game: Game) {
        if let configs = LibretroCore.sharedInstance().getConfigs(LibretroCore.Cores.FinalBurnNeo.name),
           PlayViewController.isGaming {
            
            var tuples = [(key: String, enable: Bool, name: String)]()
            configs.enumerateLines { line, stop in
                if line.hasPrefix("fbneo-cheat-") {
                    let parts = line.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                    if parts.count == 2 {
                        let key = parts[0]
                        let value = parts[1].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                        let keyComponents = key.split(separator: "-")
                        if keyComponents.count >= 4 {
                            tuples.append((key: key, enable: value != "0 - Disabled", name: String(keyComponents[4])))
                        }
                    }
                }
            }
            
            self.gameCheats = tuples.map({
                let cheatCode = GameCheat()
                cheatCode.name = $0.name
                cheatCode.code = $0.key
                cheatCode.activate = $0.enable
                return cheatCode
            })
        } else {
            self.gameCheats = []
        }
        
        super.init(frame: .zero)
        Log.debug("\(String(describing: Self.self)) init")
        
        addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.leading.bottom.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(Constants.Size.ItemHeightMid)
        }
        
        addSubview(navigationBlurView)
        navigationBlurView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalTo(self.safeAreaLayoutGuide)
            make.height.equalTo(Constants.Size.ItemHeightMid)
        }
        
        let titleLabel = UILabel()
        titleLabel.font = Constants.Font.title(size: .s)
        titleLabel.textColor = Constants.Color.LabelPrimary
        titleLabel.text = R.string.localizable.gamesCheatCode()
        navigationBlurView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(Constants.Size.ContentSpaceMax)
            make.centerY.equalToSuperview()
        }
        
        navigationBlurView.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
            make.centerY.equalToSuperview()
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FBNeoCheatCodeListView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        gameCheats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cheatCode = gameCheats[indexPath.row]
        let cell = tableView.dequeueReusableCell(withClass: CheatCodeCollectionViewCell.self)
        cell.setData(cheatCode: cheatCode)
        cell.switchButton.onChange { value in
            LibretroCore.sharedInstance().updateFBNeoCheatCode([cheatCode.code], enable: value)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}

extension FBNeoCheatCodeListView {
    static var isShow: Bool {
        Sheet.find(identifier: String(describing: FBNeoCheatCodeListView.self)).count > 0 ? true : false
    }
    
    static func show(game: Game, hideCompletion: (()->Void)? = nil, didTapClose: (()->Void)? = nil) {
        Sheet.lazyPush(identifier: String(describing: FBNeoCheatCodeListView.self)) { sheet in
            sheet.configGamePlayingStyle(hideCompletion: hideCompletion)
            
            let view = UIView()
            let containerView = RoundAndBorderView(roundCorner: (UIDevice.isPad || UIDevice.isLandscape || PlayViewController.menuInsets != nil) ? .allCorners : [.topLeft, .topRight])
            containerView.backgroundColor = Constants.Color.Background
            view.addSubview(containerView)
            containerView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                if let maxHeight = sheet.config.cardMaxHeight {
                    make.height.equalTo(maxHeight)
                }
            }
            view.addPanGesture { [weak view, weak sheet] gesture in
                guard let view = view, let sheet = sheet else { return }
                let point = gesture.translation(in: gesture.view)
                view.transform = .init(translationX: 0, y: point.y <= 0 ? 0 : point.y)
                if gesture.state == .recognized {
                    let v = gesture.velocity(in: gesture.view)
                    if (view.y > view.height*2/3 && v.y > 0) || v.y > 1200 {
                        // 达到移除的速度
                        sheet.pop()
                    }
                    UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.5, options: [.allowUserInteraction, .curveEaseOut], animations: {
                        view.transform = .identity
                    })
                }
            }
            
            let listView = FBNeoCheatCodeListView(game: game)
            listView.didTapClose = { [weak sheet] in
                sheet?.pop()
                didTapClose?()
            }
            containerView.addSubview(listView)
            listView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            sheet.set(customView: view).snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
}
