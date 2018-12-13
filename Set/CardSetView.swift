//
//  CardSetView.swift
//  
//
//  Created by Bernhard F. Kraft on 06.07.18.
//

import UIKit
import AVFoundation

protocol cardViewDataSource: class {
    func getGridDimensions() -> (cellCount: Int, aspectRatio: CGFloat)
    func getDealtCards() -> [SetCard]
    func getMatchedCards() -> [CardView]
    func getFrameOfPlayingCardPile() -> CGRect
    func getFrameOfDiscardPile() -> CGRect
    func resetMatchedCards() -> Void
    func pauseUserInteraction() -> Void
    func enableUserInteraction() -> Void
}

class CardSetView: UIView {

    //    *****************
    //    MARK: properties
    //    *****************

    weak var delegate:cardViewDataSource?
    var setCardViews = [CardView]()
    private var cardCopies = [CardView]()
    private var grid = Grid(layout: .dimensions(rowCount: 1, columnCount: 1))
    var animator:UIViewPropertyAnimator!
    private let setCardInset = UIEdgeInsets.init(top: SetViewRatios.insets, left: SetViewRatios.insets, bottom: SetViewRatios.insets, right: SetViewRatios.insets)
    private var oldCardPositions = [Int:CardView]()// id:view
    private var faceDownCards:[CardView] {
        get {
            return setCardViews.filter {!$0.isFaceUp}
        }
    }
    private var scaleFactorForDiscardAction:CGFloat {
        get {
            return delegate!.getFrameOfDiscardPile().width / (grid.cellSize.width - 2 * SetViewRatios.insets)
        }
    }
    private lazy var dynamicAnimator = UIDynamicAnimator.init(referenceView: self.superview!)
    private lazy var collisionBehavior: UICollisionBehavior = {
        let behavior = UICollisionBehavior()
        behavior.translatesReferenceBoundsIntoBoundary = true
        dynamicAnimator.addBehavior(behavior)
        return behavior
        
    }()
    private lazy var itemBehavior: UIDynamicItemBehavior = {
        let itemBehavior = UIDynamicItemBehavior.init()
        itemBehavior.elasticity = 1.0
        itemBehavior.resistance = 0
        itemBehavior.allowsRotation = true
        dynamicAnimator.addBehavior(itemBehavior)
        return itemBehavior
    }()
    private var player:AVAudioPlayer?
    private let whooshURL = Bundle.main.path(forResource: "sound_whoosh_min", ofType: "mp3")


    //    *****************
    //    MARK: lifecycle Functions
    //    *****************
    override func layoutSubviews() {
        print("csv: layoutSubviews")
        super.layoutSubviews()

        if let _ = animator {
            if !animator.isRunning {
                updateViewFromModel()
            }
        } else{
            updateViewFromModel()
        }
    }
    

    //    *****************
    //    MARK Functions
    //    *****************
    
