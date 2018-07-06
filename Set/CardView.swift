//
//  CardView.swift
//  
//
//  Created by Bernhard F. Kraft on 06.07.18.
//

import UIKit

class CardView: UIView {

    //    *****************
    //    properies
    //    *****************
    var grid = Grid(layout: .dimensions(rowCount: 5, columnCount: 4))
    static let insets = CGFloat(6.0)
    
    //    let testButton = UIButton()
    let buttonInset = UIEdgeInsets.init(top: insets, left: insets, bottom: insets, right: insets)
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        for view in self.subviews{
            view.removeFromSuperview()
        }
        
        grid.frame = self.bounds
        grid.cellCount = 12
        print ("dealt card view frame: \(self.bounds)")

        for idx in 0 ..< grid.cellCount {
            let button = UIButton()
            button.setTitle("😀", for: .normal)
            button.frame = grid[idx]!.inset(by: buttonInset)
//            button.frame.inset(by: buttonInset)
            button.backgroundColor = #colorLiteral(red: 0.1215686277, green: 0.01176470611, blue: 0.4235294163, alpha: 1)
            button.isHidden = false
            self.addSubview(button)
        }
    }


    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
    }
}
