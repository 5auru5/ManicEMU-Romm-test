//
//  AzaharAdvancedSettingViewController.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/11/21.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UniformTypeIdentifiers

class AzaharAdvancedSettingViewController: QuickTableViewController {
    
    enum SettingType {
        case none, `switch`, option
    }
    
    private lazy var currentConfig: [String: String] = { readConfig() }()
    
    private var isModified = false
    
    private var isFirstInit = true
    
    private var navigationBlurView: NavigationBlurView = {
        let view = NavigationBlurView()
        view.makeBlur()
        return view
    }()
    
    private lazy var moreContextMenuButton: ContextMenuButton = {
        var actions: [UIMenuElement] = []
        actions.append((UIAction(title: R.string.localizable.controllerMappingReset()) { [weak self] _ in
            guard let self = self else { return }
            //重置
            self.isModified = false
            try? FileManager.safeCopyItem(at: URL(fileURLWithPath: Constants.Path.AzaharDefaultConfig), to: URL(fileURLWithPath: Constants.Path.AzaharConfig), shouldReplace: true)
            self.currentConfig = self.readConfig()
            self.updateData()
        }))
        actions.append(UIAction(title: R.string.localizable.shareConfigButtonTitle()) { [weak self] _ in
            guard let self = self else { return }
            //分享配置
            if self.isModified {
                if FileManager.default.fileExists(atPath: Constants.Path.AzaharConfig) {
                    try? FileManager.default.removeItem(atPath: Constants.Path.AzaharConfig)
                }
                self.writeConfig()
                self.isModified = false
            }
            ShareManager.shareFile(fileUrl: URL(fileURLWithPath: Constants.Path.AzaharConfig))
        })
        actions.append((UIAction(title: R.string.localizable.importConfigButtonTitle()) { [weak self] _ in
            guard let self = self else { return }
            //导入配置
            FilesImporter.shared.presentImportController(supportedTypes: UTType.configTypes, allowsMultipleSelection: false) { [weak self] urls in
                guard let self else { return }
                if let url = urls.first {
                    do {
                        try FileManager.safeCopyItem(at: url, to: URL(fileURLWithPath: Constants.Path.AzaharConfig), shouldReplace: true)
                        self.currentConfig = self.readConfig()
                        self.updateData()
                    } catch {
                        UIView.makeToast(message: R.string.localizable.readConfigFileFailed())
                    }
                }
            }
        }))
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
    
    init() {
        super.init(style: .insetGrouped)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.updateData()
        
        view.addSubview(navigationBlurView)
        navigationBlurView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(Constants.Size.ItemHeightMid)
        }
        
        navigationBlurView.addSubview(moreContextMenuButton)
        moreContextMenuButton.snp.makeConstraints { make in
            make.leading.equalTo(Constants.Size.ContentSpaceMax)
            make.centerY.equalToSuperview()
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
        
        navigationBlurView.addSubview(moreButton)
        moreButton.snp.makeConstraints { make in
            make.edges.equalTo(moreContextMenuButton)
        }
        
        let titleLabel = UILabel()
        titleLabel.text = R.string.localizable.threeDSAdvanceSettingTitle()
        titleLabel.font = Constants.Font.title(size: .s)
        titleLabel.textColor = Constants.Color.LabelPrimary
        navigationBlurView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        addCloseButton(makeConstraints:  { make in
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
            make.centerY.equalTo(self.moreButton)
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isModified {
            writeConfig()
        }
    }
    
    private func readConfig(useDefault: Bool = false) -> [String: String] {
        var config: String?
        if useDefault {
            config = try? String(contentsOfFile: Constants.Path.AzaharDefaultConfig, encoding: .utf8)
        } else {
            if !FileManager.default.fileExists(atPath: Constants.Path.AzaharConfig) {
                try? FileManager.safeCopyItem(at: URL(fileURLWithPath: Constants.Path.AzaharDefaultConfig), to: URL(fileURLWithPath: Constants.Path.AzaharConfig))
            }
            config = try? String(contentsOfFile: Constants.Path.AzaharConfig, encoding: .utf8)
        }
        if let config {
            var result = [String: String]()
            config.enumerateLines { line, stop in
                let components = line.components(separatedBy: "=")
                if components.count == 2 {
                    result[components[0].trimmed.replacingOccurrences(of: "citra_", with: "")] = components[1].trimmed.replacingOccurrences(of: "\"", with: "")
                }
            }
            return result
        }
        return [:]
    }
    
    private func writeConfig() {
        guard isModified else { return }
        try? FileManager.safeRemoveItem(at: URL(fileURLWithPath: Constants.Path.AzaharConfig))
        let configString = currentConfig.reduce("", { $0 + "citra_\($1.key) = \"\($1.value)\"\n" })
        try? configString.write(toFile: Constants.Path.AzaharConfig, atomically: true, encoding: .utf8)
    }
    
    private func updateData() {
        var results = [Section]()
        for config in currentConfig {
            let key = config.key
            switch getType(key: key) {
            case .switch:
                let forDisable = (key == "use_cpu_jit" && !LibretroCore.jitAvailable()) ? true : false
                let value = config.value == "enabled" ? true : false
                let rows = [SwitchRow(text: key,
                                      switchValue: forDisable ? false : value,
                                      action: { [weak self] row in
                    guard let self else { return }
                    //开关操作
                    if let switchRow = row as? SwitchRow {
                        if switchRow.text == "use_cpu_jit", switchRow.switchValue, !LibretroCore.jitAvailable() {
                            UIView.makeToast(message: R.string.localizable.jitNoSupportDesc())
                            switchRow.switchValue = false
                            self.tableView.reloadData()
                            return
                        }
                        currentConfig[key] = switchRow.switchValue ? "enabled" : "disabled"
                        self.isModified = true
                    }
                })]
                let section = Section(title: nil, rows: rows, footer: self.getDesc(key: key))
                results.append(section)
                
            case .option:
                var rows = [Row & RowStyle]()
                let options = getOptions(key: key)
                let defaultSelected = options.firstIndex(where: {
                    $0 == (key == "cpu_scale" ? config.value + "%" : config.value)
                }) ?? 0
                for (index, option) in options.enumerated() {
                    rows.append(OptionRow(text: option, isSelected: index == defaultSelected, action: { [weak self] row in
                        guard let self else { return }
                        //选择操作
                        if let optionRow = row as? OptionRow {
                            currentConfig[key] = optionRow.text.replacingOccurrences(of: "%", with: "")
                            self.isModified = true
                        }
                    }))
                }
                results.append(Section(title: key, rows: rows, footer: getDesc(key: key)))
            case .none:
                break
            }
        }
        
        tableContents = results.sorted(by: {
            let firstkey = $0.rows.count == 1 ? $0.rows.first?.text : $0.title
            let secondKey = $1.rows.count == 1 ? $1.rows.first?.text : $1.title
            if let firstkey, let secondKey, let firstIndex = sortKeys.firstIndex(of: firstkey), let secondIndex = sortKeys.firstIndex(of: secondKey) {
                return firstIndex < secondIndex
            } else {
                return true
            }
        })
        
        if isFirstInit {
            isFirstInit = false
            DispatchQueue.main.asyncAfter(delay: 0.35) {
                var contentOffset = self.tableView.contentOffset
                contentOffset.y = -Constants.Size.ItemHeightMid
                self.tableView.contentOffset = contentOffset
            }
        }
    }
        
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var configInfo: [(key: String, type: SettingType, options: [String], desc: String)] {
        [
            ("use_cpu_jit", .switch, [], "Enable Just-In-Time compilation for ARM CPU emulation.\nSignificantly improves performance but may reduce accuracy. ")

            , ("cpu_scale", .option, ["25%", "50%", "75%", "100%", "125%", "150%", "175%", "200%", "225%", "250%", "275%", "300%", "325%", "350%", "375%", "400%"], "Adjust the emulated 3DS CPU clock speed as a percentage of normal speed.\nHigher values may improve performance in some games but can cause issues.\nLower values can help with games that run too fast.")

            , ("is_new_3ds", .option, ["Old 3DS", "New 3DS"], "Select whether to emulate the original 3DS or New 3DS.\nNew 3DS has additional CPU power and memory, required for some games. ")

            , ("region_value", .option, ["Auto", "Japan", "USA", "Europe", "Australia", "China", "Korea", "Taiwan"], "Set the 3DS system region_value. Auto-select will choose based on the game.\nSome games are region_value-locked and require matching region_values.")

            , ("language", .option, ["English", "Japanese", "French", "Spanish", "German", "Italian", "Dutch", "Portuguese", "Russian", "Korean", "Traditional Chinese", "Simplified Chinese"], "Set the system language for the emulated 3DS.\nThis affects in-game text language when supported.")

            , ("audio_emulation", .option, ["hle", "lle"],  "Select audio emulation method. HLE is faster, LLE is more accurate.")

            , ("use_hw_shaders", .switch, [], "Use GPU hardware to accelerate shader processing.\nSignificantly improves performance but may reduce accuracy.")

            , ("use_shader_jit", .switch, [], "Use Just-In-Time compilation for shaders.\nImproves performance but may cause graphical issues in some games.")

            , ("use_acc_mul", .switch, [], "Use accurate multiplication in shaders.\nMore accurate but can reduce performance. Only works with hardware shaders.")

            , ("use_hw_shader_cache", .switch, [], "Save compiled shaders to disk to reduce loading times on subsequent runs.")

            , ("texture_filter", .option, ["none", "Anime4K Ultrafast", "Bicubic", "ScaleForce", "xBRZ", "MMPX"], "Apply texture filtering to enhance visual quality.\nSome filters may significantly impact performance.")

            , ("texture_sampling", .option, ["GameControlled", "NearestNeighbor", "Linear"], "Control how textures are sampled and filtered.")

            , ("custom_textures", .switch, [], "Enable loading of custom texture packs to replace original game textures.")

            , ("dump_textures", .switch, [], "Save original game textures to disk for creating custom texture packs.\nMay impact performance.")

            , ("use_virtual_sd", .switch, [], "Enable virtual SD card support for homebrew and some commercial games.")
        ]
    }
    
    var sortKeys: [String] { configInfo.map({ $0.key }) }
    
    private func getType(key: String) -> SettingType {
        configInfo.first(where: { $0.key == key })?.type ?? .none
    }
    
    private func getOptions(key: String) -> [String] {
        configInfo.first(where: { $0.key == key })?.options ?? []
    }
    
    private func getDesc(key: String) -> String? {
        configInfo.first(where: { $0.key == key })?.desc
    }
}
