//
//  ThreeDSAdvancedSettingViewController.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/6/26.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UniformTypeIdentifiers

class ThreeDSAdvancedSettingViewController: QuickTableViewController {
    
    enum SettingType {
        case none, `switch`, option, action
    }
    
    private var currentConfig = try? INIFile(fileName: Constants.Path.ThreeDSConfig)
    private let defaultConfig = try? INIFile(fileName: Constants.Path.ThreeDSDefaultConfig)
    private var isModified = false
    
    private var navigationBlurView: UIView = {
        let view = UIView()
        view.makeBlur()
        return view
    }()
    
    private lazy var moreContextMenuButton: ContextMenuButton = {
        var actions: [UIMenuElement] = []
        actions.append((UIAction(title: R.string.localizable.controllerMappingReset()) { [weak self] _ in
            guard let self = self else { return }
            //重置
            self.isModified = false
            try? FileManager.safeCopyItem(at: URL(fileURLWithPath: Constants.Path.ThreeDSDefaultConfig), to: URL(fileURLWithPath: Constants.Path.ThreeDSConfig), shouldReplace: true)
            self.currentConfig = try? INIFile(fileName: Constants.Path.ThreeDSConfig)
            self.updateData()
        }))
        actions.append(UIAction(title: R.string.localizable.shareConfigButtonTitle()) { [weak self] _ in
            guard let self = self else { return }
            //分享配置
            if self.isModified {
                try? self.currentConfig?.writeFile()
                self.isModified = false
            }
            ShareManager.shareFile(fileUrl: URL(fileURLWithPath: Constants.Path.ThreeDSConfig))
        })
        actions.append((UIAction(title: R.string.localizable.importConfigButtonTitle()) { [weak self] _ in
            guard let self = self else { return }
            //导入配置
            FilesImporter.shared.presentImportController(supportedTypes: UTType.configTypes, allowsMultipleSelection: false) { [weak self] urls in
                guard let self else { return }
                if let url = urls.first {
                    do {
                        try FileManager.safeCopyItem(at: url, to: URL(fileURLWithPath: Constants.Path.ThreeDSConfig), shouldReplace: true)
                        self.currentConfig = try INIFile(fileName: Constants.Path.ThreeDSConfig)
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
            make.leading.top.trailing.equalToSuperview()
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
            try? currentConfig?.writeFile()
        }
    }
    
    private func updateData() {
        if let config = currentConfig, let defaultConfig {
            let sectionList = config.sectionList
            var results = [Section]()
            for section in sectionList {
                if section == "_DEFAULT_" {
                    continue
                }
                results.append(Section(title: section, rows: []))
                if let keys = config.keyList[section] {
                    for key in keys {
                        let captureSection = section
                        let captureKey = key
                        switch getType(key: key) {
                        case .switch:
                            let forDisable = (key == "use_cpu_jit" && !LibretroCore.jitAvailable()) ? true : false
                            results.append(Section(title: nil, rows: [SwitchRow(text: key, switchValue: forDisable ? false : config.readBool(section, key, defaultConfig.readBool(section, key, false)), action: { [weak self] row in
                                guard let self else { return }
                                //开关操作
                                if let switchRow = row as? SwitchRow {
                                    if switchRow.text == "use_cpu_jit", switchRow.switchValue, !LibretroCore.jitAvailable() {
                                        UIView.makeToast(message: R.string.localizable.jitNoSupportDesc())
                                        switchRow.switchValue = false
                                        self.tableView.reloadData()
                                        return
                                    }
                                    config.writeString(captureSection, captureKey, switchRow.switchValue ? "1" : "0")
                                    self.isModified = true
                                }
                                
                            })], footer: config.readKeyNote(section, key)?.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespacesAndNewlines)))
                            
                        case .option:
                            var defaultSelected = config.readInt(section, key, defaultConfig.readInt(section, key, 0))
                            if key == "region_value" {
                                defaultSelected += 1
                            }
                            var rows = [Row & RowStyle]()
                            let options = getOptions(key: key)
                            for (index, option) in options.enumerated() {
                                rows.append(OptionRow(text: option, isSelected: index == defaultSelected, action: { [weak self] row in
                                    guard let self else { return }
                                    //选择操作
                                    if let optionRow = row as? OptionRow, let index = options.firstIndex(of: optionRow.text) {
                                        config.writeString(captureSection, captureKey, String( captureKey == "region_value" ? index - 1 : index))
                                        self.isModified = true
                                    }
                                }))
                            }
                            results.append(Section(title: key, rows: rows, footer: config.readKeyNote(section, key)?.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespacesAndNewlines)))
                            
                        case .action:
                            let footer = config.readKeyNote(section, key)?.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                            results.append(Section(title: nil, rows: [NavigationRow(text: key, detailText: .value1(config.readString(section, key, defaultConfig.readString(section, key, ""))), action: { [weak self] row in
                                guard let self else { return }
                                //点击回调
                                if let navigationRow = row as? NavigationRow {
                                    LimitedTextInputView.show(title: navigationRow.text, detail: footer, text: navigationRow.detailText?.text, limitedType: self.getActionLimitedType(key: navigationRow.text)) { [weak self, weak navigationRow] result in
                                        guard let self, let navigationRow else { return }
                                        var writeString: String? = nil
                                        if let int = result as? Int {
                                            writeString = String(int)
                                        } else if let double = result as? Double {
                                            writeString = String(double)
                                        } else if let string = result as? String {
                                            writeString = string
                                        }
                                        if let writeString {
                                            config.writeString(captureSection, captureKey, writeString)
                                            self.isModified = true
                                            navigationRow.detailText = .value1(writeString)
                                            self.tableView.reloadData()
                                        }
                                    }
                                }
                                
                            })], footer: footer))
                            
                        case .none:
                            break
                        }
                    }
                }
            }
            tableContents = results
        } else {
            tableContents = []
        }
    }
        
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func getType(key: String) -> SettingType {
        switch key {
        case "use_cpu_jit",
            "disable_right_eye_render",
            "async_shader_compilation",
            "use_hw_shader",
            "shaders_accurate_mul",
            "use_shader_jit",
            "use_vsync_new",
            "use_disk_shader_cache",
            "use_frame_limit",
            "dump_textures",
            "custom_textures",
            "preload_textures",
            "async_custom_loading",
            "enable_audio_stretching",
            "use_virtual_sd",
            "is_new_3ds",
            "lle_applets",
            "plugin_loader",
            "allow_plugin_loader",
            "enable_realtime_audio":
            return .switch
        case "cpu_clock_percentage",
            "resolution_factor",
            "frame_limit",
            "bg_red",
            "bg_blue",
            "bg_green",
            "factor_3d",
            "pp_shader_name",
            "anaglyph_shader_name",
            "volume",
            "init_time",
            "init_ticks_override",
            "steps_per_hour":
            return .action
        case "spirv_shader_gen",
            "render_3d",
            "filter_mode",
            "output_type",
            "input_type",
            "region_value",
            "init_clock",
            "init_ticks_type",
            "camera_outer_right_flip",
            "camera_outer_left_flip",
            "camera_inner_flip",
            "texture_filter",
            "texture_sampling",
            "mono_render_option",
            "audio_emulation":
            return .option
        default: return .none
        }
    }
    
    private func getOptions(key: String) -> [String] {
        switch key {
        case  "spirv_shader_gen":
            return ["GLSL", "SPIR-V"]
        case "render_3d":
            return ["Off", "Side by Side", "Anaglyph", "Interlaced", "Reverse Interlaced", "Cardboard VR"]
        case "filter_mode":
            return ["Nearest", "Linear"]
        case "output_type":
            return ["Auto", "No audio output", "Cubeb", "OpenAL", "SDL"]
        case "input_type":
            return ["Auto", "No audio input", "Static noise", "Cubeb", "OpenAL"]
        case "region_value":
            return ["Auto", "Japan", "USA", "Europe", "Australia", "China", "Korea", "Taiwan"] //特殊处理 Auto是-1
        case "init_clock":
            return ["System clock", "fixed time"]
        case "init_ticks_type":
            return ["Random", "Fixed"]
        case "camera_outer_right_flip", "camera_outer_left_flip", "camera_inner_flip":
            return ["None", "Horizontal", "Vertical", "Reverse"]
        case "texture_filter":
            return ["None", "Anime4K", "Bicubic", "ScaleForce", "xBRZ", "MMPX"]
        case "texture_sampling":
            return ["GameControlled", "NearestNeighbor", "Linear"]
        case "mono_render_option":
            return ["LeftEye", "RightEye"]
        case "audio_emulation":
            return ["HLE", "LLE", "LLEMultithreaded"]
        default:
            return []
        }
    }
    
    private func getActionLimitedType(key: String) -> LimitedTextInputView.LimitedType {
        switch key {
        case "cpu_clock_percentage":
            return .integer(min: 0, max: 400)
        case "resolution_factor":
            return .integer(min: 0, max: 10)
        case "frame_limit":
            return .integer(min: 1, max: 9999)
        case "bg_red":
            return .decimal(min: 0.0, max: 1.0)
        case "bg_blue":
            return .decimal(min: 0.0, max: 1.0)
        case "bg_green":
            return .decimal(min: 0.0, max: 1.0)
        case "factor_3d":
            return .integer(min: 0, max: 100)
        case "pp_shader_name":
            return .normal(textSize: 256)
        case "anaglyph_shader_name":
            return .normal(textSize: 256)
        case "volume":
            return .decimal(min: 0.0, max: 1.0)
        case "init_time":
            return .integer(min: 946681277, max: Int.max)
        case "init_ticks_override":
            return .integer(min: 0, max: Int.max)
        case "steps_per_hour":
            return .integer(min: 0, max: Int.max)
        default:
            return .normal(textSize: 256)
        }
    }
}

