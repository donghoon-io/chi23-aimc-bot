//
//  loginInstaViewController.swift
//  HelloBot
//
//  Created by Donghoon Shin on 2022/07/16.
//

import UIKit
import Combine
import WebKit
import ComposableRequest
import ComposableRequestCrypto
import Swiftagram
import SwiftagramCrypto
import ANLoader

class LoginInstaViewController: UIViewController, isAbleToReceiveData {
    
    var delegate: isAbleToReceiveData?
    
    var identifier: String?
    var secret: Secret?
    
    var posts = [String]()
    var postsCounter = [String]()
    
    var comments = [String]()
    
    var themes = [String]()
    var finalThemes = [String]()
    
    @IBAction func loginButtonClicked(_ sender: UIButton) {
        print("Login clicked")
        let vc = LoginViewController()
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func pass(id: String, sec: Secret) {
        identifier = id
        secret = sec
        
        Endpoint.Media.Posts.owned(by: sec.identifier).unlocking(with: sec).task(maxLength: .max, by: .instagram) { (yaya) in
            ANLoader.hide()
            print(self.posts)
            
            self.performSegue(withIdentifier: "goMatching", sender: self)
            
            
        } onChange: { (result) in
            switch result {
            case .success(let posts):
                if let post = posts.media {
                    self.posts += post.map { (media) -> String in
                        return media.caption?.text ?? ""
                    }
                }
                
            case .failure(let error):
                let alertController = UIAlertController(title: error.localizedDescription, message: "실험 주관인에게 문의하시오", preferredStyle: .actionSheet)
                alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }
        }.resume()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
