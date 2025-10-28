//
//  MultiDiscBuilderViewController.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/7/3.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UniformTypeIdentifiers
import BlurUIKit

class MultiDiscBuilderViewController: BaseViewController {
    
    protocol M3uItem {
        var url: URL { get set }
        var files: [URL] { get set }
    }
    
    struct CUE: M3uItem {
        var url: URL
        var files: [URL]
    }
    
    struct CHD: M3uItem {
        var url: URL
        var files: [URL]
    }
    
    struct CDI: M3uItem {
        var url: URL
        var files: [URL]
    }
    
    private var datas: [M3uItem] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    private enum FileType {
        case undetermined, cue, chd, cdi
    }
    
    private var fileType: FileType {
        get {
            if self.datas.count == 0 {
                return .undetermined
            } else {
                if self.datas.first!.url.pathExtension.lowercased() == "cue" {
                    return .cue
                } else if self.datas.first!.url.pathExtension.lowercased() == "chd" {
                    return .chd
                } else  {
                    return .cdi
                }
            }
        }
    }
    
    private var topBlurView: UIView = {
        let view = UIView()
        view.makeBlur()
        return view
    }()
    
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.register(cellWithClass: MultiDiscDescCollectionCell.self)
        view.register(cellWithClass: MultiDiscItemCollectionCell.self)
        view.showsVerticalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.dragInteractionEnabled = true
        view.dragDelegate = self
        view.dropDelegate = self
        let bottom = (UIDevice.isPad ? (Constants.Size.ContentInsetBottom + Constants.Size.HomeTabBarSize.height + Constants.Size.ContentSpaceMax) : Constants.Size.ContentInsetBottom) + Constants.Size.ItemHeightMid + Constants.Size.ContentSpaceMid
        view.contentInset = UIEdgeInsets(top: Constants.Size.ItemHeightMid, left: 0, bottom: bottom, right: 0)
        return view
    }()
    
    private lazy var moreContextMenuButton: ContextMenuButton = {
        var actions: [UIMenuElement] = []
        actions.append((UIAction(title: R.string.localizable.m3uFileShare()) { [weak self] _ in
            guard let self = self else { return }
            //分享
            if let url = self.generateM3uFile() {
                ShareManager.shareFile(fileUrl: url)
            } else {
                UIView.makeToast(message: R.string.localizable.generateM3uFailed())
            }
        }))
        actions.append(UIAction(title: R.string.localizable.m3uFileImport()) { [weak self] _ in
            guard let self = self else { return }
            self.importGame()
        })
        let view = ContextMenuButton(image: nil, menu: UIMenu(children: actions))
        return view
    }()
    
    private lazy var moreButton: SymbolButton = {
        let view = SymbolButton(symbol: .ellipsis, enableGlass: true)
        view.enableRoundCorner = true
        view.addTapGesture { [weak self] gesture in
            self?.moreContextMenuButton.triggerTapGesture()
        }
        return view
    }()
    
    private lazy var addFileButton: SymbolButton = {
        let view = SymbolButton(image: nil, title: R.string.localizable.multiDiscAddFile("ROM"), titleFont: Constants.Font.body(size: .l, weight: .medium), titleColor: Constants.Color.LabelPrimary.forceStyle(.dark), horizontalContian: true, titlePosition: .right)
        view.enableRoundCorner = true
        view.backgroundColor = Constants.Color.Main
        view.addTapGesture { [weak self] gesture in
            guard let self else { return }
            let supportedType: [UTType]
            if let cue = UTType(filenameExtension: "cue"), let bin = UTType(filenameExtension: "bin"), let chd = UTType(filenameExtension: "chd"), let cdi = UTType(filenameExtension: "cdi") {
                switch self.fileType {
                case .undetermined:
                    supportedType = [cue, bin, chd, cdi]
                case .cue:
                    supportedType = [cue, bin]
                case .chd:
                    supportedType = [chd]
                case .cdi:
                    supportedType = [cdi]
                }
                FilesImporter.shared.presentImportController(supportedTypes: supportedType) { [weak self] urls in
                    guard let self else { return }
                    let isCue = urls.contains(where: { $0.url?.pathExtension.lowercased() == "cue" })
                    let isChd = urls.contains(where: { $0.url?.pathExtension.lowercased() == "chd" })
                    let isCdi = urls.contains(where: { $0.url?.pathExtension.lowercased() == "cdi" })
                    if (isCue || urls.contains(where: { $0.url?.pathExtension.lowercased() == "bin" })) && (isChd || isCdi) {
                        UIView.makeToast(message: R.string.localizable.multiDiscImportErrorConflict())
                        return
                    }
                    let urls = urls.sorted(by: { $0.path < $1.path })
                    if isCue {
                        let (_, errors, cueItems) = FilesImporter.handleMultiFiles(urls: urls)
                        if errors.count > 0 {
                            UIView.makeAlert(detail: errors.reduce("", { $0 + $1.localizedDescription + "\n"}))
                        }
                        var cues = [CUE]()
                        if cueItems.count > 0 {
                            for item in cueItems {
                                let tempCueUrl = URL(fileURLWithPath: Constants.Path.Temp.appendingPathComponent(item.url.lastPathComponent))
                                try? FileManager.safeCopyItem(at: item.url, to: tempCueUrl)
                                var bins = [URL]()
                                for binUrl in item.files {
                                    let tempBinUrl = URL(fileURLWithPath: Constants.Path.Temp.appendingPathComponent(binUrl.lastPathComponent))
                                    try? FileManager.safeCopyItem(at: binUrl, to: tempBinUrl, shouldReplace: true)
                                    bins.append(tempBinUrl)
                                }
                                cues.append(CUE(url: tempCueUrl, files: bins))
                            }
                            self.datas.append(contentsOf: cues)
                            self.collectionView.reloadData()
                        }
                        self.addFileButton.titleLabel.text = R.string.localizable.multiDiscAddFile(".cue .bin")
                    } else if isChd {
                        var chds = [CHD]()
                        for url in urls {
                            let tempChdUrl = URL(fileURLWithPath: Constants.Path.Temp.appendingPathComponent(url.lastPathComponent))
                            try? FileManager.safeCopyItem(at: url, to: tempChdUrl, shouldReplace: true)
                            chds.append(CHD(url: tempChdUrl, files: []))
                        }
                        self.datas.append(contentsOf: chds)
                        self.collectionView.reloadData()
                        self.addFileButton.titleLabel.text = R.string.localizable.multiDiscAddFile(".chd")
                    } else if isCdi {
                        var cdis = [CDI]()
                        for url in urls {
                            let tempChdUrl = URL(fileURLWithPath: Constants.Path.Temp.appendingPathComponent(url.lastPathComponent))
                            try? FileManager.safeCopyItem(at: url, to: tempChdUrl, shouldReplace: true)
                            cdis.append(CDI(url: tempChdUrl, files: []))
                        }
                        self.datas.append(contentsOf: cdis)
                        self.collectionView.reloadData()
                        self.addFileButton.titleLabel.text = R.string.localizable.multiDiscAddFile(".cdi")
                    } else {
                        UIView.makeToast(message: R.string.localizable.multiDiscImportErrorMissing())
                    }
                }
            }
        }
        return view
    }()
    
    private var bottomBlurView: UIView = {
        let view = BlurUIKit.VariableBlurView()
        view.direction = .up
        view.maximumBlurRadius = 15
        view.dimmingAlpha = .interfaceStyle(lightModeAlpha: 0.5, darkModeAlpha: 0.6)
        view.dimmingTintColor = Constants.Color.Background
        return view
    }()
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        isModalInPresentation = true
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
        
        let icon = UIImageView(image: UIImage(symbol: .opticaldisc))
        topBlurView.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
            make.size.equalTo(Constants.Size.IconSizeMin)
            make.centerY.equalToSuperview()
        }
        let headerTitleLabel = UILabel()
        headerTitleLabel.text = R.string.localizable.multiDiscBuilder()
        headerTitleLabel.textColor = Constants.Color.LabelPrimary
        headerTitleLabel.font = Constants.Font.title(size: .s)
        topBlurView.addSubview(headerTitleLabel)
        headerTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
            make.centerY.equalTo(icon)
        }
        
        addCloseButton { [weak self] in
            guard let self else { return }
            guard self.datas.count > 0 else {
                self.dismiss(animated: true)
                return
            }
            UIView.makeAlert(detail: R.string.localizable.multiDiscCloseAlert(),
                             cancelTitle: R.string.localizable.m3uFileImport(),
                             confirmTitle: R.string.localizable.multiDiscContinueClose(),
                             cancelAction: { [weak self] in
                guard let self else { return }
                //导入游戏库
                self.importGame()
                self.dismiss(animated: true)
            }, confirmAction: { [weak self] in
                guard let self else { return }
                self.dismiss(animated: true)
            })
        }
        
        topBlurView.addSubview(moreContextMenuButton)
        moreContextMenuButton.snp.makeConstraints { make in
            make.trailing.equalTo(closeButton.snp.leading).offset(-Constants.Size.ContentSpaceMax)
            make.centerY.equalTo(closeButton)
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
        
        topBlurView.addSubview(moreButton)
        moreButton.snp.makeConstraints { make in
            make.edges.equalTo(moreContextMenuButton)
        }
        
        view.addSubview(bottomBlurView)
        view.addSubview(addFileButton)
        addFileButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceHuge)
            make.height.equalTo(Constants.Size.ItemHeightMid)
            make.bottom.equalToSuperview().offset(-Constants.Size.ContentInsetBottom-Constants.Size.ContentSpaceMid)
        }
        bottomBlurView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(addFileButton.snp.centerY)
        }
    }
    
    private func generateM3uFile() -> URL? {
        guard self.datas.count > 0 else {
            return nil
        }
        
        let m3uContent = self.datas.reduce("") { partialResult, item in
            if partialResult.isEmpty {
                return partialResult + item.url.lastPathComponent
            } else {
                return partialResult + "\n" + item.url.lastPathComponent
            }
        }
        let name = self.datas.first!.url.lastPathComponent.deletingPathExtension + ".m3u"
        let m3uUrl = URL(fileURLWithPath: Constants.Path.Temp.appendingPathComponent(name))
        try? FileManager.safeRemoveItem(at: m3uUrl)
        try? m3uContent.write(to: m3uUrl, atomically: true, encoding: .utf8)
        return m3uUrl
    }
    
    private func importGame() {
        guard datas.count > 0 else {
            UIView.makeToast(message: R.string.localizable.generateM3uFailed())
            return
        }
        //导入游戏库
        if let m3uUrl = generateM3uFile() {
            var urls: [URL] = [m3uUrl]
            for item in datas {
                urls.append(item.url)
                for subItem in item.files {
                    urls.append(subItem)
                }
            }
            FilesImporter.importFiles(urls: urls)
        } else {
            UIView.makeToast(message: R.string.localizable.generateM3uFailed())
        }
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, env in
            //item布局
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                 heightDimension: .fractionalHeight(1)))
            //group布局
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: sectionIndex == 0 ? .estimated(100) : .absolute(MultiDiscItemCollectionCell.CellHeight(itemCount: self.datas[sectionIndex-1].files.count))), subitems: [item])
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

