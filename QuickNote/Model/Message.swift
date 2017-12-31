import Foundation
import UIKit
import RealmSwift
import IceCream
import CloudKit

class Message: Object {
    
    //MARK: Properties
    @objc dynamic var id = ""
    @objc dynamic var userId = ""
    @objc dynamic var type = 0
    @objc dynamic var content: Data? = nil
    @objc dynamic var isDeleted = false
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

extension Message: CKRecordConvertible {
    // Yep, leave it blank!
}

extension Message: CKRecordRecoverable {
    typealias O = Message
}