    private func updateViewFromModel(){
        print("csv: updateViewFromModel")
        self.grid = Grid(layout: .aspectRatio(delegate!.getGridDimensions().aspectRatio))
        grid.cellCount = (delegate!.getGridDimensions().cellCount)
        grid.frame = self.bounds
        var saveCurrentCardPosition = [CGRect]()
        print ("Cardviews: \(setCardViews.count)")
        setCardViews.forEach {saveCurrentCardPosition.append($0.frame) }
        
        for gridIndex in 0..<self.grid.cellCount {
            
            if gridIndex == setCardViews.count {//produce a card
                let card = CardView(frame: self.grid[gridIndex]!.inset(by: self.setCardInset),
                                    cardNumber: self.delegate!.getDealtCards()[gridIndex].decoration[0],
                                    cardShape: self.delegate!.getDealtCards()[gridIndex].decoration[1],
                                    cardFill: self.delegate!.getDealtCards()[gridIndex].decoration[2],
                                    cardColor: self.delegate!.getDealtCards()[gridIndex].decoration[3])
                let tap = UITapGestureRecognizer(target: self.delegate!, action: #selector(SetViewController.touchCard(_:)))
                card.addGestureRecognizer(tap)
                //            card.translatesAutoresizingMaskIntoConstraints = false
                card.isFaceUp = self.delegate!.getDealtCards()[gridIndex].isFaceUp
                self.setCardViews.append(card)
                self.addSubview(card)
            }
        }// loop through grid

        animator = UIViewPropertyAnimator.init(duration: timings.shuffle, curve: .easeInOut, animations: {
            [unowned self] in
            var idx = 0
            self.setCardViews.forEach {
                $0.frame = self.grid[idx]!.inset(by: self.setCardInset)
                idx += 1
                }
            })
        animator.startAnimation()

        faceDownCards.forEach {$0.isHidden = true}

        let _ = Timer.scheduledTimer(withTimeInterval: timings.dealStart, repeats: false, block: {_ in self.dealCards()})
        let _ = Timer.scheduledTimer(withTimeInterval: timings.turnupStart, repeats: false, block: {_ in self.turnUpCards()})
        let _ = Timer.scheduledTimer(withTimeInterval: timings.flyawayStart, repeats: false, block: {_ in self.flyawayMatchedCards()})
        let _ = Timer.scheduledTimer(withTimeInterval: timings.discardStart, repeats: false, block: {_ in self.discardFlyawaycards()})

    }//end func
    
    private func dealCards() {
        var saveCurrentCardPosition = [CGRect]()
        faceDownCards.forEach {saveCurrentCardPosition.append($0.frame)}
        faceDownCards.forEach {$0.frame = delegate!.getFrameOfPlayingCardPile()}
        delegate!.pauseUserInteraction()


        animator = UIViewPropertyAnimator.init(duration: 0.5, curve: .easeInOut, animations: {
            [unowned self, whooshURL] in
            self.faceDownCards.forEach {
                $0.isHidden = false
                $0.frame = saveCurrentCardPosition.remove(at: Int(saveCurrentCardPosition.count).arc4Random)
                do {
                    if whooshURL != nil {
                        self.player = try AVAudioPlayer (contentsOf: URL(fileURLWithPath: whooshURL!))
                        self.player?.play()
                    } else {
                        print ("no such audio file exists")
                    }
                }
                catch let error {
                    print ("error playing audio: \(error.localizedDescription)")
                }
            }
        })

        animator.startAnimation()
    }//end func

    private func turnUpCards() {

        self.faceDownCards.forEach { card in
            UIView.transition(with: card, duration: timings.turnup, options: [.transitionFlipFromLeft], animations: {
                [unowned self] in
                card.isFaceUp = true
                card.subviews.forEach{$0.removeFromSuperview()}
                self.delegate!.getDealtCards()[self.setCardViews.firstIndex(of: card)!].isFaceUp = true
                }, completion: { animatingPosition in
            })
        }//for each facedown card
    }//end func
    
    private func flyawayMatchedCards() {
        let matchedCards = self.delegate!.getMatchedCards()

        matchedCards.forEach {
            cardCopies.append($0.copy() as! CardView)
            cardCopies.last!.isFaceUp = true
            cardCopies.last!.layer.borderWidth = 1.0
            cardCopies.last!.layer.borderColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
            cardCopies.last!.layer.cornerRadius = SetViewRatios.cardCornerRadius
        }
        
        delegate?.resetMatchedCards()

        self.cardCopies.forEach {
            self.superview!.addSubview($0)
            self.collisionBehavior.addItem($0)
            self.itemBehavior.addItem($0)
            let push = UIPushBehavior(items: [$0], mode: .instantaneous)
            push.angle = (2*CGFloat.pi).arc4Random
            push.magnitude = CGFloat(10.0) + CGFloat(5.0).arc4Random
            push.action = {
                [unowned push, weak self] in
                 self?.dynamicAnimator.removeBehavior(push)
            }
            self.dynamicAnimator.addBehavior(push)
        }//for each card
    }//end func
    
    private func discardFlyawaycards() {
        
        //remove card from dynamic behaviour
        cardCopies.forEach {
            self.collisionBehavior.removeItem($0)
            self.itemBehavior.removeItem($0)
        }

        animator = UIViewPropertyAnimator.init(duration: timings.discard, dampingRatio: 0.3 , animations: {
            [unowned self, cardCopies] in
            let discardPileFrame = self.delegate!.getFrameOfDiscardPile()
            cardCopies.forEach {
                $0.alpha = 0.5
                $0.transform = CGAffineTransform.identity.translatedBy(x: discardPileFrame.getCenter().x - $0.center.x, y: discardPileFrame.getCenter().y - $0.center.y).scaledBy(x: self.scaleFactorForDiscardAction, y: self.scaleFactorForDiscardAction)
            }
        })

        animator.addCompletion({_ in
            self.cardCopies.forEach {
                $0.removeFromSuperview()
            }
            self.cardCopies.removeAll()
            self.delegate!.enableUserInteraction()   
        })

        animator.startAnimation()


    }//end func
    
}//end class

extension CardSetView{
    private struct timings: Codable {
        static let dealStart: TimeInterval = 0.6
        static let turnupStart: TimeInterval = 1.2
        static let flyawayStart: TimeInterval = 0.4
        static let discardStart: TimeInterval = 3.0
        static let shuffle: TimeInterval = 0.5
        static let deal: TimeInterval = 0.5
        static let turnup: TimeInterval = 0.5
        static let discard: TimeInterval = 2.0
    }
    private struct SetViewRatios: Codable {
        static let frameInsetRatio: CGFloat = 0.08
        static let maxSymbolsPerCard = 3
        static let cardCornerRadius:CGFloat = 5.0
        static let insets = CGFloat(3.0)
        static let cagesPerButton = 3
    }
}

extension CGRect {
    func getCenter() -> CGPoint{
        return CGPoint(x: self.origin.x + self.width/2, y: self.origin.y + self.height/2)
    }

}

