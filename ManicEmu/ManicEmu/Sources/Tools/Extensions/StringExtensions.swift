//
//  StringExtensions.swift
//  ManicEmu
//
//  Created by Aoshuang Lee on 2024/12/25.
//  Copyright © 2024 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  StringExtensions.swift
//  ZNear
//
//  Created by Max on 2021/2/22.
//

import Foundation
import CommonCrypto

//模式匹配可用

func hasPrefix(prefix: String) -> ((String) -> Bool) { { $0.hasPrefix(prefix) } }
func contains(string: String) -> ((String) -> Bool) { { $0.contains(string) } }

extension String {
    static func ~= (pattern: (String) -> Bool, value: String) -> Bool {
        pattern(value)
    }
}

//加密混淆使用的
extension String {
    var a: String { return self + "a" }
    var b: String { return self + "b" }
    var c: String { return self + "c" }
    var d: String { return self + "d" }
    var e: String { return self + "e" }
    var f: String { return self + "f" }
    var g: String { return self + "g" }
    var h: String { return self + "h" }
    var i: String { return self + "i" }
    var j: String { return self + "j" }
    var k: String { return self + "k" }
    var l: String { return self + "l" }
    var m: String { return self + "m" }
    var n: String { return self + "n" }
    var o: String { return self + "o" }
    var p: String { return self + "p" }
    var q: String { return self + "q" }
    var r: String { return self + "r" }
    var s: String { return self + "s" }
    var t: String { return self + "t" }
    var u: String { return self + "u" }
    var v: String { return self + "v" }
    var w: String { return self + "w" }
    var x: String { return self + "x" }
    var y: String { return self + "y" }
    var z: String { return self + "z" }
    
    var A: String { return self + "A" }
    var B: String { return self + "B" }
    var C: String { return self + "C" }
    var D: String { return self + "D" }
    var E: String { return self + "E" }
    var F: String { return self + "F" }
    var G: String { return self + "G" }
    var H: String { return self + "H" }
    var I: String { return self + "I" }
    var J: String { return self + "J" }
    var K: String { return self + "K" }
    var L: String { return self + "L" }
    var M: String { return self + "M" }
    var N: String { return self + "N" }
    var O: String { return self + "O" }
    var P: String { return self + "P" }
    var Q: String { return self + "Q" }
    var R: String { return self + "R" }
    var S: String { return self + "S" }
    var T: String { return self + "T" }
    var U: String { return self + "U" }
    var V: String { return self + "V" }
    var W: String { return self + "W" }
    var X: String { return self + "X" }
    var Y: String { return self + "Y" }
    var Z: String { return self + "Z" }
    
    var _1 : String { get { return self + "1" } }
    var _2 : String { get { return self + "2" } }
    var _3 : String { get { return self + "3" } }
    var _4 : String { get { return self + "4" } }
    var _5 : String { get { return self + "5" } }
    var _6 : String { get { return self + "6" } }
    var _7 : String { get { return self + "7" } }
    var _8 : String { get { return self + "8" } }
    var _9 : String { get { return self + "9" } }
    var _0 : String { get { return self + "0" } }
}

