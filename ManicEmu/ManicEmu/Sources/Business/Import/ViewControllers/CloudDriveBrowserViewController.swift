//
//  CloudDriveBrowserViewController.swift
//  ManicEmu
//
//  Created by Max on 2025/1/22.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit
import CloudServiceKit
import Tiercel

class CloudDriveBrowserViewController: BaseViewController {
    
    enum Section {
        case main
    }
    
    private var collectionView: UICollectionView!
    
    private lazy var cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel) { [weak self] in
        self?.navigationController?.dismiss(animated: true)
    }
    
    private lazy var openButton = UIBarButtonItem(title: R.string.localizable.cloudDriveBrowserDownload(), style: .plain) { [weak self] in
        guard let self = self else { return }
        if let indexPaths = self.collectionView.indexPathsForSelectedItems {
            let items = indexPaths.compactMap { self.dataSource.itemIdentifier(for: $0) }
            self.downloadFiles(items: items)
        }
    }
    
    private var downloadManageButton: UIBarButtonItem = {
        let view = DownloadButton(enableGlass: false)
        if #available(iOS 26.0, *) {
            view.backgroundColor = .clear
        }
        view.addTapGesture { gesture in
            topViewController()?.present(DownloadViewController(), animated: true)
        }
        return UIBarButtonItem(customView: view)
    }()
    
    private lazy var selectionButton: UIButton = {
        let button = UIButton(type: .custom)
        button.titleLabel?.font = Constants.Font.body(size: .l)
        button.setTitleColorForAllStates(Constants.Color.Main)
        button.setTitle(R.string.localizable.selectAll(), for: .normal)
        button.setTitle(R.string.localizable.deSelectAll(), for: .selected)
        button.onTap { [weak self] in
            guard let self = self else { return }
            if self.selectionButton.isSelected {
                self.deSelectAll()
            } else {
                self.selectAll()
            }
            self.selectionButton.isSelected = !self.selectionButton.isSelected
        }
        return button
        
    }()
    
    private var dataSource: UICollectionViewDiffableDataSource<Section, CloudItem>!
    
    private let provider: CloudServiceProvider
    
    private let directory: CloudItem
    
    private let navigationTitle: String?
    
    init(provider: CloudServiceProvider, directory: CloudItem, navigationTitle: String? = nil) {
        self.provider = provider
        self.directory = directory
        self.navigationTitle = navigationTitle
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = navigationTitle ?? directory.name
        setupCollectionView()
        setupDataSource()
        applySnapshot()
        navigationItem.setRightBarButtonItems([cancelButton, downloadManageButton], animated: true)
        view.addSubview(selectionButton)
        selectionButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
            make.top.equalTo(self.collectionView.snp.bottom).offset(Constants.Size.ContentSpaceMid)
        }
        downloadManageButton.customView?.snp.makeConstraints({ make in
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
        })
    }
    
    private func setupCollectionView() {
        let tempView = BlankSlateCollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        tempView.blankSlateView = BlankSlateEmptyView(title: R.string.localizable.noContentResult())
        collectionView = tempView
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.allowsMultipleSelection = true
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-38 - Constants.Size.SafeAera.bottom)
        }
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, env in
            //item布局
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                 heightDimension: .absolute(64)))
            //group布局
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                              heightDimension: .absolute(64)),
                                                           subitems: [item])
            //section布局
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            return section
            
        }
        return layout
    }
    
    private func setupDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<BrowserItemCollectionViewCell, CloudItem> { (cell, indexPath, item) in
            let dateString = "\(item.modificationDate?.dateTimeString(ofStyle: .short) ?? "")"
            let sizeString = FileType.humanReadableFileSize(item.size > 0 ? UInt64(item.size) : 0) ?? ""
            let detail = dateString + (!dateString.isEmpty && !sizeString.isEmpty ? "   " : "") + sizeString
            cell.setData(selectable: item.isDirectory || FileType.allSupportFileExtension().contains(item.name.pathExtension),
                         isFolder: item.isDirectory,
                         title: item.name,
                         detail: detail)
        }
        dataSource = UICollectionViewDiffableDataSource<Section, CloudItem>(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        })
    }
    
    private func applySnapshot() {
        UIView.makeLoading()
        provider.contentsOfDirectory(directory) { [weak self] result in
            UIView.hideLoading()
            guard let self = self else { return }
            switch result {
            case .success(let items):
                var snapshot = NSDiffableDataSourceSnapshot<Section, CloudItem>()
                snapshot.appendSections([.main])
                snapshot.appendItems(items.sorted(by: { $0.name < $1.name }))
                self.dataSource.apply(snapshot, animatingDifferences: false)
            case .failure(let error):
                Log.debug("applySnapshot error:\(error)")
                UIView.makeToast(message: error.localizedDescription)
            }
        }
    }
    
    private func selectAll() {
        //全选
        for i in 0..<self.collectionView.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(row: i, section: 0)
            if let item = dataSource.itemIdentifier(for: indexPath) {
                if !item.isDirectory && FileType.allSupportFileExtension().contains(item.name.pathExtension) {
                    self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                }
            }
        }
    }
    
    private func deSelectAll() {
        //取消全选
        if let seletedIndexPaths = self.collectionView.indexPathsForSelectedItems {
            for indexPath in seletedIndexPaths {
                self.collectionView.deselectItem(at: indexPath, animated: false)
            }
        }
    }
    
    private func downloadFiles(items: [CloudItem]) {
        guard !items.isEmpty else { return }
        
        if let provider = provider as? SMBServiceProvider {
            UIView.makeLoading()
            provider.download(paths: items.map({ $0.path })) { [weak self] urls, falures in
                guard let self = self else { return }
                self.dismiss(animated: true)
                var error = [ImportError]()
                if !falures.isEmpty {
                    let errorsString = falures.reduce("") { ($0.isEmpty ? $0 : "\n") + $1 }
                    error.append(ImportError.downloadError(filenames: errorsString))
                }
                FilesImporter.importFiles(urls: urls, preErrors: error)
            }
            return
        }
        
        var downloadItems: [String: URL] = [:]
        var errors: [Error] = []
        var headers: [String: String]? = nil
        let group = DispatchGroup()
        for item in items {
            if DownloadManager.shared.sessionManager.succeededTasks.contains(where: { $0.fileName == item.name })  {
                //已经下载过了报错
                errors.append(ImportError.downloadExist(fileName: item.name))
                continue
            } else {
                
                if let provider = provider as? BaiduPanServiceProvider {
                    headers = ["User-Agent": "pan.baidu.com"]
                    group.enter()
                    provider.downloadLink(of: item) { result in
                        switch result {
                        case .success(let success):
                            downloadItems[item.name] = success
                        case .failure(let failure):
                            errors.append(failure)
                        }
                        group.leave()
                    }
                } else if let provider = provider as? AliyunDriveServiceProvider {
                    group.enter()
                    provider.downloadLink(of: item) { result in
                        switch result {
                        case .success(let success):
                            downloadItems[item.name] = success
                        case .failure(let failure):
                            errors.append(failure)
                        }
                        group.leave()
                    }
                } else if let provider = provider as? GoogleDriveServiceProvider {
                    let request = provider.downloadableRequest(of: item)
                    if let url = request?.url {
                        downloadItems[item.name] = url
                    }
                    headers = request?.allHTTPHeaderFields
                } else if let provider = provider as? DropboxServiceProvider {
                    group.enter()
                    provider.getTemporaryLink(item: item) { result in
                        switch result {
                        case .success(let success):
                            downloadItems[item.name] = success
                        case .failure(let failure):
                            errors.append(failure)
                        }
                        group.leave()
                    }
                } else if let provider = provider as? OneDriveServiceProvider {
                    group.enter()
                    provider.downloadLink(of: item) { result in
                        switch result {
                        case .success(let success):
                            downloadItems[item.name] = success
                        case .failure(let failure):
                            errors.append(failure)
                        }
                        group.leave()
                    }
                } else if let provider = provider as? WebDavServiceProvider {
                    let request = provider.downloadableRequest(of: item)
                    if let url = request?.url {
                        downloadItems[item.name] = url
                    }
                    headers = request?.allHTTPHeaderFields
                }
            }
        }
        
        group.notify(queue: .main) {
            if errors.count > 0 {
                let errorsString = errors.reduce("") {
                    $0 + ($0.isEmpty ? "" : "\n") + $1.localizedDescription
                }
                UIView.makeToast(message: R.string.localizable.importDownloadError(errorsString))
            }
            if !downloadItems.isEmpty {
                var names: [String] = []
                var urls: [URL] = []
                downloadItems.forEach { key, value in
                    names.append(key)
                    urls.append(value)
                }
                DownloadManager.shared.downloads(urls: urls, fileNames: names, headers: headers)
                self.navigationItem.setRightBarButtonItems([self.cancelButton, self.downloadManageButton], animated: true)
                self.deSelectAll()
                self.dismiss(animated: true)
            }
        }
    }
}

extension CloudDriveBrowserViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        if item.isDirectory {
            collectionView.deselectItem(at: indexPath, animated: true)
            let vc = CloudDriveBrowserViewController(provider: provider, directory: item)
            navigationController?.pushViewController(vc, animated: true)
        } else {
            //选中文件
            navigationItem.setRightBarButtonItems([openButton, downloadManageButton], animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if collectionView.indexPathsForSelectedItems?.count == 0 {
            navigationItem.setRightBarButtonItems([cancelButton, downloadManageButton], animated: true)
        } else {
            navigationItem.setRightBarButtonItems([openButton, downloadManageButton], animated: true)
        }
        if selectionButton.isSelected {
            //如果是全选状态 则取消全选
            selectionButton.isSelected = false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            return false
        }
        if item.isDirectory {
            return true
        } else if FileType.allSupportFileExtension().contains(item.name.pathExtension) {
            return true
        }
        return false
    }
}
