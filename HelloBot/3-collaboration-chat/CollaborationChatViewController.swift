//
//  CollaborationChatViewController.swift
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

class CollaborationChatViewController: MessagesViewController, InputBarAccessoryViewDelegate, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
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
        if !endNotified && Date().timeIntervalSince(startTime) > 300 {
            DispatchQueue.main.asyncAfter(deadline: .now()+1.0) {
                if self.isLeader {
                    self.sendBotMessage(text: "실험이 종료되었습니다. 설문 및 인터뷰 단계로 넘어가도록 하겠습니다. 잠시만 기다려주세요")
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SurveyWebViewController") as! SurveyWebViewController
                    self.navigationController?.pushViewController(vc, animated: true)
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
        
        let newMessageInputBar = InputBarAccessoryView()
        newMessageInputBar.delegate = self
        messageInputBar = newMessageInputBar
        
        let items = [
            makeButton(image: UIImage(systemName: "at")!).onTouchUpInside({ button in
                self.messageInputBar.inputTextView.text = "@헬로봇 "
                self.messageInputBar.inputTextView.becomeFirstResponder()
            }),
            messageInputBar.sendButton.configure {
                $0.title = "전송"
                $0.titleLabel?.font = UIFont.systemFont(ofSize: 17)
            }
        ]
        messageInputBar.setRightStackViewWidthConstant(to: 80, animated: true)
        messageInputBar.setStackViewItems(items, forStack: .right, animated: true)
        reloadInputViews()
        
        messageInputBar.inputTextView.tintColor = .lightGray
        messageInputBar.inputTextView.autocorrectionType = .no
        messageInputBar.sendButton.setTitleColor(.darkGray, for: .normal)
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        messageInputBar.inputTextView.placeholder = "메시지를 입력하세요"
        
        loadChat()
    }
    
    // MARK: - Custom messages handlers
    
    func typingIndicator(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UICollectionViewCell {
        return TypingIndicatorCell()
    }
    
    func createNewChat() {
        let users = [experimentID, self.user2ID, self.botID]
        let data: [String: Any] = [
            "users":users
        ]
        
        let db = Firestore.firestore().collection("chat_collaboration")
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
        let db = Firestore.firestore().collection("chat_collaboration").whereField("users", arrayContains: experimentID)
        
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
                                            if [experimentID, self.user2ID, self.botID].contains(message.data()["senderID"] as! String) {
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
                    self.sendBotMessage(text: "이번 단계에서는, 상대방과 5분간 특정 주제로 협업을 하게 됩니다")
                    DispatchQueue.main.asyncAfter(deadline: .now()+3.0) {
                        self.sendBotMessage(text: "구체적으로, '스마트폰을 이용해서 할 수 있는 것들'이라는 주제로 제한된 시간 내에 최대한 많은 아이디어를 추가해보는 태스크를 수행할 예정입니다")
                        DispatchQueue.main.asyncAfter(deadline: .now()+3.0) {
                            self.sendBotMessage(text: "예를 들어, '스마트폰으로 인터넷에 접속할 수 있다'는 아이디어를 추가하려면, 하단 바 오른쪽 태그 (@) 버튼을 누른 뒤, '인터넷에 접속하기'와 같은 방식으로 아이디어를 추가해주세요!")
                            DispatchQueue.main.asyncAfter(deadline: .now()+3.0) {
                                self.sendBotMessage(text: "그럼, 시작해볼까요?")
                            }
                        }
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
    func makeButton(image: UIImage) -> InputBarButtonItem {
        return InputBarButtonItem()
            .configure {
                $0.spacing = .fixed(10)
                $0.image = image.withRenderingMode(.alwaysTemplate)
                $0.setSize(CGSize(width: 35, height: 35), animated: false)
                $0.tintColor = .systemBlue
            }
    }
}
