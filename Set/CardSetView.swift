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
        setCardViews.removeAll()
        grid.frame = self.bounds
        
        for gridIndex in 0..<grid.cellCount {
//            if gridIndex == setCardViews.count {//add new view
                print ("card: \(delegate!.getDealtCards()[gridIndex].id)")
                let cardUI = CardView(frame: grid[gridIndex]!.inset(by: setCardInset),
                                      cardNumber: delegate!.getDealtCards()[gridIndex].decoration[0],
                                      cardShape: delegate!.getDealtCards()[gridIndex].decoration[1],
                                      cardFill: delegate!.getDealtCards()[gridIndex].decoration[2],
                                      cardColor: delegate!.getDealtCards()[gridIndex].decoration[3])
                let tap = UITapGestureRecognizer(target: delegate!, action: #selector(SetViewController.touchCard(_:)))
                cardUI.addGestureRecognizer(tap)
                cardUI.isFaceUp = delegate!.getDealtCards()[gridIndex].isFaceUp
                self.addSubview(cardUI)
                setCardViews.append(cardUI)
//            } else {
////                print ("card: \(delegate!.getDealtCards()[gridIndex].id)")
////                print("grid frame: \(grid[gridIndex]!) - center: \(getGridCellCenter(cell: grid[gridIndex]!))")
//                let gridCenter = convert(getGridCellCenter(cell: grid[gridIndex]!), to: self)
////                print("grid center translated: \(gridCenter)")
////                print("card frame b'fore: \(setCardViews[gridIndex].dimension) - center: \(getGridCellCenter(cell: setCardViews[gridIndex].dimension))")
//
////                setCardViews[gridIndex].removeFromSuperview()
//                setCardViews[gridIndex].transform = CGAffineTransform.identity.scaledBy(x: grid[gridIndex]!.inset(by: setCardInset).width / setCardViews[gridIndex].frame.width, y: grid[gridIndex]!.inset(by:setCardInset).height / setCardViews[gridIndex].frame.height)
//
//                let dx:CGFloat
//                let dy:CGFloat
//                
//                if gridCenter.x <= getGridCellCenter(cell: setCardViews[gridIndex].dimension).x {
//                    dx = gridCenter.x - getGridCellCenter(cell: setCardViews[gridIndex].dimension).x
//                } else {
//                    dx = getGridCellCenter(cell: setCardViews[gridIndex].dimension).x - gridCenter.x
//                }
//
//                if gridCenter.y <= getGridCellCenter(cell: setCardViews[gridIndex].dimension).y {
//                    dy = gridCenter.y - getGridCellCenter(cell: setCardViews[gridIndex].dimension).y
//                } else {
//                    dy = getGridCellCenter(cell: setCardViews[gridIndex].dimension).y - gridCenter.y
//                }
//
////                setCardViews[gridIndex].transform = CGAffineTransform.identity.translatedBy(x: dx, y:  dy)
//                setCardViews[gridIndex].frame = grid[gridIndex]!.inset(by: setCardInset)
//                self.addSubview(setCardViews[gridIndex])
//
//                print("card frame after: \(setCardViews[gridIndex].dimension)- center: \(getGridCellCenter(cell: setCardViews[gridIndex].dimension))")
//                print("****")
//            }
            
            _ = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: false, block: {_ in self.turnupCards()})

        }// loop through grid
//        self.layoutIfNeeded()
        print ("I have \(self.subviews.count) subviews")
//        for index in 0..<setCardViews.count {
//            print ("grid frame: \(String(describing: grid[index]!)), cardViewFrame: \(setCardViews[index].frame)")
//            let newOrigin = convert(grid[index]!.origin, to: self as UIView)
//            let dx = grid[index]!.width / setCardViews[index].frame.width
//            let dy = grid[index]!.height / setCardViews[index].frame.height
//            setCardViews[index].transform = CGAffineTransform.identity.translatedBy(x: setCardViews[index].frame.origin.x - newOrigin.x, y: setCardViews[index].frame.origin.y - newOrigin.y).scaledBy(x: dx, y: dy)
//        }
        
    }


private func turnupCards() {
    for idx in 0 ..< delegate!.getDealtCards().count {
        if !delegate!.getDealtCards()[idx].isFaceUp{
            UIView.transition(with: setCardViews[idx], duration: 0.6, options: [.transitionFlipFromLeft],
                animations: {
                    for subview in self.setCardViews[idx].subviews{
                        subview.removeFromSuperview()
                    }
                    }, completion: {finished in
                        self.delegate!.getDealtCards()[idx].isFaceUp = true
                        self.setCardViews[idx].isFaceUp = true
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
    func getGridCellCenter(cell:CGRect) -> CGPoint{
        return CGPoint(x: cell.origin.x + cell.width/2, y: cell.origin.y + cell.height/2)
    }
}
