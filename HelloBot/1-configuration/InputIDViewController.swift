//
//  0-1-inputIDViewController.swift
//  HelloBot
//
//  Created by Donghoon Shin on 2022/07/16.
//h

import UIKit


class InputIDViewController: UIViewController {
    
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var idTextField: UITextField!
    
    @IBAction func nextButtonClicked(_ sender: UIButton) {
        experimentID = self.idTextField.text ?? ""
        self.performSegue(withIdentifier: "goInstaLogin", sender: self)
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
