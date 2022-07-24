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
import SwiftyJSON
import FirebaseFirestore
import Alamofire

class LoginInstaViewController: UIViewController, isAbleToReceiveData {
    
    var participant1 = "https://aimc-bot-qlnau.run.goorm.io/"
    var participant2 = "https://aimc-bot-qlnau.run.goorm.io/"
    
    let db = Firestore.firestore()
    
    var delegate: isAbleToReceiveData?
    
    var isDone = false
    
    var identifier: String?
    var secret: Secret?
    
    var posts = [String]()
    var post_images = [String]()
    var postsCounter = [String]()
    
    var comments = [String]()
    
    var themes = [String]()
    var organized_post_images = [String]()
    var finalThemes = [String]()
    
    @IBOutlet weak var loginButton: UIButton!
    @IBAction func loginButtonClicked(_ sender: UIButton) {
        print("Login clicked")
        
        self.loginButton.disable()
        
        let vc = LoginViewController()
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func pass(id: String, sec: Secret) {
        identifier = id
        secret = sec
        
        Endpoint.Media.Posts.owned(by: sec.identifier).unlocking(with: sec).task(maxLength: .max, by: .instagram) { (yaya) in
            ANLoader.hide()
            ANLoader.showLoading("상대방과 연결 중...", disableUI: true)
            
            self.db.collection("user_data").document(experimentID).setData(["captions": self.posts]) { (error) in
                if let error = error {
                    self.showError(error: error, button: self.loginButton)
                    return
                } else {
                    ANLoader.hide()
                    ANLoader.showLoading("상대방과의 공통된\n관심사 계산 중...", disableUI: true)
                    
                    self.db.collection("user_data").document(counterID()).getDocument { (snapshot, error) in
                        if let error = error {
                            self.showError(error: error, button: self.loginButton)
                        } else {
                            if let data = snapshot?.get("captions") as? [String] {
                                self.postsCounter = data
                                var parameters = [String:[String]]()
                                if isMyIdEven() {
                                    parameters = ["sentences1": self.postsCounter, "sentences2": self.posts]
                                } else {
                                    parameters = ["sentences1": self.posts, "sentences2": self.postsCounter]
                                }
                                AF.request(isMyIdEven() ? self.participant1 : self.participant2,
                                           method: .post,
                                           parameters: parameters,
                                           encoder: JSONParameterEncoder.default).response { response in
                                    ANLoader.hide()
                                    switch response.result {
                                    case .success(let data):
                                        if let themes = JSON(data)["keywords"].arrayObject as? [[String]] {
                                            self.themes = themes.compactMap({ str_data in
                                                return str_data[2]
                                            })
                                            self.organized_post_images = themes.compactMap({ str_data in
                                                self.post_images[(isMyIdEven() ? Int(str_data[1]) : Int(str_data[0]))!]
                                            })
                                            self.goSegue("goMatching")
                                        }
                                    case .failure(let error):
                                        self.showError(error: error, button: self.loginButton)
                                    }
                                }
                            } else {
                                ANLoader.hide()
                                ANLoader.showLoading("상대방을 기다리는 중...", disableUI: true)
                                self.db.collection("user_data").document(counterID()).addSnapshotListener { (snapshot2, error2) in
                                    if !self.isDone {
                                        if let err2 = error2 {
                                            self.showError(error: err2, button: self.loginButton)
                                        } else {
                                            if let counterTheme1 = snapshot2?.get("captions") as? [String] {
                                                self.postsCounter = counterTheme1
                                                var parameters = [String:[String]]()
                                                if isMyIdEven() {
                                                    parameters = ["sentences1": self.postsCounter, "sentences2": self.posts]
                                                } else {
                                                    parameters = ["sentences1": self.posts, "sentences2": self.postsCounter]
                                                }
                                                AF.request(isMyIdEven() ? self.participant1 : self.participant2,
                                                           method: .post,
                                                           parameters: parameters,
                                                           encoder: JSONParameterEncoder.default).response { response in
                                                    ANLoader.hide()
                                                    switch response.result {
                                                    case .success(let data):
                                                        if let themes = JSON(data)["keywords"].arrayObject as? [[String]] {
                                                            self.themes = themes.compactMap({ str_data in
                                                                return str_data[2]
                                                            })
                                                            self.organized_post_images = themes.compactMap({ str_data in
                                                                self.post_images[(isMyIdEven() ? Int(str_data[1]) : Int(str_data[0]))!]
                                                            })
                                                            
                                                            //success
                                                            self.loginButton.enable()
                                                            self.isDone = true
                                                            self.goSegue("goMatching")
                                                        }
                                                    case .failure(let error):
                                                        self.showError(error: error, button: self.loginButton)
                                                    }
                                                }
                                                ANLoader.hide()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } onChange: { (result) in
            switch result {
            case .success(let posts):
                if let post = posts.media {
                    self.posts += post.map({ media in
                        return media.caption?.text ?? ""
                    })
                    self.post_images += post.map({ media in
                        switch media.content {
                        case .picture(let pic):
                            if let imgs = pic.images, let url = imgs[0].url {
                                return url.absoluteString
                            }
                        case .album(let alb):
                            let head_img = alb[0]
                            switch head_img {
                            case .picture(let pic):
                                if let imgs = pic.images, let url = imgs[0].url {
                                    return url.absoluteString
                                }
                            case .video(let vid):
                                if let imgs = vid.images, let url = imgs[0].url {
                                    return url.absoluteString
                                }
                            default:
                                return media.code ?? ""
                            }
                        case .video(let vid):
                            if let imgs = vid.images, let url = imgs[0].url {
                                return url.absoluteString
                            }
                        default: print("not supported");
                        }
                        return media.code ?? ""
                    })
                }
                
            case .failure(let error):
                self.showError(error: error, button: self.loginButton)
                
                return
            }
        }.resume()
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goMatching" {
            if let nextViewController = segue.destination as? TopicMatchingViewController {
                nextViewController.images = self.organized_post_images
                nextViewController.captions = self.posts
                nextViewController.identifier = self.identifier
                nextViewController.secret = self.secret
                nextViewController.themes = self.themes
            }
        }
    }
}
