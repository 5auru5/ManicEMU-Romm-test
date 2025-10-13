//
//  RetroAchievementsListCell.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/8/20.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later
import Kingfisher
import MarqueeLabel
import BetterSegmentedControl

class RetroAchievementsListCell: UICollectionViewCell {
    
    class AchievementsListView: UIView, UICollectionViewDataSource, UICollectionViewDelegate {
        
        class AchievementsListViewCell: UICollectionViewCell {
            private let imageView: UIImageView = {
                let view = UIImageView()
                view.contentMode = .scaleAspectFill
                return view
            }()
            
            private let missableImageView: SymbolButton = {
                let view = SymbolButton(image: UIImage(symbol: .exclamationmarkCircle, font: Constants.Font.caption(size: .l), color: .white))
                view.enableRoundCorner = true
                view.backgroundColor = .black
                view.isHidden = true
                return view
            }()
            
            private let progressionImageView: SymbolButton = {
                let view = SymbolButton(image: UIImage(symbol: .clockBadgeCheckmark, font: Constants.Font.caption(size: .l), color: .white))
                view.enableRoundCorner = true
                view.backgroundColor = .black
                view.isHidden = true
                return view
            }()
            
            private let winImageView: SymbolButton = {
                let view = SymbolButton(image: UIImage(symbol: .starCircle, font: Constants.Font.caption(size: .l), color: .white))
                view.enableRoundCorner = true
                view.backgroundColor = .black
                view.isHidden = true
                return view
            }()
            
            override init(frame: CGRect) {
                super.init(frame: frame)
                addSubview(imageView)
                imageView.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
                
                imageView.addSubview(missableImageView)
                missableImageView.snp.makeConstraints { make in
                    make.top.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceUltraTiny)
                    make.size.equalTo(15)
                }
                
                imageView.addSubview(progressionImageView)
                progressionImageView.snp.makeConstraints { make in
                    make.top.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceUltraTiny)
                    make.size.equalTo(15)
                }
                
