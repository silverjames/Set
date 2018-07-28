//
//  CardView.swift
//  Set
//
//  Created by Bernhard F. Kraft on 28.07.18.
//  Copyright © 2018 Bernhard F. Kraft. All rights reserved.
//

import UIKit

class CardView: UIView {

    enum cColor: Int{
        case green = 0, red, blue
    }
    enum cShape: Int{
        case circle = 0, diamond, squiggle
    }
    enum cFill: Int{
        case unfilled = 0, striped, solid
    }
    enum cNumber: Int{
        case one = 0, two, three
    }
    //    *****************
    //    MARK: properties
    //    *****************
    var cardNumber:cNumber
    var cardShape:cShape
    var cardFill:cFill
    var cardColor:cColor
    
    //    *******************************
    //    MARK: class overrides
    //    *******************************
    override init (frame:CGRect) {
        self.cardNumber = .one
        self.cardShape = .circle
        self.cardFill = .solid
        self.cardColor = .red
        super.init(frame : frame)
    }
    convenience init (frame:CGRect, cardNumber number:Int, cardShape shape:Int, cardFill fill:Int, cardColor color:Int) {
        self.init(frame: frame)
        self.cardNumber = cNumber(rawValue: number)!
        self.cardShape = cShape(rawValue: shape)!
        self.cardFill = cFill(rawValue: fill)!
        self.cardColor = cColor(rawValue: color)!
        self.backgroundColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.isHidden = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.cardNumber = .one
        self.cardShape = .circle
        self.cardFill = .solid
        self.cardColor = .red
        super.init(coder: aDecoder)
    }

    override func draw(_ rect: CGRect) {

        //draw card border and background
        let cardBorderColor:UIColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
        let cardBackgroundColor:UIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        let cardUIborder = UIBezierPath(roundedRect: self.bounds, cornerRadius: CardRatios.cardCornerRadius)
        cardBorderColor.setStroke()
        cardBackgroundColor.setFill()
        cardUIborder.stroke()
        cardUIborder.fill()

        // Draw card face
        var shapeFunction: (CGRect) -> UIBezierPath
        let cages = Grid.init(layout:.dimensions(rowCount: 3, columnCount: 1) , frame: self.bounds)

        shapeFunction = {
            switch self.cardShape {
            case .circle:
                return self.createCircle($0)
            case .diamond:
                return self.createDiamond($0)
            case .squiggle:
                return self.createOval($0)
            }
        }//shape function closure
        
        
        
    }//draw rect

    //    *******************************
    //    MARK: class functions
    //    *******************************
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

    private func getCenter (_ rect:CGRect) -> CGPoint{
        return CGPoint(x: rect.midX, y: rect.midY)
    }
    private func cardInset (_ rect: CGRect) -> CGFloat{
        return (rect.width + rect.height)/2 * CardRatios.frameInsetRatio
    }
    private func symbolBounds (_ bounds: CGRect) -> CGRect{
        let symbolFrame = bounds.inset(by: UIEdgeInsets.init(top: cardInset(bounds), left: cardInset(bounds), bottom: cardInset(bounds), right: cardInset(bounds)))
        return symbolFrame
    }

    private struct CardRatios {
        static let frameInsetRatio: CGFloat = 0.08
        static let maxSymbolsPerCard = 3
        static let cardCornerRadius:CGFloat = 8.0
        static let insets = CGFloat(6.0)
        static let cagesPerButton = 3
    }
}
