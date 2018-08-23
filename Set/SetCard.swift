//
//  SetCard.swift
//  Set
//
//  Created by Bernhard F. Kraft on 08.06.18.
//  Copyright © 2018 Bernhard F. Kraft. All rights reserved.
//

import Foundation

class SetCard: Equatable, CustomStringConvertible {
    
    // **************************************
    // MARK: class functions
    // **************************************
    static func == (lhs: SetCard, rhs: SetCard) -> Bool {
        return  lhs.id == rhs.id
    }

    static var uniqueIdentifier = 0
    static func uniqueIdentifierFactory(){
        uniqueIdentifier += 1
    }

    // **************************************
    // MARK: API
    // **************************************
    var id:Int
    var isFaceUp:Bool

    var description: String{
        get {
            return "Card \(id) with number \(self.number), shape \(self.shape), shading \(self.shading) and color \(self.color)"
        }
    }

    var decoration: [Int]{
        get{
            return [number, shape, shading, color]
        }
        set (newValue){
            number = newValue[0]
            shape = newValue[1]
            shading = newValue[2]
            color = newValue[3]
        }
    }
    
    init(){
        id = SetCard.uniqueIdentifier
        isFaceUp = true
        SetCard.uniqueIdentifierFactory()
    }

    // **************************************
    // MARK: private properties
    // **************************************
    private var number = 0
    private var shape = 0
    private var shading = 0
    private var color = 0
 
}
