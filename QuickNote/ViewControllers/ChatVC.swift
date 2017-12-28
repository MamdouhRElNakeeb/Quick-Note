import UIKit
import Photos
//import Firebase
import CoreLocation
import RealmSwift

class ChatVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate,  UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLLocationManagerDelegate {
    
    //MARK: Properties
    @IBOutlet var inputBar: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    override var inputAccessoryView: UIView? {
        get {
            self.inputBar.frame.size.height = self.barHeight
            self.inputBar.clipsToBounds = true
            return self.inputBar
        }
    }
    override var canBecomeFirstResponder: Bool{
        return true
    }
    let locationManager = CLLocationManager()
    var items = [Message]()
    let imagePicker = UIImagePickerController()
    let barHeight: CGFloat = 50
    var currentUser: User?
    var canSendLocation = true
    

    let realm = try! Realm()
    var firstMsg = false
    
    //MARK: Methods
    func customization() {
        self.imagePicker.delegate = self
        self.tableView.estimatedRowHeight = self.barHeight
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.contentInset.bottom = self.barHeight
        self.tableView.scrollIndicatorInsets.bottom = self.barHeight
        self.navigationItem.title = self.currentUser?.name
//        self.navigationItem.setHidesBackButton(true, animated: false)
//        let icon = UIImage.init(named: "back")?.withRenderingMode(.alwaysTemplate)
//        let backButton = UIBarButtonItem.init(image: icon!, style: .plain, target: self, action: #selector(self.dismissSelf))
//        backButton.tintColor = self.view.tintColor
//        self.navigationItem.leftBarButtonItem = backButton
        
        navigationItem.largeTitleDisplayMode = .never
        
        self.locationManager.delegate = self
    }
    
    //Downloads messages
    func fetchData() {
//        Message.downloadAllMessages(forUserID: self.currentUser!.id, completion: {[weak weakSelf = self] (message) in
//            weakSelf?.items.append(message)
//            weakSelf?.items.sort{ $0.timestamp < $1.timestamp }
//            DispatchQueue.main.async {
//                if let state = weakSelf?.items.isEmpty, state == false {
//                    weakSelf?.tableView.reloadData()
//                    weakSelf?.tableView.scrollToRow(at: IndexPath.init(row: self.items.count - 1, section: 0), at: .bottom, animated: false)
//                }
//            }
//        })
//        Message.markMessagesRead(forUserID: self.currentUser!.id)
        
        let user = realm.objects(User.self).filter("id = \(currentUser?.id ?? 0)").first
        
        if user == nil {
            print("user not found")
            firstMsg = true
            return
        }
        
        let msgs = realm.objects(Message.self).filter("userId = \(currentUser?.id ?? 0)")
        
        if msgs.isEmpty {
            print("no messages found")
            return
        }
        
        self.items = Array(msgs)
    }
    
    //Hides current viewcontroller
    func dismissSelf() {
        if let navController = self.navigationController {
            navController.popViewController(animated: true)
        }
    }
    
    func composeMessage(type: MessageType, content: Data)  {
//        let message = Message.init(type: type, content: content, owner: .sender, timestamp: Int(Date().timeIntervalSince1970), isRead: false)
//        Message.send(message: message, toID: self.currentUser!.id, completion: {(_) in
//        })
        
        let message = Message()
        message.content = content
        message.type = type.hashValue
        message.userId = (currentUser?.id)!
        message.id = Int((Date().timeIntervalSince1970 * 1000).rounded())
        try! self.realm.write {
            
            self.realm.add(message)
            print(message)
            currentUser?.lastMessage = message
            self.realm.add(currentUser!, update: true)
            self.items.append(message)
            self.tableView.reloadData()
            if firstMsg {
                self.navigationController?.viewControllers.remove(at: (self.navigationController?.viewControllers.count)! - 2)
                firstMsg = false
            }
        }
    }
    
