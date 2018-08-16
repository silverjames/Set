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
    private var selectedCards = [Int:CardView]()
    private var matchPoints:Int {
        get {
            return (GameConstants.maxCardsOnTable)/game.dealtCards.count + 1
        }
    }
    private lazy var cheatSet = [SetCard]()
    private lazy var cardPiles = [UIImageView]()
    private let tapSound = SystemSoundID(1105)
    private let newGameSound = SystemSoundID(1108)
    private let matchSound = SystemSoundID(1332)
    private let misMatchSound = SystemSoundID(1024)
//    private var animator:UIViewPropertyAnimator!

    // **************************************
    // MARK: outlets and functions
    // **************************************

//    @IBOutlet weak var dealButton: UIButton!
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
    
    @IBOutlet weak var deal: UIImageView!{
        didSet {
            let dealGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(cardPileTapped(_:)))
            deal.addGestureRecognizer(dealGestureRecognizer)
        }
    }
    
    @IBAction func cheatNow(_ sender: Any) {
        selectedCards.removeAll(keepingCapacity: true)

        for card in cheatSet {
            addselectedCardToMatchingSet(cardView.setCardViews[game.dealtCards.firstIndex(of: card)!])
        }
        _ = Timer.scheduledTimer(withTimeInterval: 1.8, repeats: false, block: {_ in self.processMatch(matchSet: self.cheatSet)})
        
        let penalty = -2 * matchPoints
        game.score += penalty
        updateScore()
    }
    
    @objc func touchCard(_ sender: UITapGestureRecognizer) {

        let card = sender.view! as! CardView
        AudioServicesPlaySystemSound(tapSound)
        if selectedCards.contains(where: {$0.value == card }){
            selectedCards.remove(at: selectedCards.firstIndex(where: {$0.value == card })!)
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
                    _ = Timer.scheduledTimer(withTimeInterval: 1.8, repeats: false, block: {_ in self.processMatch(matchSet: matchSet)})
                } else {
                    print("cards did not match!")
                    AudioServicesPlaySystemSound(misMatchSound)
                    _ = Timer.scheduledTimer(withTimeInterval: 1.8, repeats: false, block: {_ in self.processMismatch(matchSet: matchSet)})
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
    func getFrameOfPlayingCardPile() -> CGRect {
        if cardPiles.count == 2 {
            return cardPiles[0].frame
        } else{
            return self.view.frame
        }
    }
    
    func getFrameOfDiscardPile() -> CGRect {
        if cardPiles.count == 2 {
            return cardPiles[1].frame
        } else{
            return self.view.frame
        }
    }

    // **************************************
    // MARK: view lifecycle functions
    // **************************************
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        cardPiles.removeAll()
        
        for subView in view.subviews{
            if subView is UIStackView {
                for stackSubView in subView.subviews {
                    if stackSubView is UIButton {
                        let button = stackSubView as! UIButton
                        button.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
                        button.layer.cornerRadius = 5
                        button.layer.borderWidth = 0.0
                        button.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
                        
                    }
                    if stackSubView is UILabel{
                        stackSubView.layer.cornerRadius = 5
                        stackSubView.layer.borderWidth = 0.2
                        stackSubView.layer.borderColor = #colorLiteral(red: 0.1294117719, green: 0.2156862766, blue: 0.06666667014, alpha: 0)
                        stackSubView.backgroundColor = #colorLiteral(red: 0.1294117719, green: 0.2156862766, blue: 0.06666667014, alpha: 0)
                    }
                }//stack view subs
            }//stack view
            
            if subView is UIImageView{
                subView.layer.borderColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                subView.layer.borderWidth = 1.0
                subView.layer.cornerRadius = 5
                subView.isUserInteractionEnabled = true
                cardPiles.append(subView as! UIImageView)
            }//image views
        }//subviews
        self.cardPiles[0].image = UIImage(named: "cardback")
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
        cheatButton.isHidden = !checkForCheat()
        updateScore()
        print ("\(game.description)")
        cardView.setCardViews.removeAll()
        cardView.subviews.forEach{$0.removeFromSuperview()}
        cardView.setNeedsLayout()
        cardView.setNeedsDisplay()
    }

    @objc private func cardPileTapped(_ gestureRecognizer: UITapGestureRecognizer){
        guard gestureRecognizer.view != nil else {return}
        dealCards()
    }
    private func dealCards(){
        AudioServicesPlaySystemSound(tapSound)
        game.deal()
        if game.dealtCards.count == GameConstants.maxCardsOnTable{
            cardPiles[0].isUserInteractionEnabled = false
            cardPiles[0].image = nil
        }
        
        cheatButton.isHidden = !checkForCheat()
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
                    }
                }
            }
        }
        return cheatFound
    }
    private func addselectedCardToMatchingSet(_ sender:CardView){
//        print ("\(sender)")
        let idx = game.dealtCards[cardView.setCardViews.firstIndex(of: sender)!].id
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
        }//loop through dictionary

        let cardUIs = Array(selectedCards.values)

        cardView.animator = UIViewPropertyAnimator.init(duration: 2.5, curve: .easeInOut, animations: {
            [unowned self, cardUIs] in
            cardUIs.forEach{
                let dx = (self.getFrameOfDiscardPile().origin.x) - $0.frame.origin.x
                let dy = (self.getFrameOfDiscardPile().origin.y) - $0.frame.origin.y
                $0.transform = CGAffineTransform.identity.translatedBy(x: dx-25, y: dy-10).rotated(by: CGFloat.pi).scaledBy(x: 0.35, y: 0.35)
                $0.alpha = 0.0
            }
        })
        
        cardView.animator.addCompletion({finished in
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.8, delay: 0, options: .curveEaseInOut, animations:{
                self.cardPiles[1].image = UIImage(named: "cardback")
                self.cardPiles[1].alpha = 0.7
                self.cardView.setNeedsLayout()
                cardUIs.forEach {
                    $0.removeFromSuperview()
                    if let _ = self.cardView.setCardViews.firstIndex(of: $0){
                        self.cardView.setCardViews.remove(at: self.cardView.setCardViews.firstIndex(of: $0)!)
                    }//if let
                }//for all card views
            })
        })
        
        cardView.animator.startAnimation()
        
        game.score += matchPoints
        updateScore()
        selectedCards.removeAll()
        dealCards()
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
        attributes = [.font:UIFont.preferredFont(forTextStyle: .body).withSize(10), .foregroundColor: UIColor(red: 1.0, green: 0.5, blue: 0.5, alpha: 0.25), .strokeWidth: -3.0]
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
