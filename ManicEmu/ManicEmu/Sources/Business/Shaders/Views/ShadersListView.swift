//
//  ShadersListView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/12/11.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import SwipeCellKit
import RealmSwift
import ManicEmuCore
import ProHUD
import BetterSegmentedControl
import Fuse

typealias ShadersListData = [ShadersListView.ShaderSource: [(sectionTitle: String, shaders: [Shader])]]

class ShadersListView: BaseView {
    enum ShaderSource: Int, CaseIterable {
        case `default`, retroarch, imported, custom
        
        var title: String {
            switch self {
            case .default:
                R.string.localizable.default()
            case .retroarch:
                "RetroArch"
            case .imported:
                R.string.localizable.tabbarTitleImport()
            case .custom:
                R.string.localizable.custom()
            }
        }
        
        var searchUrl: URL {
            switch self {
            case .default:
                URL(fileURLWithPath: Constants.Path.ShaderDefault)
            case .retroarch:
                URL(fileURLWithPath: Constants.Path.ShaderRetroArch)
            case .imported:
                URL(fileURLWithPath: Constants.Path.ShaderImported)
            case .custom:
                URL(fileURLWithPath: Constants.Path.Shaders)
            }
        }
        
    }
    
    enum InitType {
        case normal, gamePlay, preview
    }
    
    private var currentSource: ShaderSource {
        return ShaderSource(rawValue: self.segmentView.index) ?? .default
    }
    
    private var initType: InitType
    private var isGlsl: Bool
    private var selectedShader: Shader? = nil
    
    private var didSelectIndexSearch: Bool = false
    
