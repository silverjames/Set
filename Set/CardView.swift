//
//  CardView.swift
//  
//
//  Created by Bernhard F. Kraft on 06.07.18.
//

import UIKit

protocol cardViewDataSource: class {
    func getGridDimensions() -> (rows: Int, columns: Int)
}

class CardView: UIView {

    //    *****************
    //    MARK: properies
    //    *****************
    
    weak var dataSource:cardViewDataSource?
    
    static let insets = CGFloat(6.0)
    let buttonInset = UIEdgeInsets.init(top: insets, left: insets, bottom: insets, right: insets)
    
    
    //    *****************
    //    MARK: lifecycle Functions
    //    *****************
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var grid = Grid(layout: .dimensions(rowCount: (dataSource?.getGridDimensions().rows)!, columnCount: (dataSource?.getGridDimensions().columns)!))

        for view in self.subviews{
            view.removeFromSuperview()
        }
        
        grid.frame = self.bounds

        for idx in 0 ..< grid.cellCount {
            let button = UIButton()
            button.setTitle("😀", for: .normal)
            button.frame = grid[idx]!.inset(by: buttonInset)
            button.backgroundColor = #colorLiteral(red: 0.1215686277, green: 0.01176470611, blue: 0.4235294163, alpha: 1)
            button.isHidden = false
            button.addTarget(nil, action: Selector(("touchCard:")), for: .allTouchEvents)
            self.addSubview(button)
        }
    }



    override func draw(_ rect: CGRect) {
    }
}
