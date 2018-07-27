//
//  CardView.swift
//  
//
//  Created by Bernhard F. Kraft on 06.07.18.
//

import UIKit

protocol cardViewDataSource: class {
    func getGridDimensions() -> (cellCount: Int, aspectRatio: CGFloat)
    func getDealtCards() -> [SetCard]
}

class CardView: UIView {

    //    *****************
    //    MARK: properties
    //    *****************

    weak var delegate:cardViewDataSource?
    var gameButtons = [UIButton]()
    var grid = Grid(layout: .dimensions(rowCount: 1, columnCount: 1))
    var animator:UIViewPropertyAnimator!
    let buttonInset = UIEdgeInsets.init(top: Constants.insets, left: Constants.insets, bottom: Constants.insets, right: Constants.insets)

    //    *****************
    //    MARK: lifecycle Functions
    //    *****************
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let _ = animator {
            if !animator.isRunning {
                updateViewFromModel()
            }
        } else{
            updateViewFromModel()
        }

    }

    override func draw(_ rect: CGRect) {

        UIColor.green.setFill()
        UIColor.blue.setStroke()
        var shapeFunction: (CGRect) -> UIBezierPath

        for idx in 0 ..< delegate!.getDealtCards().count {
            shapeFunction = {
                switch self.delegate!.getDealtCards()[idx].decoration[1] {
                case 0:
                    return self.createCircle($0)
                case 1:
                    return self.createDiamond($0)
                case 2:
                    return self.createOval($0)
                default:
                    return self.createCircle($0)
                }
            }//shape function closure
 
            let button = UIButton()
            button.frame = grid[idx]!.inset(by: buttonInset)
            button.backgroundColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
            button.isHidden = false

            let shapeToDraw = shapeFunction(button.frame)
            shapeToDraw.stroke()
            shapeToDraw.fill()

            button.addTarget(delegate, action: Selector(("touchCard:")), for: .touchUpInside)
            self.addSubview(button)
            gameButtons.append(button)

//        let cages = Grid.init(layout:.dimensions(rowCount: getDimensionsForCell(rect).rowCount, columnCount: getDimensionsForCell(rect).columnCount) , frame: rect)
//        for idx in 0..<cages.cellCount{
//            let shapeToDraw = shapeFunction(cages[idx]!)
//            shapeToDraw.stroke()
//            shapeToDraw.fill()
//        }

        }//for loop: dealt cards
    }//func

    //    *****************
    //    MARK Functions
    //    *****************
    
    private func updateViewFromModel(){
        
        self.grid = Grid(layout: .aspectRatio(delegate!.getGridDimensions().aspectRatio))
        grid.cellCount = (delegate!.getGridDimensions().cellCount)

        for view in self.subviews{
            view.removeFromSuperview()
        }
        gameButtons.removeAll()
        grid.frame = self.bounds
//        self.setNeedsDisplay()

    }
    
    func buttonFormatNotSelected(button: UIButton){
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 0.2
        button.mask?.clipsToBounds = true
        button.layer.borderColor = #colorLiteral(red: 0.1294117719, green: 0.2156862766, blue: 0.06666667014, alpha: 0)
//        button.setBackgroundImage(UIImage(named: "white")!, for: UIControl.State .normal)
    }
    
    func buttonFormatSelected(button: UIButton){
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 3.0
        button.mask?.clipsToBounds = true
        button.layer.borderColor = #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1)
//        button.setBackgroundImage(UIImage(named: "white")!, for: UIControl.State .normal)
    }
    
    private func createDiamond(_ rect: CGRect) -> UIBezierPath{
        let diamond = UIBezierPath()
        let axis = (min(rect.width, rect.height) * 0.9)/2
        let center = getCenter(rect)
        let p1 = CGPoint(x: center.x, y: center.y - axis)
        let p2 = CGPoint(x: center.x + axis, y: center.y)
        let p3 = CGPoint(x: center.x, y: center.y + axis)
        let p4 = CGPoint(x: center.x - axis, y: center.y)
        diamond.move(to: p1)
        diamond.addLine(to: p2)
        diamond.addLine(to: p3)
        diamond.addLine(to: p4)
        diamond.close()
        return diamond
    }
    
    private func createOval(_ rect: CGRect) -> UIBezierPath{
        let oval = UIBezierPath()
        let p1 = CGPoint(x: rect.origin.x + 0.75 * rect.size.width, y: rect.origin.y + 2*cardInset(rect))
        let p2 = CGPoint(x: p1.x, y: rect.origin.y + rect.height - 2*cardInset(rect))
        let p3 = CGPoint(x: rect.origin.x + 0.25 * rect.size.width, y: p2.y)
        let p4 = CGPoint(x: p3.x, y:p1.y)
        let cp1 = CGPoint(x: rect.origin.x + rect.size.width - cardInset(rect)/2, y: rect.origin.y + rect.height/2)
        let cp2 = CGPoint(x: rect.origin.x + rect.size.width/2, y: rect.origin.y + rect.size.height - cardInset(rect)/2)
        let cp3 = CGPoint(x: rect.origin.x + cardInset(rect)/2, y: cp1.y)
        let cp4 = CGPoint(x: cp2.x, y: rect.origin.y + cardInset(rect)/2)
        oval.move(to: p1)
        oval.addQuadCurve(to: p2, controlPoint: cp1)
        oval.addQuadCurve(to: p3, controlPoint: cp2)
        oval.addQuadCurve(to: p4, controlPoint: cp3)
        oval.addQuadCurve(to: p1, controlPoint: cp4)
        oval.lineJoinStyle = .round
        return oval
    }
    
    private func createCircle(_ rect: CGRect) -> UIBezierPath{
        let circle = UIBezierPath()
        let center = getCenter(rect)
        let radius = min(rect.width, rect.height)/2 * 0.9
        circle.addArc(withCenter: center, radius: radius, startAngle: 0.0, endAngle: 2*CGFloat.pi, clockwise: false)
        return circle
    }

}

private struct Constants{
    static let insets = CGFloat(6.0)
}

extension CardView{
    private struct SetViewRatios {
        static let frameInsetRatio: CGFloat = 0.08
        static let maxSymbolsPerCard = 3
    }
    
    private func cardInset (_ rect: CGRect) -> CGFloat{
        return (rect.width + rect.height)/2 * SetViewRatios.frameInsetRatio
    }
    private func symbolBounds (_ bounds: CGRect) -> CGRect{
        let symbolFrame = bounds.inset(by: UIEdgeInsets.init(top: cardInset(bounds), left: cardInset(bounds), bottom: cardInset(bounds), right: cardInset(bounds)))
        return symbolFrame
    }
    private func getCenter (_ rect:CGRect) -> CGPoint{
        return CGPoint(x: rect.midX, y: rect.midY)
    }
}
