//
//  ChatVC.swift
//  QuickNote
//
//  Created by Mamdouh El Nakeeb on 12/23/17.
//  Copyright © 2017 Nakeeb.me All rights reserved.
//

import UIKit
import Photos
import CoreLocation
import AVFoundation
import RealmSwift

class ChatVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate,  UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLLocationManagerDelegate {
    
    //MARK: Properties
    @IBOutlet var inputBar: UIView!
    @IBOutlet weak var sendBtn: UIButton!
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
    
    // Voice Note
    var vnStartTime: Int?
    var vnEndTime: Int?
    var recorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer!
    var progressView: UISlider?
    var playBtn: UIButton?
    var vnScheduler: Timer?
    var playerState = VoiceNoteState.stopped.hashValue
    var vnFileUrl: URL?
    var recordingSession: AVAudioSession!
    var vnSettings: [String: Any] = [
        AVFormatIDKey: kAudioFormatMPEG4AAC,
        AVNumberOfChannelsKey: 2,
        AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
        AVEncoderBitRateKey: 320000,
        AVSampleRateKey: 44100.0
    ]
    
    // Realm DB
    let realm = try! Realm()
    var firstMsg = false
    
    var firstTime = true
    
    //MARK: Methods
    func customization() {
        self.imagePicker.delegate = self
        self.tableView.estimatedRowHeight = self.barHeight
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.contentInset.bottom = self.barHeight
        self.tableView.scrollIndicatorInsets.bottom = self.barHeight
        self.navigationItem.title = self.currentUser?.name
        
        
        navigationItem.largeTitleDisplayMode = .never
        
        self.locationManager.delegate = self
        
        inputTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        sendBtn.imageView?.contentMode = .scaleAspectFit
        sendBtn.imageView?.tintColor = view.tintColor
        toggleSendBtn()
    }
    
    // Config Recorder
    
