//
//  FamChat2ViewController.swift
//  BlahBlahBot
//
//  Created by Donghoon Shin on 2020/12/18.
//

import UIKit
import InputBarAccessoryView
import Firebase
import MessageKit
import FirebaseFirestore
import IQKeyboardManagerSwift
import ComposableRequest
import ComposableRequestCrypto
import Swiftagram
import SwiftagramCrypto
import PINRemoteImage

class FamChat2ViewController: MessagesViewController, InputBarAccessoryViewDelegate, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    var displayName = "나"
    
    var user2Name = "대화방"
    var user2ImgUrl: String?
    var user2ID = counterID()
    var botID = "bot"
    
    var isLeader = false
    
    private var docReference: DocumentReference?
    
    var messages: [Message] = []
    
    var lastDate = Date()
    
    var timer = Timer()
    
    var endTimer = Timer()
    var startTime = Date()
    var endNotified = false
    
    @objc func countEnd(){
        if !endNotified && Date().timeIntervalSince(startTime) > 540 {
            DispatchQueue.main.asyncAfter(deadline: .now()+1.0) {
                if self.isLeader {
                    self.sendBotMessage(text: "실험이 종료되었습니다. 다음 실험과정으로 넘어가도록 하겠습니다. 잠시만 기다려주세요")
                }
                DispatchQueue.main.asyncAfter(deadline: .now()+2.0) {
                    //next view
                }
            }
            endNotified = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.endTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.countEnd), userInfo: nil, repeats: true)
        
        navigationItem.hidesBackButton = true
        
        isLeader = !isMyIdEven()
        
        IQKeyboardManager.shared.enable = false
        
        self.title = user2Name
        
        
        navigationItem.largeTitleDisplayMode = .never
        maintainPositionOnKeyboardFrameChanged = true
        messageInputBar.inputTextView.tintColor = .lightGray
        messageInputBar.inputTextView.autocorrectionType = .no
        messageInputBar.sendButton.setTitleColor(.darkGray, for: .normal)
        
        messageInputBar.delegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        messageInputBar.inputTextView.placeholder = "메시지를 입력하세요"
        messageInputBar.sendButton.setTitle("전송", for: .normal)
        
        loadChat()
    }
    
    func typingIndicator(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UICollectionViewCell {
        return TypingIndicatorCell()
    }
    
    func createNewChat() {
        let users = [experimentID, self.user2ID, self.botID]
        let data: [String: Any] = [
            "users": users
        ]
        
        let db = Firestore.firestore().collection("chat_familiarization")
        db.addDocument(data: data) { (error) in
            if let error = error {
                print("Unable to create chat! \(error)")
                return
            } else {
                self.loadChat()
            }
        }
    }
    
    func loadChat() {
        
        //Fetch all the chats which has current user in it
        let db = Firestore.firestore().collection("chat_familiarization")
            .whereField("users", arrayContains: experimentID)
        
        
        db.getDocuments { (chatQuerySnap, error) in
            
            if let error = error {
                print("Error: \(error)")
                return
            } else {
                guard let queryCount = chatQuerySnap?.documents.count else {
                    return
                }
                if queryCount == 0 {
                    self.createNewChat()
                }
                else if queryCount >= 1 {
                    for doc in chatQuerySnap!.documents {
                        let chat = Chat(dictionary: doc.data())
                        if (chat?.users.contains(self.user2ID))! {
                            self.docReference = doc.reference
                            doc.reference.collection("thread")
                                .order(by: "created", descending: false)
                                .addSnapshotListener(includeMetadataChanges: true, listener: { (threadQuery, error) in
                                    if let error = error {
                                        print("Error: \(error)")
                                        return
                                    } else {
                                        self.messages.removeAll()
                                        for message in threadQuery!.documents {
                                            if [experimentID, self.user2ID, self.botID].contains(message.data()["senderID"] as! String) {
                                                let msg = Message(dictionary: message.data())
                                                self.messages.append(msg!)
                                            }
                                        }
                                        self.messagesCollectionView.reloadData()
                                        self.messagesCollectionView.scrollToLastItem()
                                        
                                        self.bot()
                                    }
                                })
                            return
                        }
                    }
                    self.createNewChat()
                } else {
                    print("Let's hope this error never prints!")
                }
            }
        }
    }
    
    
    private func insertNewMessage(_ message: Message) {
        messages.append(message)
        messagesCollectionView.reloadData()
        
        DispatchQueue.main.async {
            self.messagesCollectionView.scrollToLastItem(animated: true)
        }
    }
    
    private func save(_ message: Message) {
        
        var data = [String: Any]()
        
        if let url = message.url {
            data = [
                "content": message.content,
                "created": message.created,
                "id": message.id,
                "senderID": message.senderID,
                "senderName": message.senderName,
                "url": url
            ]
        } else {
            data = [
                "content": message.content,
                "created": message.created,
                "id": message.id,
                "senderID": message.senderID,
                "senderName": message.senderName
            ]
        }
        
        docReference?.collection("thread").addDocument(data: data, completion: { (error) in
            if let error = error {
                print("Error Sending message: \(error)")
                return
            }
            self.messagesCollectionView.scrollToLastItem()
        })
    }
    
    // MARK: - InputBarAccessoryViewDelegate
    
    var isInitial = true
    
    func sendBotMessage(text: String) {
        let message = Message(id: UUID().uuidString, content: text, created: Timestamp(), senderID: botID, senderName: "봇")
        
        insertNewMessage(message)
        save(message)
        
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: true)
    }
    
    func bot() {
        if isLeader {
            if isInitial {
                isInitial = false
                DispatchQueue.main.asyncAfter(deadline: .now()+1.0) {
                    self.sendBotMessage(text: "두 분께서는 먼저 9분간 자유 주제로 대화를 나눠보세요")
                }
            }
        }
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let message = Message(id: UUID().uuidString, content: text, created: Timestamp(), senderID: experimentID, senderName: self.displayName)
        
        //messages.append(message)
        insertNewMessage(message)
        save(message)
        
        inputBar.inputTextView.text = ""
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: true)
    }
    
    
    // MARK: - MessagesDataSource
    func currentSender() -> SenderType {
        return Sender(id: experimentID, displayName: displayName)
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    // MARK: - MessagesLayoutDelegate
    
    func avatarSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return .zero
    }
    
    // MARK: - MessagesDisplayDelegate
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        switch message.sender.senderId {
        case experimentID: return .systemBlue
        case user2ID: return .systemGray5
        default: return .systemGreen
        }
    }
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        switch message.sender.senderId {
        case experimentID: return .white
        case user2ID: return .darkGray
        default: return .white
        }
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        switch message.sender.senderId {
        case experimentID: avatarView.initials = "나"
        case user2ID: avatarView.initials = "상대"
        default: avatarView.initials = "봇"
        }
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight: .bottomLeft
        return .bubbleTail(corner, .curved)
    }
}
