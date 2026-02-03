//
//  GameListStyleCollectionViewCell.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/5/24.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import BetterSegmentedControl

class GameListStyleCollectionViewCell: UICollectionViewCell {
    
    private lazy var gamesPerRowSegmentView: BetterSegmentedControl = {
        let titles = ["2", "3", "4", "5"]
        let segments = LabelSegment.segments(withTitles: titles,
                                             normalFont: Constants.Font.body(),
                                             normalTextColor: Constants.Color.LabelSecondary,
                                            selectedTextColor: Constants.Color.LabelPrimary)
        let options: [BetterSegmentedControl.Option] = [
            .backgroundColor(Constants.Color.Background),
            .indicatorViewInset(5),
            .indicatorViewBackgroundColor(Constants.Color.BackgroundPrimary),
            .cornerRadius(16)
        ]
        let view = BetterSegmentedControl(frame: .zero,
                                          segments: segments,
                                          options: options)
        return view
    }()
    
    private var gamesPerRowLabel: UILabel = {
        let label = UILabel()
        label.font = Constants.Font.body(size: .s)
        label.textColor = Constants.Color.LabelSecondary
        label.text = R.string.localizable.gamesPerRowTitle()
        return label
    }()
    
    private lazy var groupTitleStyleSegmentView: BetterSegmentedControl = {
        let titles = [R.string.localizable.groupTitleStyelAbbr(),
                      R.string.localizable.groupTitleStyelFull(),
                      R.string.localizable.groupTitleStyelBrand()]
        let segments = LabelSegment.segments(withTitles: titles,
                                             normalFont: Constants.Font.body(),
                                             normalTextColor: Constants.Color.LabelSecondary,
                                            selectedTextColor: Constants.Color.LabelPrimary)
        let options: [BetterSegmentedControl.Option] = [
            .backgroundColor(Constants.Color.Background),
            .indicatorViewInset(5),
            .indicatorViewBackgroundColor(Constants.Color.BackgroundPrimary),
            .cornerRadius(16)
        ]
        let view = BetterSegmentedControl(frame: .zero,
                                          segments: segments,
                                          options: options)
        return view
    }()
    
    private var groupTitleStyleLabel: UILabel = {
        let label = UILabel()
        label.font = Constants.Font.body(size: .s)
        label.textColor = Constants.Color.LabelSecondary
        label.text = R.string.localizable.groupTitleStyelDesc()
        return label
    }()
    
    private var hideScrollIndicatorIconView: IconView = {
        let view = IconView()
        view.layerCornerRadius = 6
        view.image = UIImage(symbol: .calendarDayTimelineTrailing, font: Constants.Font.body(size: .s, weight: .medium), color: Constants.Color.LabelPrimary.forceStyle(.dark))
        return view
    }()
    
    private var  hideScrollIndicatorButton: DisabledTapSwitch = {
        let view = DisabledTapSwitch()
        view.onTintColor = Constants.Color.Main
        view.tintColor = Constants.Color.BackgroundSecondary
        return view
    }()
    
    private var hideGroupTitleIconView: IconView = {
        let view = IconView()
        view.layerCornerRadius = 6
        view.image = UIImage(symbol: .listBullet, font: Constants.Font.body(size: .s, weight: .medium), color: Constants.Color.LabelPrimary.forceStyle(.dark))
        return view
    }()
    
    private var hideGroupTitleSwitchButton: DisabledTapSwitch = {
        let view = DisabledTapSwitch()
        view.onTintColor = Constants.Color.Main
        view.tintColor = Constants.Color.BackgroundSecondary
        return view
    }()
    
    private var filterSwitchButton: DisabledTapSwitch = {
        let view = DisabledTapSwitch()
        view.onTintColor = Constants.Color.Main
        view.tintColor = Constants.Color.BackgroundSecondary
        return view
    }()
    
