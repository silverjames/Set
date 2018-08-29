//
//  CardSetView.swift
//  
//
//  Created by Bernhard F. Kraft on 06.07.18.
//

import UIKit

protocol cardViewDataSource: class {
    func getGridDimensions() -> (cellCount: Int, aspectRatio: CGFloat)
    func getDealtCards() -> [SetCard]
    func getFrameOfPlayingCardPile() -> CGRect
    func getFrameOfDiscardPile() -> CGRect
}

class CardSetView: UIView {

    //    *****************
    //    MARK: properties
    //    *****************

    weak var delegate:cardViewDataSource?
    var setCardViews = [CardView]()
    private var grid = Grid(layout: .dimensions(rowCount: 1, columnCount: 1))
    var animator:UIViewPropertyAnimator!
    private let setCardInset = UIEdgeInsets.init(top: SetViewRatios.insets, left: SetViewRatios.insets, bottom: SetViewRatios.insets, right: SetViewRatios.insets)
    private var oldCardPositions = [Int:CardView]()// id:index in grid
    private var faceDownCards:[CardView] {
        get {
            return setCardViews.filter {!$0.isFaceUp}
        }
    }

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

        for idx in 0..<setCardViews.count {
            oldCardPositions[delegate!.getDealtCards()[idx].id] = setCardViews[idx]
        }

        self.subviews.forEach {$0.removeFromSuperview()}
        setCardViews.removeAll()
        
        for gridIndex in 0..<self.grid.cellCount {//create all cards
//            print ("card: \(self.delegate!.getDealtCards()[gridIndex].id)")

            let cardUI = CardView(frame: self.grid[gridIndex]!.inset(by: self.setCardInset),
                                  cardNumber: self.delegate!.getDealtCards()[gridIndex].decoration[0],
                                  cardShape: self.delegate!.getDealtCards()[gridIndex].decoration[1],
                                  cardFill: self.delegate!.getDealtCards()[gridIndex].decoration[2],
                                  cardColor: self.delegate!.getDealtCards()[gridIndex].decoration[3])
            let tap = UITapGestureRecognizer(target: self.delegate!, action: #selector(SetViewController.touchCard(_:)))
            cardUI.addGestureRecognizer(tap)
            cardUI.translatesAutoresizingMaskIntoConstraints = false
            cardUI.isFaceUp = self.delegate!.getDealtCards()[gridIndex].isFaceUp
            self.setCardViews.append(cardUI)

            if let oldFrame = oldCardPositions[delegate!.getDealtCards()[gridIndex].id] {
                cardUI.frame = oldFrame.frame
            }
//            self.addSubview(cardUI)

            animator = UIViewPropertyAnimator.init(duration: 0.5, curve: .easeInOut, animations: {
                [unowned self] in
                self.setCardViews[gridIndex].frame = self.grid[gridIndex]!.inset(by: self.setCardInset)
            })

            animator.startAnimation()
            self.addSubview(setCardViews[gridIndex])

        }// loop through grid
        
        faceDownCards.forEach {$0.isHidden = true}

        let _ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: {_ in self.dealCards()})
        let _ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: {_ in self.turnUpCards()})

    }//end func
    
    func dealCards() {
        var saveCurrentCardPosition = [CGRect]()
        faceDownCards.forEach {saveCurrentCardPosition.append($0.frame)}
        faceDownCards.forEach {$0.frame = delegate!.getFrameOfPlayingCardPile()}

        animator = UIViewPropertyAnimator.init(duration: 0.5, curve: .easeInOut, animations: {
            [unowned self] in
            self.faceDownCards.forEach {
                $0.isHidden = false
                $0.frame = saveCurrentCardPosition.remove(at: Int(saveCurrentCardPosition.count).arc4Random)
            }
        })
        
        animator.startAnimation()
    }

    func turnUpCards() {

        self.faceDownCards.forEach { cardView in
            UIView.transition(with: cardView, duration: 0.5, options: [.transitionFlipFromLeft], animations: {
                [unowned self] in
                cardView.isFaceUp = true
                cardView.subviews.forEach{$0.removeFromSuperview()}
                self.delegate!.getDealtCards()[self.setCardViews.firstIndex(of: cardView)!].isFaceUp = true
                }, completion: { animatingPosition in
            })
            
        }//for each facedown card
    }
    
}//end class

extension CardSetView{
    private struct SetViewRatios {
        static let frameInsetRatio: CGFloat = 0.08
        static let maxSymbolsPerCard = 3
        static let cardCornerRadius:CGFloat = 5.0
        static let insets = CGFloat(3.0)
        static let cagesPerButton = 3
    }
    func getGridCellCenter(cell:CGRect) -> CGPoint{
        return CGPoint(x: cell.origin.x + cell.width/2, y: cell.origin.y + cell.height/2)
    }
}

