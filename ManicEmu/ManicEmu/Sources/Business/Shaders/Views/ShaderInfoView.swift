//
//  ShaderInfoView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/12/14.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import IQKeyboardManagerSwift
import ProHUD

class ShaderInfoView: BaseView {
    
    enum SectionIndex: Int {
        case desc, shaderName, appendShaders, parameters
        
        var title: String {
            switch self {
            case .desc:
                ""
            case .shaderName:
                R.string.localizable.shaderName()
            case .appendShaders:
                R.string.localizable.appendShadersTitle()
            case .parameters:
                R.string.localizable.parameters()
            }
        }
    }

    private var navigationBlurView: NavigationBlurView = {
        let view = NavigationBlurView()
        view.makeBlur()
        return view
    }()
    
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.register(cellWithClass: NoInsetDescriptionCollectionViewCell.self)
        view.register(cellWithClass: ShaderInfoInputCell.self)
        view.register(cellWithClass: ShaderInfoAppendCell.self)
        view.register(cellWithClass: ShaderInfoParameterCell.self)
        view.register(supplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withClass: BackgroundColorHaderReusableView.self)
        view.showsVerticalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.contentInset = UIEdgeInsets(top: Constants.Size.ItemHeightMid, left: 0, bottom: Constants.Size.ContentInsetBottom, right: 0)
        return view
    }()
    
    private lazy var saveButton: HowToButton = {
        let view = HowToButton(title: R.string.localizable.saveTitle(), enableGlass: true) { [weak self] in
            guard let self = self else { return }
            self.collectionView.endEditing(true)
            
            if self.editShader.title == "retroarch" {
                UIView.makeToast(message: R.string.localizable.customShaderTitleWrong())
                return
            }
            
            func saveShader() {
                if !FileManager.default.fileExists(atPath: self.editShader.changingPath) {
                    UIView.makeAlert(detail: R.string.localizable.customShaderSaveFailed(), cancelTitle: R.string.localizable.confirmTitle())
                    return
                }
                self.editShader.optimizeConfig()
                try? FileManager.safeCopyItem(at: URL(fileURLWithPath: self.editShader.changingPath), to: URL(fileURLWithPath: self.editShader.customPath), shouldReplace: true)
                UIView.makeToast(message: R.string.localizable.customShaderSaveSuccess(self.editShader.title))
                didTapClose?(true)
            }
            
            if FileManager.default.fileExists(atPath: self.editShader.customPath) {
                UIView.makeAlert(detail: R.string.localizable.customShaderExists(), confirmTitle: R.string.localizable.confirmTitle(), confirmAction: {
                    saveShader()
                })
            } else {
                saveShader()
            }
        }
        return view
    }()
    
    private lazy var closeButton: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .xmark, font: Constants.Font.body(weight: .bold)), enableGlass: true)
        view.enableRoundCorner = true
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            if self.editShader != self.originShader {
                UIView.makeAlert(detail: R.string.localizable.changeAlert(), confirmTitle: R.string.localizable.multiDiscContinueClose(), confirmAction: {
                    self.didTapClose?(false)
                })
            } else {
                self.didTapClose?(false)
            }
        }
        return view
    }()
    
    private var originShader: Shader
    private var editShader: Shader
    private var libretroEngine: Any? = nil
    
    var didTapClose: ((Bool)->Void)? = nil
    
    init(shader: Shader) {
        var tempShader = shader
        tempShader.isBase = true
        self.originShader = tempShader
        self.editShader = tempShader
        super.init(frame: .zero)
        Log.debug("\(String(describing: Self.self)) init")
        
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(navigationBlurView)
        navigationBlurView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalTo(self.safeAreaLayoutGuide)
            make.height.equalTo(Constants.Size.ItemHeightMid)
        }
        
        updateConfirmButton(enable: false)
        navigationBlurView.addSubview(saveButton)
        saveButton.snp.makeConstraints { make in
            make.leading.equalTo(Constants.Size.ContentSpaceMax)
            make.centerY.equalToSuperview()
            make.height.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
        
        navigationBlurView.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
            make.centerY.equalToSuperview()
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
        
        IQKeyboardManager.shared.isEnabled = true
        
        UIView.makeLoading()
        DispatchQueue.main.asyncAfter(delay: 0.35, execute: {
            if !PlayViewController.isGaming {
                self.libretroEngine = LibretroCore.sharedInstance().start(withCustomSaveDir: nil)
                LibretroCore.sharedInstance().pause()
            }
            if LibretroCore.sharedInstance().setShader(self.editShader.forceBasePath ?? self.editShader.filePath) {
                self.originShader.fulfillAppendedShaders()
                self.originShader.updateAppendedShadersForEngine()
                self.originShader.updateForceBasePrameters()
                self.originShader.fulfillParameters()
                self.editShader = self.originShader
                UIView.hideLoading()
                self.collectionView.reloadData()
            } else {
                DispatchQueue.main.asyncAfter(delay: 1.5) {
                    UIView.hideLoading()
                    UIView.makeToast(message: R.string.localizable.shaderLoadFailed())
                    self.didTapClose?(false)
                }
            }
        })
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
        Task {
            await MainActor.run {
                IQKeyboardManager.shared.isEnabled = false
            }
        }
        if let _ = libretroEngine {
            LibretroCore.sharedInstance().resume()
            LibretroCore.sharedInstance().stop()
        }
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, env in
            guard let sectionType = SectionIndex(rawValue: sectionIndex) else { return nil }
            //item布局
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                 heightDimension: .fractionalHeight(1)))
            
            
            
            
            let itemHeight: CGFloat = sectionType == .desc || sectionType == .appendShaders ? 60 : 50
            
            //group布局
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: sectionType == .desc ? .estimated(itemHeight) : .absolute(itemHeight)), subitems: [item])
            group.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                          leading: Constants.Size.ContentSpaceMid,
                                                          bottom: 0,
                                                          trailing: Constants.Size.ContentSpaceMid)
            
            //section布局
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: Constants.Size.ContentSpaceMin, trailing: 0)
            if sectionType == .parameters {
                section.interGroupSpacing = 20
            }
            
            
            if sectionType != .desc {
                //header布局
                let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                                                heightDimension: .absolute(44)),
                                                                             elementKind: UICollectionView.elementKindSectionHeader,
                                                                             alignment: .top)
                headerItem.pinToVisibleBounds = true
                section.boundarySupplementaryItems = [headerItem]
            }
            
            return section
        }
        return layout
    }
    
    private func updateConfirmButton(enable: Bool) {
        if #available(iOS 26.0, *) {
            if enable {
                saveButton.label.font = Constants.Font.caption(size: .l, weight: .semibold)
                saveButton.label.textColor = Constants.Color.LabelPrimary
                saveButton.isUserInteractionEnabled = true
            } else {
                saveButton.label.font = Constants.Font.caption(size: .l, weight: .regular)
                saveButton.label.textColor = Constants.Color.LabelTertiary
                saveButton.isUserInteractionEnabled = false
            }
        } else {
            if enable {
                saveButton.backgroundColor = Constants.Color.Main
                saveButton.label.textColor = Constants.Color.LabelPrimary.forceStyle(.dark)
                saveButton.isUserInteractionEnabled = true
            } else {
                saveButton.backgroundColor = Constants.Color.BackgroundPrimary
                saveButton.label.textColor = Constants.Color.LabelTertiary
                saveButton.isUserInteractionEnabled = false
            }
        }
    }
    
    private func validateChange() {
        let isChange = originShader != editShader
        updateConfirmButton(enable: isChange)
    }
}