    private lazy var gameSortTypeMenuButton: ContextMenuButton = {
        var actions: [UIMenuElement] = []
        var sortType = GameSortType.allCases.map { $0.title }
        for (index, type) in sortType.enumerated() {
            actions.append((UIAction(title: type) { [weak self] _ in
                guard let self = self else { return }
                self.gameSortTypeLabel.text = type
                Theme.defalut.updateExtra(key: ExtraKey.gameSortType.rawValue, value: index)
                NotificationCenter.default.post(name: Constants.NotificationName.GameSortChange, object: nil)
            }))
        }
        let view = ContextMenuButton(image: nil, menu: UIMenu(title: R.string.localizable.gameSortType(), children: actions))
        return view
    }()
    
    private lazy var gameSortTypeLabel: UILabel = {
        let label = UILabel()
        label.text = (GameSortType(rawValue: Theme.defalut.getExtraInt(key: ExtraKey.gameSortType.rawValue) ?? 0) ?? .title).title
        label.textColor = Constants.Color.LabelSecondary
        label.font = Constants.Font.caption(size: .l)
        return label
    }()
    
    private lazy var gameSortOrderMenuButton: ContextMenuButton = {
        var actions: [UIMenuElement] = []
        var sortOrder = GameSortOrder.allCases.map { $0.title }
        for (index, order) in sortOrder.enumerated() {
            actions.append((UIAction(title: order) { [weak self] _ in
                guard let self = self else { return }
                self.gameSortOrderLabel.text = order
                Theme.defalut.updateExtra(key: ExtraKey.gameSortOrder.rawValue, value: index)
                NotificationCenter.default.post(name: Constants.NotificationName.GameSortChange, object: nil)
            }))
        }
        let view = ContextMenuButton(image: nil, menu: UIMenu(title: R.string.localizable.gameSortOrder(), children: actions))
        return view
    }()
    
    private lazy var gameSortOrderLabel: UILabel = {
        let label = UILabel()
        label.text = (GameSortOrder(rawValue: Theme.defalut.getExtraInt(key: ExtraKey.gameSortOrder.rawValue) ?? 0) ?? .ascending).title
        label.textColor = Constants.Color.LabelSecondary
        label.font = Constants.Font.caption(size: .l)
        return label
    }()
    
    private lazy var backgroundImageView: UIImageView = {
        let image: UIImage?
        var contentMode: UIView.ContentMode = .center
        if FileManager.default.fileExists(atPath: Constants.Path.GameListBackground),
            let i = UIImage(contentsOfFile: Constants.Path.GameListBackground) {
            image = i
            contentMode = .scaleAspectFill
        } else {
            image = R.image.brand_icon()
        }
        let view = UIImageView(image: image)
        view.isUserInteractionEnabled = true
        view.contentMode = contentMode
        view.backgroundColor = Constants.Color.Background
        view.layerCornerRadius = Constants.Size.CornerRadiusMax
        return view
    }()
    
    private lazy var backgroundImageMenuButton: ContextMenuButton = {
        var titles = [R.string.localizable.readyEditCoverTakePhoto(),
                      R.string.localizable.readyEditCoverAlbum(),
                      R.string.localizable.readyEditCoverFile(),
                      R.string.localizable.removeTitle()]
        
        var symbols: [SFSymbol] = [.camera, .photoOnRectangleAngled, .folder, .trash]
        
        var actions: [UIMenuElement] = []
        
        func saveImage(_ image: UIImage?) {
            if let image, let data = image.pngData() {
                do {
                    try data.writeWithCompletePath(to: URL(fileURLWithPath: Constants.Path.GameListBackground))
                    self.backgroundImageView.image = image
                    self.backgroundImageView.contentMode = .scaleAspectFill
                    NotificationCenter.default.post(name: Constants.NotificationName.GameListBackgroundChange, object: nil)
                } catch {
                    
                }
            }
        }
        
        for (index, title) in titles.enumerated() {
            let isLastOne = (index == titles.count - 1)
            actions.append((UIAction(title: title, image: isLastOne ? UIImage(symbol: .trash, color: Constants.Color.Red) : .symbolImage(symbols[index]), attributes: isLastOne  ? .destructive : []) { [weak self] _ in
                guard let self = self else { return }
                if index == 0 {
                    //拍摄
                    ImageFetcher.capture(preferenceSize: nil) { image in
                        saveImage(image)
                    }
                } else if index == 1 {
                    //相册
                    ImageFetcher.pick(preferenceSize: nil) { image in
                        saveImage(image)
                    }
                } else if index == 2 {
                    //文件
                    ImageFetcher.file(preferenceSize: nil) { image in
                        saveImage(image)
                    }
                } else if index == 3 {
                    //移除
                    if FileManager.default.fileExists(atPath: Constants.Path.GameListBackground) {
                        try? FileManager.default.removeItem(atPath: Constants.Path.GameListBackground)
                        self.backgroundImageView.image = R.image.brand_icon()
                        self.backgroundImageView.contentMode = .center
                        NotificationCenter.default.post(name: Constants.NotificationName.GameListBackgroundChange, object: nil)
                    }
                }
            }))
        }
        let view = ContextMenuButton(image: nil, menu: UIMenu(children: actions))
        return view
    }()
    
