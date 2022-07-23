//
//  InitialMatchingViewController.swift
//  HelloBot
//
//  Created by Donghoon Shin on 2022/07/16.
//

import UIKit
import ANLoader
import TagListView
import FirebaseFirestore
import ComposableRequest
import ComposableRequestCrypto
import Swiftagram
import SwiftagramCrypto

class TopicMatchingViewController: UIViewController, TagListViewDelegate {

    @IBOutlet weak var tagListView: TagListView!
    @IBOutlet weak var tagHeight: NSLayoutConstraint!
    
    @IBOutlet weak var startButton: UIButton!
    
    let db = Firestore.firestore()
    
    var captions = [String]()
    var images = [String]()
    var identifier: String?
    var secret: Secret?
    
    var themes = [String]()
    
    var selectedThemes = [String]()
    
    var finalImages = [String]()
    var finalThemes = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tagListView.delegate = self
        setTagListView()
        createTag(themes)
        
        
        
        startButton.disable()
    }
    
    @IBAction func startButtonClicked(_ sender: UIButton) {
        self.startButton.disable()
        ANLoader.showLoading("상대방 기다리는 중...", disableUI: true)
        
        
        let counter = Int(experimentID)! % 2 == 0 ? "\(Int(experimentID)!+1)" : "\(Int(experimentID)!-1)"
        let counterDocument = self.db.collection("user_data").document(counter)
        
        
        if Int(experimentID)! % 2 == 0 {
            self.db.collection("user_data").document(experimentID).updateData(["keywords": self.selectedThemes]) { (error) in
                if let error = error {
                    self.startButton.enable()
                    self.showAlert(error.localizedDescription)
                    return
                } else {
                    counterDocument.getDocument { (snapshot1, error1) in
                        if let err = error1 {
                            self.startButton.enable()
                            self.showAlert(err.localizedDescription)
                        } else {
                            if let counterTheme = snapshot1?.get("keywords") as? [String] {
                                ANLoader.hide()
                                
                                self.performSegue(withIdentifier: "goChatting1", sender: self)
                            } else {
                                counterDocument.addSnapshotListener { (snapshot2, error2) in
                                    if let err2 = error2 {
                                        self.startButton.enable()
                                        self.showAlert(err2.localizedDescription)
                                    } else {
                                        if let counterTheme1 = snapshot2?.get("keywords") as? [String] {
                                            ANLoader.hide()
                                            
                                            self.performSegue(withIdentifier: "goChatting1", sender: self)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            createNewChat { (errrrr) in
                if let erer = errrrr {
                    self.startButton.enable()
                    self.showAlert(erer.localizedDescription)
                } else {
                    self.db.collection("user_data").document(experimentID).setData(["keywords": self.selectedThemes]) { (error) in
                        if let error = error {
                            self.startButton.enable()
                            self.showAlert(error.localizedDescription)
                            return
                        } else {
                            counterDocument.getDocument { (snapshot1, error1) in
                                if let err = error1 {
                                    self.showAlert(err.localizedDescription)
                                } else {
                                    if let counterTheme = snapshot1?.get("keywords") as? [String] {
                                        self.finalThemes = self.handleThemes(me: self.selectedThemes, counter: counterTheme)
                                        self.finalImages = self.finalThemes.map({ key in
                                            return self.images[self.themes.firstIndex(of: key)!]
                                        })
                                        ANLoader.hide()
                                        
                                        self.performSegue(withIdentifier: "goChatting1", sender: self)
                                    } else {
                                        counterDocument.addSnapshotListener { (snapshot2, error2) in
                                            if let err2 = error2 {
                                                self.startButton.enable()
                                                self.showAlert(err2.localizedDescription)
                                            } else {
                                                if let counterTheme1 = snapshot2?.get("keywords") as? [String] {
                                                    self.finalThemes = self.handleThemes(me: self.selectedThemes, counter: counterTheme1)
                                                    self.finalImages = self.finalThemes.map({ key in
                                                        return self.images[self.themes.firstIndex(of: key)!]
                                                    })
                                                    ANLoader.hide()
                                                    
                                                    self.performSegue(withIdentifier: "goChatting1", sender: self)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func handleThemes(me: [String], counter: [String]) -> [String] {
        let common = me.filter{ counter.contains($0) }
        let sum = me + counter
        let minus = sum.filter{ !common.contains($0) }
        return common.shuffled() + minus.shuffled()
    }
    
    func createNewChat(completionHandler: @escaping (_ err: Error?) -> ()) {
        let users = [experimentID, String(Int(experimentID)! % 2 == 0 ? Int(experimentID)!+1 : Int(experimentID)!-1), "bot"]
        let data: [String: Any] = [
            "users":users
        ]
        
        Firestore.firestore().collection("chat_familiarization").addDocument(data: data) { (error) in
            completionHandler(error)
        }
    }
    
    func createTag(_ texts: [String]) {
        for item in texts {
            let tagView = tagListView.addTag("# \(item)")
            tagView.tagBackgroundColor = UIColor.systemGray6
            tagView.frame.size.height = 15
            tagView.textColor = .systemGray2
            tagView.onTap = { tagView in
                if self.selectedThemes.contains(item) {
                    self.selectedThemes = self.selectedThemes.filter { $0 != item }
                    tagView.tagBackgroundColor = .systemGray6
                    tagView.textColor = .systemGray2
                } else {
                    self.selectedThemes.append(item)
                    tagView.tagBackgroundColor = .systemBlue
                    tagView.textColor = .white
                }
                
                self.selectedThemes.count >= 3 ? self.startButton.enable() : self.startButton.disable()
            }
        }
        tagHeight.constant = self.tagListView.intrinsicContentSize.height
        self.view.layoutIfNeeded()
    }
    func setTagListView() {
        tagListView.textFont = UIFont.systemFont(ofSize: 15.0, weight: .medium)
        tagListView.alignment = .center
        tagListView.paddingX = 7
        tagListView.paddingY = 7
        tagListView.marginX = 7
        tagListView.marginY = 7
        tagListView.cornerRadius = 12
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goChatting1" {
            if let nextViewController = segue.destination as? FamChat1ViewController {
                nextViewController.images = self.images
                nextViewController.captions = self.captions
                nextViewController.identifier = self.identifier
                nextViewController.secret = self.secret
                nextViewController.themesToDiscuss = self.finalThemes
            }
        }
    }
}