extension MultiDiscBuilderViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1 + datas.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withClass: MultiDiscDescCollectionCell.self, for: indexPath)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withClass: MultiDiscItemCollectionCell.self, for: indexPath)
            cell.setData(index: indexPath.section, item: datas[indexPath.section-1])
            cell.deleteIcon.addTapGesture { [weak self] gesture in
                guard let self else { return }
                self.datas.remove(at: indexPath.section-1)
                self.collectionView.reloadData()
                if self.datas.count == 0 {
                    self.addFileButton.titleLabel.text = R.string.localizable.multiDiscAddFile("ROM")
                }
            }
            return cell
        }
    }
    
}

extension MultiDiscBuilderViewController: UICollectionViewDelegate {
    
}

extension MultiDiscBuilderViewController: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: any UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard indexPath.section > 0 else { return [] }
        let item = datas[indexPath.section-1]
        let itemProvider = NSItemProvider(object: item.url.path as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = item
        return [dragItem]
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath,
              destinationIndexPath.section > 0 else { return }
        
        coordinator.items.forEach { dropItem in
            guard let sourceIndexPath = dropItem.sourceIndexPath,
                  sourceIndexPath.section > 0 else { return }
            
            datas.swapAt(sourceIndexPath.section-1, destinationIndexPath.section-1)
            collectionView.reloadSections([sourceIndexPath.section, destinationIndexPath.section])
            coordinator.drop(dropItem.dragItem, toItemAt: destinationIndexPath)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        canHandle session: UIDropSession) -> Bool {
        return session.localDragSession != nil
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        dropSessionDidUpdate session: UIDropSession,
                        withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard let indexPath = destinationIndexPath, indexPath.section > 0 else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
    
}