    private lazy var backgroundImageButton: SymbolButton = {
        let view = SymbolButton(symbol: .cameraFill, symbolFont: Constants.Font.body(size: .l), symbolColor: Constants.Color.Red)
        view.backgroundColor = Constants.Color.BackgroundPrimary
        view.enableRoundCorner = true
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            self.backgroundImageMenuButton.triggerTapGesture()
        }
        return view
    }()
    
    private var mainColorChangeNotification: Any? = nil
    
    deinit {
        if let mainColorChangeNotification = mainColorChangeNotification {
            NotificationCenter.default.removeObserver(mainColorChangeNotification)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layerCornerRadius = Constants.Size.CornerRadiusMax
        backgroundColor = Constants.Color.BackgroundPrimary
        
        let theme = Theme.defalut
        //游戏行数
        addSubview(gamesPerRowLabel)
        gamesPerRowLabel.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
        }
        
        gamesPerRowSegmentView.setIndex(theme.gamesPerRow-2)
        addSubview(gamesPerRowSegmentView)
        gamesPerRowSegmentView.snp.makeConstraints { make in
            make.top.equalTo(gamesPerRowLabel.snp.bottom).offset(Constants.Size.ContentSpaceMin)
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.height.equalTo(Constants.Size.ItemHeightMid)
        }
        gamesPerRowSegmentView.on(.valueChanged) { sender, forEvent in
            guard let index = (sender as? BetterSegmentedControl)?.index else { return }
            UIDevice.generateHaptic()
            Theme.change { realm in
                theme.gamesPerRow = index + 2
            }
        }
        
        //隐藏滚动条
        let hideScrollIndicatorContainer = UIView()
        hideScrollIndicatorContainer.backgroundColor = Constants.Color.Background
        hideScrollIndicatorContainer.layerCornerRadius = Constants.Size.CornerRadiusMid
        addSubview(hideScrollIndicatorContainer)
        hideScrollIndicatorContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.top.equalTo(gamesPerRowSegmentView.snp.bottom).offset(Constants.Size.ContentSpaceMax)
            make.height.equalTo(Constants.Size.ItemHeightMax)
        }
        
        hideScrollIndicatorContainer.addSubview(hideScrollIndicatorIconView)
        hideScrollIndicatorIconView.backgroundColor = Constants.Color.Main
        hideScrollIndicatorIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
            make.size.equalTo(Constants.Size.IconSizeMin)
            make.centerY.equalToSuperview()
        }
        
        let hideScrollIndicatorTitleLabel: UILabel = {
            let view = UILabel()
            view.numberOfLines = 3
            let matt = NSMutableAttributedString(string: R.string.localizable.gamesHideScrollIndicator(), attributes: [.font: Constants.Font.body(size: .l, weight: .semibold), .foregroundColor: Constants.Color.LabelPrimary])
            view.attributedText = matt
            return view
        }()
        hideScrollIndicatorContainer.addSubview(hideScrollIndicatorTitleLabel)
        hideScrollIndicatorTitleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(hideScrollIndicatorIconView)
            make.leading.equalTo(hideScrollIndicatorIconView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.trailing.equalToSuperview().offset(-46-Constants.Size.ContentSpaceMid)
        }
        
        hideScrollIndicatorContainer.addSubview(hideScrollIndicatorButton)
        hideScrollIndicatorButton.setOn(theme.hideIndicator, animated: false)
        hideScrollIndicatorButton.snp.makeConstraints { make in
            make.centerY.equalTo(hideScrollIndicatorIconView)
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMin)
            if #available(iOS 26.0, *) {
                make.size.equalTo(CGSize(width: 63, height: 28))
            } else {
                make.size.equalTo(CGSize(width: 51, height: 31))
            }
        }
        if #available(iOS 26.0, *) {} else {
            hideScrollIndicatorButton.transform = CGAffineTransformMakeScale(0.9, 0.9)
        }
        hideScrollIndicatorButton.onChange { value in
            Theme.change { realm in
                theme.hideIndicator = value
            }
        }
        
        //分组标题样式
        addSubview(groupTitleStyleLabel)
        groupTitleStyleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
            make.top.equalTo(hideScrollIndicatorContainer.snp.bottom).offset(Constants.Size.ContentSpaceMax)
        }
        
        groupTitleStyleSegmentView.setIndex(theme.groupTitleStyle.rawValue)
        addSubview(groupTitleStyleSegmentView)
        groupTitleStyleSegmentView.snp.makeConstraints { make in
            make.top.equalTo(groupTitleStyleLabel.snp.bottom).offset(Constants.Size.ContentSpaceMin)
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.height.equalTo(Constants.Size.ItemHeightMid)
        }
        groupTitleStyleSegmentView.on(.valueChanged) { sender, forEvent in
            guard let index = (sender as? BetterSegmentedControl)?.index else { return }
            UIDevice.generateHaptic()
            if let style = GroupTitleStyle(rawValue: index) {
                Theme.change { realm in
                    theme.groupTitleStyle = style
                }
            }
        }
        
        //隐藏分组标题
        let hideGroupTitleContainer = UIView()
        hideGroupTitleContainer.backgroundColor = Constants.Color.Background
        hideGroupTitleContainer.layerCornerRadius = Constants.Size.CornerRadiusMid
        addSubview(hideGroupTitleContainer)
        hideGroupTitleContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.top.equalTo(groupTitleStyleSegmentView.snp.bottom).offset(Constants.Size.ContentSpaceMax)
            make.height.equalTo(Constants.Size.ItemHeightMax)
        }
        
        hideGroupTitleContainer.addSubview(hideGroupTitleIconView)
        hideGroupTitleIconView.backgroundColor = Constants.Color.Main
        hideGroupTitleIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
            make.size.equalTo(Constants.Size.IconSizeMin)
            make.centerY.equalToSuperview()
        }
        
        let hideGroupTitleLabel: UILabel = {
            let view = UILabel()
            view.font = Constants.Font.body(size: .l, weight: .semibold)
            view.textColor = Constants.Color.LabelPrimary
            view.text = R.string.localizable.hideGroupTitleDesc()
            return view
        }()
        hideGroupTitleContainer.addSubview(hideGroupTitleLabel)
        hideGroupTitleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(hideGroupTitleIconView)
            make.leading.equalTo(hideGroupTitleIconView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.trailing.equalToSuperview().offset(-46-Constants.Size.ContentSpaceMid)
        }
        
        hideGroupTitleContainer.addSubview(hideGroupTitleSwitchButton)
        hideGroupTitleSwitchButton.setOn(theme.hideGroupTitle, animated: false)
        hideGroupTitleSwitchButton.snp.makeConstraints { make in
            make.centerY.equalTo(hideGroupTitleIconView)
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMin)
            if #available(iOS 26.0, *) {
                make.size.equalTo(CGSize(width: 63, height: 28))
            } else {
                make.size.equalTo(CGSize(width: 51, height: 31))
            }
        }
        if #available(iOS 26.0, *) {} else {
            hideGroupTitleSwitchButton.transform = CGAffineTransformMakeScale(0.9, 0.9)
        }
        hideGroupTitleSwitchButton.onChange { value in
            Theme.change { realm in
                theme.hideGroupTitle = value
            }
        }
        
        //排序
        let gameSortLabel = UILabel()
        gameSortLabel.font = Constants.Font.body(size: .s)
        gameSortLabel.textColor = Constants.Color.LabelSecondary
        gameSortLabel.text = R.string.localizable.gameSortDesc()
        addSubview(gameSortLabel)
        gameSortLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
            make.top.equalTo(hideGroupTitleContainer.snp.bottom).offset(Constants.Size.ContentSpaceMax)
        }
        
        let gameSortContainer = UIView()
        gameSortContainer.backgroundColor = Constants.Color.Background
        gameSortContainer.layerCornerRadius = Constants.Size.CornerRadiusMid
        addSubview(gameSortContainer)
        gameSortContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.top.equalTo(gameSortLabel.snp.bottom).offset(Constants.Size.ContentSpaceMin)
            make.height.equalTo(Constants.Size.ItemHeightMax * 2)
        }
        
        func genGameSortView(symbol: SFSymbol, title: String, detailLabel: UILabel) -> UIView {
            let container = UIView()
            container.enableInteractive = true
            container.delayInteractiveTouchEnd = true
            
            let iconView = IconView()
            iconView.layerCornerRadius = 6
            iconView.image = UIImage(symbol: symbol, font: Constants.Font.body(size: .s, weight: .medium), color: Constants.Color.LabelPrimary.forceStyle(.dark))
            container.addSubview(iconView)
            iconView.backgroundColor = Constants.Color.Main
            iconView.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
                make.size.equalTo(Constants.Size.IconSizeMin)
                make.centerY.equalToSuperview()
            }
            
            let titleLabel: UILabel = {
                let view = UILabel()
                view.font = Constants.Font.body(size: .l, weight: .semibold)
                view.textColor = Constants.Color.LabelPrimary
                view.text = title
                return view
            }()
            container.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.centerY.equalTo(iconView)
                make.leading.equalTo(iconView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            }
            
            let chevronIconView = UIImageView(image: UIImage(symbol: .chevronRight, font: Constants.Font.caption(size: .l, weight: .bold), color: Constants.Color.BackgroundSecondary))
            chevronIconView.contentMode = .center
            container.addSubview(chevronIconView)
            chevronIconView.snp.makeConstraints { make in
                make.centerY.equalTo(iconView)
                make.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            }
            
            container.addSubview(detailLabel)
            detailLabel.snp.makeConstraints { make in
                make.centerY.equalTo(iconView)
                make.trailing.equalTo(chevronIconView.snp.leading).offset(-Constants.Size.ContentSpaceUltraTiny)
            }
            return container
        }
        
        //排序方式
        let gameSortTypeView = genGameSortView(symbol: .line3Horizontal, title: R.string.localizable.gameSortType(), detailLabel: gameSortTypeLabel)
        gameSortTypeView.addSubview(gameSortTypeMenuButton)
        gameSortTypeMenuButton.snp.makeConstraints { make in
            make.edges.equalTo(gameSortTypeLabel)
        }
        gameSortContainer.addSubview(gameSortTypeView)
        gameSortTypeView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(Constants.Size.ItemHeightMax)
        }
        gameSortTypeView.addTapGesture { [weak self] gesture in
            self?.gameSortTypeMenuButton.triggerTapGesture()
        }
        
        //排序顺序
        let gameSortOrderView = genGameSortView(symbol: .arrowUpArrowDown, title: R.string.localizable.gameSortOrder(), detailLabel: gameSortOrderLabel)
        gameSortOrderView.addSubview(gameSortOrderMenuButton)
        gameSortOrderMenuButton.snp.makeConstraints { make in
            make.edges.equalTo(gameSortOrderLabel)
        }
        gameSortContainer.addSubview(gameSortOrderView)
        gameSortOrderView.snp.makeConstraints { make in
            make.leading.bottom.trailing.equalToSuperview()
            make.top.equalTo(gameSortTypeView.snp.bottom)
        }
        gameSortOrderView.addTapGesture { [weak self] gesture in
            self?.gameSortOrderMenuButton.triggerTapGesture()
        }
        
        //背景
        let backgroundImageLabel = UILabel()
        backgroundImageLabel.font = Constants.Font.body(size: .s)
        backgroundImageLabel.textColor = Constants.Color.LabelSecondary
        backgroundImageLabel.text = R.string.localizable.gameListBackground()
        addSubview(backgroundImageLabel)
        backgroundImageLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
            make.top.equalTo(gameSortContainer.snp.bottom).offset(Constants.Size.ContentSpaceMax)
        }
        
        addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { make in
            make.size.equalTo(154)
            make.centerX.equalToSuperview()
            make.top.equalTo(backgroundImageLabel.snp.bottom).offset(Constants.Size.ContentSpaceMin)
        }
        backgroundImageView.addSubview(backgroundImageMenuButton)
        backgroundImageView.addSubview(backgroundImageButton)
        backgroundImageButton.snp.makeConstraints { make in
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
            make.trailing.bottom.equalToSuperview().inset(6)
        }
        backgroundImageMenuButton.snp.makeConstraints { make in
            make.edges.equalTo(backgroundImageButton)
        }
        
        //使用厂商筛选
        let filterlabel = UILabel()
        filterlabel.font = Constants.Font.body(size: .s)
        filterlabel.textColor = Constants.Color.LabelSecondary
        filterlabel.text = R.string.localizable.filterTitle()
        addSubview(filterlabel)
        filterlabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
            make.top.equalTo(backgroundImageView.snp.bottom).offset(Constants.Size.ContentSpaceMax)
        }
        
        let filterContainer = UIView()
        filterContainer.backgroundColor = Constants.Color.Background
        filterContainer.layerCornerRadius = Constants.Size.CornerRadiusMid
        addSubview(filterContainer)
        filterContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.top.equalTo(filterlabel.snp.bottom).offset(Constants.Size.ContentSpaceMin)
            make.height.equalTo(Constants.Size.ItemHeightMax)
        }
        
        let filterIconView = IconView()
        filterIconView.layerCornerRadius = 6
        filterIconView.image = UIImage(symbol: .line3HorizontalDecrease, font: Constants.Font.body(size: .s, weight: .medium), color: Constants.Color.LabelPrimary.forceStyle(.dark))
        filterContainer.addSubview(filterIconView)
        filterIconView.backgroundColor = Constants.Color.Main
        filterIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
            make.size.equalTo(Constants.Size.IconSizeMin)
            make.centerY.equalToSuperview()
        }
        
        let filterTitleLabel: UILabel = {
            let view = UILabel()
            view.font = Constants.Font.body(size: .l, weight: .semibold)
            view.textColor = Constants.Color.LabelPrimary
            view.text = R.string.localizable.enableManufacturerFilter()
            return view
        }()
        filterContainer.addSubview(filterTitleLabel)
        filterTitleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(filterIconView)
            make.leading.equalTo(filterIconView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
        }
        
        filterContainer.addSubview(filterSwitchButton)
        filterSwitchButton.setOn(theme.getExtraBool(key: ExtraKey.enableManufacturerFilter.rawValue) ?? false, animated: false)
        filterSwitchButton.snp.makeConstraints { make in
            make.centerY.equalTo(filterIconView)
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMin)
            if #available(iOS 26.0, *) {
                make.size.equalTo(CGSize(width: 63, height: 28))
            } else {
                make.size.equalTo(CGSize(width: 51, height: 31))
            }
        }
        if #available(iOS 26.0, *) {} else {
            filterSwitchButton.transform = CGAffineTransformMakeScale(0.9, 0.9)
        }
        filterSwitchButton.onChange { value in
            theme.updateExtra(key: ExtraKey.enableManufacturerFilter.rawValue, value: value)
            NotificationCenter.default.post(name: Constants.NotificationName.ManufacturerFilterChange, object: value)
        }
        
        mainColorChangeNotification = NotificationCenter.default.addObserver(forName: Constants.NotificationName.MainColorChange, object: nil, queue: .main) { [weak self] notification in
            guard let self = self else { return }
            self.hideScrollIndicatorIconView.backgroundColor = Constants.Color.Main
            self.hideGroupTitleIconView.backgroundColor = Constants.Color.Main
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
