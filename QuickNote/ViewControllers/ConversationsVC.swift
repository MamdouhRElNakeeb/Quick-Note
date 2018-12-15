//
//  ConvrsationsVC.swift
//  QuickNote
//
//  Created by Mamdouh El Nakeeb on 12/23/17.
//  Copyright © 2017 Nakeeb.me All rights reserved.
//

import UIKit
import AudioToolbox
import RealmSwift

class ConversationsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    //MARK: Properties
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var alertBottomConstraint: NSLayoutConstraint!
    
    var items = [User]()
    var filteredItems = [User]()
    var selectedUser: User?
    
    var searchController = UISearchController()
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
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
    }
    
    //Downloads conversations
    func fetchData() {
        
        let users = realm.objects(User.self).sorted(byKeyPath: "lastMessageTime", ascending: false)
        if users.isEmpty {
            print("no users found")
            return
        }
        
        setupLargeNavBar()
        
        self.items = Array(users)
        self.tableView.reloadData()
        
    }
    
    //Shows contacts extra view
    @objc func showContacts() {
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "AvailableContactsTVC") as! AvailableContactsTVC
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    //Shows Chat viewcontroller with given user
    @objc func pushToUserMesssages(notification: NSNotification) {
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
        
        if isFiltering(){
            return self.filteredItems.count
        }
        else {
            if self.items.count == 0 {
                return 1
            } else {
                return self.items.count
            }
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
        
        var user = User()
        if isFiltering(){
            user = filteredItems[indexPath.row]
        }
        else if items.count != 0 {
            user = items[indexPath.row]
        }
        
        switch self.items.count {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Empty Cell")!
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ConversationsTBCell
            cell.clearCellData()
            
            cell.nameLabel.text = user.name
            cell.messageLabel.text = user.lastMessage
            if let userImg = user.img{
                cell.profilePic.image = UIImage(data: userImg)
            }
            let messageDate = Date.init(timeIntervalSince1970: TimeInterval(user.lastMessageTime / 1000))
            let dataformatter = DateFormatter.init()
            dataformatter.timeStyle = .short
            let date = dataformatter.string(from: messageDate)
            cell.timeLabel.text = date
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "Chat") as! ChatVC
        var user = User()
        
        if !items.isEmpty {
            if isFiltering(){
                user = filteredItems[indexPath.row]
            }
            else {
                user = items[indexPath.row]
            }
        }
        
        vc.currentUser = user
        searchController.isActive = false
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "chatSegue" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let user: User
                if isFiltering() {
                    user = filteredItems[indexPath.row]
                } else {
                    user = items[indexPath.row]
                }
                let controller = (segue.destination as! UINavigationController).topViewController as! ChatVC
                controller.currentUser = user
                controller.navigationItem.largeTitleDisplayMode = .never
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }
    
    //MARK: ViewController lifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.customization()
        self.fetchData()
        
        print(Realm.Configuration.defaultConfiguration.fileURL!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let selectionIndexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selectionIndexPath, animated: animated)
        }
        
    }
    
    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredItems = items.filter({( user : User) -> Bool in
            print(user.name)
            return user.name.lowercased().contains(searchText.lowercased())
        })
        
        self.tableView.reloadData()
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
}


extension ConversationsVC: UISearchResultsUpdating, UISearchBarDelegate {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        //
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
}