    func toggleSendBtn(){
        
        if (inputTextField.text?.isEmpty)!{
            
            sendBtn.removeTarget(self, action: #selector(sendMessage(_:)), for: .touchUpInside)
            sendBtn.addTarget(self, action: #selector(startRecord), for: .touchDown)
            sendBtn.addTarget(self, action: #selector(stopRecord), for: .touchUpInside)
            sendBtn.addTarget(self, action: #selector(stopRecord), for: .touchUpOutside)
            sendBtn.setImage(UIImage(named: "mic_icn") , for: .normal)
            sendBtn.setImage(UIImage(named: "mic_icn2") , for: .highlighted)
            
        }
        else {
            sendBtn.removeTarget(self, action: #selector(startRecord), for: .touchDown)
            sendBtn.removeTarget(self, action: #selector(stopRecord), for: .touchUpInside)
            sendBtn.removeTarget(self, action: #selector(stopRecord), for: .touchUpOutside)
            sendBtn.addTarget(self, action: #selector(sendMessage(_:)), for: .touchUpInside)
            sendBtn.setImage(UIImage(named: "send_icn") , for: .normal)
            sendBtn.setImage(UIImage(named: "send_icn2") , for: .highlighted)
        }
        
    }
    
    func configRecorder(){
        
        tableView.register(VoiceNoteCell.self, forCellReuseIdentifier: "Voicenote")
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        if self.recorder == nil {
                            //self.startRecord()
                        } else {
                            self.stopRecord()
                        }
                    } else {
                        // failed to record!
                    }
                }
            }
        } catch {
            // failed to record!
        }
    }
    
    @objc func startRecord(){
        print("start rec")
        
        recorder?.stop()
        
        vnFileUrl = getDocumentsDirectory().appendingPathComponent("\(Int(Date().timeIntervalSince1970)).m4a")
        
        do {
            recorder = try AVAudioRecorder(url: vnFileUrl!, settings: vnSettings)
            
            recorder?.record()
            vnStartTime = Int(Date().timeIntervalSince1970 * 1000)
            
        } catch {
            print("can't record kda")
        }
        
    }
    
    @objc func stopRecord(){
        
        vnEndTime = Int(Date().timeIntervalSince1970 * 1000)
        
        print("stop rec")
        recorder?.stop()
        recorder = nil
        
        // Cancel if less than 1 second
        if vnEndTime! - vnStartTime! < 1000 {
            return
        }
        
        do{
            let voiceNote = try Data(contentsOf: vnFileUrl!)
            
            composeMessage(type: .voicenote, content: voiceNote)
        }
        catch{
            print("error in rec")
        }
    }
    
    @objc func toggleVoiceNote(_ sender: VoiceNoteUIButton){
        
        playBtn = sender
        progressView = sender.params["progressBar"] as? UISlider
        
        switch playerState {
        case VoiceNoteState.stopped.hashValue:
            print("play after stop")
            do
            {
                // 2
                audioPlayer = try AVAudioPlayer(data: self.items[sender.tag].content!)
                audioPlayer.play()
                // 3
                vnScheduler = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateAudioProgressView), userInfo: nil, repeats: true)
                progressView?.maximumValue = Float(audioPlayer.duration)
                progressView?.setValue(Float(audioPlayer.currentTime), animated: true)
                playerState = VoiceNoteState.playing.hashValue
                playBtn?.setImage(UIImage(named: "pause_icn"), for: .normal)
            }
            catch
            {
                print("An error occurred while trying to extract audio file")
            }
            
        case VoiceNoteState.paused.hashValue:
            print("play after pause")
            if audioPlayer != nil && !audioPlayer.isPlaying{
                
                vnScheduler = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateAudioProgressView), userInfo: nil, repeats: true)
                audioPlayer.currentTime = TimeInterval((progressView?.value)!)
                audioPlayer.play()
                playerState = VoiceNoteState.playing.hashValue
                playBtn?.setImage(UIImage(named: "pause_icn"), for: .normal)
            }
        default:
            print("stop after ay 7aga")
            if audioPlayer != nil{
                audioPlayer.pause()
                playerState = VoiceNoteState.paused.hashValue
                playBtn?.setImage(UIImage(named: "play_icn"), for: .normal)
                progressView?.setValue(Float(audioPlayer.currentTime), animated: true)
                vnScheduler?.invalidate()
                vnScheduler = nil
            }
        }
        
    }
    
    @objc func updateAudioProgressView()
    {
        // Update progress
        progressView?.setValue(Float(audioPlayer.currentTime), animated: true)
        
        if !audioPlayer.isPlaying && playerState != VoiceNoteState.paused.hashValue {
            audioPlayer.stop()
            playerState = VoiceNoteState.stopped.hashValue
            playBtn?.setImage(UIImage(named: "play_icn"), for: .normal)
            
            vnScheduler?.invalidate()
            vnScheduler = nil
        }
        else{
            
            playerState = VoiceNoteState.playing.hashValue
            playBtn?.setImage(UIImage(named: "pause_icn"), for: .normal)
        }
    }
    
