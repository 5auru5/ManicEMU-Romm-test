//
//  DownloadManageView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/4/29.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit
import Tiercel

class DownloadManageView: BaseView {
    
    private var topBlurView: UIView = {
        let view = UIView()
        view.makeBlur()
        return view
    }()
    
    private lazy var collectionView: UICollectionView = {
        let view = BlankSlateCollectionView(frame: .zero, collectionViewLayout: createLayout())
        view.blankSlateView = BlankSlateEmptyView(title: R.string.localizable.noDownloadTask())
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.register(cellWithClass: DownloadItemCollectionViewCell.self)
        view.showsVerticalScrollIndicator = false
        view.dataSource = self
        view.contentInset = UIEdgeInsets(top: Constants.Size.ItemHeightMid, left: 0, bottom: Constants.Size.ContentInsetBottom, right: 0)
        return view
    }()
    
    private lazy var tasks: [DownloadTask] = { getTasks() }()
    
    var didTapClose: (()->Void)? = nil

    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        Log.debug("\(String(describing: Self.self)) init")
        
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(topBlurView)
        topBlurView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(Constants.Size.ItemHeightMid)
        }
        
        let icon = UIImageView(image: UIImage(symbol: .arrowDownCircle))
        topBlurView.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
            make.size.equalTo(Constants.Size.IconSizeMin)
            make.centerY.equalToSuperview()
        }
        let headerTitleLabel = UILabel()
        headerTitleLabel.text = R.string.localizable.cloudDriveBrowserDownload()
        headerTitleLabel.textColor = Constants.Color.LabelPrimary
        headerTitleLabel.font = Constants.Font.title(size: .s)
        topBlurView.addSubview(headerTitleLabel)
        headerTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
            make.centerY.equalTo(icon)
        }
        
        let closeButton = SymbolButton(image: UIImage(symbol: .xmark, font: Constants.Font.body(weight: .bold)), enableGlass: true)
        closeButton.enableRoundCorner = true
        topBlurView.addSubview(closeButton)
        closeButton.addTapGesture { [weak self] gesture in
            self?.didTapClose?()
        }
        closeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
            make.centerY.equalToSuperview()
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, env in
            //item布局
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                 heightDimension: .fractionalHeight(1)))
            //group布局
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(82)), subitems: [item])
            group.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                            leading: Constants.Size.ContentSpaceMid,
                                                            bottom: 0,
                                                            trailing: Constants.Size.ContentSpaceMid)
            //section布局
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            
            return section
        }
        return layout
    }
    
    private func getTasks() -> [DownloadTask] {
        let tasks = DownloadManager.shared.sessionManager.tasks.filter { $0.status == .running || $0.status == .waiting || $0.status == .suspended || $0.status == .failed }
        for task in tasks {
            task.completion { [weak self] insideTask in
                Log.debug("下载任务回调 \(insideTask.fileName) 状态:\(insideTask.status)")
                guard let self = self else { return }
                if insideTask.status == .removed || insideTask.status == .succeeded {
                    self.tasks = self.getTasks()
                    self.collectionView.reloadData()
                }
            }
        }
        return tasks
    }
}

extension DownloadManageView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        tasks.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClass: DownloadItemCollectionViewCell.self, for: indexPath)
        cell.setData(task: tasks[indexPath.row])
        return cell
    }
}
