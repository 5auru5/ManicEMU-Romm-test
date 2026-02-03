//
//  ShaderManager.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/3/8.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

struct ShaderManager {
    
    static func fetchShaders(source: ShadersListView.ShaderSource? = nil, isGlsl: Bool, selectedShader: Shader?, includeOriginal: Bool, shaderConfig: ShaderConfig?, ignoreShaderConfig: Bool, currentCoreName: String?) -> ShadersListData {
        var result = ShadersListData()
        let sourceCase = source == nil ? ShadersListView.ShaderSource.allCases : [source!]
        var hasSelectedShader = false
        for source in sourceCase {
            if source == .imported {
                if FileManager.default.fileExists(atPath: Constants.Path.ShaderImportedInDocument) {
                    //复制到shader的工作区
                    try? FileManager.safeCopyItem(at: URL(fileURLWithPath: Constants.Path.ShaderImportedInDocument), to: URL(fileURLWithPath: Constants.Path.ShaderImported), shouldReplace: true)
                } else {
                    try? FileManager.default.createDirectory(atPath: Constants.Path.ShaderImportedInDocument, withIntermediateDirectories: true)
                }
            }
            let isRecursive = source != .custom
            let shadersRelativePathes = findShaderFiles(in: source.searchUrl, isGlsl: isGlsl, isRecursive: isRecursive)
            switch source {
            case .default, .custom:
                var shaders = shadersRelativePathes.map({
                    let shader = genShader($0, selectedShader: selectedShader, shaderConfig: shaderConfig, ignoreShaderConfig: ignoreShaderConfig, currentCoreName: currentCoreName)
                    if shader.isSelected {
                        hasSelectedShader = true
                    }
                    return shader
                })
                if source == .default, includeOriginal {
                    shaders.insert(ShaderManager.genOriginalShader(), at: 0)
                }
                result[source] = [("", shaders)]
            case .retroarch, .imported:
                var subResult = [String: [Shader]]()
                for path in shadersRelativePathes {
                    let sectionTitleIndex = source == .retroarch ? 2 : 1
                    let components = path.pathComponents
                    if components.count > sectionTitleIndex + 1 {
                        let sectionTitle = components[sectionTitleIndex]
                        let shader = genShader(path, selectedShader: selectedShader, shaderConfig: shaderConfig, ignoreShaderConfig: ignoreShaderConfig, currentCoreName: currentCoreName)
                        if shader.isSelected {
                            hasSelectedShader = true
                        }
                        if var shaderArray = subResult[sectionTitle] {
                            shaderArray.append(shader)
                            subResult[sectionTitle] = shaderArray.sorted(by: {
                                $0.title.lowercased() < $1.title.lowercased()
                            })
                        } else {
                            subResult[sectionTitle] = [shader]
                        }
                    }
                }
                result[source] = subResult.sorted(by: \.key).map({ ($0, $1) })
            }
        }
        
        if !hasSelectedShader, let _ = result[.default] {
            //需要把"原始"设置为选中
            result[.default]![0].shaders[0].isSelected = true
        }
        
        //将多个选中的shader选出一个值得选中的
        var selectedShaders = [(source: ShadersListView.ShaderSource, section: Int, index: Int, shader: Shader)]()
        for source in result.keys {
            if let shadersInSouce = result[source] {
                for (section, shadersInSection) in shadersInSouce.enumerated() {
                    for (index, shader) in shadersInSection.shaders.enumerated() {
                        if shader.isSelected {
                            selectedShaders.append((source, section, index, shader))
                        }
                    }
                }
            }
        }
        if selectedShaders.count > 1 {
            selectedShaders = selectedShaders.sorted(by: { left, _ in
                if left.shader.isOriginal {
                    return true
                }
                if let selectedShader, left.shader.relativePath == selectedShader.relativePath {
                    return true
                }
                if let currentCoreName, left.shader.coreConfigs.contains(currentCoreName) {
                    return true
                }
                if left.shader.isGlobalConfig {
                    return true
                }
                return false
            })
            selectedShaders[1...].forEach({
                result[$0.source]![$0.section].shaders[$0.index].isSelected = false
            })
        }
        
        return result
    }
    
    private static func findShaderFiles(in directory: URL, isGlsl: Bool, isRecursive: Bool) -> [String] {
        var result: [String] = []
        let fileManager = FileManager.default
        let pathExtension = isGlsl ? "glslp" : "slangp"
        if isRecursive {
            let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: nil)
            while let fileURL = enumerator?.nextObject() as? URL {
                if fileURL.pathExtension.lowercased() == pathExtension && fileURL.lastPathComponent.deletingPathExtension.lowercased() != "retroarch",
                    let relativePath = getRelativePath(fileURL.path) {
                    result.append(relativePath)
                }
            }
        } else {
            if let fileUrls = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles) {
                for fileUrl in fileUrls {
                    let isDirectory = (try? fileUrl.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                    if !isDirectory,
                       fileUrl.pathExtension.lowercased() == pathExtension,
                       fileUrl.lastPathComponent.deletingPathExtension.lowercased() != "retroarch",
                       let relativePath = getRelativePath(fileUrl.path) {
                        result.append(relativePath)
                    }
                }
            }
        }
        return result.sorted(by: { $0 < $1 })
    }
    
    private static func getRelativePath(_ path: String) -> String? {
        if let range = path.range(of: "/Libretro/shaders/") {
            return String(path[range.upperBound...])
        }
        return nil
    }
    
    static func genShader(_ relativePath: String, selectedShader: Shader?, shaderConfig: ShaderConfig?, ignoreShaderConfig: Bool, currentCoreName: String?) -> Shader {
        var isSelected = false
        if let selectedShader {
            isSelected = (selectedShader.relativePath == relativePath)
        }
        var shader = Shader(title: relativePath.deletingPathExtension.lastPathComponent, isSelected: isSelected, relativePath: relativePath)
        var isCoreConfig = false
        if let shaderConfig {
            shaderConfig.coreConfigs.forEach { core, shaderName in
                if shader.relativePath == shaderName {
                    shader.coreConfigs.append(core)
                    if let currentCoreName, core == currentCoreName {
                        isCoreConfig = true
                    }
                }
            }
            if let globalConfig = shaderConfig.globalConfig, shader.relativePath == globalConfig {
                shader.isGlobalConfig = true
            }
        }
        if selectedShader == nil && (isCoreConfig || shader.isGlobalConfig) && !ignoreShaderConfig {
            shader.isSelected = true
        }
        return shader
    }
    
    static func genOriginalShader() -> Shader {
        var shader = Shader(title: R.string.localizable.filterOriginTitle(), isSelected: false, relativePath: "")
        shader.isOriginal = true
        return shader
    }
    
}