extension String {
    var validateAndExtractURLComponents: (scheme: String?, host: String, port: Int?, path: String?)? {
        let trimmedInput = self.trimmingCharacters(in: .whitespacesAndNewlines)
        // 修正正则分组结构，使用非捕获组保持索引
        let pattern = #"^(([a-zA-Z][a-zA-Z0-9+.-]*)://)?((?:$$([0-9a-fA-F:]+)$$|([^/?#:]+)))(?::(\d+))?(?:/([^?#]*))?(?:[?#].*)?$"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        
        let range = NSRange(trimmedInput.startIndex..., in: trimmedInput)
        guard let match = regex.firstMatch(in: trimmedInput, options: [], range: range) else {
            return nil
        }
        
        // 提取 scheme (分组2)
        let schemeRange = Range(match.range(at: 2), in: trimmedInput)
        let scheme = schemeRange.flatMap { String(trimmedInput[$0]) }
        
        // 提取 host (分组3包含方括号，实际host在分组4或5)
        var host: String?
        var isIPv6 = false
        if let ipv6Range = Range(match.range(at: 4), in: trimmedInput), !ipv6Range.isEmpty {
            host = String(trimmedInput[ipv6Range]) // IPv6实际内容在分组4
            isIPv6 = true
        } else if let normalHostRange = Range(match.range(at: 5), in: trimmedInput), !normalHostRange.isEmpty {
            host = String(trimmedInput[normalHostRange]) // 普通host在分组5
        }
        
        guard let validHost = host, !validHost.isEmpty else {
            return nil
        }
        
        // 严格host验证（保持原逻辑）
        let adjustedHost = isIPv6 ? validHost : validHost
        let isDomainValid = NSPredicate(format: "SELF MATCHES %@", #"^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$"#).evaluate(with: adjustedHost)
        let isIPv4Valid = NSPredicate(format: "SELF MATCHES %@", #"^(?:(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d\d?)$"#).evaluate(with: adjustedHost)
        let isIPv6Valid = isIPv6 && NSPredicate(format: "SELF MATCHES %@", #"^[0-9a-fA-F:]+$"#).evaluate(with: adjustedHost)
        
        guard isIPv6Valid || isIPv4Valid || isDomainValid else {
            return nil
        }
        
        // 提取 port (分组6)
        let portString = Range(match.range(at: 6), in: trimmedInput).flatMap { String(trimmedInput[$0]) }
        let port = portString.flatMap { Int($0) }.flatMap { (1...65535).contains($0) ? $0 : nil }
        
        // 提取 path (分组7)
        let path = Range(match.range(at: 7), in: trimmedInput).flatMap {
            let str = String(trimmedInput[$0])
            return str.isEmpty ? nil : str
        }
        
        return (scheme, adjustedHost, port, path)
    }
    
    func calculateWidth(font: UIFont, height: CGFloat) -> CGFloat {
        let constraintRect = CGSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: height
        )
        let boundingBox = self.boundingRect(
            with: constraintRect,
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil
        )
        return ceil(boundingBox.width)
    }
    
    static func errorMessage(from errors: [Error]) -> String {
        return errors.reduce("") { partialResult, error in
            if partialResult == "" {
                return error.localizedDescription
            } else {
                return partialResult + "\n" + error.localizedDescription
            }
        }
    }
    
    static func successMessage(from names: [String]) -> String {
        return names.reduce("") { partialResult, name in
            if partialResult == "" {
                return name
            } else {
                return partialResult + "\n" + name
            }
        }
    }
    
    func isEnglishLanguage() -> Bool {
        // 定义允许的字符集：英文、数字、标点、空格、emoji
        let allowedCharacterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
            .union(.punctuationCharacters)
            .union(.whitespaces)
            .union(.symbols)          // 包括部分 emoji
            .union(.nonBaseCharacters)
            .union(.emojis)
        
        // 检查是否存在不在允许集合内的字符
        return !self.unicodeScalars.contains { !allowedCharacterSet.contains($0) }
    }
    
    /// 高效 SHA256（固定 64 位 hex）
    @inline(__always)
    func sha256() -> String {
        let data = Data(self.utf8)
        
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &hash)
        }
        
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    func trimedExceptNumberAndLetters() -> String {
        return self.filter { ($0 >= "a" && $0 <= "z") || ($0 >= "A" && $0 <= "Z") || ($0 >= "0" && $0 <= "9") }
    }
    
    func writeWithCompletePath(to path: String) throws {
        try writeWithCompletePath(to: URL(fileURLWithPath: path))
    }
    
    func writeWithCompletePath(to url: URL) throws {
        let parentUrl = url.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: parentUrl.path) {
            try FileManager.default.createDirectory(at: parentUrl, withIntermediateDirectories: true)
        }
        try write(to: url, atomically: true, encoding: .utf8)
    }
    
    func parseIPv4() -> (ips: [Int], port: Int)? {
        let parts = self.split(separator: ":")
        guard parts.count == 2,
              let port = Int(parts[1]) else {
            return nil
        }
        
        let ipDigits: [Int] = parts[0]
            .split(separator: ".")
            .flatMap { segment -> [Int] in
                let padded = String(format: "%03d", Int(segment)!)
                return padded.map { Int(String($0))! }
            }
        
        return (ipDigits, port)
    }
}

// 扩展用于识别 emoji 的字符集
extension CharacterSet {
    static let emojis: CharacterSet = {
        var set = CharacterSet()

        // 常见 emoji 范围
        set.insert(charactersIn: "\u{1F300}"..."\u{1F5FF}")
        set.insert(charactersIn: "\u{1F600}"..."\u{1F64F}")
        set.insert(charactersIn: "\u{1F680}"..."\u{1F6FF}")
        set.insert(charactersIn: "\u{1F900}"..."\u{1F9FF}")
        set.insert(charactersIn: "\u{1FA70}"..."\u{1FAFF}")
        set.insert(charactersIn: "\u{2600}"..."\u{26FF}")
        set.insert(charactersIn: "\u{2700}"..."\u{27BF}")
        return set
    }()
}

extension String {
    
    @discardableResult
    /// 替换正则表达式匹配到的字符串为指定字符串
    /// - Parameters:
    ///   - pattern: 正则表达式
    ///   - text: 替换成的字符串
    /// - Returns: 替换后的字符串
    func replace(pattern: String, with text: String) -> String {
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let result = regex?.stringByReplacingMatches(in: self, range: NSMakeRange(0, self.count), withTemplate: text)
        return result ?? self
    }
    
    func match(pattern: String) -> Bool {
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        guard let regex = regex else { return false }
        let resultArray = regex.matches(in: self, range: NSRange(location: 0, length: self.count))
        guard resultArray.count == 1, let result = resultArray.first else {
            return false
        }
        return self.count == result.range.length
    }
}

extension String {
    var queryDict: [String: String?]? {
        guard let urlComponents = URLComponents(string: self) else {
            return nil
        }
        var querys: [String: String] = [:]
        if let queryItems = urlComponents.queryItems {
            for (_, item) in queryItems.enumerated() {
                querys[item.name] = item.value
            }
        }
        return querys.keys.count > 0 ? querys : nil
    }
    
    var libretroPath: String {
        // Use .backwards for "/Library/" to match the app's Library directory,
        // not the user's ~/Library on macOS where the container path contains
        // "/Library/" twice (e.g., /Users/X/Library/Containers/.../Data/Library/...)
        if let range = self.range(of: "/Documents/") ?? self.range(of: "/Library/", options: .backwards) {
            return "~" + String(self[range.lowerBound...])
        }
        return self
    }
}
