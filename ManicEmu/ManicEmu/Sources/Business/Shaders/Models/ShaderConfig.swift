//
//  ShaderConfig.swift
//  ManicEmu
//
//  Created by Daiuno on 2026/1/22.
//  Copyright © 2026 Manic EMU. All rights reserved.
//

import SmartCodable

struct ShaderConfig: SmartCodable {
    enum SettingType {
        case setGlobal, removeGlobal, setCore(String), removeCore(String)
    }
    
    var coreConfigs: [String: String] = [:] // "NES" : "/xxx/xxx/xxx.glslp"
    var globalConfig: String?
    
    static func getConfig() -> ShaderConfig? {
        if let shaderConfigString = Settings.defalut.getExtraString(key: ExtraKey.shaderConfig.rawValue),
           let shaderConfig = ShaderConfig.deserialize(from: shaderConfigString) {
            return shaderConfig
        }
        return nil
    }
    
    static func setCoreShader(_ relativePath: String?, core: String) {
        var result: ShaderConfig? = nil
        
        if let shaderConfig = getConfig() {
            var newConfig = shaderConfig
            if let relativePath {
                //设定
                newConfig.coreConfigs[core] = relativePath
            } else {
                //移除
                newConfig.coreConfigs.removeAll(keys: [core])
            }
            result = newConfig
        } else {
            if let relativePath {
                result = ShaderConfig(coreConfigs: [core: relativePath])
            }
        }
        if let result, let json = result.toJSONString() {
            Settings.defalut.updateExtra(key: ExtraKey.shaderConfig.rawValue, value: json)
        }
    }
    
    static func setGlobalShader(_ relativePath: String?) {
        var result: ShaderConfig? = nil
        
        if let shaderConfig = getConfig() {
            var newConfig = shaderConfig
            if let relativePath {
                //设定
                newConfig.globalConfig = relativePath
            } else {
                //移除
                newConfig.globalConfig = nil
            }
            result = newConfig
        } else {
            if let relativePath {
                result = ShaderConfig(globalConfig: relativePath)
            }
        }
        if let result, let json = result.toJSONString() {
            Settings.defalut.updateExtra(key: ExtraKey.shaderConfig.rawValue, value: json)
        }
    }
    
}
