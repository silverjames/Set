//
//  SetCardGame.swift
//  Set
//
//  Created by Bernhard F. Kraft on 08.06.18.
//  Copyright © 2018 Bernhard F. Kraft. All rights reserved.
//

import Foundation

class SetCardGame: CustomStringConvertible {
    //  **************************************
    // MARK: API properties
    //  **************************************
    var setGame = [SetCard]()
    var dealtCards = [SetCard]()
    var matchedCards = [SetCard]()
    var description: String {
        get{
            var deck=""
            let idList = setGame.map({$0.id})
            let sortedIdList = idList.sorted {$1 > $0}
            deck += ("This deck has ID's \(String(describing: sortedIdList.first!)) through \(String(describing: sortedIdList.last!))\n")
//            for card in setGame{
//                deck += "\(card) \n"
//                }
            return deck
            }
        }
    var score = 0
//    enum far{}

    //  **************************************
    // MARK: private properties
    //  **************************************

    
    //  **************************************
    // MARK: API functions
    //  **************************************
    init(){
        newGame()
    }
    
    func deal(){
        dealCards(numberToDeal:GameConstants.dealSize)
    }
    
    func newGame(){
        setGame.removeAll()
        dealtCards.removeAll()
        matchedCards.removeAll()
        score = 0
        generateCards()
        setGame.shuffle()
        dealCards(numberToDeal: GameConstants.initialDealSize)
    }
    
    func match(keysToMatch:[SetCard]) -> Bool{
        var matched = [false, false, false, false]
        
        let numbers = keysToMatch.map {$0.decoration[0]}
        if numbers.allEqual() || numbers.allDifferent(){
            matched[0] = true
        }
        let shapes = keysToMatch.map {$0.decoration[1]}
        if shapes.allEqual() || shapes.allDifferent(){
            matched[1] = true
        }
        let shadings = keysToMatch.map {$0.decoration[2]}
        if shadings.allEqual() || shadings.allDifferent(){
            matched[2] = true
        }
        let colors = keysToMatch.map {$0.decoration[3]}
        if colors.allEqual() || colors.allDifferent(){
            matched[3] = true
        }

        return matched.allEqual() && matched.first == true
    }
    
    //  **************************************
    //  MARK: private functions
    //  **************************************
    private func generateCards(){
        for numbers in GameConstants.featureRange{
            for shapes in GameConstants.featureRange{
                for shadings in GameConstants.featureRange{
                    for colors in GameConstants.featureRange{
                        let card = SetCard.init()
                        card.decoration = [numbers, shapes, shadings, colors]
                        setGame.append(card)
                    }
                }
            }
        }
    }

    private func dealCards(numberToDeal:Int){
        if dealtCards.count + numberToDeal <= GameConstants.maxCardsOnTable{
            if setGame.count >= numberToDeal {
                for _ in 0...numberToDeal-1{
                    let card = setGame.remove(at: Int(setGame.count).arc4Random)
                    dealtCards.append(card)
                }
            }
        }
    }
    
}
//  **************************************
//  MARK: constants and extensions
//  **************************************

extension Int {
    var arc4Random: Int {
        return Int(arc4random_uniform(UInt32(self)))
    }
}

extension Array where Element:Hashable {
    func allEqual() -> Bool{
        return allSatisfy {$0 == last}
    }
    
    func allDifferent() -> Bool {
        var allDiffer = true
        let checkSet = Set(self)
        if checkSet.count != count{
            allDiffer = false
        }
        return allDiffer
    }
}

struct GameConstants {
    static let featureRange:CountableClosedRange = 0...2
    static let initialDealSize = 12 //mark: debug
    static let dealSize = 3
    static let maxCardsOnTable = 81
    static let mismatchPoints = -4
    static let cheatPoints = -5
    static let deselectPoints = -1
}

