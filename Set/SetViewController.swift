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
    lazy var game:SetCardGame = SetCardGame()
    private var selectedCards = [Int:CardView]()
    private var matchPoints:Int {
        get {
            return (GameConstants.maxCardsOnTable)/game.dealtCards.count + 1
        }
    }
    private var allCardsDealt:Bool {
        get {
            return game.setGame.count == 0
        }
    }
    private var matchSetCounter:Int {
        get {
            return (GameConstants.maxCardsOnTable - (game.dealtCards.count + game.setGame.count)) / 3
        }
    }
    private var remainingSetCounter:Int {
        get {
            return (game.dealtCards.count + game.setGame.count) / 3
        }
    }
    private lazy var cheatSet = [SetCard]()
    private lazy var matchSet = [CardView]()
    private var cheated:Bool = false
    var stateRestorationActive = false
    private lazy var cardPiles = [UIImageView]()
    private var animator:UIViewPropertyAnimator!

    private var player:AVAudioPlayer?
    private let tapSound = SystemSoundID(1105)
    private let newGameSound = SystemSoundID(1108)
    private let misMatchSound = SystemSoundID(1024)
    private let clickURL = Bundle.main.path(forResource: "Click_Electronic_05", ofType: "mp3")

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
    @IBOutlet weak var newGameButton: UIButton!
    @IBOutlet weak var setCounter: UILabel!
    @IBOutlet weak var remainingSets: UILabel!
    @IBAction func newGame(_ sender: UIButton) {
        AudioServicesPlaySystemSound(newGameSound)
        newGame()
        stateRestorationActive = false
    }
    
    @IBOutlet weak var deal: UIImageView!{
        didSet {
            let dealGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(cardPileTapped(_:)))
            deal.addGestureRecognizer(dealGestureRecognizer)
        }
    }
    
    @IBAction func cheatNow(_ sender: Any) {
        cheated = true
        selectedCards.removeAll(keepingCapacity: true)

        cheatSet.forEach {
            if let _ = game.dealtCards.firstIndex(of: $0) {
                addselectedCardToMatchingSet(cardView.setCardViews[game.dealtCards.firstIndex(of: $0)!])
            }
        }
        _ = Timer.scheduledTimer(withTimeInterval: Constants.timerInterval, repeats: false, block: {_ in self.processMatch(matchingCards: self.cheatSet)})
        
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
                    
                //                    AudioServicesPlaySystemSound(matchSound)
                    _ = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false, block: {_ in self.processMatch(matchingCards: matchSet)})
                } else {
                    print("cards did not match!")
                    AudioServicesPlaySystemSound(misMatchSound)
                    _ = Timer.scheduledTimer(withTimeInterval: 1.1, repeats: false, block: {_ in self.processMismatch(matchSet: matchSet)})
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
    func getMatchedCards() -> [CardView] {
        return matchSet
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
    func resetMatchedCards() -> Void {
        matchSet.forEach {
            $0.removeFromSuperview()
        }
        matchSet.removeAll()
    }
    
    func pauseUserInteraction() -> Void {
        cardPiles.forEach {$0.isUserInteractionEnabled = false}
        cheatButton.isUserInteractionEnabled = false
        return
    }
    
    func enableUserInteraction() -> Void {
        cardPiles.forEach {$0.isUserInteractionEnabled = true}
        cheatButton.isUserInteractionEnabled = true
        return
    }

    // **************************************
    // MARK: view lifecycle functions
    // **************************************
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        var attributes = [NSAttributedString.Key: Any?]()
        let font = UIFont.preferredFont(forTextStyle: .body)
        let metrics = UIFontMetrics(forTextStyle: .body)
        let fontToUse = metrics.scaledFont(for: font)
        let color:UIColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
        attributes = [.font:fontToUse, .foregroundColor: color, .strokeWidth: -3.0]
        cheatButton.setAttributedTitle(NSAttributedString(string: "Cheat", attributes:attributes as [NSAttributedString.Key : Any]), for: .normal)
        newGameButton.setAttributedTitle(NSAttributedString(string: "New Game", attributes:attributes as [NSAttributedString.Key : Any]), for: .normal)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        cardPiles.removeAll()
        self.restorationIdentifier = "SetViewController"
        
        for subView in view.subviews{
            if subView is UIStackView {
                for stackSubView in subView.subviews {
                    if stackSubView is UIButton {
                        let button = stackSubView as! UIButton
                        button.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
                        button.layer.cornerRadius = 5
                        button.layer.borderWidth = 0.0
                    }
                }//stack view subs
            }//stack view
            
            if subView is UIImageView{
                subView.isUserInteractionEnabled = true
                cardPiles.append(subView as! UIImageView)
            }//image views
        }//subviews
        
        self.cardPiles[0].image = UIImage(named: "cardback")
        self.cardPiles[1].image = UIImage(named: "cardback")
        self.cardPiles[1].isHidden = true

        printMessageForBernie()
        
        if !stateRestorationActive{
            newGame()
        } else {
            cheatButton.isHidden = !checkForCheat()
            updateScore()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cardView.setNeedsDisplay()
    }
    
    // **************************************
    // MARK: private functions
    // **************************************
    private func newGame(){
        game.newGame()
        cardView.setCardViews.removeAll()
        cardView.subviews.forEach{$0.removeFromSuperview()}
        cheatButton.isHidden = !checkForCheat()

        cardPiles[0].image = UIImage(named: "cardback")
        cardPiles[1].image = UIImage(named: "cardback")
        cardPiles[0].isUserInteractionEnabled = true
        cardPiles[1].isHidden = true

        updateScore()
        print ("\(game.description)")
        cardView.setNeedsLayout()
    }

    @objc private func cardPileTapped(_ gestureRecognizer: UITapGestureRecognizer){
        guard gestureRecognizer.view != nil else {return}
        dealCards()
    }
    
    private func dealCards(){
        game.deal()
        if allCardsDealt {
            cardPiles[0].isUserInteractionEnabled = false
            cardPiles[0].image = nil
        }
        
        cheatButton.isHidden = !checkForCheat()
        if cheatButton.isHidden && allCardsDealt {
            endGame()
        }
        cardView.setNeedsLayout()
    }

    private func checkForCheat () -> Bool{
        var cheatFound = false
        cheatSet.removeAll(keepingCapacity: true)
        var checkSet:[SetCard]
        if game.dealtCards.count >= GameConstants.dealSize {
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
        }
        return cheatFound
    }
    
    private func addselectedCardToMatchingSet(_ sender:CardView){
//        print ("\(sender)")
        if let _ = cardView.setCardViews.firstIndex(of: sender) {
            let id = game.dealtCards[cardView.setCardViews.firstIndex(of: sender)!].id
            print("added card \(String(describing: id))")
            selectedCards[id] = sender
            sender.selected = true
        }
    }
    
    private func processMatch(matchingCards:[SetCard]){

        matchSet = Array(selectedCards.values)
        
        for matches in selectedCards{
            let card = game.dealtCards.filter {$0.id == matches.key}
            game.dealtCards.remove(at: game.dealtCards.lastIndex(of: card.first!)!)
            game.matchedCards.append(card.first!)
            matches.value.selected = false
            if cardView.setCardViews.firstIndex(of: matches.value) != nil {
                cardView.setCardViews.remove(at: cardView.setCardViews.firstIndex(of: matches.value)!)
            }
        }//loop through dictionary
        
        if !cheated {
            game.score += matchPoints
        } else {
            cheated = false
        }

        //play sound
        do {
            if clickURL != nil {
                player = try AVAudioPlayer (contentsOf: URL(fileURLWithPath: clickURL!))
                player?.play()
            } else {
                print ("no such audio file exists")
            }
        }
        catch let error {
            print ("error playing audio: \(error.localizedDescription)")
        }

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
        var attributes = [NSAttributedString.Key: Any?]()
        let font = UIFont.preferredFont(forTextStyle: .body)
        let metrics = UIFontMetrics(forTextStyle: .body)
        let fontToUse = metrics.scaledFont(for: font)
        let color:UIColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
        attributes = [.font:fontToUse, .foregroundColor: color, .strokeWidth: -3.0]
        score.attributedText = (NSAttributedString(string: "Score: \(game.score)", attributes:attributes as [NSAttributedString.Key : Any]))
        setCounter.attributedText = (NSAttributedString(string: ("\(matchSetCounter)"), attributes:attributes as [NSAttributedString.Key : Any]))
        remainingSets.attributedText = (NSAttributedString(string: ("\(remainingSetCounter)"), attributes:attributes as [NSAttributedString.Key : Any]))
        if matchSetCounter != 0 {
            self.cardPiles[1].isHidden  = false
        }
    }
    
    private func printMessageForBernie(){
        //        MARK: test code for nsattributedstring
        var attributes = [NSAttributedString.Key: Any?]()
        attributes = [.font:UIFont.preferredFont(forTextStyle: .body).withSize(10), .foregroundColor: UIColor(red: 1.0, green: 0.5, blue: 0.5, alpha: 0.25), .strokeWidth: -3.0]
        test.attributedText = (NSAttributedString(string:"Bernie was here...", attributes:attributes as [NSAttributedString.Key : Any]))
    }
    
    private func endGame(){
        //create a message label
        let labelWidth = self.view.bounds.width * 0.7
        let labelHeigth = self.view.bounds.height * 0.4
        let labelSize = CGSize(width: labelWidth, height: labelHeigth)
        let labelOrigin = self.view.bounds.origin
        let labelFrame = CGRect(origin: labelOrigin, size: labelSize)
        let label = UILabel(frame: labelFrame)
        label.center = self.view.center
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = .center
        label.backgroundColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 0)
        label.alpha = 0
        self.view.addSubview(label)
        
        //create a message
        var attributes = [NSAttributedString.Key: Any?]()
        attributes = [.font:UIFont.preferredFont(forTextStyle: .body).withSize(88), .foregroundColor: #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1), .strokeWidth: -4.0]
        label.attributedText = NSAttributedString(string:"Game Over", attributes:attributes as [NSAttributedString.Key : Any])
        
        animator = UIViewPropertyAnimator.init(duration: 6, curve: .easeOut, animations: {
            [unowned self, label, score] in
            label.alpha = 1
            self.cardView.alpha = 0
            score?.transform = CGAffineTransform.identity.scaledBy(x: 2.0, y: 2.0)
            
            self.view.subviews.forEach {
                if $0 is UIImageView {
                    $0.alpha = 0
                }
            }
        })
        
        animator.addCompletion({finished in
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 2.0, delay: 0, options: .curveEaseOut, animations: {
                [label] in
                label.alpha = 0
                }, completion:{finished in
                    label.removeFromSuperview()
                    self.cardView.alpha = 1
                    self.score.transform = CGAffineTransform.identity
                    self.newGame()
                    for subView in self.view.subviews{
                        if subView is UIImageView{
                            subView.alpha = 1
                        }
                    }
            })
        })
        animator.startAnimation(afterDelay: 3.0)

    }
}

extension CGFloat {
    var arc4Random: CGFloat {
        return CGFloat(arc4random_uniform(UInt32(self)))
    }
}

//MARK: need to re-dupe the constants
private struct Constants {
    static let mismatchPoints = -2
    static let matchPoints = 5
    static let deselectPoints = -1
    static let defaultAspectRatio:CGFloat = 5/8
    static let timerInterval:Double = 0.5
}
