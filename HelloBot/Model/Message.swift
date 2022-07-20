//
//  Message.swift
//  BlahBlahBot
//
//  Created by Donghoon Shin on 2020/12/18.
//
import UIKit
import Firebase
import MessageKit

struct Message {
    
    var id: String
    var content: String
    var created: Timestamp
    var senderID: String
    var senderName: String
    var url: String?
    
    var dictionary: [String: Any] {
        
        return [
            "id": id,
            "content": content,
            "created": created,
            "senderID": senderID,
            "senderName": senderName,
            "url": url
        ]
        
    }
}

extension Message {
    init?(dictionary: [String: Any]) {
        
        guard let id = dictionary["id"] as? String,
              let content = dictionary["content"] as? String,
              let created = dictionary["created"] as? Timestamp,
              let senderID = dictionary["senderID"] as? String,
              let senderName = dictionary["senderName"] as? String
        else {return nil}
        
        if let url = dictionary["url"] as? String {
            self.init(id: id, content: content, created: created, senderID: senderID, senderName:senderName, url: url)
        } else {
            self.init(id: id, content: content, created: created, senderID: senderID, senderName:senderName)
        }
    }
}

extension Message: MessageType {
    
    var sender: SenderType {
        return Sender(id: senderID, displayName: senderName)
    }
    
    var messageId: String {
        return id
    }
    
    var sentDate: Date {
        return created.dateValue()
    }
    
    var kind: MessageKind {
        if let url = url {
            let mediaItem = ImageMediaItem(url: URL(string: url))
            return .photo(mediaItem)
        } else {
            return .text(content)
        }
    }
}

struct ImageMediaItem: MediaItem {
  var url: URL?
  var image: UIImage?
  var placeholderImage: UIImage
  var size: CGSize

  init(url: URL?) {
    self.url = url
    self.size = CGSize(width: 240, height: 240)
    self.placeholderImage = UIImage()
  }
}
