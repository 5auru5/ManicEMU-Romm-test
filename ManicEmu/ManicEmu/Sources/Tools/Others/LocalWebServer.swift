//
//  LocalWebServer.swift
//  ManicEmu
//
//  Created by Daiuno on 2026/1/21.
//  Copyright © 2026 Manic EMU. All rights reserved.
//
import GCDWebServer

class LocalWebServer {
    enum ServerType {
        case JGenesis, RomPatcher
    }
    
    private var server: GCDWebServer?
    private let port: UInt = 8080
    private var files: [String: String] = [:] // fileId -> filePath
    
    func start(serverType: ServerType) throws {
        server = GCDWebServer()
        
        let resourcePath: String
        switch serverType {
        case .JGenesis:
            resourcePath = Constants.Path.JGenesis
            
            // 首先添加通用的目录处理器（优先级最低）
            server?.addGETHandler(forBasePath: "/",
                                  directoryPath: resourcePath,
                                  indexFilename: nil,
                                  cacheAge: 0,
                                  allowRangeRequests: true)
            
            // 然后添加特定文件类型的处理器（优先级更高）
            // HTML 文件处理器
            server?.addHandler(forMethod: "GET", pathRegex: "/.*\\.html", request: GCDWebServerRequest.self) { request in
                let response = GCDWebServerDataResponse.init(htmlTemplate: resourcePath.appendingPathComponent(request.path), variables: [:])
                response?.setValue("same-origin", forAdditionalHeader: "Cross-Origin-Opener-Policy")
                response?.setValue("require-corp", forAdditionalHeader: "Cross-Origin-Embedder-Policy")
                return response
            }
            
            // WASM 文件处理器，设置正确的 MIME type（优先级最高）
            server?.addHandler(forMethod: "GET", pathRegex: "/.*\\.wasm", request: GCDWebServerRequest.self) { request in
                let wasmPath = resourcePath.appendingPathComponent(request.path)
                guard FileManager.default.fileExists(atPath: wasmPath) else {
                    return GCDWebServerResponse(statusCode: 404)
                }
                let response = GCDWebServerFileResponse(file: wasmPath)
                // 直接设置 contentType 属性，而不是通过 header
                response?.contentType = "application/wasm"
                response?.setValue("same-origin", forAdditionalHeader: "Cross-Origin-Opener-Policy")
                response?.setValue("require-corp", forAdditionalHeader: "Cross-Origin-Embedder-Policy")
                return response
            }
            
            // ROM 文件流式处理器
            server?.addHandler(forMethod: "GET", pathRegex: "/file/.*", request: GCDWebServerRequest.self) { [weak self] request in
                guard let self else { return nil }
                let fileId = request.path.lastPathComponent
                guard let filePath = self.files[fileId] else {
                    return GCDWebServerResponse(statusCode: 404)
                }
                
                guard FileManager.default.fileExists(atPath: filePath) else {
                    return GCDWebServerResponse(statusCode: 404)
                }
                
                let response = GCDWebServerFileResponse(file: filePath)
                response?.cacheControlMaxAge = 0
                response?.setValue("no-cache, no-store, must-revalidate", forAdditionalHeader: "Cache-Control")
                response?.setValue("no-cache", forAdditionalHeader: "Pragma")
                response?.setValue("0", forAdditionalHeader: "Expires")
                response?.setValue("same-origin", forAdditionalHeader: "Cross-Origin-Opener-Policy")
                response?.setValue("require-corp", forAdditionalHeader: "Cross-Origin-Embedder-Policy")
                response?.contentType = "application/octet-stream"
                return response
            }
            
        case .RomPatcher:
            resourcePath = Constants.Path.RomPatcher
            
            // 首先添加通用的目录处理器（优先级最低）
            server?.addGETHandler(forBasePath: "/",
                                  directoryPath: resourcePath,
                                  indexFilename: nil,
                                  cacheAge: 0,
                                  allowRangeRequests: true)
        }

        try server?.start(options: [
            GCDWebServerOption_Port: port,
            GCDWebServerOption_BindToLocalhost: true
        ])
        
        Log.debug("✅ 服务器启动: http://localhost:\(port)")
    }
    
    func stop() {
        DispatchQueue.global(qos: .utility).async {
            self.server?.stop()
        }
    }
    
    func getURL() -> URL? {
        return URL(string: "http://localhost:\(port)/index.html")
    }
    
    /// 注册 ROM 文件，返回唯一文件 ID
    func registerFile(filePath: String) -> String {
        let fileId = "\(filePath.lastPathComponent.sha256())"
        files[fileId] = filePath
        return fileId
    }
}
