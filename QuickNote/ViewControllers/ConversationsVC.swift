import UIKit
import AudioToolbox
import RealmSwift

class ConversationsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    //MARK: Properties
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var alertBottomConstraint: NSLayoutConstraint!
    lazy var leftButton: UIBarButtonItem = {
        let image = UIImage.init(named: "default profile")?.withRenderingMode(.alwaysOriginal)
        let button  = UIBarButtonItem.init(image: image, style: .plain, target: self, action: #selector(ConversationsVC.showProfile))
        return button
    }()
    var items = [User]()
    var selectedUser: User?
    
    let realm = try! Realm()
    
    //MARK: Methods
    func customization()  {
        
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.pushToUserMesssages(notification:)), name: NSNotification.Name(rawValue: "showUserMessages"), object: nil)
        
        
        let rightButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showContacts))
        self.navigationItem.rightBarButtonItem = rightButton
        
        self.tableView.tableFooterView = UIView.init(frame: CGRect.zero)

    }
    
    func setupLargeNavBar(){
        
        // Large Navigation Bar with Search Bar
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.navigationItem.largeTitleDisplayMode = .always
        let searchBar = UISearchController(searchResultsController: nil)
        navigationItem.searchController = searchBar
        navigationItem.hidesSearchBarWhenScrolling = false
        
    }
    
    //Downloads conversations
    func fetchData() {
        
        let users = realm.objects(User.self)
        if users.isEmpty {
            print("no users found")
            return
        }
        
        setupLargeNavBar()
        
        self.items = Array(users)
        self.tableView.reloadData()
        
    }
    
    //Shows profile extra view
    func showProfile() {
        let info = ["viewType" : ShowExtraView.profile]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "showExtraView"), object: nil, userInfo: info)
        self.inputView?.isHidden = true
    }
    
    //Shows contacts extra view
    func showContacts() {
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "AvailableContactsTVC") as! AvailableContactsTVC
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    //Show EmailVerification on the bottom
    func showEmailAlert() {
        
    }
    
    //Shows Chat viewcontroller with given user
    func pushToUserMesssages(notification: NSNotification) {
        if let user = notification.userInfo?["user"] as? User {
            self.selectedUser = user
            self.performSegue(withIdentifier: "chatSegue", sender: self)
        }
    }
    
    func playSound()  {
        var soundURL: NSURL?
        var soundID:SystemSoundID = 0
        let filePath = Bundle.main.path(forResource: "newMessage", ofType: "wav")
        soundURL = NSURL(fileURLWithPath: filePath!)
        AudioServicesCreateSystemSoundID(soundURL!, &soundID)
        AudioServicesPlaySystemSound(soundID)
    }

    

    //MARK: Delegates
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.items.count == 0 {
            return 1
        } else {
            return self.items.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.items.count == 0 {
            return self.view.bounds.height - self.navigationController!.navigationBar.bounds.height
        } else {
            return 80
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.items.count {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Empty Cell")!
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ConversationsTBCell
            cell.clearCellData()
            
            cell.nameLabel.text = self.items[indexPath.row].name
            switch self.items[indexPath.row].lastMessage?.type {
            case MessageType.text.hashValue?:
                let message = String(data: (self.items[indexPath.row].lastMessage?.content!)!, encoding: .utf8)
                cell.messageLabel.text = message
            case MessageType.location.hashValue?:
                cell.messageLabel.text = "Location"
            default:
                cell.messageLabel.text = "Media"
            }
            let messageDate = Date.init(timeIntervalSince1970: TimeInterval((self.items[indexPath.row].lastMessage?.id)! / 1000))
            let dataformatter = DateFormatter.init()
            dataformatter.timeStyle = .short
            let date = dataformatter.string(from: messageDate)
            cell.timeLabel.text = date
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "Chat") as! ChatVC
        vc.currentUser = self.items[indexPath.row]
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    //MARK: ViewController lifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.customization()
        self.fetchData()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let selectionIndexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selectionIndexPath, animated: animated)
        }
        
        self.tableView.reloadData()
    }
}





