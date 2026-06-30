//
//  RommClient.swift
//  ManicEmu
//
//  Created by Chris Habibi on 6/29/26.
//  Copyright © 2026 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation


struct RommPage<T: Decodable>: Decodable {
    let items: [T]
}

struct RommPlatform: Decodable {
    let id: Int
    let name: String
    let rom_count: Int?
}

struct RommRom: Decodable {
    let id: Int
    let name: String?
    let fs_name: String
    let fs_size_bytes: Int64?
}


final class RommClient {
    private let baseURL: URL
    private let session: URLSession
    private let authHeader: String
    
    private let PlatformApiStub = "/api/platforms"
    private let RomApiStub = "/api/roms"
    
    var PaginationLimit: Int { 250 }
    
    
    init?(scheme: String, host: String, port: Int?, user: String?, password: String?) {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.port = port
        guard let url = components.url else { return nil }
        self.baseURL = url

        let raw = "\(user ?? ""):\(password ?? "")"
        guard let token = raw.data(using: .utf8)?.base64EncodedString() else { return nil }
        self.authHeader = "Basic \(token)"
        self.session = .shared
    }

    func request(path: String, query: [URLQueryItem] = []) -> URLRequest? {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path),
                                             resolvingAgainstBaseURL: false) else { return nil }
        if !query.isEmpty { components.queryItems = query }
        guard let url = components.url else { return nil }
        var req = URLRequest(url: url)
        req.setValue(authHeader, forHTTPHeaderField: "Authorization")
        return req
    }

    private func get<T: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        guard let req = request(path: path, query: query) else {
            throw URLError(.badURL)
        }
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.userAuthenticationRequired)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    func platforms() async throws -> [RommPlatform] {
        try await get(PlatformApiStub)
    }

    func roms(platformID: Int) async throws -> [RommRom] {
        let page: RommPage<RommRom> = try await get(
            RomApiStub,
            query: [.init(name: "platform_id", value: "\(platformID)"),
                    .init(name: "limit", value: String(PaginationLimit))]
        )
        return page.items
    }
}