                imageView.addSubview(winImageView)
                winImageView.snp.makeConstraints { make in
                    make.top.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceUltraTiny)
                    make.size.equalTo(15)
                }
            }
            
            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
            func setData(achievement: CheevosAchievement, isHardcoreList: Bool) {
                var url: String? = nil
                if isHardcoreList {
                    if achievement.hardcoreUnlocked {
                        url = achievement.unlockedBadgeUrl
                    } else {
                        url = achievement.activeBadgeUrl
                    }
                } else {
                    if achievement.softcoreUnlocked {
                        url = achievement.unlockedBadgeUrl
                    } else {
                        url = achievement.activeBadgeUrl
                    }
                }
                imageView.kf.setImage(with: URL(string: url), placeholder: UIImage.placeHolder(preferenceSize: .init(64)))
                if achievement.isMissable && achievement.isProgression {
                    winImageView.isHidden = false
                    missableImageView.isHidden = true
                    progressionImageView.isHidden = true
                } else {
                    if achievement.isMissable {
                        winImageView.isHidden = true
                        missableImageView.isHidden = false
                        progressionImageView.isHidden = true
                    } else if achievement.isProgression {
                        winImageView.isHidden = true
                        missableImageView.isHidden = true
                        progressionImageView.isHidden = false
                    } else {
                        winImageView.isHidden = true
                        missableImageView.isHidden = true
                        progressionImageView.isHidden = true
                    }
                }
            }
        }

        var datas: [CheevosAchievement] = [] {
            didSet {
                collectionView.reloadData()
            }
        }
        
        private var isHardcoreList = true
        
        var didTapAchievement: ((CheevosAchievement)->Void)? = nil
        
        private lazy var segmentView: BetterSegmentedControl = {
            let titles = [R.string.localizable.hardcore(), R.string.localizable.softcore()]
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
            
            view.on(.valueChanged) { [weak self] sender, forEvent in
                guard let self = self, let index = (sender as? BetterSegmentedControl)?.index else { return }
                UIDevice.generateHaptic()
                self.isHardcoreList = index == 0
                self.datas = self.datas.sorted(by: {
                    if self.isHardcoreList {
                        if $0.hardcoreUnlocked {
                            return true
                        } else if $1.hardcoreUnlocked {
                            return false
                        }
                        return false
                    } else {
                        if $0.softcoreUnlocked {
                            return true
                        } else if $1.softcoreUnlocked {
                            return false
                        }
                        return false
                    }
                })
            }
            return view
        }()
        
        private lazy var collectionView: UICollectionView = {
            let view = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
            view.backgroundColor = .clear
            view.contentInsetAdjustmentBehavior = .never
            view.register(cellWithClass: AchievementsListViewCell.self)
            view.showsVerticalScrollIndicator = false
            view.showsHorizontalScrollIndicator = false
            view.dataSource = self
            view.delegate = self
            return view
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = Constants.Color.BackgroundPrimary
            layerCornerRadius = Constants.Size.CornerRadiusMax
            
            addSubview(segmentView)
            segmentView.snp.makeConstraints { make in
                make.top.equalTo(Constants.Size.ContentSpaceMid)
                make.height.equalTo(Constants.Size.ItemHeightMid)
                make.leading.equalTo(Constants.Size.ContentSpaceHuge)
                make.trailing.equalTo(-Constants.Size.ContentSpaceHuge)
            }
            
            addSubview(collectionView)
            collectionView.snp.makeConstraints { make in
                make.top.equalTo(segmentView.snp.bottom)
                make.leading.bottom.trailing.equalToSuperview()
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func createLayout() -> UICollectionViewLayout {
            let layout = UICollectionViewCompositionalLayout { sectionIndex, env in
                var column = 4.0
                if UIDevice.isPhone && UIDevice.isLandscape {
                    column = 8.0
                } else if UIDevice.isPad && UIDevice.isLandscape {
                    column = 6.0
                }
                let cellSize = (env.container.contentSize.width - Constants.Size.ContentSpaceHuge*2 - Constants.Size.ContentSpaceMin*(column-1))/column
                
                //item布局
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(cellSize),
                                                                                     heightDimension: .absolute(cellSize)))
                //group布局
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(cellSize)), subitem: item, count: Int(column))
                group.interItemSpacing = NSCollectionLayoutSpacing.fixed(Constants.Size.ContentSpaceMin)
                //section布局
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = Constants.Size.ContentSpaceMin
                section.contentInsets = NSDirectionalEdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24)
                return section
            }
            return layout
        }
        
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { datas.count }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withClass: AchievementsListViewCell.self, for: indexPath)
            cell.setData(achievement: datas[indexPath.row], isHardcoreList: isHardcoreList)
            return cell
        }
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            didTapAchievement?(datas[indexPath.row])
        }
    }
    
    class AchievementsProgressView: UIView {
        let indicatorView: UIView = {
            let view = UIView()
            view.backgroundColor = Constants.Color.Yellow
            view.layerCornerRadius = 1
            return view
        }()
        //0-100
        var progress: CGFloat = 0 {
            didSet {
                indicatorView.snp.remakeConstraints { make in
                    make.leading.top.bottom.equalToSuperview()
                    make.width.equalToSuperview().multipliedBy(progress/100)
                }
                UIView.springAnimate {
                    self.layoutIfNeeded()
                }
            }
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = Constants.Color.BackgroundSecondary
            layerCornerRadius = 1
            addSubview(indicatorView)
            indicatorView.snp.makeConstraints { make in
                make.leading.top.bottom.equalToSuperview()
                make.width.equalTo(0)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }
    
    private let coverImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.layerCornerRadius = Constants.Size.CornerRadiusMid
        return view
    }()
    
    private let progressLabel: UILabel = {
        let view = UILabel()
        view.font = Constants.Font.body()
        view.textColor = Constants.Color.Yellow
        return view
    }()
    
    private let progressView: AchievementsProgressView = {
        let view = AchievementsProgressView()
        return view
    }()
    
    private let titleLabel: UILabel = {
        let view = MarqueeLabel()
        view.textAlignment = .left
        view.font = Constants.Font.title(size: .l, weight: .semibold)
        view.textColor = Constants.Color.LabelPrimary
        return view
    }()
    
    private let lastActivityIcon: UIImageView = {
        let view = UIImageView()
        view.contentMode = .center
        view.image = .symbolImage(.starCircleFill).applySymbolConfig(color: Constants.Color.LabelSecondary)
        return view
    }()
    
    private let lastActivityLabel: UILabel = {
        let view = UILabel()
        view.textColor = Constants.Color.LabelSecondary
        view.font = Constants.Font.body()
        return view
    }()
    
    let enableSwitchButton: DisabledTapSwitch = {
        let view = DisabledTapSwitch()
        view.onTintColor = Constants.Color.Main
        view.tintColor = Constants.Color.BackgroundSecondary
        return view
    }()
    
    let hardcoreSwitchButton: DisabledTapSwitch = {
        let view = DisabledTapSwitch()
        view.onTintColor = Constants.Color.Main
        view.tintColor = Constants.Color.BackgroundSecondary
        return view
    }()
    
    let alwaysShowProgressButton: DisabledTapSwitch = {
        let view = DisabledTapSwitch()
        view.onTintColor = Constants.Color.Main
        view.tintColor = Constants.Color.BackgroundSecondary
        return view
    }()
    
    private let achievementsCountLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        return view
    }()
    
    private let pointLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        return view
    }()
    
    private lazy var listView: AchievementsListView = {
        let view = AchievementsListView()
        view.didTapAchievement = { [weak self] achievement in
            guard let self else { return }
            //尝试读取缓存中的解锁进度
            if achievement.measuredProgress == nil,
               let game = self.game,
               let achievementProgress = game.getAchievementProgress(id: achievement._id) {
                achievement.measuredPercent = achievementProgress.measuredPercent
                achievement.measuredProgress = achievementProgress.measuredProgress
            }
            topViewController()?.present(RetroAchievementsDetailViewController(achievement: achievement), animated: true)
        }
        return view
    }()
    
    private lazy var bottomButton: UIButton = {
        let view = UIButton(type: .custom)
        view.setAttributedTitle(NSAttributedString(string: "RetroAchievements", attributes: [.font: Constants.Font.body(size: .s), .foregroundColor: Constants.Color.Indigo]).underlined, for: .normal)
        view.onTap { [weak self] in
            guard let self else { return }
            if let username = self.username {
                UIApplication.shared.open(Constants.URLs.RetroProfile(username: username))
            } else {
                UIApplication.shared.open(Constants.URLs.Retro)
            }
        }
        return view
    }()
    
    private var username: String? = nil
    
    private weak var game: Game? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(coverImageView)
        coverImageView.snp.makeConstraints { make in
            make.size.equalTo(80)
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceHuge)
            make.top.equalToSuperview()
        }
        
        let retroAchievementLabel = UILabel()
        retroAchievementLabel.attributedText = NSAttributedString(string: R.string.localizable.retroAchievements(), attributes: [.font: Constants.Font.title(size: .s, weight: .semibold), .foregroundColor: Constants.Color.LabelPrimary])
        addSubview(retroAchievementLabel)
        retroAchievementLabel.snp.makeConstraints { make in
            make.leading.equalTo(coverImageView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.top.equalTo(coverImageView).offset(Constants.Size.ContentSpaceMin)
        }
        
        let completionProgressLabel = UILabel()
        completionProgressLabel.attributedText = NSAttributedString(string: R.string.localizable.completionProgress(), attributes: [.font: Constants.Font.body(), .foregroundColor: Constants.Color.LabelSecondary])
        addSubview(completionProgressLabel)
        completionProgressLabel.snp.makeConstraints { make in
            make.leading.equalTo(retroAchievementLabel)
            make.top.equalTo(retroAchievementLabel.snp.bottom).offset(Constants.Size.ContentSpaceUltraTiny/2)
        }
        
        addSubview(progressLabel)
        progressLabel.snp.makeConstraints { make in
            make.centerY.equalTo(completionProgressLabel)
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceHuge)
        }
        
        addSubview(progressView)
        progressView.snp.makeConstraints { make in
            make.height.equalTo(2)
            make.leading.equalTo(retroAchievementLabel)
            make.trailing.equalTo(progressLabel)
            make.top.equalTo(completionProgressLabel.snp.bottom).offset(Constants.Size.ContentSpaceMin)
        }
        
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(coverImageView)
            make.trailing.equalTo(progressLabel)
            make.top.equalTo(coverImageView.snp.bottom).offset(Constants.Size.ContentSpaceMax)
        }
        
        addSubview(lastActivityIcon)
        lastActivityIcon.snp.makeConstraints { make in
            make.size.equalTo(24)
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(Constants.Size.ContentSpaceMin)
        }
        
        addSubview(lastActivityLabel)
        lastActivityLabel.snp.makeConstraints { make in
            make.centerY.equalTo(lastActivityIcon)
            make.leading.equalTo(lastActivityIcon.snp.trailing).offset(6)
            make.trailing.equalTo(progressLabel)
        }
        
        let enableContainer = UIView()
        enableContainer.layerCornerRadius = Constants.Size.CornerRadiusMax
        enableContainer.backgroundColor = Constants.Color.BackgroundPrimary
        addSubview(enableContainer)
        enableContainer.snp.makeConstraints { make in
            make.height.equalTo(Constants.Size.ItemHeightMax)
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.top.equalTo(lastActivityIcon.snp.bottom).offset(Constants.Size.ContentSpaceMax)
        }
        let enableIcon = UIImageView(image: .symbolImage(.gamecontrollerFill).applySymbolConfig(size: 19, color: Constants.Color.LabelPrimary))
        enableIcon.contentMode = .center
        enableContainer.addSubview(enableIcon)
        enableIcon.snp.makeConstraints { make in
            make.size.equalTo(24)
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
            make.centerY.equalToSuperview()
        }
        let enableLabel: UILabel = {
            let view = UILabel()
            view.numberOfLines = 2
            let matt = NSMutableAttributedString(string: R.string.localizable.enableAchievements(), attributes: [.font: Constants.Font.body(size: .l, weight: .semibold), .foregroundColor: Constants.Color.LabelPrimary])
            let style = NSMutableParagraphStyle()
            style.lineSpacing = Constants.Size.ContentSpaceUltraTiny/2
            view.attributedText = matt.applying(attributes: [.paragraphStyle: style])
            return view
        }()
        enableContainer.addSubview(enableLabel)
        enableLabel.snp.makeConstraints { make in
            make.centerY.equalTo(enableIcon)
            make.leading.equalTo(enableIcon.snp.trailing).offset(Constants.Size.ContentSpaceTiny)
        }
        enableContainer.addSubview(enableSwitchButton)
        enableSwitchButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMid)
            make.leading.equalTo(enableLabel.snp.trailing).offset(Constants.Size.ContentSpaceTiny)
            if #available(iOS 26.0, *) {
                make.size.equalTo(CGSize(width: 63, height: 28))
            } else {
                make.size.equalTo(CGSize(width: 51, height: 31))
            }
        }
        if #available(iOS 26.0, *) {} else {
            enableSwitchButton.transform = CGAffineTransformMakeScale(0.9, 0.9)
        }
        
        let hardcoreContainer = UIView()
        hardcoreContainer.layerCornerRadius = Constants.Size.CornerRadiusMax
        hardcoreContainer.backgroundColor = Constants.Color.BackgroundPrimary
        addSubview(hardcoreContainer)
        hardcoreContainer.snp.makeConstraints { make in
            make.height.equalTo(Constants.Size.ItemHeightMax)
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.top.equalTo(enableContainer.snp.bottom).offset(Constants.Size.ContentSpaceMax)
        }
        let hardcoreIcon = UIImageView(image: .symbolImage(.flameFill).applySymbolConfig(size: 19, color: Constants.Color.LabelPrimary))
        hardcoreIcon.contentMode = .center
        hardcoreContainer.addSubview(hardcoreIcon)
        hardcoreIcon.snp.makeConstraints { make in
            make.size.equalTo(24)
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
            make.centerY.equalToSuperview()
        }
        let hardcoreScoreLabel: UILabel = {
            let view = UILabel()
            view.numberOfLines = 2
            let matt = NSMutableAttributedString(string: R.string.localizable.hardcoreMode(), attributes: [.font: Constants.Font.body(size: .l, weight: .semibold), .foregroundColor: Constants.Color.LabelPrimary])
            matt.append(NSAttributedString(string: "\n" + R.string.localizable.hardcoreDesc(), attributes: [.font: Constants.Font.caption(size: .l), .foregroundColor: Constants.Color.LabelSecondary]))
            let style = NSMutableParagraphStyle()
            style.lineSpacing = Constants.Size.ContentSpaceUltraTiny/2
            view.attributedText = matt.applying(attributes: [.paragraphStyle: style])
            return view
        }()
        hardcoreContainer.addSubview(hardcoreScoreLabel)
        hardcoreScoreLabel.snp.makeConstraints { make in
            make.centerY.equalTo(hardcoreIcon)
            make.leading.equalTo(hardcoreIcon.snp.trailing).offset(Constants.Size.ContentSpaceTiny)
        }
        hardcoreContainer.addSubview(hardcoreSwitchButton)
        hardcoreSwitchButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMid)
            make.leading.equalTo(hardcoreScoreLabel.snp.trailing).offset(Constants.Size.ContentSpaceTiny)
            if #available(iOS 26.0, *) {
                make.size.equalTo(CGSize(width: 63, height: 28))
            } else {
                make.size.equalTo(CGSize(width: 51, height: 31))
            }
        }
        if #available(iOS 26.0, *) {} else {
            hardcoreSwitchButton.transform = CGAffineTransformMakeScale(0.9, 0.9)
        }
        
        let alwaysShowProgressContainer = UIView()
        alwaysShowProgressContainer.layerCornerRadius = Constants.Size.CornerRadiusMax
        alwaysShowProgressContainer.backgroundColor = Constants.Color.BackgroundPrimary
        addSubview(alwaysShowProgressContainer)
        alwaysShowProgressContainer.snp.makeConstraints { make in
            make.height.equalTo(Constants.Size.ItemHeightMax)
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.top.equalTo(hardcoreContainer.snp.bottom).offset(Constants.Size.ContentSpaceMax)
        }
        let alwaysShowProgressIcon = UIImageView(image: .symbolImage(.squareTextSquareFill).applySymbolConfig(size: 19, color: Constants.Color.LabelPrimary))
        alwaysShowProgressIcon.contentMode = .center
        alwaysShowProgressContainer.addSubview(alwaysShowProgressIcon)
        alwaysShowProgressIcon.snp.makeConstraints { make in
            make.size.equalTo(24)
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
            make.centerY.equalToSuperview()
        }
        let alwaysShowProgressLabel: UILabel = {
            let view = UILabel()
            view.numberOfLines = 2
            let matt = NSMutableAttributedString(string: R.string.localizable.alwaysShowProgress(), attributes: [.font: Constants.Font.body(size: .l, weight: .semibold), .foregroundColor: Constants.Color.LabelPrimary])
            matt.append(NSAttributedString(string: "\n" + R.string.localizable.alwaysShowProgressDesc(), attributes: [.font: Constants.Font.caption(size: .l), .foregroundColor: Constants.Color.LabelSecondary]))
            let style = NSMutableParagraphStyle()
            style.lineSpacing = Constants.Size.ContentSpaceUltraTiny/2
            view.attributedText = matt.applying(attributes: [.paragraphStyle: style])
            return view
        }()
        alwaysShowProgressContainer.addSubview(alwaysShowProgressLabel)
        alwaysShowProgressLabel.snp.makeConstraints { make in
            make.centerY.equalTo(alwaysShowProgressIcon)
            make.leading.equalTo(alwaysShowProgressIcon.snp.trailing).offset(Constants.Size.ContentSpaceTiny)
        }
        alwaysShowProgressContainer.addSubview(alwaysShowProgressButton)
        alwaysShowProgressButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMid)
            make.leading.equalTo(alwaysShowProgressLabel.snp.trailing).offset(Constants.Size.ContentSpaceTiny)
            if #available(iOS 26.0, *) {
                make.size.equalTo(CGSize(width: 63, height: 28))
            } else {
                make.size.equalTo(CGSize(width: 51, height: 31))
            }
        }
        if #available(iOS 26.0, *) {} else {
            alwaysShowProgressButton.transform = CGAffineTransformMakeScale(0.9, 0.9)
        }
        
        
        let achievementInfoContainer = UIView()
        achievementInfoContainer.layerCornerRadius = Constants.Size.CornerRadiusMax
        achievementInfoContainer.backgroundColor = Constants.Color.BackgroundPrimary
        addSubview(achievementInfoContainer)
        achievementInfoContainer.snp.makeConstraints { make in
            make.height.equalTo(Constants.Size.ItemHeightMax*2)
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.top.equalTo(alwaysShowProgressContainer.snp.bottom).offset(Constants.Size.ContentSpaceMax)
        }
        let achievementCountIcon = SymbolButton(image: R.image.customTrophyFill()?.applySymbolConfig())
        achievementInfoContainer.addSubview(achievementCountIcon)
        achievementCountIcon.snp.makeConstraints { make in
            make.size.equalTo(24)
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
            make.top.equalTo(18)
        }
        achievementInfoContainer.addSubview(achievementsCountLabel)
        achievementsCountLabel.snp.makeConstraints { make in
            make.centerY.equalTo(achievementCountIcon)
            make.leading.equalTo(achievementCountIcon.snp.trailing).offset(Constants.Size.ContentSpaceTiny)
            make.trailing.equalToSuperview()
        }
        let pointIcon = SymbolButton(image: R.image.customFlagPatternCheckered()?.applySymbolConfig())
        achievementInfoContainer.addSubview(pointIcon)
        pointIcon.snp.makeConstraints { make in
            make.size.equalTo(24)
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
            make.top.equalTo(achievementCountIcon.snp.bottom).offset(36)
        }
        achievementInfoContainer.addSubview(pointLabel)
        pointLabel.snp.makeConstraints { make in
            make.centerY.equalTo(pointIcon)
            make.leading.equalTo(pointIcon.snp.trailing).offset(Constants.Size.ContentSpaceTiny)
            make.trailing.equalToSuperview()
        }
        
        let achievementListLabel = UILabel()
        achievementListLabel.attributedText = NSAttributedString(string: R.string.localizable.achievementsList(), attributes: [.font: Constants.Font.body(weight: .semibold), .foregroundColor: Constants.Color.LabelSecondary])
        addSubview(achievementListLabel)
        achievementListLabel.snp.makeConstraints { make in
            make.leading.equalTo(coverImageView)
            make.top.equalTo(achievementInfoContainer.snp.bottom).offset(Constants.Size.ContentSpaceMax)
        }
        
        addSubview(listView)
        listView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.top.equalTo(achievementListLabel.snp.bottom).offset(Constants.Size.ContentSpaceMin)
            make.height.equalTo(16+(24*2)+50+(64*4)+(16*3))
        }
        
        let bottomLabelContainer = UIView()
        addSubview(bottomLabelContainer)
        bottomLabelContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(listView.snp.bottom).offset(Constants.Size.ContentSpaceMax)
        }
        let bottomLabel = UILabel()
        bottomLabel.attributedText = NSAttributedString(string: R.string.localizable.achievementsMoreDetail(), attributes: [.font : Constants.Font.caption(size: .l), .foregroundColor: Constants.Color.Indigo])
        bottomLabelContainer.addSubview(bottomLabel)
        bottomLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        bottomLabelContainer.addSubview(bottomButton)
        bottomButton.snp.makeConstraints { make in
            make.leading.equalTo(bottomLabel.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
            make.top.bottom.trailing.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setDatas(game: Game, retroGame: CheevosGame?) {
        guard let retroGame else { return }
        self.game = game
        coverImageView.kf.setImage(with: URL(string: retroGame.badgeUrl), placeholder: UIImage.placeHolder(preferenceSize: .init(80)))
        
        var achievementCount = 0
        var hardcoreUnlockCount = 0
        var softcoreUnlockCount = 0
        var totalPoints = 0
        var hardcorePoints = 0
        var softcorePoints = 0
        var unlockAchievementCount = 0
        if let achievements = retroGame.achievements {
            var validAchievements = [CheevosAchievement]()
            for a in achievements {
                if let badgeName = a.badgeName, badgeName == "00000" {
                    continue
                }
                validAchievements.append(a)
                achievementCount += 1
                if a.unlocked {
                    unlockAchievementCount += 1
                }
                if a.hardcoreUnlocked {
                    hardcoreUnlockCount += 1
                    hardcorePoints += a.points
                }
                if a.softcoreUnlocked {
                    softcoreUnlockCount += 1
                    softcorePoints += a.points
                }
                totalPoints += a.points
            }
            let percentage = achievementCount == 0 ? 0.0 : (Double(unlockAchievementCount)/Double(achievementCount)*100)
            progressLabel.text = String(format: "%.1f%%", percentage)
            progressView.progress = percentage
            listView.datas = validAchievements.sorted(by: {
                if $0.hardcoreUnlocked {
                    return true
                } else if $1.hardcoreUnlocked {
                    return false
                }
                return false
            })
        }
        
        
        
        titleLabel.text = retroGame.title ?? game.aliasName ?? game.name
        
        if let timeAgo = game.latestPlayDate?.timeAgo() {
            lastActivityLabel.text = R.string.localizable.readyGameInfoSubTitle(timeAgo, Date.timeDuration(milliseconds: Int(game.totalPlayDuration)))
        } else {
            lastActivityLabel.text = R.string.localizable.readyGameInfoNeverPlayed()
        }
        
        
        achievementsCountLabel.attributedText = {
            let matt = NSMutableAttributedString(string: R.string.localizable.totalAchievements(achievementCount), attributes: [.font: Constants.Font.body(size: .l, weight: .semibold), .foregroundColor: Constants.Color.LabelPrimary])
            matt.append(NSAttributedString(string: "\n" + R.string.localizable.hardcore() + ": ", attributes: [.font: Constants.Font.caption(size: .l), .foregroundColor: Constants.Color.LabelSecondary]))
            matt.append(NSAttributedString(string: "\(hardcoreUnlockCount)    ", attributes: [.font: Constants.Font.body(size: .l, weight: .semibold), .foregroundColor: Constants.Color.Yellow]))
            matt.append(NSAttributedString(string: R.string.localizable.softcore() + ": ", attributes: [.font: Constants.Font.caption(size: .l), .foregroundColor: Constants.Color.LabelSecondary]))
            matt.append(NSAttributedString(string: "\(softcoreUnlockCount)", attributes: [.font: Constants.Font.body(size: .l, weight: .semibold), .foregroundColor: Constants.Color.Yellow]))
            let style = NSMutableParagraphStyle()
            style.lineSpacing = Constants.Size.ContentSpaceUltraTiny/2
            return matt.applying(attributes: [.paragraphStyle: style])
        }()
        pointLabel.attributedText = {
            let matt = NSMutableAttributedString(string: R.string.localizable.totalPoints(totalPoints), attributes: [.font: Constants.Font.body(size: .l, weight: .semibold), .foregroundColor: Constants.Color.LabelPrimary])
            matt.append(NSAttributedString(string: "\n" + R.string.localizable.hardcore() + ": ", attributes: [.font: Constants.Font.caption(size: .l), .foregroundColor: Constants.Color.LabelSecondary]))
            matt.append(NSAttributedString(string: "\(hardcorePoints)    ", attributes: [.font: Constants.Font.body(size: .l, weight: .semibold), .foregroundColor: Constants.Color.Yellow]))
            matt.append(NSAttributedString(string: R.string.localizable.softcore() + ": ", attributes: [.font: Constants.Font.caption(size: .l), .foregroundColor: Constants.Color.LabelSecondary]))
            matt.append(NSAttributedString(string: "\(softcorePoints)", attributes: [.font: Constants.Font.body(size: .l, weight: .semibold), .foregroundColor: Constants.Color.Yellow]))
            let style = NSMutableParagraphStyle()
            style.lineSpacing = Constants.Size.ContentSpaceUltraTiny/2
            return matt.applying(attributes: [.paragraphStyle: style])
        }()
        
        enableSwitchButton.setOn(game.enableAchievements, animated: false)
        
        if retroGame.notSupportHardcore {
            hardcoreSwitchButton.isEnabled = false
            hardcoreSwitchButton.setOn(false, animated: false)
            hardcoreSwitchButton.onDisableTap {
                UIView.makeAlert(detail: R.string.localizable.notSupportHardcore(), cancelTitle: R.string.localizable.gotIt())
            }
        } else {
            hardcoreSwitchButton.isEnabled = true
            hardcoreSwitchButton.setOn(game.enableHarcore, animated: false)
            hardcoreSwitchButton.onDisableTap {}
        }
        
        alwaysShowProgressButton.setOn(game.getExtraBool(key: ExtraKey.alwaysShowProgress.rawValue) ?? false, animated: false)
    }
}
