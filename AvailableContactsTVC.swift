//
//  AvailableContactsTVC.swift
//  QuickNote
//
//  Created by Mamdouh El Nakeeb on 12/23/17.
//  Copyright © 2017 Nakeeb.me All rights reserved.
//

import UIKit

class AvailableContactsTVC: UITableViewController {

    
    var searchController = UISearchController()
    
    var items = [User]()
    var filteredItems = [User]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        navigationController?.navigationItem.largeTitleDisplayMode = .always
        let searchBar = UISearchController(searchResultsController: nil)
        navigationItem.searchController = searchBar
        navigationItem.hidesSearchBarWhenScrolling = false
        
        setupLargeNavBar()
        
        fetchUsers()
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
    
    func fetchUsers()  {
        ContactsManager.requestAccess { (bool) in
            if bool {
                ContactsManager.fetchContactsOnBackgroundThread(completionHandler: { (error, contacts) in
                    if error != nil {
                        print(error?.localizedDescription as Any)
                    } else {
                        for item in contacts{
                            let user = User()
                            
                            if item.phoneNumbers.count != 0 {
                                
                                user.id = ContactsManager.CNPhoneNumberToString(CNPhoneNumber: item.phoneNumbers[0].value)
                                user.name = item.givenName + " " + item.familyName
                                
                                for userEmail in item.emailAddresses{
                                    user.emails.append(userEmail.value as String)
                                }
                                
                                for userNumber in item.phoneNumbers{
                                    user.numbers.append(ContactsManager.CNPhoneNumberToString(CNPhoneNumber: userNumber.value))
                                }
                                
                                if let userImg = item.imageData{
                                    user.img = userImg
                                }
                                
                                self.items.append(user)
                                
                            }
                            
                            
                        }
                        self.tableView.reloadData()
                    }
                })
            } else {
                print("No Contact Permission")
            }
        }
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
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

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        
        var user = User()
        if isFiltering(){
            user = filteredItems[indexPath.row]
        }
        else if items.count != 0 {
            user = items[indexPath.row]
        }
        
        cell.textLabel?.text = user.name
        return cell
    }
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "Chat") as! ChatVC
        
        var user = User()
        if isFiltering(){
            user = filteredItems[indexPath.row]
        }
        else {
            user = items[indexPath.row]
        }
        vc.currentUser = user
        
        searchController.isActive = false
        self.navigationController?.pushViewController(vc, animated: true)
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

extension AvailableContactsTVC: UISearchResultsUpdating, UISearchBarDelegate {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        //
        filterContentForSearchText(searchController.searchBar.text!)
    }
}


