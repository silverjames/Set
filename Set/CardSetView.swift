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
    var gameCards = [CardView]()
    var grid = Grid(layout: .dimensions(rowCount: 1, columnCount: 1))
    var animator:UIViewPropertyAnimator!
    let setCardInset = UIEdgeInsets.init(top: SetViewRatios.insets, left: SetViewRatios.insets, bottom: SetViewRatios.insets, right: SetViewRatios.insets)

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

        for view in self.subviews{
            view.removeFromSuperview()
        }
        gameCards.removeAll()
        grid.frame = self.bounds
        
        for idx in 0 ..< delegate!.getDealtCards().count {
            //create the card's UI
            let cardUI = CardView(frame: grid[idx]!.inset(by: setCardInset),
                                  cardNumber: delegate!.getDealtCards()[idx].decoration[0],
                                  cardShape: delegate!.getDealtCards()[idx].decoration[1],
                                  cardFill: delegate!.getDealtCards()[idx].decoration[2],
                                  cardColor: delegate!.getDealtCards()[idx].decoration[3])
            let tap = UITapGestureRecognizer(target: delegate!, action: #selector(SetViewController.touchCard(_:)))
            cardUI.addGestureRecognizer(tap)
            cardUI.isHidden = false
            cardUI.isFaceUp = delegate!.getDealtCards()[idx].isFaceUp
            self.addSubview(cardUI)
            gameCards.append(cardUI)
            _ = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: false, block: {_ in self.turnupCards()})
        }
    }


private func turnupCards() {
    for idx in 0 ..< delegate!.getDealtCards().count {
        if !delegate!.getDealtCards()[idx].isFaceUp{
            UIView.transition(with: gameCards[idx], duration: 0.6, options: [.transitionFlipFromLeft],
                animations: {
                    for subview in self.gameCards[idx].subviews{
                        subview.removeFromSuperview()
                    }
                    }, completion: {finished in
                        self.delegate!.getDealtCards()[idx].isFaceUp = true
                        self.gameCards[idx].isFaceUp = true
                })
            }//check id facedown
        }//for loop
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
}