    @objc func updateVNProgress(_ sender: UISlider){
        
        if audioPlayer != nil
        {
            // Update progress
            audioPlayer.currentTime = Double((progressView?.value)!)
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    //Downloads messages
    func fetchData() {
        
        let user = realm.objects(User.self).filter("id = '\(currentUser?.id ?? "0")'").first
        
        if user == nil {
            print("user not found")
            firstMsg = true
            return
        }
        
        let msgs = realm.objects(Message.self).filter("userId = '\(currentUser?.id ?? "0")'")
        
        if msgs.isEmpty {
            print("no messages found")
            return
        }
        
        self.items = Array(msgs)
        self.tableView.reloadData()
        
        
    }
    
    //Hides current viewcontroller
    func dismissSelf() {
        if let navController = self.navigationController {
            navController.popViewController(animated: true)
        }
    }
    
    func composeMessage(type: MessageType, content: Data)  {
        
        let message = Message()
        message.content = content
        message.type = type.hashValue
        message.userId = (currentUser?.id)!
        message.id = String(Int((Date().timeIntervalSince1970 * 1000).rounded()))
        try! self.realm.write {
            
            self.realm.add(message)
            print(message)
            switch (type){
            
            case MessageType.photo:
                currentUser?.lastMessage = "Media"
                break
            case MessageType.location:
                currentUser?.lastMessage = "Location"
                break
            case MessageType.voicenote:
                currentUser?.lastMessage = "Voice"
                break
            default:
                currentUser?.lastMessage = String(data: content, encoding: .utf8)!
                break
            }
            currentUser?.lastMessageTime = Int(message.id) ?? 0
            
            self.realm.add(currentUser!, update: true)
            self.items.append(message)
            self.tableView.reloadData()
            self.tableView.scrollToLastCell(animated: true)
            self.toggleSendBtn()
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
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
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
                toggleSendBtn()
            }
        }
    }
    
    //MARK: NotificationCenter handlers
    @objc func showKeyboard(notification: Notification) {
        if let frame = notification.userInfo![UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let height = frame.cgRectValue.height
            self.tableView.contentInset.bottom = height
            self.tableView.scrollIndicatorInsets.bottom = height
            if self.items.count > 0 {
                self.tableView.scrollToRow(at: IndexPath.init(row: self.items.count - 1, section: 0), at: .bottom, animated: true)
            }
        }
    }

    func scrollToTVBottom() {
        let numRows = tableView(tableView, numberOfRowsInSection: 0)
        var contentInsetTop = self.tableView.bounds.size.height
        for i in 0..<numRows {
            contentInsetTop -= tableView(tableView, heightForRowAt: IndexPath(item: i, section: 0))
            if contentInsetTop <= 0 {
                contentInsetTop = 0
            }
        }
        tableView.contentInset = UIEdgeInsetsMake(contentInsetTop, 0, 0, 0)
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if self.items[indexPath.row].type == MessageType.voicenote.hashValue {
            return 60
        }
        else {
            return UITableViewAutomaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let note = self.items[indexPath.row]
        
        switch note.type {
        case MessageType.voicenote.hashValue:
            let vnCell = tableView.dequeueReusableCell(withIdentifier: "Voicenote", for: indexPath) as! VoiceNoteCell
            vnCell.vnPlayBtn.tag = indexPath.row
            vnCell.vnPlayBtn.addTarget(self, action: #selector(self.toggleVoiceNote(_:)), for: .touchUpInside)
            vnCell.vnPlayBtn.params = [
                "index": indexPath.row,
                "progressBar": vnCell.vnProgress
            ]
            vnCell.vnProgress.addTarget(self, action: #selector(self.updateVNProgress(_:)), for: .editingChanged)
            return vnCell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Receiver", for: indexPath) as! ReceiverCell
            cell.clearCellData()
            
            switch note.type {
            case MessageType.text.hashValue:
                cell.message.text = String(data: note.content!, encoding: .utf8)
            case MessageType.photo.hashValue:
                if let image = UIImage(data: note.content!) {
                    cell.messageBackground.image = image
                    cell.message.isHidden = true
                }
                
            case MessageType.location.hashValue:
                cell.messageBackground.image = UIImage.init(named: "location")
                cell.messageBackground.backgroundColor = UIColor.clear
                cell.message.isHidden = true
            default:
                break
            }
            return cell
        }
        
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
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if  firstTime && tableView.numberOfRows(inSection: 0) == self.items.count{
            firstTime = false
            tableView.scrollToLastCell(animated: true)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func textFieldDidChange(_ textField: UITextField){
        
        toggleSendBtn()
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
        if audioPlayer != nil{
            audioPlayer.stop()
        }
        if recorder != nil{
            recorder?.stop()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.customization()
        self.configRecorder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.fetchData()
        print(Realm.Configuration.defaultConfiguration.fileURL!)
    }
}






