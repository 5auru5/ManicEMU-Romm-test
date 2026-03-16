//
//  LibretroCoreExtensions.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/8/3.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

extension LibretroCore {
    enum Cores {
        case Nestopia, Snes9x, PicoDrive, Yabause, BeetleSaturn, Mupen64PlushNext, BeetleVB, PokeMini, BeetlePSXHW, bsnes, Gambatte, VBAM, mGBA, Flycast, Gearsystem, ClownMDEmu, bsnesJG, melonDSDS, PPSSPP, MAME, FinalBurnNeo, PrBoom, Citra, Azahar, JGenesis, DeSmuME, Stella, Atari800, ProSystem, VirtualJaguar, Holani
        
        var name: String {
            switch self {
            case .Nestopia:
                "Nestopia"
            case .Snes9x:
                "Snes9x"
            case .PicoDrive:
                "PicoDrive"
            case .Yabause:
                "Yabause"
            case .BeetleSaturn:
                "Beetle Saturn"
            case .Mupen64PlushNext:
                "Mupen64Plus-Next"
            case .BeetleVB:
                "Beetle VB"
            case .PokeMini:
                "PokeMini"
            case .BeetlePSXHW:
                "Beetle PSX HW"
            case .bsnes:
                "bsnes"
            case .Gambatte:
                "Gambatte"
            case .VBAM:
                "VBA-M"
            case .mGBA:
                "mGBA"
            case .Flycast:
                "Flycast"
            case .ClownMDEmu:
                "ClownMDEmu"
            case .Gearsystem:
                "Gearsystem"
            case .bsnesJG:
                "bsnes-jg"
            case .melonDSDS:
                "melonDS DS"
            case .PPSSPP:
                "PPSSPP"
            case .MAME:
                "MAME"
            case .FinalBurnNeo:
                "FinalBurn Neo"
            case .PrBoom:
                "PrBoom"
            case .Citra:
                "Citra"
            case .Azahar:
                "Azahar"
            case .JGenesis:
                "JGenesis"
            case .DeSmuME:
                "DeSmuME"
            case .Stella:
                "Stella"
            case .Atari800:
                "Atari800"
            case .ProSystem:
                "ProSystem"
            case .VirtualJaguar:
                "Virtual Jaguar"
            case .Holani:
                "Holani"
            }
        }
    }
}