extension ShaderInfoView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return editShader.parameters.count > 0 ? 4 : 3
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == SectionIndex.parameters.rawValue {
            return editShader.parameters.count
        }
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == SectionIndex.desc.rawValue {
            let cell = collectionView.dequeueReusableCell(withClass: NoInsetDescriptionCollectionViewCell.self, for: indexPath)
            cell.descLabel.text = R.string.localizable.shaderEditAlert()
            return cell
        } else if indexPath.section == SectionIndex.shaderName.rawValue {
            let cell = collectionView.dequeueReusableCell(withClass: ShaderInfoInputCell.self, for: indexPath)
            cell.editTextField.text = editShader.title
            cell.shouldGoNext = { [weak self] in
                guard let self = self else { return }
                self.collectionView.endEditing(true)
                self.validateChange()
            }
            cell.editTextField.onChange { [weak self, weak cell] string in
                guard let self, let cell else { return }
                if string.count > 255 {
                    cell.editTextField.text = String(string[...255])
                    return
                }
                self.editShader.title = string
            }
            return cell
        } else if indexPath.section == SectionIndex.appendShaders.rawValue {
            let cell = collectionView.dequeueReusableCell(withClass: ShaderInfoAppendCell.self, for: indexPath)
            cell.chevronButton.titleLabel.text = "\(editShader.appendedShaders.count)"
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withClass: ShaderInfoParameterCell.self, for: indexPath)
            let param = editShader.parameters[indexPath.row]
            cell.titleLabel.text = param.desc
            cell.chevronButton.titleLabel.text = "\(param.current.roundedString(scale: 4, minFraction: 1, maxFraction: 4))"
            return cell
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: BackgroundColorHaderReusableView.self, for: indexPath)
        if let sectionIndex = SectionIndex(rawValue: indexPath.section) {
            let matt = NSMutableAttributedString(string: sectionIndex.title, attributes: [.font: Constants.Font.body(size: .s, weight: .semibold), .foregroundColor: Constants.Color.LabelSecondary])
            header.titleLabel.attributedText = matt
        }
        return header
    }
}

