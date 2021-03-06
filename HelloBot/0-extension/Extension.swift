//
//  extension.swift
//  HelloBot
//
//  Created by Donghoon Shin on 2022/07/16.
//

import Foundation
import UIKit
import ANLoader

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        let hex: String = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let scanner = Scanner(string: hex)
        if (hex.hasPrefix("#")) {
            scanner.scanLocation = 1
        }
        var color: UInt32 = 0
        scanner.scanHexInt32(&color)
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
    func toHexString() -> String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        return String(format:"#%06x", rgb)
    }
    
    static var disabledBackgroundColor: UIColor {
        return UIColor(red:0.92, green:0.93, blue:0.94, alpha:1.00)
    }
    static var disabledTextColor: UIColor {
        return UIColor(red:0.92, green:0.93, blue:0.94, alpha:1.00)
    }
    static var enabledBackgroundColor: UIColor {
        return UIColor(hex: "#e6e6e6")
    }
    static var enabledTextColor: UIColor {
        return UIColor(hex: "#333333")
    }
}

extension UIButton {
    func enable() {
        self.setTitleColor(.enabledTextColor, for: .normal)
        self.backgroundColor = .enabledTextColor
        self.isEnabled = true
        self.alpha = 1
        self.layer.cornerRadius = 15
        self.clipsToBounds = true
    }
    func disable() {
        self.setTitleColor(.enabledTextColor, for: .normal)
        self.backgroundColor = .enabledTextColor
        self.isEnabled = false
        self.alpha = 0.5
        self.layer.cornerRadius = 15
        self.clipsToBounds = true
    }
}

extension String {
    func matches(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }
}

extension UIViewController {
    func showAlert(_ err: String) {
        let alertController = UIAlertController(title: err, message: "?????? ??????????????? ???????????????", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "??????", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    func showError(error: Error, button: UIButton) {
        ANLoader.hide()
        button.enable()
        self.showAlert(error.localizedDescription)
    }
    func goSegue(_ id: String) {
        ANLoader.hide()
        self.performSegue(withIdentifier: id, sender: self)
    }
}
extension TimeInterval {

    var seconds: Int {
        return Int(self.rounded())
    }

    var milliseconds: Int {
        return Int(self * 1_000)
    }
}
func isMyIdEven() -> Bool {
    return Int(experimentID)! % 2 == 0
}

func counterID() -> String {
    return isMyIdEven() ? "\(Int(experimentID)!+1)" : "\(Int(experimentID)!-1)"
}
