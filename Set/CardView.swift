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

//    override func draw(_ rect: CGRect) {
//    }

    //    *****************
    //    MARK Functions
    //    *****************
//    @objc func touchCard(sender:UIButton){
//        print("button pressed!")
//    }
    
    func updateViewFromModel(){
        
        self.grid = Grid(layout: .aspectRatio(delegate!.getGridDimensions().aspectRatio))
        grid.cellCount = (delegate!.getGridDimensions().cellCount)

        for view in self.subviews{
            view.removeFromSuperview()
        }
        gameButtons.removeAll()
        grid.frame = self.bounds
        
        for idx in 0 ..< delegate!.getDealtCards().count {
            let button = UIButton()
            button.setTitle("😀", for: .normal)
            button.frame = grid[idx]!.inset(by: buttonInset)
            button.backgroundColor = #colorLiteral(red: 0.1215686277, green: 0.01176470611, blue: 0.4235294163, alpha: 1)
            button.isHidden = false
            button.addTarget(delegate, action: Selector(("touchCard:")), for: .touchUpInside)
            self.addSubview(button)
            gameButtons.append(button)
        }

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

}

private struct Constants{
    static let insets = CGFloat(6.0)
}