extension ShaderInfoView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == SectionIndex.appendShaders.rawValue {
            ShaderOrderView.show(shader: editShader, didChangeShader: { [weak self] modifiedShader in
                guard let self, let modifiedShader else { return }
                UIView.makeLoading()
                DispatchQueue.main.asyncAfter(delay: 0.35, execute: {
                    self.editShader = modifiedShader
                    self.editShader.updateAppendedShadersForEngine()
                    let changingParameters = self.editShader.getChangingParameters(with: self.originShader)
                    for parameter in changingParameters {
                        self.editShader.updateParameters(identifier: parameter.identifier, value: parameter.value)
                    }
                    self.editShader.fulfillParameters()
                    self.collectionView.reloadData()
                    self.validateChange()
                    UIView.hideLoading()
                })
            })
        } else if indexPath.section == SectionIndex.parameters.rawValue {
            let param = editShader.parameters[indexPath.row]
            
            let values = Array(stride(from: Double(param.minimum), through: Double(param.maximum), by: Double(param.step)))
            TriggerProTimePickerView.show(title: param.desc,
                                          values: values,
                                          defaultValue: Double(param.current),
                                          unitString: "",
                                          scale: 4,
                                          minFraction: 1,
                                          maxFraction: 4,
                                          didSelectValue: { [weak self] value, string in
                guard let self else { return }
                self.editShader.parameters[indexPath.row].current = Float(value)
                self.editShader.updateParameters(identifier: self.editShader.parameters[indexPath.row].identifier, value: Float(value))
                if let cell = self.collectionView.cellForItem(at: indexPath) as? ShaderInfoParameterCell {
                    cell.chevronButton.titleLabel.text = string
                }
                self.validateChange()
            })
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let cell = collectionView.cellForItem(at: IndexPath(row: 0, section: SectionIndex.shaderName.rawValue)) as? ShaderInfoInputCell, cell.editTextField.isFirstResponder {
            cell.editTextField.resignFirstResponder()
        }
    }
}

extension ShaderInfoView {
    static func show(shader: Shader, hideCompletion: (()->Void)? = nil, didSavedShader:(()->Void)? = nil) {
        Sheet { sheet in
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
            
            let listView = ShaderInfoView(shader: shader)
            listView.didTapClose = { [weak sheet] saveSuccess in
                if saveSuccess {
                    didSavedShader?()
                }
                sheet?.pop()
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
