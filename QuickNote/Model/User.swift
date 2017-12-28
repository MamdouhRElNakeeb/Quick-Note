import Foundation
import UIKit
import RealmSwift

class User: Object {
    
    //MARK: Properties
    @objc dynamic var id = 0
    @objc dynamic var name = ""
    let emails = List<String>()
    let numbers = List<String>()
    @objc dynamic var img: Data? = nil
    @objc dynamic var lastMessage: Message?
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

