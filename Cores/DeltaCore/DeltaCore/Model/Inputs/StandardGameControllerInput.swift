//
//  StandardGameControllerInput.swift
//  DeltaCore
//
//  Created by Riley Testut on 7/20/17.
//  Copyright © 2017 Riley Testut. All rights reserved.
//

import Foundation

public extension GameControllerInputType
{
    static let standard = GameControllerInputType("standard")
}

public enum StandardGameControllerInput: String, Codable
{
    case menu
    //自定义
    case flex
    case quickSave
    case quickLoad
    case fastForward
    case toggleFastForward
    case reverseScreens
    case volume
    case saveStates
    case cheatCodes
    case skins
    case filters
    case screenshot
    case haptics
    case controllers
    case orientation
    case functionLayout
    case restart
    case resolution
    case quit
    case amiibo
    case homeMenu
    case airplay
    case toggleControlls
    case blowing
    case palette
    case swapDisk
    case retroAchievements
    case airPlayScaling
    case airPlayLayout
    case toggleAnalog
    case gameplayManuals
    case triggerPro
    case fastForward2x
    case fastForward3x
    case fastForward4x

    case up
    case down
    case left
    case right
    
    case rightDpadUp
    case rightDpadDown
    case rightDpadLeft
    case rightDpadRight
    
    case leftThumbstickUp
    case leftThumbstickDown
    case leftThumbstickLeft
    case leftThumbstickRight
    
    case rightThumbstickUp
    case rightThumbstickDown
    case rightThumbstickLeft
    case rightThumbstickRight
    
    case a
    case b
    case c
    case x
    case y
    case z
    
    case start
    case select
    
    case l
    case l1
    case l2
    case l3
    
    case r
    case r1
    case r2
    case r3
}

extension StandardGameControllerInput: Input
{
    public var type: InputType {
        return .controller(.standard)
    }
    
    public var isContinuous: Bool {
        switch self
        {
        case .leftThumbstickUp, .leftThumbstickDown, .leftThumbstickLeft, .leftThumbstickRight: return true
        case .rightThumbstickUp, .rightThumbstickDown, .rightThumbstickLeft, .rightThumbstickRight: return true
        default: return false
        }
    }
}

public extension StandardGameControllerInput
{
    private static var inputMappings = [GameType: GameControllerInputMapping]()
    
    func input(for gameType: GameType) -> Input?
    {
        if let inputMapping = StandardGameControllerInput.inputMappings[gameType]
        {
            let input = inputMapping.input(forControllerInput: self)
            return input
        }
        
        guard
            let deltaCore = ManicEmu.core(for: gameType),
            let fileURL = deltaCore.resourceBundle.url(forResource: deltaCore.name, withExtension: "keymapping")
        else {
            
            fatalError("Cannot find keymapping for game type \(gameType)")
        }
        
        do
        {
            let inputMapping = try GameControllerInputMapping(fileURL: fileURL)
            StandardGameControllerInput.inputMappings[gameType] = inputMapping
            
            let input = inputMapping.input(forControllerInput: self)
            return input
        }
        catch
        {
            fatalError(String(describing: error))
        }
    }
}