    /// 充当导航条
    private var navigationBlurView: NavigationBlurView = {
        let view = NavigationBlurView()
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
    
    private var downloadManageButton: DownloadButton = {
        let view = DownloadButton()
        view.addTapGesture { gesture in
            topViewController()?.present(DownloadViewController(), animated: true)
        }
        view.isHidden = true
        return view
    }()
    
    private lazy var downloadRetroArchShadersButton: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .arrowClockwise, font: Constants.Font.body(weight: .bold)), enableGlass: true)
        view.enableRoundCorner = true
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            UIView.makeAlert(detail: R.string.localizable.downloadRetroArchShaders(), confirmTitle: R.string.localizable.cloudDriveBrowserDownload(), confirmAction: {
                DownloadManager.shared.downloads(urls: [Constants.URLs.SlangShaders, Constants.URLs.GLSLShaders],
                                                 fileNames: [Constants.Strings.SlangShader, Constants.Strings.GLSLShader])
            })
        }
        view.isHidden = true
        return view
    }()
    
    private lazy var importButton: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .folderBadgePlus, font: Constants.Font.body(weight: .bold)), enableGlass: true)
        view.enableRoundCorner = true
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            UIView.makeAlert(detail: R.string.localizable.importShader(), cancelTitle: R.string.localizable.confirmTitle())
        }
        view.isHidden = true
        return view
    }()
    
    private lazy var segmentView: BetterSegmentedControl = {
        let segments = LabelSegment.segments(withTitles: ShaderSource.allCases.map({ $0.title }),
                                             normalFont: Constants.Font.body(),
                                             normalTextColor: Constants.Color.LabelSecondary,
                                             selectedTextColor: Constants.Color.LabelPrimary)
        let options: [BetterSegmentedControl.Option] = [
            .backgroundColor(Constants.Color.SegmentBackground),
            .indicatorViewInset(5),
            .indicatorViewBackgroundColor(Constants.Color.SegmentHighlight),
            .cornerRadius(16)
        ]
        let view = BetterSegmentedControl(frame: .zero,
                                          segments: segments,
                                          options: options)
        
        view.on(.valueChanged) { [weak self] sender, forEvent in
            guard let self, let index = (sender as? BetterSegmentedControl)?.index else { return }
            UIDevice.generateHaptic()
            let shaderSource = self.currentSource
            switch shaderSource {
            case .default:
                self.updateBlankSlateView(shaderSource: shaderSource)
                self.downloadRetroArchShadersButton.isHidden = true
                self.downloadManageButton.isHidden = true
                self.importButton.isHidden = true
            case .retroarch:
                self.updateBlankSlateView(shaderSource: shaderSource)
                self.downloadRetroArchShadersButton.isHidden = false
                self.downloadManageButton.isHidden = false
                self.importButton.isHidden = true
            case .imported:
                self.updateBlankSlateView(shaderSource: shaderSource)
                self.updateBlankSlateView(shaderSource: shaderSource)
                self.downloadRetroArchShadersButton.isHidden = true
                self.downloadManageButton.isHidden = true
                self.importButton.isHidden = false
            case .custom:
                self.updateBlankSlateView(shaderSource: shaderSource)
                self.updateBlankSlateView(shaderSource: shaderSource)
                self.downloadRetroArchShadersButton.isHidden = true
                self.downloadManageButton.isHidden = true
                self.importButton.isHidden = true
            }
            self.tableView.reloadData()
            self.reloadIndexView()
        }
        return view
    }()
    
    private var searchTextField: UITextField = {
        let view = UITextField()
        view.textColor = Constants.Color.LabelPrimary
        view.font = Constants.Font.body(size: .l)
        view.clearButtonMode = .whileEditing
        view.returnKeyType = .search
        view.attributedPlaceholder = NSAttributedString(string: R.string.localizable.readyEditCoverSearch() + R.string.localizable.shaders(), attributes: [.font: Constants.Font.body(size: .l), .foregroundColor: Constants.Color.LabelSecondary])
        return view
    }()
    
    private lazy var blankSlateView: ShadersListBlankSlateView = {
        let view = ShadersListBlankSlateView()
        view.button.addTapGesture { [weak self] gesture in
            guard let self else { return }
            switch self.currentSource {
            case .default:
                break
            case .retroarch:
                UIView.makeAlert(detail: R.string.localizable.downloadRetroArchShaders(), confirmTitle: R.string.localizable.cloudDriveBrowserDownload(), confirmAction: {
                    DownloadManager.shared.downloads(urls: [Constants.URLs.SlangShaders, Constants.URLs.GLSLShaders],
                                                     fileNames: [Constants.Strings.SlangShader, Constants.Strings.GLSLShader])
                })
            case .imported:
                UIView.makeAlert(detail: R.string.localizable.importShader(), cancelTitle: R.string.localizable.confirmTitle())
            case .custom:
                break
            }
        }
        view.button.isHidden = true
        return view
    }()
    
    private lazy var deleteImage = UIImage(symbol: .trash, color: Constants.Color.LabelPrimary.forceStyle(.dark), backgroundColor: Constants.Color.Red, imageSize: .init(Constants.Size.ItemHeightMin)).withRoundedCorners()
    
    private lazy var editImage = UIImage(symbol: .squareAndPencil, color: Constants.Color.LabelPrimary.forceStyle(.dark), backgroundColor: Constants.Color.Yellow, imageSize: .init(Constants.Size.ItemHeightMin)).withRoundedCorners()
    
    private lazy var tableView: UITableView = {
        let view = BlankSlateTableView(frame: .zero, style: .grouped)
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.delegate = self
        view.dataSource = self
        view.separatorStyle = .none
        view.showsVerticalScrollIndicator = false
        view.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: Constants.Size.ContentInsetBottom, right: 0)
        view.register(cellWithClass: ShadersListCell.self)
        view.register(headerFooterViewClassWith: TriggerProHeaderView.self)
        view.blankSlateView = self.blankSlateView
        view.sectionHeaderTopPadding = 0
        view.sectionFooterHeight = 0;
        return view
    }()
    
    ///右侧索引栏
    private lazy var indexView: SectionIndexView = {
        let view = SectionIndexView()
        view.isItemIndicatorAlwaysInCenterY = true
        view.delegate = self
        view.dataSource = self
        view.hideSearch = true
        return view
    }()
    
    private var isSearch: Bool = false
    
    private var normalShaders = ShadersListData()
    private var searchShaders = ShadersListData()
    private var shaders: ShadersListData {
        return isSearch ? searchShaders : normalShaders
    }
    
    private var shaderConfig: ShaderConfig? = nil
    
    private var ignoreShaderConfig: Bool
    
    private var currentCoreName: String?
    
    var didTapClose: (()->Void)? = nil
    
    var didSelectShader: ((Shader)->Void)? = nil
    
    var didUpdateShaderConfig: ((ShaderConfig.SettingType)->Void)? = nil
    
    private var retroArchShadersDownloadSuccess: Any? = nil
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
        if let retroArchShadersDownloadSuccess {
            NotificationCenter.default.removeObserver(retroArchShadersDownloadSuccess)
        }
    }
    
    init(showClose: Bool = true, initType: InitType, isGlsl: Bool = false, ignoreShaderConfig: Bool, usingShaderPath: String? = nil, currentCoreName: String? = nil) {
        self.initType = initType
        self.isGlsl = isGlsl
        self.ignoreShaderConfig = ignoreShaderConfig
        super.init(frame: .zero)
        self.currentCoreName = currentCoreName
        Log.debug("\(String(describing: Self.self)) init")
        
        shaderConfig = ShaderConfig.getConfig()
        
        if let usingShaderPath {
            var shader = ShaderManager.genShader(usingShaderPath, selectedShader: nil, shaderConfig: shaderConfig, ignoreShaderConfig: ignoreShaderConfig, currentCoreName: currentCoreName)
            shader.isSelected = true
            if FileManager.default.fileExists(atPath: shader.filePath) {
                self.selectedShader = shader
            }
        }
        
        loadShaders()
        
        addSubview(navigationBlurView)
        navigationBlurView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalTo(self.safeAreaLayoutGuide)
            make.height.equalTo(Constants.Size.ItemHeightMid)
        }
        
        let textFieldContainer = RoundAndBorderView(roundCorner: .allCorners, radius: Constants.Size.CornerRadiusMid)
        textFieldContainer.backgroundColor = Constants.Color.BackgroundPrimary
        addSubview(textFieldContainer)
        textFieldContainer.snp.makeConstraints { make in
            make.top.equalTo(navigationBlurView.snp.bottom)
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.height.equalTo(Constants.Size.ItemHeightMin)
        }
        
        textFieldContainer.addSubview(searchTextField)
        searchTextField.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
        }
        searchTextField.shouldClear { [weak self] in
            guard let self = self else { return true }
            self.stopSearchShaders()
            return true
        }
        searchTextField.onEditingEnded { [weak self] in
            guard let self = self else { return }
            if let text = self.searchTextField.text?.trimmed, !text.isEmpty {
                self.startSearchShaders()
            } else {
                self.stopSearchShaders()
            }
        }
        searchTextField.onReturnKeyPress { [weak self] in
            guard let self = self else { return }
            self.searchTextField.resignFirstResponder()
        }
        
        let segmentViewContainer = UIView()
        addSubview(segmentViewContainer)
        segmentViewContainer.snp.makeConstraints { make in
            make.top.equalTo(textFieldContainer.snp.bottom).offset(Constants.Size.ContentSpaceTiny)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(Constants.Size.ItemHeightMid + 20)
        }
        segmentViewContainer.addSubview(segmentView)
        segmentView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.top.equalToSuperview().offset(10)
            make.height.equalTo(Constants.Size.ItemHeightMid)
        }
        
        addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(segmentViewContainer.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        let icon = UIImageView(image: R.image.customAppBackgroundDotted()?.applySymbolConfig(size: 20, color: Constants.Color.LabelPrimary))
        navigationBlurView.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
            make.size.equalTo(Constants.Size.IconSizeMin)
            make.centerY.equalToSuperview()
        }
        
        let titleLabel = UILabel()
        titleLabel.font = Constants.Font.title(size: .s)
        titleLabel.textColor = Constants.Color.LabelPrimary
        titleLabel.text = R.string.localizable.shaders()
        navigationBlurView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(Constants.Size.ContentSpaceTiny)
            make.centerY.equalToSuperview()
        }
        
        if showClose {
            navigationBlurView.addSubview(closeButton)
            closeButton.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
                make.centerY.equalToSuperview()
                make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
            }
        }
        
        navigationBlurView.addSubview(downloadRetroArchShadersButton)
        downloadRetroArchShadersButton.snp.makeConstraints { make in
            if showClose {
                make.trailing.equalTo(closeButton.snp.leading).offset(-Constants.Size.ContentSpaceMid)
            } else {
                make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
            }
            make.centerY.equalToSuperview()
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
        
        navigationBlurView.addSubview(downloadManageButton)
        downloadManageButton.snp.makeConstraints { make in
            make.trailing.equalTo(downloadRetroArchShadersButton.snp.leading).offset(-Constants.Size.ContentSpaceMid)
            make.centerY.equalToSuperview()
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
        
        navigationBlurView.addSubview(importButton)
        importButton.snp.makeConstraints { make in
            if showClose {
                make.trailing.equalTo(closeButton.snp.leading).offset(-Constants.Size.ContentSpaceMid)
            } else {
                make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
            }
            make.centerY.equalToSuperview()
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
        
        addSubview(indexView)
        indexView.snp.makeConstraints { make in
            make.top.bottom.trailing.equalToSuperview()
            make.width.equalTo(31)
        }
        indexView.isHidden = true
        
        retroArchShadersDownloadSuccess = NotificationCenter.default.addObserver(forName: Constants.NotificationName.RetroArchShadersDownloadSuccess, object: nil, queue: .main) { [weak self] _ in
            self?.updateShaders(source: .retroarch)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateBlankSlateView(shaderSource: ShaderSource) {
        switch shaderSource {
        case .default:
            blankSlateView.button.isHidden = true
            break
        case .retroarch:
            blankSlateView.detailLabel.text = R.string.localizable.downloadRetroArchSahders()
            blankSlateView.button.imageView.image = UIImage(symbol: .arrowDownToLineCircleFill, font: Constants.Font.title(size: .s, weight: .medium), color: Constants.Color.LabelPrimary.forceStyle(.dark))
            blankSlateView.button.titleLabel.text = R.string.localizable.cloudDriveBrowserDownload()
            blankSlateView.button.isHidden = false
        case .imported:
            blankSlateView.detailLabel.text = R.string.localizable.importShaders()
            blankSlateView.button.imageView.image = UIImage(symbol: .folderFillBadgePlus, font: Constants.Font.title(size: .s, weight: .medium), color: Constants.Color.LabelPrimary.forceStyle(.dark))
            blankSlateView.button.titleLabel.text = R.string.localizable.tabbarTitleImport()
            blankSlateView.button.isHidden = false
        case .custom:
            blankSlateView.detailLabel.text = R.string.localizable.customShaderDesc()
            blankSlateView.button.isHidden = true
        }
    }
    
    private func loadShaders(showLoading: Bool = true) {
        if showLoading {
            UIView.makeLoading()
        }
        DispatchQueue.global().async { [weak self] in
            guard let self else { return }
            self.normalShaders = ShaderManager.fetchShaders(isGlsl: self.isGlsl, selectedShader: self.selectedShader, includeOriginal: initType == .gamePlay, shaderConfig: self.shaderConfig, ignoreShaderConfig: self.ignoreShaderConfig, currentCoreName: currentCoreName)
            if self.isSearch {
                startSearchShaders()
            }
            DispatchQueue.main.async {
                if showLoading {
                    UIView.hideLoading()
                }
                
                var selectedSource = ShaderSource.default
                var selectedIndexPath = IndexPath(row: 0, section: 0)
                outerloop: for source in ShaderSource.allCases {
                    if let sectionShaders = self.shaders[source] {
                        for (section, shaders) in sectionShaders.enumerated() {
                            if let row = shaders.shaders.firstIndex(where: { $0.isSelected }) {
                                //找到了当前选中
                                selectedSource = source
                                selectedIndexPath = IndexPath(row: row, section: section)
                                break outerloop
                            } else {
                                continue
                            }
                        }
                    }
                }
                
                if selectedSource != self.currentSource {
                    self.segmentView.setIndex(selectedSource.rawValue)
                }
                
                self.tableView.reloadData {
                    if selectedIndexPath.row != 0 {
                        self.tableView.selectRow(at: selectedIndexPath, animated: true, scrollPosition: .middle)
                    }
                }
                
                self.reloadIndexView()
            }
        }
    }
    
    private func updateShaders(source: ShaderSource? = nil) {
        if let source {
            let sourceShaders = ShaderManager.fetchShaders(source: source, isGlsl: self.isGlsl, selectedShader: self.selectedShader, includeOriginal: false, shaderConfig: shaderConfig, ignoreShaderConfig: ignoreShaderConfig, currentCoreName: currentCoreName)
            normalShaders[source] = sourceShaders[source]
            if isSearch {
                startSearchShaders()
            }
            if initType == .gamePlay {
                //更新全部的选择状态
                refreshSelection()
            } else if !isSearch {
                self.tableView.reloadData()
                self.reloadIndexView()
            }
        } else {
            loadShaders(showLoading: false)
        }
    }
    
    private func refreshSelection() {
        var newShaders = ShadersListData()
        shaders.forEach { source, sections in
            var newSections = [(sectionTitle: String, shaders: [Shader])]()
            for tuple in sections {
                newSections.append((tuple.sectionTitle, tuple.shaders.map({
                    var newShader = $0
                    if let selectedShader {
                        newShader.isSelected = (selectedShader.relativePath == newShader.relativePath)
                    } else {
                        newShader.isSelected = newShader.isOriginal
                    }
                    return newShader
                })))
            }
            newShaders[source] = newSections
        }
        normalShaders = newShaders
        if isSearch {
            startSearchShaders()
        }
        self.tableView.reloadData()
        self.reloadIndexView()
    }
    
    private func reloadIndexView() {
        let sectionCount = shaders[currentSource]?.count ?? 0
        if sectionCount < 2 {
            indexView.isHidden = true
            return
        } else {
            indexView.isHidden = false
        }
        indexView.reloadData()
        indexView.deselectCurrentItem()
        indexView.selectItem(at: 0)
    }
    
    private func showShaderInfoView(shader: Shader) {
        var newShader = shader
        if currentSource == .custom {
            if let content = try? String(contentsOfFile: newShader.filePath, encoding: .utf8) {
                if let reference = content.lines().first(where: { $0.contains("#reference") }) {
                    let baseRelativePath = reference.replacingOccurrences(of: "#reference", with: "").trimmed.replacingOccurrences(of: "\"", with: "")
                    newShader.baseRelativePath = baseRelativePath
                }
                
                if let forceBaseString = content.lines().first(where: { $0.contains(Constants.Strings.ShaderForceBase) }) {
                    let components = forceBaseString.components(separatedBy: "=")
                    if components.count == 2 {
                        newShader.forceBase = components[1].trimmed.replacingOccurrences(of: "\"", with: "")
                    }
                }
            }
        }
        ShaderInfoView.show(shader: newShader, didSavedShader: { [weak self] in
            guard let self else { return }
            if self.currentSource != .custom {
                self.segmentView.setIndex(ShaderSource.custom.rawValue)
            }
            self.updateShaders(source: .custom)
            self.didSelectShader?(self.selectedShader ?? ShaderManager.genOriginalShader())
        })
    }
    
    private func startSearchShaders() {
        isSearch = true
        if let searchWord = searchTextField.text?.trimmed, !searchWord.isEmpty {
            UIView.makeLoading()
            DispatchQueue.global().async {
                let fuse = Fuse()
                let pattern = fuse.createPattern(from: searchWord)
                
                var result = ShadersListData()
                self.normalShaders.forEach { source, list in
                    var listResult = [(String, [Shader])]()
                    list.forEach { item in
                        var shadersResult = [Shader]()
                        item.shaders.forEach { shader in
                            if let score = fuse.search(pattern, in: shader.title)?.score, score < 0.2 {
                                shadersResult.append(shader)
                            }
                        }
                        if shadersResult.count > 0 {
                            listResult.append((item.sectionTitle, shadersResult))
                        }
                    }
                    if listResult.count > 0 {
                        result[source] = listResult
                    }
                }
                self.searchShaders = result
                DispatchQueue.main.async {
                    UIView.hideLoading()
                    self.tableView.reloadData()
                    self.reloadIndexView()
                }
            }
        } else {
            isSearch = false
        }
    }
    
    private func stopSearchShaders() {
        isSearch = false
        searchShaders = ShadersListData()
        tableView.reloadData()
        reloadIndexView()
    }
    
}

extension ShadersListView: SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        //initType为normal时只有customSource 或 initType为gamePlay 支持侧滑
        if initType == .preview {
            return nil
        }
        if initType == .normal, currentSource != .custom {
            return nil
        }
        guard let shader = getShader(at: indexPath) else { return nil }
        UIDevice.generateHaptic()
        if orientation == .right {
            if initType == .normal, currentSource == .custom {
                //仅支持删除操作
                let delete = SwipeAction(style: .default, title: nil) { [weak self] action, indexPath in
                    guard let self else { return }
                    UIDevice.generateHaptic()
                    action.fulfill(with: .reset)
                    self.removeShader(shader)
                }
                delete.backgroundColor = .clear
                delete.image = self.deleteImage
                return [delete]
            }else if initType == .gamePlay {
                //仅支持编辑操作
                if shader.isOriginal {
                    return nil
                }
                let edit = SwipeAction(style: .default, title: nil) { [weak self] action, indexPath in
                    guard let self else { return }
                    UIDevice.generateHaptic()
                    self.showShaderInfoView(shader: shader)
                }
                edit.hidesWhenSelected = true
                edit.backgroundColor = .clear
                edit.image = editImage
                return [edit]
            }
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = SwipeExpansionStyle(target: .percentage(0.6),
                                                     elasticOverscroll: true,
                                                     completionAnimation: .fill(.manual(timing: .with)))
        options.expansionDelegate = self
        options.transitionStyle = .border
        options.backgroundColor = Constants.Color.Background
        options.maximumButtonWidth = Constants.Size.ItemHeightMin + Constants.Size.ContentSpaceTiny*2
        return options
    }
}

extension ShadersListView: SwipeExpanding {
    func animationTimingParameters(buttons: [UIButton], expanding: Bool) -> SwipeCellKit.SwipeExpansionAnimationTimingParameters {
        ScaleAndAlphaExpansion.default.animationTimingParameters(buttons: buttons, expanding: expanding)
    }
    
    func actionButton(_ button: UIButton, didChange expanding: Bool, otherActionButtons: [UIButton]) {
        ScaleAndAlphaExpansion.default.actionButton(button, didChange: expanding, otherActionButtons: otherActionButtons)
        if expanding {
            UIDevice.generateHaptic()
        }
    }
}

extension ShadersListView: UITableViewDataSource, UITableViewDelegate {
    private func getShaders(at section: Int) -> [Shader] {
        if let shadersInSource = shaders[currentSource] {
            return shadersInSource[section].shaders
        }
        return []
    }
    
    private func getSectionTitle(at section: Int) -> String {
        if let shadersInSource = shaders[currentSource] {
            return shadersInSource[section].sectionTitle
        }
        return ""
    }
    
    private func getShader(at indexPath: IndexPath) -> Shader? {
        let shaders = getShaders(at: indexPath.section)
        if shaders.count > indexPath.row {
            return shaders[indexPath.row]
        }
        return nil
    }
    
    private func removeShader(_ shader: Shader) {
        try? FileManager.safeRemoveItem(at: URL(fileURLWithPath: shader.filePath))
        if var sources = normalShaders[currentSource] {
            sources.removeAll(where: { $0.shaders.contains(where: { $0 == shader})})
            normalShaders[currentSource] = sources
            if isSearch {
                startSearchShaders()
            }
        }
        tableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return shaders[currentSource]?.count ?? 0
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getShaders(at: section).count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: ShadersListCell.self)
        cell.setData(shader: getShader(at: indexPath), initType: initType)
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let shader = getShader(at: indexPath) else { return }
        switch initType {
        case .normal:
            //跳转编辑
            showShaderInfoView(shader: shader)
            break
        case .gamePlay:
            //使用shader
            var tempShader = shader
            if tempShader.isOriginal {
                selectedShader = nil
            } else {
                tempShader.isSelected = true
                selectedShader = tempShader
            }
            DispatchQueue.main.asyncAfter(delay: 0.35) {
                self.refreshSelection()
            }
            didSelectShader?(tempShader)
            break
        case .preview:
            didSelectShader?(shader)
            break
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionTitle = getSectionTitle(at: section)
        if sectionTitle.isEmpty {
            return nil
        }
        
        let header = tableView.dequeueReusableHeaderFooterView(withClass: TriggerProHeaderView.self)
        header.titleLabel.attributedText = NSAttributedString(string: sectionTitle, attributes: [.foregroundColor: Constants.Color.LabelSecondary, .font: Constants.Font.body(size: .s)])
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if currentSource == .default || currentSource == .custom {
            return 0
        }
        if section == 0 {
            return 20
        }
        return 40
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if searchTextField.isFirstResponder {
            searchTextField.resignFirstResponder()
        }
        // indexView变更
        guard !didSelectIndexSearch,
              !indexView.isTouching,
              let tableView = scrollView as? UITableView,
              let indexPaths = tableView.indexPathsForVisibleRows,
              let firstIndexPath = indexPaths.min() else { return }
        
        let currentSection = firstIndexPath.section
        guard let item = self.indexView.item(at: currentSection), item.bounds != .zero else { return }
        guard !(self.indexView.selectedItem?.isEqual(item) ?? false) else { return }
        self.indexView.deselectCurrentItem()
        self.indexView.selectItem(at: currentSection)
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        var actions = [UIMenuElement]()
        if let shader = getShader(at: indexPath) {
            if shader.isOriginal {
                return nil
            }
            //添加为平台设定
            actions.append(UIMenu(title: R.string.localizable.updateBackgroundForConsole(""),
                                  options: .singleSelection,
                                  children: System.allCores.map({
                let coreName = $0.gameType.localizedShortName
                let isSelected = shader.coreConfigs.contains(where: { $0 == coreName })
                
                let action = UIAction(title: coreName,
                                      image: isSelected ? .symbolImage(.checkmark) : nil,
                                      state: .off,
                                      handler: { [weak self] _ in
                    guard let self else { return }
                    if isSelected {
                        //移除Core
                        self.ignoreShaderConfig = false
                        ShaderConfig.setCoreShader(nil, core: coreName)
                        self.didUpdateShaderConfig?(.setCore(coreName))
                    } else {
                        //添加Core
                        self.ignoreShaderConfig = false
                        ShaderConfig.setCoreShader(shader.relativePath, core: coreName)
                        self.didUpdateShaderConfig?(.removeCore(coreName))
                    }
                    self.shaderConfig = ShaderConfig.getConfig()
                    self.updateShaders()
                    
                })
                return action
            })))
            
            if shader.isGlobalConfig {
                //取消全局设定
                actions.append(UIAction(title: R.string.localizable.removeShaderForGlobal(), handler: { [weak self] _ in
                    guard let self else { return }
                    self.ignoreShaderConfig = false
                    ShaderConfig.setGlobalShader(nil)
                    self.shaderConfig = ShaderConfig.getConfig()
                    self.updateShaders()
                    self.didUpdateShaderConfig?(.removeGlobal)
                }))
            } else {
                //为全局设定
                actions.append(UIAction(title: R.string.localizable.updateBackgroundForGlobal(), handler: { [weak self] _ in
                    guard let self else { return }
                    self.ignoreShaderConfig = false
                    ShaderConfig.setGlobalShader(shader.relativePath)
                    self.shaderConfig = ShaderConfig.getConfig()
                    self.updateShaders()
                    self.didUpdateShaderConfig?(.setGlobal)
                }))
            }
        }
        return UIContextMenuConfiguration(actionProvider: { _ in
            UIMenu(children: actions)
        })
    }
}

extension ShadersListView {
    static var isShow: Bool {
        Sheet.find(identifier: String(describing: ShadersListView.self)).count > 0 ? true : false
    }
    
    static func show(game: Game? = nil,
                     initType: InitType? = nil,
                     isGlsl: Bool = false,
                     ignoreShaderConfig: Bool,
                     hideCompletion: (()->Void)? = nil,
                     didTapClose: (()->Void)? = nil,
                     didSelectShader: ((Shader)->Void)? = nil,
                     didUpdateShaderConfig: ((ShaderConfig.SettingType)->Void)? = nil) {
        guard game != nil || initType != nil else { return }
        Sheet.lazyPush(identifier: String(describing: ShadersListView.self) + (isShow ? "\(Int.random(in: 0...10))" : "")) { sheet in
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
            
            var isGlsl = isGlsl
            if let game, game.gameType == .n64, !game.isN64ParaLLEl {
                isGlsl = true
            }
            let listView = ShadersListView(initType: initType ?? .gamePlay, isGlsl: isGlsl, ignoreShaderConfig: ignoreShaderConfig, usingShaderPath: game?.filterName, currentCoreName: game?.gameType.localizedShortName)
            listView.didTapClose = { [weak sheet] in
                sheet?.pop()
                didTapClose?()
            }
            listView.didSelectShader = { [weak sheet] shader in
                if let initType, initType == .preview {
                    sheet?.pop()
                }
                didSelectShader?(shader)
                if let initType, initType == .preview {
                    didTapClose?()
                }
            }
            listView.didUpdateShaderConfig = { type in
                didUpdateShaderConfig?(type)
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

extension ShadersListView: SectionIndexViewDataSource, SectionIndexViewDelegate {
    func numberOfScetions(in sectionIndexView: SectionIndexView) -> Int {
        shaders[currentSource]?.count ?? 0
    }
    
    func sectionIndexView(_ sectionIndexView: SectionIndexView, itemAt section: Int) -> any SectionIndexViewItem {
        let item = SectionIndexViewItemView()
        item.title = getSectionTitle(at: section).firstCharacterAsString?.uppercased() ?? "?"
        item.titleColor = Constants.Color.LabelTertiary
        item.titleSelectedColor = Constants.Color.LabelPrimary.forceStyle(.dark)
        item.selectedColor = Constants.Color.Main
        item.titleFont = Constants.Font.caption(size: .s, weight: .bold)
        return item
    }
    
    func sectionIndexView(_ sectionIndexView: SectionIndexView, didSelect section: Int) {
        didSelectIndexSearch = true
        sectionIndexView.hideCurrentItemIndicator()
        sectionIndexView.deselectCurrentItem()
        sectionIndexView.selectItem(at: section)
        sectionIndexView.showCurrentItemIndicator()
        sectionIndexView.impact()
        tableView.panGestureRecognizer.isEnabled = false
        tableView.scrollToRow(at:  IndexPath(row: 0, section: section), at: .top, animated: true)
        DispatchQueue.main.asyncAfter(delay: 0.5) {
            self.didSelectIndexSearch = false
        }
    }
    
    func sectionIndexViewToucheEnded(_ sectionIndexView: SectionIndexView) {
        UIView.animate(withDuration: 0.3) {
            sectionIndexView.hideCurrentItemIndicator()
        }
        tableView.panGestureRecognizer.isEnabled = true
    }
    
    func sectionIndexViewDidSelectSearch(_ sectionIndexView: SectionIndexView) {
        tableView.scrollToTop()
    }
}
