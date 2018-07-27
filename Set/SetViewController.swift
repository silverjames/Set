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
    private var selectedCards = [Int:UIButton]()
    private var matchPoints:Int {
        get {
            return (GameConstants.maxCardsOnTable*2)/game.dealtCards.count + 1
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
    @IBOutlet weak var cardView: CardView!{
        didSet {
            print("SVC: setting outlet")
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
            addselectedCardToMatchingSet(cardView.gameButtons[game.dealtCards.firstIndex(of: card)!])
        }
        _ = Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: {_ in self.processMatch(matchSet: self.cheatSet)})
        
        let penalty = -2 * matchPoints
        game.score += penalty
        updateScore()
    }
    
    @objc func touchCard(_ sender: UIButton) {
//        print ("card touched")
        AudioServicesPlaySystemSound(tapSound)
        if selectedCards.contains(where: {$0.value == sender }){
            selectedCards.remove(at: selectedCards.firstIndex(where: {$0.value == sender })!)
            cardView.buttonFormatNotSelected(button: sender)
            game.score += Constants.deselectPoints
            updateScore()
            
        } else {
            switch selectedCards.count{
                
            case 0,1:
                addselectedCardToMatchingSet(sender)
                
            case 2:
                addselectedCardToMatchingSet(sender)
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
        return (game.dealtCards.count, CGFloat(Constants.defaultAspectRatio))
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
        render(howMany: game.dealtCards.count)
        cardView.setNeedsLayout()
    }

    private func deal(){
        game.deal()
        if game.dealtCards.count == GameConstants.maxCardsOnTable{
            dealButton.isEnabled = false
        } else{
            dealButton.isEnabled = true
        }
        render(howMany: game.dealtCards.count)
        cheatButton.isEnabled = checkForCheat()
        cardView.setNeedsLayout()
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
    private func addselectedCardToMatchingSet(_ sender:UIButton){
        let idx = game.dealtCards[cardView.gameButtons.firstIndex(of: sender)!].id
        print("added card \(String(describing: idx))")
        selectedCards[idx] = sender
        sender.layer.borderWidth = 3.0
        sender.layer.borderColor = #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1)
    }


    private func render(howMany:Int){
        cardFaces.removeAll()
        
        for card in game.dealtCards{
            var symbols=""
            for _ in 0...card.decoration[0]{
                    symbols.append(validSymbols[card.decoration[1]])
            }
            cardFaces.append(NSAttributedString(string: symbols, attributes: {getAttributes(card.decoration)}() as [NSAttributedString.Key : Any]))
        }
    }
    
    private func getAttributes (_ deco: [Int]) -> [NSAttributedString.Key: Any?]{
        var attributes: [NSAttributedString.Key:Any]? = nil
        let color:UIColor
        
        switch deco[3] {
        case 0:
            color = UIColor.red
        case 1:
            color = UIColor.green
        case 2:
            color = UIColor.blue
        default:
            color = UIColor.gray
        }
        switch deco[2] {
        case 0:
            attributes = [.font:UIFont.preferredFont(forTextStyle: .body).withSize(22), .foregroundColor: color, .strokeWidth: -5.0]
        case 1:
            attributes = [.font:UIFont.preferredFont(forTextStyle: .body).withSize(22), .foregroundColor: color.withAlphaComponent(0.2), .strokeWidth: -5.0]
        case 2:
            attributes = [.font:UIFont.preferredFont(forTextStyle: .body).withSize(22), .foregroundColor: color.withAlphaComponent(1.0), .strokeWidth: 5.0]
        default:
            break
        }

        return attributes!
    }
    
    private func processMatch(matchSet:[SetCard]){
        for matches in selectedCards{
            let card = game.dealtCards.filter {$0.id == matches.key}
            game.dealtCards.remove(at: game.dealtCards.lastIndex(of: card.first!)!)
            game.matchedCards.append(card.first!)
            cardView.buttonFormatNotSelected(button: matches.value)
        }
        game.score += matchPoints
        updateScore()
        selectedCards.removeAll()
        deal()
    }
    
    private func processMismatch(matchSet:[SetCard]){
        for matches in selectedCards{
            cardView.buttonFormatNotSelected(button: matches.value)
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
    static let defaultAspectRatio = 1.0
    static let timerInterval = 1.2
}
