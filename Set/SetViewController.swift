//
//  SetViewController.swift
//  Set
//
//  Created by Bernhard F. Kraft on 08.06.18.
//  Copyright © 2018 Bernhard F. Kraft. All rights reserved.
//

import UIKit
import AVFoundation

class SetViewController: UIViewController, cardViewDataSource {

    // **************************************
    // MARK: private properties
    // **************************************
    private lazy var game:SetCardGame = SetCardGame()
    private var cardFaces = [NSAttributedString]()
    private var selectedCards = [Int:CardView]()
    private var matchPoints:Int {
        get {
            return (GameConstants.maxCardsOnTable)/game.dealtCards.count + 1
        }
    }
    private var validSymbols:[String] {
        return ["▲", "■", "●"]
    }
    private lazy var cheatSet = [SetCard]()
    private let tapSound = SystemSoundID(1105)
    private let newGameSound = SystemSoundID(1108)
    private let matchSound = SystemSoundID(1024)

    // **************************************
    // MARK: outlets and functions
    // **************************************

    @IBOutlet weak var dealButton: UIButton!
    @IBOutlet weak var cardView: CardSetView!{
        didSet {
            cardView.delegate = self
        }
    }
    @IBOutlet weak var test: UILabel!
    @IBOutlet weak var score: UILabel!
    @IBOutlet weak var cheatButton: UIButton!
 
    @IBAction func newGame(_ sender: UIButton) {
        AudioServicesPlaySystemSound(newGameSound)
        newGame()
    }
    
    @IBAction func deal(_ sender: UIButton) {
        AudioServicesPlaySystemSound(tapSound)
        deal()
    }

    @IBAction func cheatNow(_ sender: Any) {
        selectedCards.removeAll(keepingCapacity: true)

        for card in cheatSet {
            addselectedCardToMatchingSet(cardView.gameCards[game.dealtCards.firstIndex(of: card)!])
        }
        _ = Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: {_ in self.processMatch(matchSet: self.cheatSet)})
        
        let penalty = -2 * matchPoints
        game.score += penalty
        updateScore()
    }
    
    @objc func touchCard(_ sender: UITapGestureRecognizer) {
        print ("card touched")
        let card = sender.view! as! CardView
        AudioServicesPlaySystemSound(tapSound)
        if selectedCards.contains(where: {$0.value == sender }){
            selectedCards.remove(at: selectedCards.firstIndex(where: {$0.value == sender })!)
            card.selected = false
            game.score += Constants.deselectPoints
            updateScore()
            
        } else {
            switch selectedCards.count{
                
            case 0,1:
                addselectedCardToMatchingSet(card)
                
            case 2:
                addselectedCardToMatchingSet(card)
                var matchSet = [SetCard]()
                for cardID in selectedCards.keys{
                    if let card = game.dealtCards.first(where: {$0.id == cardID}){
                        matchSet.append(card)
                    }
                }
                
                if game.match(keysToMatch: matchSet){
                    print("cards matched!")
                    AudioServicesPlaySystemSound(matchSound)
                    _ = Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: {_ in self.processMatch(matchSet: matchSet)})
                } else {
                    print("cards did not match!")
                    _ = Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: {_ in self.processMismatch(matchSet: matchSet)})
                }
                
            default:
                break
            }
        }
    }
    
    // **************************************
    // MARK: protocol functions
    // **************************************
    func getGridDimensions() -> (cellCount: Int, aspectRatio: CGFloat) {
        return (game.dealtCards.count, Constants.defaultAspectRatio)
    }
    func getDealtCards() -> [SetCard] {
        return game.dealtCards
    }
    
    // **************************************
    // MARK: view lifecycle functions
    // **************************************
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        for subView in view.subviews{
            if subView is UIButton {
                let button = subView as! UIButton
                button.layer.backgroundColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
                button.layer.cornerRadius = 5
                button.layer.borderWidth = 0.2
                button.mask?.clipsToBounds = true
                button.layer.borderColor = #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1)
                button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16.0)
                
            }
            if subView is UILabel{
                subView.layer.cornerRadius = 5
                subView.layer.borderWidth = 0.2
                subView.mask?.clipsToBounds = true
                subView.layer.borderColor = #colorLiteral(red: 0.1294117719, green: 0.2156862766, blue: 0.06666667014, alpha: 0)
                subView.backgroundColor = #colorLiteral(red: 0.1294117719, green: 0.2156862766, blue: 0.06666667014, alpha: 0)
            }
        }
        printMessageForBernie()
        newGame()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    // **************************************
    // MARK: private functions
    // **************************************
    private func newGame(){
        game.newGame()
        dealButton.isEnabled = true
        cheatButton.isEnabled = checkForCheat()
        updateScore()
        print ("\(game.description)")
        cardView.setNeedsLayout()
        cardView.setNeedsDisplay()
    }

    private func deal(){
        game.deal()
        if game.dealtCards.count == GameConstants.maxCardsOnTable{
            dealButton.isEnabled = false
        } else{
            dealButton.isEnabled = true
        }
        cheatButton.isEnabled = checkForCheat()
        cardView.setNeedsLayout()
        cardView.setNeedsDisplay()
    }
    
    private func checkForCheat () -> Bool{
        var cheatFound = false
        cheatSet.removeAll(keepingCapacity: true)
        var checkSet:[SetCard]
        for i in 0..<game.dealtCards.count-2{
            for j in i+1..<game.dealtCards.count-1{
                for k in j+1..<game.dealtCards.count{
                    checkSet = [game.dealtCards[i], game.dealtCards[j], game.dealtCards[k]]
                    if !cheatFound && game.match(keysToMatch: checkSet)  {
                        cheatButton.isEnabled = true
                        cheatFound = true
                        cheatSet = checkSet
//                        print ("\(cheatSet)")
                    }
                }
            }
        }
        return cheatFound
    }
    private func addselectedCardToMatchingSet(_ sender:CardView){
//        print ("\(sender)")
        let idx = game.dealtCards[cardView.gameCards.firstIndex(of: sender)!].id
        print("added card \(String(describing: idx))")
        selectedCards[idx] = sender
        sender.selected = true
    }
    
    private func processMatch(matchSet:[SetCard]){
        for matches in selectedCards{
            let card = game.dealtCards.filter {$0.id == matches.key}
            game.dealtCards.remove(at: game.dealtCards.lastIndex(of: card.first!)!)
            game.matchedCards.append(card.first!)
            matches.value.selected = false
        }
        game.score += matchPoints
        updateScore()
        selectedCards.removeAll()
        deal()
    }
    
    private func processMismatch(matchSet:[SetCard]){
        for matches in selectedCards{
            matches.value.selected = false
        }
        game.score += Constants.mismatchPoints
        updateScore()
        selectedCards.removeAll()
        
        }
    
    private func updateScore(){
        score.text = "Score: \(game.score)"
    }
    
    private func printMessageForBernie(){
        //        MARK: test code for nsattributedstring
        var attributes = [NSAttributedString.Key: Any?]()
        attributes = [.font:UIFont.preferredFont(forTextStyle: .body).withSize(10), .foregroundColor: UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.15), .strokeWidth: -3.0]
        test.attributedText = (NSAttributedString(string:"Bernie was here...", attributes:attributes as [NSAttributedString.Key : Any]))
    }
}
//MARK: need to re-dupe the constants
private struct Constants {
    static let mismatchPoints = -2
    static let matchPoints = 5
    static let deselectPoints = -1
    static let defaultAspectRatio:CGFloat = 5/8
    static let timerInterval = 1.2
}
