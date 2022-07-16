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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        idTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)

        nextButton.disable()
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if let txt = textField.text {
            if txt.matches(#"P\d\d"#) || txt.matches(#"p\d\d"#) {
                nextButton.enable()
            } else {
                nextButton.disable()
            }
        }
        else {
            nextButton.disable()
        }
    }

    //P\d\d

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
