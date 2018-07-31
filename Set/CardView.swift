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
        case green = 0, red, purple
    }
    enum cShape: Int{
        case oval = 0, diamond, squiggle
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
    var selected:Bool = false {didSet {setNeedsDisplay()}}
    private let setSymbolInset = UIEdgeInsets.init(top: CardRatios.insets, left: CardRatios.insets, bottom: CardRatios.insets, right: CardRatios.insets)

    //    *******************************
    //    MARK: class overrides
    //    *******************************
    override init (frame:CGRect) {
        self.cardNumber = .one
        self.cardShape = .squiggle
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
        self.backgroundColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 0)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.isHidden = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.cardNumber = .one
        self.cardShape = .squiggle
        self.cardFill = .solid
        self.cardColor = .purple
        super.init(coder: aDecoder)
    }

    override func draw(_ rect: CGRect) {
        print ("cv: draw")
        //draw card border and background
        let cardBorderColor = #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1)
        var cardBackgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        if selected {
            cardBackgroundColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
        }
        
        let cardUIborder = UIBezierPath(roundedRect: self.bounds, cornerRadius: CardRatios.cardCornerRadius)
        cardUIborder.lineWidth = CardRatios.cardBorderLineWidth
        cardBorderColor.setStroke()
        cardBackgroundColor.setFill()
        cardUIborder.stroke()
        cardUIborder.fill()

        // Draw card face
        var shapeFunction: (CGRect) -> UIBezierPath
        let cages = Grid.init(layout:.dimensions(rowCount: 3, columnCount: 1) , frame: self.bounds)

        //determine shape
        shapeFunction = {
            switch self.cardShape {
            case .squiggle:
                return self.createSquiggle($0)
            case .diamond:
                return self.createDiamond($0)
            case .oval:
                return self.createOval($0)
            }
        }//shape function closure

        //determine color
        var currentPrimaryColor:UIColor
        var currentSecondaryColor:UIColor
        switch self.cardColor {
        case .purple:
            currentPrimaryColor = UIColor.purple
        case .red:
            currentPrimaryColor = UIColor.red
        case .green:
            currentPrimaryColor = UIColor.green
         }
        currentPrimaryColor.setStroke()
        
        //determine fill
        switch self.cardFill {
        case .solid:
            currentPrimaryColor.setFill()
        case .striped:
            currentSecondaryColor = currentPrimaryColor.withAlphaComponent(0.3)
            currentSecondaryColor.setFill()
        case .unfilled:
            currentSecondaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
            currentSecondaryColor.setFill()
        }

        //consider the number of symbols per card
        var shapes = [UIBezierPath]()
        switch self.cardNumber {
        case .one:
            shapes.append(shapeFunction(cages[1]!.inset(by: setSymbolInset)))
        case .two:
            shapes.append(shapeFunction(cages[0]!.inset(by: setSymbolInset)))
            shapes.append(shapeFunction(cages[2]!.inset(by: setSymbolInset)))
        case .three:
            shapes.append(shapeFunction(cages[0]!.inset(by: setSymbolInset)))
            shapes.append(shapeFunction(cages[1]!.inset(by: setSymbolInset)))
            shapes.append(shapeFunction(cages[2]!.inset(by: setSymbolInset)))
        }
        shapes.forEach {
            $0.lineWidth = CardRatios.symbolLineWidth
            $0.stroke()
            $0.fill()
        }
        
        
    }//draw rect

    //    *******************************
    //    MARK: class functions
    //    *******************************
    private func createDiamond(_ rect: CGRect) -> UIBezierPath{
        let diamond = UIBezierPath()
        let axis = (min(rect.width, rect.height) * 0.9)/2
        let center = getCenter(rect)
        let p1 = CGPoint(x: center.x, y: center.y - axis)
        let p2 = CGPoint(x: center.x + axis/CardRatios.diamondfactor, y: center.y)
        let p3 = CGPoint(x: center.x, y: center.y + axis)
        let p4 = CGPoint(x: center.x - axis/CardRatios.diamondfactor, y: center.y)
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
//        let cp2 = CGPoint(x: rect.origin.x + rect.size.width/2, y: rect.origin.y + rect.size.height - cardInset(rect)/2)
        let cp3 = CGPoint(x: rect.origin.x + cardInset(rect)/2, y: cp1.y)
//        let cp4 = CGPoint(x: cp2.x, y: rect.origin.y + cardInset(rect)/2)
        oval.move(to: p1)
        oval.addQuadCurve(to: p2, controlPoint: cp1)
        oval.addLine(to: p3)
//        oval.addQuadCurve(to: p3, controlPoint: cp2)
        oval.addQuadCurve(to: p4, controlPoint: cp3)
        oval.addLine(to: p1)
//        oval.addQuadCurve(to: p1, controlPoint: cp4)
        oval.lineJoinStyle = .round
        return oval
    }
  
    private func createSquiggle(_ rect: CGRect) -> UIBezierPath{
        let squiggle = UIBezierPath()
        let p1 = CGPoint(x: rect.origin.x + CardRatios.p1_dx * rect.width, y: rect.origin.y + CardRatios.p1_dy * rect.height)
        let p2 = CGPoint(x: rect.origin.x + CardRatios.p2_dx * rect.width, y: rect.origin.y + CardRatios.p2_dy * rect.height)
        let p3 = CGPoint(x: rect.origin.x + CardRatios.p3_dx * rect.width, y: rect.origin.y + CardRatios.p3_dy * rect.height)
        let p4 = CGPoint(x: rect.origin.x + CardRatios.p4_dx * rect.width, y: rect.origin.y + CardRatios.p4_dy * rect.height)
        let p5 = CGPoint(x: rect.origin.x + CardRatios.p5_dx * rect.width, y: rect.origin.y + CardRatios.p5_dy * rect.height)
        let p6 = CGPoint(x: rect.origin.x + CardRatios.p6_dx * rect.width, y: rect.origin.y + CardRatios.p6_dy * rect.height)
        let cp1 = CGPoint(x: rect.origin.x + CardRatios.cp1_dx * rect.width, y: rect.origin.y + CardRatios.cp1_dy * rect.height)
        let cp2 = CGPoint(x: rect.origin.x + CardRatios.cp2_dx * rect.width, y: rect.origin.y + CardRatios.cp2_dy * rect.height)
        let cp3 = CGPoint(x: rect.origin.x + CardRatios.cp3_dx * rect.width, y: rect.origin.y + CardRatios.cp3_dy * rect.height)
        let cp4 = CGPoint(x: rect.origin.x + CardRatios.cp4_dx * rect.width, y: rect.origin.y + CardRatios.cp4_dy * rect.height)
        let cp5 = CGPoint(x: rect.origin.x + CardRatios.cp5_dx * rect.width, y: rect.origin.y + CardRatios.cp5_dy * rect.height)
        let cp6 = CGPoint(x: rect.origin.x + CardRatios.cp6_dx * rect.width, y: rect.origin.y + CardRatios.cp6_dy * rect.height)
        let cp7 = CGPoint(x: rect.origin.x + CardRatios.cp7_dx * rect.width, y: rect.origin.y + CardRatios.cp7_dy * rect.height)
        let cp8 = CGPoint(x: rect.origin.x + CardRatios.cp8_dx * rect.width, y: rect.origin.y + CardRatios.cp8_dy * rect.height)
        let cp9 = CGPoint(x: rect.origin.x + CardRatios.cp9_dx * rect.width, y: rect.origin.y + CardRatios.cp9_dy * rect.height)

        squiggle.move(to: p1)
        squiggle.addQuadCurve(to: p2, controlPoint: cp1)
        squiggle.addQuadCurve(to: p3, controlPoint: cp2)
        squiggle.addCurve(to: p4, controlPoint1: cp3, controlPoint2: cp4)
        squiggle.addCurve(to: p5, controlPoint1: cp5, controlPoint2: cp6)
        squiggle.addQuadCurve(to: p6, controlPoint: cp7)
        squiggle.addCurve(to: p1, controlPoint1: cp8, controlPoint2: cp9)
        squiggle.lineJoinStyle = .round
        return squiggle
    }

