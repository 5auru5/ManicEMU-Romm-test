//
//  Shader.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/12/13.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

struct Shader: Equatable {
    struct Parameter {
        var identifier: String
        var desc: String
        var current: Float
        var minimum: Float
        var maximum: Float
        var step: Float
        var pass: UInt32
    }
    
    var title: String
    var isSelected: Bool
    var relativePath: String
    
    //需要通过Libretro获取以下参数
    var parameters = [Parameter]()
    var appendedShaders = [Shader]()
    var indexInAppendage = 0
    var isBase: Bool = false
    
    //特殊属性
    var isOriginal: Bool = false
    var baseRelativePath: String? = nil
    var forceBase: String? = nil
    var coreConfigs: [String] = []
    var isGlobalConfig: Bool = false
    var configAlert: String? {
        var placeholder = ""
        if isGlobalConfig {
            placeholder += R.string.localizable.global()
        }
        if coreConfigs.count > 0 {
            placeholder += "\(placeholder.isEmpty ? "" : " ") \(coreConfigs.reduce("", { $0 + ($0.isEmpty ? "" : " ") + $1}))"
        }
        if !placeholder.isEmpty {
            return R.string.localizable.shaderConfigAlert(placeholder)
        }
        return nil
    }
    
    //计算属性
    var filePath: String {
        Constants.Path.Shaders.appendingPathComponent(relativePath)
    }
    
    var changingPath: String {
        Constants.Path.Shaders.appendingPathComponent("retroarch.\(relativePath.pathExtension)")
    }
    
    var customPath: String {
        Constants.Path.Shaders.appendingPathComponent("\(title).\(relativePath.pathExtension)")
    }
    
    var forceBasePath: String? {
        if let forceBase {
            return Constants.Path.Shaders.appendingPathComponent(forceBase)
        }
        return nil
    }
    
    static func == (lhs: Shader, rhs: Shader) -> Bool {
        if lhs.title != rhs.title {
            return false
        }
        if lhs.indexInAppendage != rhs.indexInAppendage {
            return false
        }
        if lhs.appendedShaders.count != rhs.appendedShaders.count {
            return false
        }
        for (index, lhsShader) in lhs.appendedShaders.enumerated() {
            let rhsShader = rhs.appendedShaders[index]
            if lhsShader != rhsShader {
                return false
            }
        }
        if lhs.parameters.count != rhs.parameters.count {
            return false
        }
        for (index, lhsParams) in lhs.parameters.enumerated() {
            let rhsParams = rhs.parameters[index]
            if lhsParams.identifier != rhsParams.identifier {
                return false
            }
            if lhsParams.current != rhsParams.current {
                return false
            }
        }
        return true
    }
    
    //从预设中文件中读取已经附加的其他预设并填充appendedShaders属性
    mutating func fulfillAppendedShaders() {
        if let shaderString = try? String(contentsOfFile: filePath, encoding: .utf8) {
            for line in shaderString.lines() {
                if line.starts(with: Constants.Strings.AppendedShaders) {
                    if let listString = line.components(separatedBy: "=").last?.trimmed.replacingOccurrences(of: "\"", with: "") {
                        let appendedShadersPathes = listString.components(separatedBy: ",")
                        var appendedShaders = [Shader]()
                        for (index, path) in appendedShadersPathes.enumerated() {
                            if path.trimmed.isEmpty {
                                continue
                            }
                            let shader = Shader(title: path.trimmed.lastPathComponent.deletingPathExtension, isSelected: false, relativePath: path.trimmed)
                            if shader.relativePath == self.relativePath {
                                self.indexInAppendage = index
                                continue
                            }
                            appendedShaders.append(shader)
                        }
                        self.appendedShaders = appendedShaders
                        break
                    }
                }
            }
        }
    }
    
    mutating func fulfillParameters() {
        if let parameters = LibretroCore.sharedInstance().loadParameters() {
            self.parameters = parameters.map({ Parameter(identifier: $0.identifier, desc: $0.desc, current: $0.current, minimum: $0.minimum, maximum: $0.maximum, step: $0.step, pass: $0.pass)})
        }
    }
    
    func updateForceBasePrameters() {
        if let _ = forceBase {
            LibretroCore.sharedInstance().setShader(filePath)
            if let parameters = LibretroCore.sharedInstance().loadParameters() {
                updateAppendedShadersForEngine()
                for parameter in parameters {
                    updateParameters(identifier: parameter.identifier, value: parameter.current)
                }
            }
        }
    }
    
