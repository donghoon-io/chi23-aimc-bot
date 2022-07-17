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
    var post_images = [String]()
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
            
            
            self.performSegue(withIdentifier: "goMatching", sender: self)
            
        } onChange: { (result) in
            switch result {
            case .success(let posts):
                if let post = posts.media {
                    self.posts += post.map({ media in
                        return media.caption?.text ?? ""
                    })
                    self.post_images += post.map({ media in
                        return media.code ?? ""
                    })
                }
                
            case .failure(let error):
                let alertController = UIAlertController(title: error.localizedDescription, message: "실험 주관인에게 문의하시오", preferredStyle: .actionSheet)
                alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }
        }.resume()
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goMatching" {
            if let nextViewController = segue.destination as? TopicMatchingViewController {
                nextViewController.images = self.post_images
                nextViewController.captions = self.posts
                nextViewController.identifier = self.identifier
                nextViewController.secret = self.secret
            }
        }
    }
}
