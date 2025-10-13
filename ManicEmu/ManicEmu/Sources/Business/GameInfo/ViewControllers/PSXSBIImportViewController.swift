//
//  PSXSBIImportViewController.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/8/4.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UniformTypeIdentifiers

class PSXSBIImportViewController: BaseViewController {
    
    private let datas: [String]
    
    private let game: Game
    
    private var topBlurView: UIView = {
        let view = UIView()
        view.makeBlur()
        return view
    }()
    
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.register(cellWithClass: PSXSBIDescCollectionCell.self)
        view.register(cellWithClass: PSXSBICollectionCell.self)
        view.showsVerticalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        let bottom = (UIDevice.isPad ? (Constants.Size.ContentInsetBottom + Constants.Size.HomeTabBarSize.height + Constants.Size.ContentSpaceMax) : Constants.Size.ContentInsetBottom) + Constants.Size.ItemHeightMid + Constants.Size.ContentSpaceMid
        view.contentInset = UIEdgeInsets(top: Constants.Size.ItemHeightMid, left: 0, bottom: bottom, right: 0)
        return view
    }()
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
    }
    
    init(game: Game) {
        self.game = game
        if game.isRomExtsts {
            if game.romUrl.pathExtension.lowercased() == "m3u", let m3uContents = try? String(contentsOf: game.romUrl, encoding: .utf8) {
                //读取多碟文件
                datas = m3uContents.components(separatedBy: .newlines).filter { !$0.isEmpty }
            } else {
                datas = [game.romUrl.lastPathComponent]
            }
        } else {
            datas = []
        }
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        view.addSubview(topBlurView)
        topBlurView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(Constants.Size.ItemHeightMid)
        }
        
        let icon = UIImageView(image: UIImage(symbol: .lockRectangleStack))
        topBlurView.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
            make.size.equalTo(Constants.Size.IconSizeMin)
            make.centerY.equalToSuperview()
        }
        let headerTitleLabel = UILabel()
        headerTitleLabel.text = R.string.localizable.sbiImport()
        headerTitleLabel.textColor = Constants.Color.LabelPrimary
        headerTitleLabel.font = Constants.Font.title(size: .s)
        topBlurView.addSubview(headerTitleLabel)
        headerTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
            make.centerY.equalTo(icon)
        }
        
        addCloseButton()
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, env in
            //item布局
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                 heightDimension: .fractionalHeight(1)))
            //group布局
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: sectionIndex == 0 ? .estimated(100) : .absolute(PSXSBICollectionCell.CellHeight())), subitems: [item])
            group.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                            leading: Constants.Size.ContentSpaceMid,
                                                            bottom: 0,
                                                            trailing: Constants.Size.ContentSpaceMid)
            
            //section布局
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: Constants.Size.ContentSpaceMin, trailing: 0)
            return section
        }
        return layout
    }
}

extension PSXSBIImportViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1 + datas.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withClass: PSXSBIDescCollectionCell.self, for: indexPath)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withClass: PSXSBICollectionCell.self, for: indexPath)
            let filePath = game.romUrl.path.deletingLastPathComponent.appendingPathComponent(datas[indexPath.section-1])
            cell.setData(filePath: filePath)
            cell.addFileButton.addTapGesture { [weak self] gesture in
                guard let self else { return }
                if let sbi = UTType(filenameExtension: "sbi") {
                    let supportedType = [sbi]
                    FilesImporter.shared.presentImportController(supportedTypes: supportedType, allowsMultipleSelection: false) { [weak self] urls in
                        guard let self else { return }
                        if let url = urls.first {
                            do {
                                let sbiFilePath = filePath.deletingPathExtension + ".sbi"
                                try FileManager.safeCopyItem(at: url, to: URL(fileURLWithPath: sbiFilePath), shouldReplace: true)
                                UIView.makeToast(message: R.string.localizable.biosImportSuccess(url.lastPathComponent))
                                self.collectionView.reloadData()
                            } catch {
                                UIView.makeToast(message: R.string.localizable.biosImportFailed())
                            }
                        }
                    }
                }
            }
            return cell
        }
    }
    
}

extension PSXSBIImportViewController: UICollectionViewDelegate {
    
}
