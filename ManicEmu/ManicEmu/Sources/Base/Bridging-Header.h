//
//  Bridging-Header.h
//  ManicEmu
//
//  Created by Aoshuang Lee on 2024/12/25.
//  Copyright © 2024 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

@import SwifterSwift;
@import Closures;
@import SnapKit;
@import FluentDarkModeKit;
@import SFSafeSymbols;
#import <UniversalDetector/UniversalDetector.h>
#import <Libretro/LibretroCore.h>
#if CRASH_COLLECT
#import <UMCommon/UMCommon.h>
#import <UMAPM/UMAPMConfig.h>
#import <UMAPM/UMCrashConfigure.h>
#endif
#import "ShadowLabel.h"