    func updateAppendedShadersForEngine() {
        LibretroCore.sharedInstance().setShader(forceBasePath ?? filePath)
        
        //更新附加预设
        var tempAppendedShaders = appendedShaders
        tempAppendedShaders.insert(self, at: indexInAppendage)
        if tempAppendedShaders.count > 1, indexInAppendage < tempAppendedShaders.count {
            var prepends = [Shader]()
            var appends = [Shader]()
            if indexInAppendage > 0 {
                prepends = (tempAppendedShaders[..<indexInAppendage]).reversed()
            }
            
            if indexInAppendage != tempAppendedShaders.count - 1 {
                appends = Array(appendedShaders[(indexInAppendage)...])
            }

            for prepend in prepends {
                LibretroCore.sharedInstance().appendShader(prepend.filePath, prepend: true)
                LibretroCore.sharedInstance().setShader(changingPath)
            }
            for append in appends {
                LibretroCore.sharedInstance().appendShader(append.filePath, prepend: false)
                LibretroCore.sharedInstance().setShader(changingPath)
            }
        }
    }
    
    func updateParameters(identifier: String, value: Float) {
        LibretroCore.sharedInstance().updateParameter(with: identifier, value: value, changingPath: changingPath)
    }

    func getChangingParameters(with originShader: Shader) -> [(identifier: String, value: Float)] {
        var result = [(identifier: String, value: Float)]()
        for parameter in parameters {
            if let originParameter = originShader.parameters.first(where: { $0.identifier == parameter.identifier }) {
                if parameter.current != originParameter.current {
                    result.append((parameter.identifier, parameter.current))
                }
            } else {
                result.append((parameter.identifier, parameter.current))
            }
        }
        return result
    }
    
    func optimizeConfig() {
        func readConfig(content: String) -> [(key: String, value: String)] {
            let pattern = #"\s*([A-Za-z0-9_]+)\s*=\s*"(.*?)"\s*"#
            let regex = try! NSRegularExpression(pattern: pattern)
            
            let nsRange = NSRange(content.startIndex..., in: content)
            let matches = regex.matches(in: content, range: nsRange)
            
            return matches.compactMap { match in
                guard
                    let keyRange = Range(match.range(at: 1), in: content),
                    let valueRange = Range(match.range(at: 2), in: content)
                else {
                    return nil
                }
                
                return (
                    key: String(content[keyRange]),
                    value: String(content[valueRange])
                )
            }
        }
        
        func updateConfig(
            content: String,
            key: String,
            value: String
        ) -> String {
            let pattern = #"(^|\n)\s*\#(key)\s*=\s*"(.*?)""#
            
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                return content
            }
            
            let range = NSRange(content.startIndex..., in: content)
            
            return regex.stringByReplacingMatches(
                in: content,
                options: [],
                range: range,
                withTemplate: #"$1\#(key) = "\#(value)""#
            )
        }
        
        if let configString = try? String(contentsOfFile: changingPath, encoding: .utf8) {
            let configs = readConfig(content: configString)
            let pathMatch = "/Library/Libretro/shaders/"
            var needToUpdates = [String: String]()
            for config in configs {
                if let range = config.value.range(of: pathMatch) {
                    needToUpdates[config.key] = String(config.value[range.upperBound...])
                }
            }
            var newConfig = configString
            if needToUpdates.count > 0 {
                for update in needToUpdates {
                    newConfig = updateConfig(content: newConfig, key: update.key, value: update.value)
                }
            }
            
            if appendedShaders.count > 0 {
                var tempAppendedShaders = appendedShaders
                var tempShader = self
                tempShader.relativePath = tempShader.title + "." + tempShader.relativePath.pathExtension
                tempAppendedShaders.insert(tempShader, at: indexInAppendage)
                let appendString = tempAppendedShaders.reduce("", { $0 + ($0 == "" ? "" : ",") + $1.relativePath })
                
                if configs.contains(where: { $0.key == Constants.Strings.AppendedShaders }) {
                    newConfig = updateConfig(content: newConfig, key: Constants.Strings.AppendedShaders, value: appendString)
                } else {
                    newConfig = newConfig + "\n\(Constants.Strings.AppendedShaders) = \"\(appendString)\""
                }
                
                if configs.contains(where: { $0.key == Constants.Strings.ShaderForceBase }) {
                    newConfig = updateConfig(content: newConfig, key: Constants.Strings.ShaderForceBase, value: forceBase ?? relativePath)
                } else {
                    newConfig = newConfig + "\n\(Constants.Strings.ShaderForceBase) = \"\(forceBase ?? relativePath)\""
                }
                
            } else if let baseRelativePath {
                newConfig = newConfig.lines().reduce("", {
                    var newLine = $1
                    if $1.contains("#reference") {
                        newLine = "#reference \"\(baseRelativePath)\""
                    }
                    return $0 + ($0 == "" ? "" : "\n") + newLine
                })
            }
            Log.debug(
"""
\n=======================Shader已更新=======================
\(newConfig)
=========================================================
""")
            try? newConfig.write(toFile: changingPath, atomically: true, encoding: .utf8)
        }
    }
}