//    private func createCircle(_ rect: CGRect) -> UIBezierPath{
//        let circle = UIBezierPath()
//        let center = getCenter(rect)
//        let radius = min(rect.width, rect.height)/2 * 0.9
//        circle.addArc(withCenter: center, radius: radius, startAngle: 0.0, endAngle: 2*CGFloat.pi, clockwise: false)
//        return circle
//    }

    private func getCenter (_ rect:CGRect) -> CGPoint{
        return CGPoint(x: rect.midX, y: rect.midY)
    }
    private func cardInset (_ rect: CGRect) -> CGFloat{
        return (rect.width + rect.height)/2 * CardRatios.frameInsetRatio
    }

    private struct CardRatios {
        static let symbolLineWidth: CGFloat = 3.0
        static let frameInsetRatio: CGFloat = 0.08
        static let cardCornerRadius:CGFloat = 8.0
        static let cardBorderLineWidth:CGFloat = 4.0
        static let diamondfactor:CGFloat = 0.7
        static let insets = CGFloat(4.0)
        static let p1_dx = CGFloat(0.5092592592592593)
        static let p1_dy = CGFloat(0.2814207650273224)
        static let p2_dx = CGFloat(0.6944444444444444)
        static let p2_dy = CGFloat(0.22131147540983606)
        static let p3_dx = CGFloat(0.7530864197530864)
        static let p3_dy = CGFloat(0.27049180327868855)
        static let p4_dx = CGFloat(0.6280864197530864)
        static let p4_dy = CGFloat(0.5437158469945356)
        static let p5_dx = CGFloat(0.23148148148148148)
        static let p5_dy = CGFloat(0.6092896174863388)
        static let p6_dx = CGFloat(0.18518518518518517)
        static let p6_dy = CGFloat(0.4098360655737705)
        static let cp1_dx = CGFloat(0.6172839506172839)
        static let cp1_dy = CGFloat(0.3224043715846995)
        static let cp2_dx = CGFloat(0.7407407407407407)
        static let cp2_dy = CGFloat(0.17759562841530055)
        static let cp3_dx = CGFloat(0.7669753086419753)
        static let cp3_dy = CGFloat(0.32786885245901637)
        static let cp4_dx = CGFloat(0.7160493827160493)
        static let cp4_dy = CGFloat(0.546448087431694)
        static let cp5_dx = CGFloat(0.42746913580246915)
        static let cp5_dy = CGFloat(0.5519125683060109)
        static let cp6_dx = CGFloat(0.41975308641975306)
        static let cp6_dy = CGFloat(0.4098360655737705)
        static let cp7_dx = CGFloat(0.16358024691358025)
        static let cp7_dy = CGFloat(0.6311475409836066)
        static let cp8_dx = CGFloat(0.21296296296296297)
        static let cp8_dy = CGFloat(0.2677595628415301)
        static let cp9_dx = CGFloat(0.27314814814814814)
        static let cp9_dy = CGFloat(0.1092896174863388)
    }
}
