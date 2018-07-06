//
//  SetViewController.swift
//  Set
//
//  Created by Bernhard F. Kraft on 08.06.18.
//  Copyright © 2018 Bernhard F. Kraft. All rights reserved.
//

import UIKit

class SetViewController: UIViewController {

    // **************************************
    // MARK: outlets
    // **************************************


    @IBOutlet weak var dealButton: UIButton!
    
    @IBOutlet var gameButtons: [UIButton]!

    @IBOutlet weak var test: UILabel!
    
    @IBOutlet weak var score: UILabel!
    
    @IBOutlet weak var cheatButton: UIButton!

    @IBAction func touchCard(_ sender: UIButton) {
       if selectedCards.contains(where: {$0.value == sender }){
            selectedCards.remove(at: selectedCards.firstIndex(where: {$0.value == sender })!)
            buttonFormatNotSelected(button: sender)
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
 
    @IBAction func newGame(_ sender: UIButton) {
        newGame()
    }
    
    @IBAction func deal(_ sender: UIButton) {
        deal()
    }

    @IBAction func cheatNow(_ sender: Any) {
        selectedCards.removeAll(keepingCapacity: true)

        for card in cheatSet {
            addselectedCardToMatchingSet(gameButtons[game.dealtCards.firstIndex(of: card)!])
        }
        _ = Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: {_ in self.processMatch(matchSet: self.cheatSet)})
        
        let penalty = -2 * matchPoints
        game.score += penalty
        updateScore()
    }


    // **************************************
    // MARK: private properties
    // **************************************
    private lazy var game:SetCardGame = SetCardGame()
    private var cardFaces = [NSAttributedString]()
    
    private var matchPoints:Int {
        get {
            return (Constants.maxCardsOnTable*2)/game.dealtCards.count + 1
        }
    }

    private var validNumbers:[Int]{
        return [1, 2, 3]
    }
    private var validFills:[Double]{
        return [0.2, 0.5, 1.0]
    }
    private var validSymbols:[String] {
        return ["▲", "■", "●"]
    }
    private var validColors:[String] {
        return ["redColor", "blueColor", "greenColor"]
    }
    
    private var selectedCards = [Int:UIButton]()
    
    private lazy var cheatSet = [SetCard]()

    
    // **************************************
    // MARK: view lifecycle functions
    // **************************************
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        gameButtons.removeAll()

        for subView in view.subviews{
            if subView is UIButton {
                let button = subView as! UIButton
                button.layer.backgroundColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
                button.layer.cornerRadius = 5
                button.layer.borderWidth = 0.2
                button.mask?.clipsToBounds = true
                button.layer.borderColor = #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1)
                button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16.0)
                
            } else{
                if subView is UIStackView{
                    for stackViews in subView.subviews{
                        for view in stackViews.subviews{
                            let button = view as! UIButton
                            buttonFormatNotSelected(button: button)
                            gameButtons.append(button)
                        }
                    }
                }
                if subView is UILabel{
                    subView.layer.cornerRadius = 5
                    subView.layer.borderWidth = 0.2
                    subView.mask?.clipsToBounds = true
                    subView.layer.borderColor = #colorLiteral(red: 0.1294117719, green: 0.2156862766, blue: 0.06666667014, alpha: 0)
                    subView.backgroundColor = #colorLiteral(red: 0.1294117719, green: 0.2156862766, blue: 0.06666667014, alpha: 0)
                    
                }
            }
        }
        printMessageForBernie()
        newGame()
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
        showButtons()
    }

    private func deal(){
        game.deal()
        if game.dealtCards.count == Constants.maxCardsOnTable{
            dealButton.isEnabled = false
        } else{
            dealButton.isEnabled = true
        }
        render(howMany: game.dealtCards.count)
        cheatButton.isEnabled = checkForCheat()
        showButtons()
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
    
    private func showButtons(){
//        for idx in 0..<gameButtons.count{
//            if idx < cardFaces.count{
//                gameButtons[idx].isHidden = false
//                gameButtons[idx].setAttributedTitle(cardFaces[idx], for: .normal)
//            } else{
//                gameButtons[idx].isHidden = true
//            }
//        }
    }

    private func addselectedCardToMatchingSet(_ sender:UIButton){
        let idx = game.dealtCards[gameButtons.firstIndex(of: sender)!].id
        print("added card \(String(describing: idx))")
        selectedCards[idx] = sender
        sender.layer.borderWidth = 3.0
        sender.layer.borderColor = #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1)
    }
    
    private func buttonFormatNotSelected(button: UIButton){
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 0.2
        button.mask?.clipsToBounds = true
        button.layer.borderColor = #colorLiteral(red: 0.1294117719, green: 0.2156862766, blue: 0.06666667014, alpha: 0)
        button.setBackgroundImage(UIImage(named: "white")!, for: UIControl.State .normal)
    }

    private func buttonFormatSelected(button: UIButton){
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 3.0
        button.mask?.clipsToBounds = true
        button.layer.borderColor = #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1)
        button.setBackgroundImage(UIImage(named: "white")!, for: UIControl.State .normal)
    }

    private func processMatch(matchSet:[SetCard]){
        for matches in selectedCards{
            let card = game.dealtCards.filter {$0.id == matches.key}
            game.dealtCards.remove(at: game.dealtCards.lastIndex(of: card.first!)!)
            game.matchedCards.append(card.first!)
            buttonFormatNotSelected(button: matches.value)
        }
        game.score += matchPoints
        updateScore()
        selectedCards.removeAll()
        deal()
    }
    
    private func processMismatch(matchSet:[SetCard]){
        for matches in selectedCards{
            buttonFormatNotSelected(button: matches.value)
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