    func checkLocationPermission() -> Bool {
        var state = false
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            state = true
        case .authorizedAlways:
            state = true
        default: break
        }
        return state
    }
    
    func animateExtraButtons(toHide: Bool)  {
        switch toHide {
        case true:
            self.bottomConstraint.constant = 0
            UIView.animate(withDuration: 0.3) {
                self.inputBar.layoutIfNeeded()
            }
        default:
            self.bottomConstraint.constant = -50
            UIView.animate(withDuration: 0.3) {
                self.inputBar.layoutIfNeeded()
            }
        }
    }
    
    @IBAction func showMessage(_ sender: Any) {
       self.animateExtraButtons(toHide: true)
    }
    
    @IBAction func selectGallery(_ sender: Any) {
        self.animateExtraButtons(toHide: true)
        let status = PHPhotoLibrary.authorizationStatus()
        if (status == .authorized || status == .notDetermined) {
            self.imagePicker.sourceType = .savedPhotosAlbum;
            self.present(self.imagePicker, animated: true, completion: nil)
        }
        
    }
    
    @IBAction func selectCamera(_ sender: Any) {
        self.animateExtraButtons(toHide: true)
        let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        if (status == .authorized || status == .notDetermined) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                self.imagePicker.sourceType = .camera
                self.imagePicker.allowsEditing = false
                self.present(self.imagePicker, animated: true, completion: nil)
            }
            else{
                print("Camera not available")
            }
        }
    }
    
    @IBAction func selectLocation(_ sender: Any) {
        self.canSendLocation = true
        self.animateExtraButtons(toHide: true)
        if self.checkLocationPermission() {
            self.locationManager.startUpdatingLocation()
        } else {
            self.locationManager.requestWhenInUseAuthorization()
        }
    }
    
    @IBAction func showOptions(_ sender: Any) {
        self.animateExtraButtons(toHide: false)
    }
    
    @IBAction func sendMessage(_ sender: Any) {
        if let text = self.inputTextField.text {
            if text.characters.count > 0 {
                let msgData = self.inputTextField.text?.data(using: .utf8)
                self.composeMessage(type: .text, content: msgData!)
                self.inputTextField.text = ""
            }
        }
    }
    
    //MARK: NotificationCenter handlers
    func showKeyboard(notification: Notification) {
        if let frame = notification.userInfo![UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let height = frame.cgRectValue.height
            self.tableView.contentInset.bottom = height
            self.tableView.scrollIndicatorInsets.bottom = height
            if self.items.count > 0 {
                self.tableView.scrollToRow(at: IndexPath.init(row: self.items.count - 1, section: 0), at: .bottom, animated: true)
            }
        }
    }

    //MARK: Delegates
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView.isDragging {
            cell.transform = CGAffineTransform.init(scaleX: 0.5, y: 0.5)
            UIView.animate(withDuration: 0.3, animations: {
                cell.transform = CGAffineTransform.identity
            })
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Receiver", for: indexPath) as! ReceiverCell
        cell.clearCellData()
        //            cell.profilePic.image = self.currentUser?.profilePic
        switch self.items[indexPath.row].type {
        case MessageType.text.hashValue:
            cell.message.text = String(data: self.items[indexPath.row].content!, encoding: .utf8)
        case MessageType.photo.hashValue:
            if let image = UIImage(data: self.items[indexPath.row].content!) {
                cell.messageBackground.image = image
                cell.message.isHidden = true
            }
//            else {
//                cell.messageBackground.image = UIImage.init(named: "loading")
//                cell.messageBackground.image = UIImage(data: self.items[indexPath.row].content!)
//                self.items[indexPath.row].downloadImage(indexpathRow: indexPath.row, completion: { (state, index) in
//                    if state == true {
//                        DispatchQueue.main.async {
//                            self.tableView.reloadData()
//                        }
//                    }
//                })
//            }
        case MessageType.location.hashValue:
            cell.messageBackground.image = UIImage.init(named: "location")
            cell.message.isHidden = true
        default:
            break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.inputTextField.resignFirstResponder()
        switch self.items[indexPath.row].type {
        case MessageType.photo.hashValue:
            if let photo = UIImage(data: self.items[indexPath.row].content!) {
                let info = ["viewType" : ShowExtraView.preview, "pic": photo] as [String : Any]
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "showExtraView"), object: nil, userInfo: info)
                self.inputAccessoryView?.isHidden = true
            }
        case MessageType.location.hashValue:
            let coordinates = String(data: self.items[indexPath.row].content!, encoding: .utf8)?.components(separatedBy: ":")
            let location = CLLocationCoordinate2D.init(latitude: CLLocationDegrees(coordinates![0])!, longitude: CLLocationDegrees(coordinates![1])!)
            let info = ["viewType" : ShowExtraView.map, "location": location] as [String : Any]
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "showExtraView"), object: nil, userInfo: info)
            self.inputAccessoryView?.isHidden = true
            
        default:
            break
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            let msgData = UIImagePNGRepresentation(pickedImage)
            self.composeMessage(type: .photo, content: msgData!)
        } else {
            let pickedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
            let msgData = UIImagePNGRepresentation(pickedImage)
            self.composeMessage(type: .photo, content: msgData!)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locationManager.stopUpdatingLocation()
        if let lastLocation = locations.last {
            if self.canSendLocation {
                let coordinate = String(lastLocation.coordinate.latitude) + ":" + String(lastLocation.coordinate.longitude)

                composeMessage(type: .location, content: coordinate.data(using: .utf8)!)
                self.canSendLocation = false
            }
        }
    }

    //MARK: ViewController lifecycle
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.inputBar.backgroundColor = UIColor.clear
        self.view.layoutIfNeeded()
        NotificationCenter.default.addObserver(self, selector: #selector(ChatVC.showKeyboard(notification:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.customization()
        self.fetchData()
        print(Realm.Configuration.defaultConfiguration.fileURL!)
    }
}



