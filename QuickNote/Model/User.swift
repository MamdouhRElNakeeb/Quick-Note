import Foundation
import UIKit
import RealmSwift
import IceCream
import CloudKit

class User: Object {
    
    //MARK: Properties
    @objc dynamic var id = ""
    @objc dynamic var name = ""
    let emails = List<String>()
    let numbers = List<String>()
    @objc dynamic var img: Data? = nil
    @objc dynamic var lastMessage = ""
    @objc dynamic var lastMessageTime = 0
    @objc dynamic var isDeleted = false
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

extension User: CKRecordConvertible {    
    // Yep, leave it blank!
}

extension User: CKRecordRecoverable {
    typealias O = User
}

