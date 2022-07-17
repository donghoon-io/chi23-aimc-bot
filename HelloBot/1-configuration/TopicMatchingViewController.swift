//
//  InitialMatchingViewController.swift
//  HelloBot
//
//  Created by Donghoon Shin on 2022/07/16.
//

import UIKit
import ANLoader
import TagListView
import ComposableRequest
import ComposableRequestCrypto
import Swiftagram
import SwiftagramCrypto

class TopicMatchingViewController: UIViewController, TagListViewDelegate {

    @IBOutlet weak var tagListView: TagListView!
    @IBOutlet weak var tagHeight: NSLayoutConstraint!
    
    @IBOutlet weak var startButton: UIButton!
    
    var captions = [String]()
    var images = [String]()
    var identifier: String?
    var secret: Secret?
    
    var themes = ["가","나","다","라"]// [String]()
    var selectedThemes = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(images)
        
        tagListView.delegate = self
        setTagListView()
        createTag(themes)
        
        startButton.disable()
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
            if let nextViewController = segue.destination as? TopicMatchingViewController {
                nextViewController.images = self.images
                nextViewController.captions = self.captions
                nextViewController.identifier = self.identifier
                nextViewController.secret = self.secret
            }
        }
    }
}
