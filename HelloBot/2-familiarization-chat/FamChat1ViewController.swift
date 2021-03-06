//
//  FamChat1ViewController.swift
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
    var user2ID = counterID()
    var botID = "bot"
    
    var secretBotID = "secretBot" + experimentID
    var counterSecretBotID = "secretBot" + counterID()
    
    var isLeader = false
    
    private var docReference: DocumentReference?
    
    var messages: [Message] = []
    
    var lastDate = Date()
    var timer = Timer()
    var currentOrderIndex = 0
    
    var introTimer = Timer()
    var introSeconds = 120
    var mainTimer = Timer()
    var mainSeconds = 300
    var farewellTimer = Timer()
    var farewellSeconds = 120
    
    @objc func countIntro() {
        introSeconds -= 1
        if introSeconds >= 0 {
            self.timeButton.title = String(format: "남은 시간: %01d:%02d", introSeconds/60, introSeconds%60)
        }
        if introSeconds == 30 {
            if self.isLeader {
                self.sendBotMessage(text: "30초 남았습니다")
            }
        }
    }
    @objc func countMain() {
        mainSeconds -= 1
        if mainSeconds >= 0 {
            self.timeButton.title = String(format: "남은 시간: %01d:%02d", mainSeconds/60, mainSeconds%60)
        }
        if mainSeconds == 200 && isLeader {
            sendImageSuggestion()
        } else if mainSeconds == 100 && !isLeader {
            sendImageSuggestion()
        }
        if mainSeconds == 60 {
            if self.isLeader {
                self.sendBotMessage(text: "1분 남았습니다")
            }
        }
    }
    @objc func countFarewell() {
        farewellSeconds -= 1
        if farewellSeconds >= 0 {
            self.timeButton.title = String(format: "남은 시간: %01d:%02d", farewellSeconds/60, farewellSeconds%60)
        }
        if farewellSeconds == 30 {
            if self.isLeader {
                self.sendBotMessage(text: "30초 남았습니다")
            }
        }
    }
    
    @IBOutlet weak var timeButton: UIBarButtonItem!
    
    @objc func updateCounting() {
        if introSeconds == 1 && currentOrderIndex == 0 {
            lastDate = Date()
            currentOrderIndex += 1
            DispatchQueue.main.asyncAfter(deadline: .now()+1.0) {
                let lastStr = UnicodeScalar(String(self.themesToDiscuss[0].last ?? "이"))?.value ?? 28
                if self.isLeader {
                    if (lastStr-44032) % 28 == 0 {
                        self.sendBotMessage(text: "서로 인사는 즐겁게 나누셨나요? 그럼, 지금부터 5분간 두 분께서 공통되게 관심을 가질만한 '\(self.themesToDiscuss[0])'라는 토픽으로 이야기를 시작해보세요.")
                    } else {
                        self.sendBotMessage(text: "서로 인사는 즐겁게 나누셨나요? 그럼, 지금부터 5분간 두 분께서 공통되게 관심을 가질만한 '\(self.themesToDiscuss[0])'이라는 토픽으로 이야기를 시작해보세요.")
                    }
                }
                self.introTimer.invalidate()
                self.mainTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.countMain), userInfo: nil, repeats: true)
            }
        } else if mainSeconds == 1 && currentOrderIndex == 1 {
            lastDate = Date()
            currentOrderIndex += 1
            DispatchQueue.main.asyncAfter(deadline: .now()+1.0) {
                if self.isLeader {
                    self.sendBotMessage(text: "두분 다 즐거운 대화 나누셨나요? 마지막으로, 2분간 서로 대화를 마무리하고 인사말을 나눠보세요:)")
                }
                self.mainTimer.invalidate()
                self.farewellTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.countFarewell), userInfo: nil, repeats: true)
            }
        } else if farewellSeconds == 1 && currentOrderIndex == 2 {
            lastDate = Date()
            currentOrderIndex += 1
            DispatchQueue.main.asyncAfter(deadline: .now()+1.0) {
                if self.isLeader {
                    self.sendBotMessage(text: "실험이 종료되었습니다. 다음 실험과정으로 넘어가도록 하겠습니다! 잠시만 기다려주세요")
                }
                DispatchQueue.main.asyncAfter(deadline: .now()+2.0) {
                    self.timer.invalidate()
                    //next view
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateCounting), userInfo: nil, repeats: true)
        
        navigationItem.hidesBackButton = true
        
        isLeader = !isMyIdEven()
        
        IQKeyboardManager.shared.enable = false
        
        self.timeButton.isEnabled = false
        
        
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
        self.sendImageMessage(image: self.images[0])
    }
    
    // MARK: - Custom messages handlers
    
    func typingIndicator(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UICollectionViewCell {
        return TypingIndicatorCell()
    }
    
    func createNewChat() {
        let users = [experimentID, self.user2ID, self.botID, self.secretBotID, self.counterSecretBotID]
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
        let db = Firestore.firestore().collection("chat_familiarization").whereField("users", arrayContains: experimentID)
        
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
                                            if [experimentID, self.user2ID, self.botID, self.secretBotID].contains(message.data()["senderID"] as! String) {
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
    
    func sendImageSuggestion() {
        DispatchQueue.main.asyncAfter(deadline: .now()+1.0) {
            self.sendBotMessage(text: "본 주제와 비슷한 사진을 찾았어요! 보다 더 대화를 구체적으로 나누기 위해 본 사진을 공유해보세요!\n아래 이미지의 오른쪽 버튼을 누르면 상대방과 공유됩니다.", isPrivate: true)
            DispatchQueue.main.asyncAfter(deadline: .now()+2.0) {
                self.sendBotImageMessage(image: self.images[0])
            }
        }
    }
    
    func bot() {
        if isInitial {
            isInitial = false
            DispatchQueue.main.asyncAfter(deadline: .now()+1.0) {
                if self.isLeader {
                    self.sendBotMessage(text: "안녕하세요, 저는 여러분들의 인스타그램 데이터를 바탕으로 친밀해지도록 돕는 헬로봇이예요.")
                }
                DispatchQueue.main.asyncAfter(deadline: .now()+2.0) {
                    if self.isLeader {
                        self.sendBotMessage(text: "먼저 시작하기에 앞서, 두분께서는 서로 인사를 나누며 자기소개를 해볼까요?")
                    }
                    self.introTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.countIntro), userInfo: nil, repeats: true)
                }
            }
        }
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let message = Message(id: UUID().uuidString, content: text, created: Timestamp(), senderID: experimentID, senderName: self.displayName)
        
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
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if message.sender.senderId.contains("secretBot") {
            return NSAttributedString(string: "비밀 메시지", attributes: [.foregroundColor: UIColor.darkGray, .font: UIFont.systemFont(ofSize: 12, weight: .bold)])
        }
        return nil
    }
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if message.sender.senderId.contains("secretBot") {
            return 25
        }
        return 0
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
