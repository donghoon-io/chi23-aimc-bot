//
//  CollaborationReadyViewController.swift
//  HelloBot
//
//  Created by Donghoon Shin on 2022/07/23.
//

import UIKit
import ANLoader
import Firebase
import FirebaseFirestore

class CollaborationReadyViewController: UIViewController {
    
    let db = Firestore.firestore()
    
    @IBOutlet weak var connectionButton: UIButton!
    @IBAction func connectionButtonClicked(_ sender: UIButton) {
        self.connectionButton.disable()
        ANLoader.showLoading("연결 중..", disableUI: true)
        
        db.collection("user_data").document(experimentID).setData(["is_collaboration_ready": true], merge: true) { err1 in
            if let error1 = err1 {
                self.showError(error: error1, button: self.connectionButton)
            } else {
                self.db.collection("user_data").document(counterID()).getDocument { snapshot, err2 in
                    if let error2 = err2 {
                        self.showError(error: error2, button: self.connectionButton)
                    } else {
                        if let data = snapshot?.data(), data.keys.contains("is_collaboration_ready") {
                            ANLoader.hide()
                            self.performSegue(withIdentifier: "goCollaboration3", sender: self)
                        }
                        else {
                            self.db.collection("user_data").document(counterID()).addSnapshotListener { snapshot, err3 in
                                if let error3 = err3 {
                                    self.showError(error: error3, button: self.connectionButton)
                                } else {
                                    if let avail = snapshot?.get("is_collaboration_ready") as? Bool {
                                        ANLoader.hide()
                                        self.performSegue(withIdentifier: "goCollaboration3", sender: self)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
}
