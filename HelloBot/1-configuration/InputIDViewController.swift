//
//  0-1-inputIDViewController.swift
//  HelloBot
//
//  Created by Donghoon Shin on 2022/07/16.
//h

import UIKit
import TweeTextField


class InputIDViewController: UIViewController {
    
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var idTextField: TweeBorderedTextField!
    
    @IBAction func nextButtonClicked(_ sender: UIButton) {
        experimentID = self.idTextField.text ?? ""
        switch experimentID.prefix(1) {
        case "1": // AI
            self.performSegue(withIdentifier: "goInstaLogin", sender: self)
        case "2": // Conversation
            self.performSegue(withIdentifier: "goConversationConnection", sender: self)
        default: // No conversation
            self.performSegue(withIdentifier: "goWithoutConversationConnection", sender: self)
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        idTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)

        nextButton.disable()
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if let txt = textField.text {
            if txt.matches(#"\d{3}"#) && txt.count == 3 {
                nextButton.enable()
            } else {
                nextButton.disable()
            }
        }
        else {
            nextButton.disable()
        }
    }
}
