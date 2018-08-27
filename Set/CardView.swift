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
    var isFaceUp:Bool = false {didSet {setNeedsDisplay()}}
    var dimension:CGRect {
        get {
            return self.frame
        }
    }
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
        self.layer.backgroundColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 0)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.isHidden = false
        self.contentMode = .redraw
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.cardNumber = .one
        self.cardShape = .squiggle
        self.cardFill = .solid
        self.cardColor = .purple
        super.init(coder: aDecoder)
    }

    override func draw(_ rect: CGRect) {
//        print ("cv: draw")
        //draw card border and background
        let cardBorderColor = #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 0)
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
        
        if isFaceUp {
            drawCardFace(rect)
        } else {
            drawCardBack(rect)
        }
        
    }//draw rect

    //    *******************************
    //    MARK: class functions
    //    *******************************
    private func drawCardFace (_ rect:CGRect){
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
        
        //determine fill
        switch self.cardFill {
        case .solid:
            currentPrimaryColor.setFill()
        case .striped:
            currentSecondaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
//            currentSecondaryColor = currentPrimaryColor.withAlphaComponent(0.3)
//            currentSecondaryColor.setFill()
        case .unfilled:
            currentSecondaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
            currentSecondaryColor.setFill()
        }

        shapes.forEach {
            $0.lineWidth = CardRatios.symbolLineWidth
            switch self.cardFill{
            case .solid, .unfilled:
                $0.fill()
                $0.stroke()
            case .striped:
                let context = UIGraphicsGetCurrentContext()
                context?.saveGState()
                $0.addClip()
                let stepperSize = $0.bounds.width/CardRatios.stripeCount
                for x in stride(from: $0.bounds.minX + stepperSize, to: $0.bounds.maxX, by: stepperSize) {
                    $0.move(to: CGPoint(x: x, y: $0.bounds.minY))
                    $0.addLine(to: CGPoint(x: x, y: $0.bounds.maxY))
                }
                $0.stroke()
                context?.restoreGState()
            }//switch
        }//for each shape
    }
    
    private func drawCardBack (_ rect:CGRect){
        let cardBackView = UIImageView.init(image: UIImage(named: "cardback"))
        cardBackView.frame = rect
        cardBackView.contentMode = .scaleToFill
        self.addSubview(cardBackView)
    }
    
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
        let cp3 = CGPoint(x: rect.origin.x + cardInset(rect)/2, y: cp1.y)
        oval.move(to: p1)
        oval.addQuadCurve(to: p2, controlPoint: cp1)
        oval.addLine(to: p3)
        oval.addQuadCurve(to: p4, controlPoint: cp3)
        oval.addLine(to: p1)
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

    private func getCenter (_ rect:CGRect) -> CGPoint{
        return CGPoint(x: rect.midX, y: rect.midY)
    }

    private func cardInset (_ rect: CGRect) -> CGFloat{
        return (rect.width + rect.height)/2 * CardRatios.frameInsetRatio
    }

    private struct CardRatios {
        static let symbolLineWidth: CGFloat = 1.8
        static let frameInsetRatio: CGFloat = 0.08
        static let cardCornerRadius:CGFloat = 8.0
        static let cardBorderLineWidth:CGFloat = 4.0
        static let diamondfactor:CGFloat = 0.7
        static let insets = CGFloat(4.0)
        static let stripeCount = CGFloat(11)
       static let p1_dx = CGFloat(0.5092592592592593)
       static let p1_dy = CGFloat(0.15300546448087432)
       static let p2_dx = CGFloat(0.8734567901234568)
       static let p2_dy = CGFloat(0.13114754098360656)
       static let p3_dx = CGFloat(0.9583333333333334)
       static let p3_dy = CGFloat(0.27049180327868855)
       static let p4_dx = CGFloat(0.7222222222222222)
       static let p4_dy = CGFloat(0.7049180327868853)
       static let p5_dx = CGFloat(0.18209876543209877)
       static let p5_dy = CGFloat(0.7486338797814208)
       static let p6_dx = CGFloat(0.047839506172839504)
       static let p6_dy = CGFloat(0.5737704918032787)
       static let cp1_dx = CGFloat(0.7592592592592593)
       static let cp1_dy = CGFloat(0.273224043715847)
       static let cp2_dx = CGFloat(0.9722222222222222)
       static let cp2_dy = CGFloat(0.030054644808743168)
       static let cp3_dx = CGFloat(0.9212962962962963)
       static let cp3_dy = CGFloat(0.587431693989071)
       static let cp4_dx = CGFloat(0.7916666666666666)
       static let cp4_dy = CGFloat(0.7404371584699454)
       static let cp5_dx = CGFloat(0.38580246913580246)
       static let cp5_dy = CGFloat(0.5136612021857924)
       static let cp6_dx = CGFloat(0.2191358024691358)
       static let cp6_dy = CGFloat(0.6885245901639344)
       static let cp7_dx = CGFloat(0.046296296296296294)
       static let cp7_dy = CGFloat(0.9781420765027322)
       static let cp8_dx = CGFloat(0.06018518518518518)
       static let cp8_dy = CGFloat(0.1885245901639344)
       static let cp9_dx = CGFloat(0.19135802469135801)
       static let cp9_dy = CGFloat(0.03551912568306011)
    }
}
