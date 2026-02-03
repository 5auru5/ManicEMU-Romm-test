//
//  LibretroKeyboardCode.m
//  Libretro
//
//  Created by Daiuno on 2026/1/24.
//  Copyright © 2026 Manic EMU. All rights reserved.
//

#import "LibretroKeyboardCode.h"
#include "../../libretro-common/include/libretro.h"

@interface LibretroKeyboardCode()

@property(nonatomic, copy) NSString *label;
@property(assign) unsigned code;

@end

@implementation LibretroKeyboardCode

+ (instancetype)createCodeWithLabel:(NSString *)label code:(unsigned)code {
    LibretroKeyboardCode *keyboardCode = [LibretroKeyboardCode new];
    keyboardCode.label = label;
    keyboardCode.code = code;
    return keyboardCode;
}

+ (instancetype)createCodeWithLabel:(NSString *_Nonnull)label {
    if ([label isEqualToString:@"1"]) { return [self createCodeWithLabel:label code:RETROK_1]; }
    else if ([label isEqualToString:@"2"]) { return [self createCodeWithLabel:label code:RETROK_2]; }
    else if ([label isEqualToString:@"3"]) { return [self createCodeWithLabel:label code:RETROK_3]; }
    else if ([label isEqualToString:@"4"]) { return [self createCodeWithLabel:label code:RETROK_4]; }
    else if ([label isEqualToString:@"5"]) { return [self createCodeWithLabel:label code:RETROK_5]; }
    else if ([label isEqualToString:@"Q"]) { return [self createCodeWithLabel:label code:RETROK_q]; }
    else if ([label isEqualToString:@"W"]) { return [self createCodeWithLabel:label code:RETROK_w]; }
    else if ([label isEqualToString:@"E"]) { return [self createCodeWithLabel:label code:RETROK_e]; }
    else if ([label isEqualToString:@"R"]) { return [self createCodeWithLabel:label code:RETROK_r]; }
    else if ([label isEqualToString:@"T"]) { return [self createCodeWithLabel:label code:RETROK_t]; }
    else if ([label isEqualToString:@"A"]) { return [self createCodeWithLabel:label code:RETROK_a]; }
    else if ([label isEqualToString:@"S"]) { return [self createCodeWithLabel:label code:RETROK_s]; }
    else if ([label isEqualToString:@"D"]) { return [self createCodeWithLabel:label code:RETROK_d]; }
    else if ([label isEqualToString:@"F"]) { return [self createCodeWithLabel:label code:RETROK_f]; }
    else if ([label isEqualToString:@"G"]) { return [self createCodeWithLabel:label code:RETROK_g]; }
    else if ([label isEqualToString:@"Z"]) { return [self createCodeWithLabel:label code:RETROK_z]; }
    else if ([label isEqualToString:@"X"]) { return [self createCodeWithLabel:label code:RETROK_x]; }
    else if ([label isEqualToString:@"C"]) { return [self createCodeWithLabel:label code:RETROK_c]; }
    else if ([label isEqualToString:@"V"]) { return [self createCodeWithLabel:label code:RETROK_v]; }
    else if ([label isEqualToString:@"B"]) { return [self createCodeWithLabel:label code:RETROK_b]; }
    else if ([label isEqualToString:@"FN"])  { return [self createCodeWithLabel:label code:9000]; }
    else if ([label isEqualToString:@"LSHIFT"]) { return [self createCodeWithLabel:label code:RETROK_LSHIFT]; }
    else if ([label isEqualToString:@"LCTRL"]) { return [self createCodeWithLabel:label code:RETROK_LCTRL]; }
    else if ([label isEqualToString:@"LALT"]) { return [self createCodeWithLabel:label code:RETROK_LALT]; }
    else if ([label isEqualToString:@"F1"]) { return [self createCodeWithLabel:label code:RETROK_F1]; }
    else if ([label isEqualToString:@"F2"]) { return [self createCodeWithLabel:label code:RETROK_F2]; }
    else if ([label isEqualToString:@"F3"]) { return [self createCodeWithLabel:label code:RETROK_F3]; }
    else if ([label isEqualToString:@"F4"]) { return [self createCodeWithLabel:label code:RETROK_F4]; }
    else if ([label isEqualToString:@"F5"]) { return [self createCodeWithLabel:label code:RETROK_F5]; }
    else if ([label isEqualToString:@"-"]) { return [self createCodeWithLabel:label code:RETROK_MINUS]; }
    else if ([label isEqualToString:@"="]) { return [self createCodeWithLabel:label code:RETROK_EQUALS]; }
    else if ([label isEqualToString:@"/"]) { return [self createCodeWithLabel:label code:RETROK_SLASH]; }
    else if ([label isEqualToString:@"["]) { return [self createCodeWithLabel:label code:RETROK_LEFTBRACKET]; }
    else if ([label isEqualToString:@"]"]) { return [self createCodeWithLabel:label code:RETROK_RIGHTBRACKET]; }
    else if ([label isEqualToString:@";"]) { return [self createCodeWithLabel:label code:RETROK_SEMICOLON]; }
    else if ([label isEqualToString:@"~"]) { return [self createCodeWithLabel:label code:RETROK_TILDE]; }
    else if ([label isEqualToString:@":"]) { return [self createCodeWithLabel:label code:RETROK_COLON]; }
    else if ([label isEqualToString:@"?"]) { return [self createCodeWithLabel:label code:RETROK_QUESTION]; }
    else if ([label isEqualToString:@"!"]) { return [self createCodeWithLabel:label code:RETROK_EXCLAIM]; }
    else if ([label isEqualToString:@"RSHIFT"]) { return [self createCodeWithLabel:label code:RETROK_RSHIFT]; }
    else if ([label isEqualToString:@"RCTRL"]) { return [self createCodeWithLabel:label code:RETROK_RCTRL]; }
    else if ([label isEqualToString:@"RALT"]) { return [self createCodeWithLabel:label code:RETROK_RALT]; }
    else if ([label isEqualToString:@"6"]) { return [self createCodeWithLabel:label code:RETROK_6]; }
    else if ([label isEqualToString:@"7"]) { return [self createCodeWithLabel:label code:RETROK_7]; }
    else if ([label isEqualToString:@"8"]) { return [self createCodeWithLabel:label code:RETROK_8]; }
    else if ([label isEqualToString:@"9"]) { return [self createCodeWithLabel:label code:RETROK_9]; }
    else if ([label isEqualToString:@"0"]) { return [self createCodeWithLabel:label code:RETROK_0]; }
    else if ([label isEqualToString:@"Y"]) { return [self createCodeWithLabel:label code:RETROK_y]; }
    else if ([label isEqualToString:@"U"]) { return [self createCodeWithLabel:label code:RETROK_u]; }
    else if ([label isEqualToString:@"I"]) { return [self createCodeWithLabel:label code:RETROK_i]; }
    else if ([label isEqualToString:@"O"]) { return [self createCodeWithLabel:label code:RETROK_o]; }
    else if ([label isEqualToString:@"P"]) { return [self createCodeWithLabel:label code:RETROK_p]; }
    else if ([label isEqualToString:@"H"]) { return [self createCodeWithLabel:label code:RETROK_h]; }
    else if ([label isEqualToString:@"J"]) { return [self createCodeWithLabel:label code:RETROK_j]; }
    else if ([label isEqualToString:@"K"]) { return [self createCodeWithLabel:label code:RETROK_k]; }
    else if ([label isEqualToString:@"L"]) { return [self createCodeWithLabel:label code:RETROK_l]; }
    else if ([label isEqualToString:@"'"]) { return [self createCodeWithLabel:label code:RETROK_QUOTE]; }
    else if ([label isEqualToString:@"N"]) { return [self createCodeWithLabel:label code:RETROK_n]; }
    else if ([label isEqualToString:@"M"]) { return [self createCodeWithLabel:label code:RETROK_m]; }
    else if ([label isEqualToString:@","]) { return [self createCodeWithLabel:label code:RETROK_COMMA]; }
    else if ([label isEqualToString:@"."]) { return [self createCodeWithLabel:label code:RETROK_PERIOD]; }
    else if ([label isEqualToString:@"BKSPC"]) { return [self createCodeWithLabel:label code:RETROK_BACKSPACE]; }
    else if ([label isEqualToString:@"TAB"]) { return [self createCodeWithLabel:label code:RETROK_TAB]; }
    else if ([label isEqualToString:@"RETURN"]) { return [self createCodeWithLabel:label code:RETROK_RETURN]; }
    else if ([label isEqualToString:@"F6"]) { return [self createCodeWithLabel:label code:RETROK_F6]; }
    else if ([label isEqualToString:@"F7"]) { return [self createCodeWithLabel:label code:RETROK_F7]; }
    else if ([label isEqualToString:@"F8"]) { return [self createCodeWithLabel:label code:RETROK_F8]; }
    else if ([label isEqualToString:@"F9"]) { return [self createCodeWithLabel:label code:RETROK_F9]; }
    else if ([label isEqualToString:@"F10"]) { return [self createCodeWithLabel:label code:RETROK_F10]; }
    else if ([label isEqualToString:@"PAGEUP"]) { return [self createCodeWithLabel:label code:RETROK_PAGEUP]; }
    else if ([label isEqualToString:@"HOME"]) { return [self createCodeWithLabel:label code:RETROK_HOME]; }
    else if ([label isEqualToString:@"INS"]) { return [self createCodeWithLabel:label code:RETROK_INSERT]; }
    else if ([label isEqualToString:@"END"]) { return [self createCodeWithLabel:label code:RETROK_END]; }
    else if ([label isEqualToString:@"PAGEDWN"]) { return [self createCodeWithLabel:label code:RETROK_PAGEDOWN]; }
    else if ([label isEqualToString:@"F11"]) { return [self createCodeWithLabel:label code:RETROK_F11]; }
    else if ([label isEqualToString:@"⬆️"]) { return [self createCodeWithLabel:label code:RETROK_UP]; }
    else if ([label isEqualToString:@"F12"]) { return [self createCodeWithLabel:label code:RETROK_F12]; }
    else if ([label isEqualToString:@"⬅️"]) { return [self createCodeWithLabel:label code:RETROK_LEFT]; }
    else if ([label isEqualToString:@"⬇️"]) { return [self createCodeWithLabel:label code:RETROK_DOWN]; }
    else if ([label isEqualToString:@"➡️"]) { return [self createCodeWithLabel:label code:RETROK_RIGHT]; }
    else if ([label isEqualToString:@"DEL"]) { return [self createCodeWithLabel:label code:RETROK_DELETE]; }
    else if ([label isEqualToString:@"SPACE"]) { return [self createCodeWithLabel:label code:RETROK_SPACE]; }
    else if ([label isEqualToString:@"ESC"]) { return [self createCodeWithLabel:label code:RETROK_ESCAPE]; }
    else if ([label isEqualToString:@"RETURN"]) { return [self createCodeWithLabel:label code:RETROK_RETURN]; }
    return nil;
}

@end
