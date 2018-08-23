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
            print ("card: \(self.delegate!.getDealtCards()[gridIndex].id)")

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
            
            self.addSubview(cardUI)
            
            animator = UIViewPropertyAnimator.init(duration: 0.5, curve: .easeInOut, animations: {
                [unowned self, unowned cardUI] in
                cardUI.frame = self.grid[gridIndex]!.inset(by: self.setCardInset)
            })
            
            if !cardUI.isFaceUp {
                animator.addCompletion({animatingPosition in
                    switch animatingPosition {
                    case .end:
                        UIView.transition(with: cardUI, duration: 0.5, options: [.transitionFlipFromLeft], animations: {
                            cardUI.isFaceUp = true
                        })
                    default:
                        break
                    }
                })
                delegate!.getDealtCards()[gridIndex].isFaceUp = true
            }//end if
            
            animator.startAnimation()
        }// loop through grid
        
    }//end func
    

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
