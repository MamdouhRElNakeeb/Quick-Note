//
//  AvailableContactsTVC.swift
//  QuickNote
//
//  Created by Mamdouh El Nakeeb on 12/23/17.
//  Copyright © 2017 Nakeeb. All rights reserved.
//

import UIKit

class AvailableContactsTVC: UITableViewController {

    var contacts = [User]()
    
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
        
        fetchUsers()
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
                                
                                
                                self.contacts.append(user)
                                
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
        return contacts.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        cell.textLabel?.text = contacts[indexPath.row].name
        return cell
    }
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "Chat") as! ChatVC
        vc.currentUser = contacts[indexPath.row]
        self.navigationController?.pushViewController(vc, animated: true)
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
