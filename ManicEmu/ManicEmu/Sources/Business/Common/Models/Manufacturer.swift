//
//  Manufacturer.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/11/12.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import ManicEmuCore

enum Manufacturer: Int, CaseIterable {
    case nintendo, sony, sega, arcade, atari
    
    static var allCases: [Manufacturer] {
        if Locale.prefersUS {
            [.nintendo, .sony, .sega, .atari, .arcade]
        } else {
            [.nintendo, .sony, .sega, .arcade, .atari]
        }
    }
    
    var title: String {
        switch self {
        case .nintendo:
            "Nintendo"
        case .sony:
            "SONY"
        case .sega:
            "SEGA"
        case .arcade:
            "Arcade"
        case .atari:
            "Atari"
        }
    }
    
    var gameTypes: [GameType] {
        System.allCases.map({ $0.gameType }).filter({ $0.manufacturer == self })
    }
    
    var normalImage: UIImage {
        switch self {
        case .nintendo:
            R.image.nintendo_normal()!
        case .sony:
            R.image.sony_normal()!
        case .sega:
            R.image.sega_normal()!
        case .arcade:
            R.image.arcade_normal()!
        case .atari:
            R.image.atari_normal()!
        }
    }
    
    var highlightImage: UIImage {
        switch self {
        case .nintendo:
            R.image.nintendo_highlight()!
        case .sony:
            R.image.sony_highlight()!
        case .sega:
            R.image.sega_highlight()!
        case .arcade:
            R.image.arcade_highlight()!
        case .atari:
            R.image.atari_highlight()!
        }
    }
}
