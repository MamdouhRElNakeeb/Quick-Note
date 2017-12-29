import Foundation
import UIKit
import RealmSwift

class Message: Object {
    
    //MARK: Properties
    @objc dynamic var id = 0
    @objc dynamic var userId = 0
    @objc dynamic var type = 0
    @objc dynamic var content: Data? = nil
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
