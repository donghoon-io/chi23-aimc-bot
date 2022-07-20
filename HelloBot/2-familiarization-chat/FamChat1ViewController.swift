//
//  Chat1ViewController.swift
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

class FamChat1ViewController: MessagesViewController, InputBarAccessoryViewDelegate, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    var captions = [String]()
    var images = [String]()
    var identifier: String?
    var secret: Secret?
    
    var displayName = "나"
    
    var themesToDiscuss = [String]()
    
    var user2Name = "대화방"
    var user2ImgUrl: String?
    var user2ID = String(Int(experimentID)! % 2 == 0 ? Int(experimentID)!+1 : Int(experimentID)!-1)
    var botID = "bot"
    
    var secretBotID = "secretBot" + experimentID
    var counterSecretBotID = "secretBot" + String(Int(experimentID)! % 2 == 0 ? String(Int(experimentID)!+1) : String(Int(experimentID)!-1))
    
    var isLeader = false
    
    private var docReference: DocumentReference?
    
    var messages: [Message] = []
    
    var lastDate = Date()
    
    var timer = Timer()
    
    var currentOrderIndex = 0
    
    @objc func updateCounting() {
        if isLeader && Date().timeIntervalSince(lastDate) > 120.0 && currentOrderIndex == 0 {
            lastDate = Date()
            currentOrderIndex += 1
            DispatchQueue.main.asyncAfter(deadline: .now()+1.0) {
                let lastStr = UnicodeScalar(String(self.themesToDiscuss[0].last ?? "이"))?.value ?? 28
                if (lastStr-44032) % 28 == 0 {
                    self.sendBotMessage(text: "서로 인사는 즐겁게 나누셨나요? 그럼, 지금부터 4분간 '\(self.themesToDiscuss[0])'라는 토픽으로 이야기를 시작해보세요.")
                } else {
                    self.sendBotMessage(text: "서로 인사는 즐겁게 나누셨나요? 그럼, 지금부터 4분간 '\(self.themesToDiscuss[0])'이라는 토픽으로 이야기를 시작해보세요.")
                }
            }
        } else if isLeader && Date().timeIntervalSince(lastDate) > 240.0 && [1,2,3].contains(currentOrderIndex) {
            lastDate = Date()
            currentOrderIndex += 1
            DispatchQueue.main.asyncAfter(deadline: .now()+1.0) {
                let lastStr = UnicodeScalar(String(self.themesToDiscuss[self.currentOrderIndex-1].last ?? "이"))?.value ?? 28
                if (lastStr-44032) % 28 == 0 {
                    switch self.currentOrderIndex {
                    case 1:
                        self.sendBotMessage(text: "\(self.themesToDiscuss[self.currentOrderIndex-2])에 대한 대화를 잘 나누셨다면, 다음으로 '\(self.themesToDiscuss[self.currentOrderIndex-1])'라는 토픽으로 4분간 이야기를 나눠보세요!")
                    case 2:
                        self.sendBotMessage(text: "이야기가 끝났다면, 이번에는 '\(self.themesToDiscuss[self.currentOrderIndex-1])'에 대한 각자의 경험을 4분간 대화를 나눠보세요!")
                    default:
                        self.sendBotMessage(text: "\(self.themesToDiscuss[self.currentOrderIndex-2])에 관한 대화는 어땠나요? 마지막으로, '\(self.themesToDiscuss[self.currentOrderIndex-1])'란 토픽으로 4분간 대화를 나눠보는건 어떨까요?")
                    }
                } else {
                    switch self.currentOrderIndex {
                    case 1:
                        self.sendBotMessage(text: "\(self.themesToDiscuss[self.currentOrderIndex-2])에 대한 대화를 잘 나누셨다면, 다음으로 '\(self.themesToDiscuss[self.currentOrderIndex-1])'이란 토픽으로 4분간 이야기를 나눠보세요!")
                    case 2:
                        self.sendBotMessage(text: "이야기가 끝났다면, 이번에는 '\(self.themesToDiscuss[self.currentOrderIndex-1])'에 대한 각자의 경험을 4분간 나눠보세요!")
                    default:
                        self.sendBotMessage(text: "\(self.themesToDiscuss[self.currentOrderIndex-2])에 관한 대화는 어땠나요? 마지막으로, '\(self.themesToDiscuss[self.currentOrderIndex-1])'이라는 토픽으로 4분간 대화를 나눠보는건 어떨까요?")
                    }
                }
            }
        } else if isLeader && Date().timeIntervalSince(lastDate) > 240.0 && currentOrderIndex == 4 {
            lastDate = Date()
            currentOrderIndex += 1
            DispatchQueue.main.asyncAfter(deadline: .now()+1.0) {
                self.sendBotMessage(text: "두분 다 좋은 이야기 나누셨나요? 마지막으로, 2분간 서로 대화를 마무리하고 인사말을 나눠보세요:)")
            }
        }
    }
    
    var endTimer = Timer()
    var startTime = Date()
    var endNotified = false
    
    @objc func countEnd(){
        if !endNotified && Date().timeIntervalSince(startTime) > 1200 {
            DispatchQueue.main.asyncAfter(deadline: .now()+1.0) {
                if self.isLeader {
                    self.sendBotMessage(text: "실험이 종료되었습니다. 지금부터 인터뷰 및 설문조사를 진행하도록 하겠습니다.")
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
        
        
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateCounting), userInfo: nil, repeats: true)
        
        navigationItem.hidesBackButton = true
        
        if Int(experimentID)! % 2 == 1 {
            isLeader = true
        }
        
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
        
        let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout
        layout?.setMessageIncomingAccessoryViewSize(CGSize(width: 30, height: 30))
        layout?.setMessageIncomingAccessoryViewPadding(HorizontalEdgeInsets(left: 8, right: 0))
        layout?.setMessageIncomingAccessoryViewPosition(.messageBottom)
        layout?.setMessageOutgoingAccessoryViewSize(CGSize(width: 30, height: 30))
        layout?.setMessageOutgoingAccessoryViewPadding(HorizontalEdgeInsets(left: 0, right: 8))
        
        loadChat()
    }
    
    @objc func click() {
        self.sendImageMessage(image: "https://scontent-ssn1-1.cdninstagram.com/v/t51.2885-15/116672160_794831917720770_6108094005385287376_n.jpg?stp=dst-jpg_e35_s1080x1080&_nc_ht=scontent-ssn1-1.cdninstagram.com&_nc_cat=106&_nc_ohc=AFe1ZHyoDTMAX_vEGeS&edm=ABmJApABAAAA&ccb=7-5&ig_cache_key=MjM2NzA1MTcyMDY2MjM3MzQ2Mw%3D%3D.2-ccb7-5&oh=00_AT9hbPTNY3BtCC5JudJ0nVeceSjembHtE126mc9u8W-VKA&oe=62DF5A4F&_nc_sid=6136e7")
    }
    
    // MARK: - Custom messages handlers
    
    func typingIndicator(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UICollectionViewCell {
        return TypingIndicatorCell()
    }
    
    func createNewChat() {
        let users = [experimentID, self.user2ID, self.botID, self.secretBotID, self.counterSecretBotID]
        let data: [String: Any] = [
            "users":users
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
                
                //Count the no. of documents returned
                guard let queryCount = chatQuerySnap?.documents.count else {
                    return
                }
                
                if queryCount == 0 {
                    //If documents count is zero that means there is no chat available and we need to create a new instance
                    self.createNewChat()
                }
                else if queryCount >= 1 {
                    //Chat(s) found for currentUser
                    for doc in chatQuerySnap!.documents {
                        
                        let chat = Chat(dictionary: doc.data())
                        //Get the chat which has user2 id
                        if (chat?.users.contains(self.user2ID))! {
                            
                            self.docReference = doc.reference
                            //fetch it's thread collection
                            doc.reference.collection("thread")
                                .order(by: "created", descending: false)
                                .addSnapshotListener(includeMetadataChanges: true, listener: { (threadQuery, error) in
                                    if let error = error {
                                        print("Error: \(error)")
                                        return
                                    } else {
                                        self.messages.removeAll()
                                        for message in threadQuery!.documents {
                                            if [experimentID, self.user2ID, self.botID, self.secretBotID].contains(message.data()["senderID"] as! String) {
                                                let msg = Message(dictionary: message.data())
                                                self.messages.append(msg!)
                                            }
                                        }
                                        self.messagesCollectionView.reloadData()
                                        self.messagesCollectionView.scrollToBottom(animated: true)
                                        
                                        // handle bot here
                                        self.bot()
                                    }
                                })
                            return
                        } //end of if
                    } //end of for
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
    
    func sendBotImageMessage(image: String) {
        let message = Message(id: UUID().uuidString, content: "", created: Timestamp(), senderID: secretBotID, senderName: "봇", url: image)
        
        insertNewMessage(message)
        save(message)
        
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: true)
    }
    
    func sendImageMessage(image: String) {
        let message = Message(id: UUID().uuidString, content: "", created: Timestamp(), senderID: experimentID, senderName: displayName, url: image)
        
        insertNewMessage(message)
        save(message)
        
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: true)
    }
    
    func sendBotMessage(text: String, isPrivate: Bool = false) {
        if isPrivate {
            let message = Message(id: UUID().uuidString, content: text, created: Timestamp(), senderID: secretBotID, senderName: "봇")
            
            insertNewMessage(message)
            save(message)
        } else {
            let message = Message(id: UUID().uuidString, content: text, created: Timestamp(), senderID: botID, senderName: "봇")
            
            insertNewMessage(message)
            save(message)
        }
        
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: true)
    }
    
    func bot() {
        if isLeader {
            if isInitial {
                isInitial = false
                DispatchQueue.main.asyncAfter(deadline: .now()+1.0) {
                    self.sendBotMessage(text: "(비밀 메시지)\n본 주제와 비슷한 사진을 찾았어요! 보다 더 대화를 구체적으로 하기 위해서 본 사진을 공유해보세요! 아래 이미지의 오른쪽 버튼을 누르면 상대방과 공유됩니다.", isPrivate: true)
                    DispatchQueue.main.asyncAfter(deadline: .now()+2.0) {
                        self.sendBotImageMessage(image: "https://scontent-ssn1-1.cdninstagram.com/v/t51.2885-15/116672160_794831917720770_6108094005385287376_n.jpg?stp=dst-jpg_e35_s1080x1080&_nc_ht=scontent-ssn1-1.cdninstagram.com&_nc_cat=106&_nc_ohc=AFe1ZHyoDTMAX_vEGeS&edm=ABmJApABAAAA&ccb=7-5&ig_cache_key=MjM2NzA1MTcyMDY2MjM3MzQ2Mw%3D%3D.2-ccb7-5&oh=00_AT9hbPTNY3BtCC5JudJ0nVeceSjembHtE126mc9u8W-VKA&oe=62DF5A4F&_nc_sid=6136e7")
                    }
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
        case secretBotID: return .systemGray
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
    func configureAccessoryView(_ accessoryView: UIView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        // Cells are reused, so only add a button here once. For real use you would need to
        // ensure any subviews are removed if not needed
        
        
        accessoryView.subviews.forEach { $0.removeFromSuperview() }
        accessoryView.backgroundColor = .clear
        
        if message.sender.senderId == secretBotID {
            switch message.kind {
            case .photo(_):
                let button = UIButton(type: .contactAdd)
                button.tintColor = .link
                accessoryView.addSubview(button)
                button.frame = accessoryView.bounds
                button.addTarget(self, action: #selector(click), for: .touchUpInside)
                accessoryView.layer.cornerRadius = accessoryView.frame.height / 2
                accessoryView.backgroundColor = .clear
            default: break
            }
        }
        
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight: .bottomLeft
        return .bubbleTail(corner, .curved)
        
    }
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let msg = message as? Message, let url = msg.url else { return }
        imageView.pin_setImage(from: URL(string: url)!)
    }
    
}
extension UIImageView {
  func load(url: URL) {
    DispatchQueue.global().async { [weak self] in
        if let data = try? Data(contentsOf: url) {
            if let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.image = image
                }
            }
        }
     }
   }
 }
