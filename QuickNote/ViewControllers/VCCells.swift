//
//  VCCells.swift
//  QuickNote
//
//  Created by Mamdouh El Nakeeb on 12/23/17.
//  Copyright © 2017 Nakeeb.me All rights reserved.
//

import Foundation
import UIKit


class SenderCell: UITableViewCell {
    
    @IBOutlet weak var profilePic: RoundedImageView!
    @IBOutlet weak var message: UITextView!
    @IBOutlet weak var messageBackground: UIImageView!
    
    func clearCellData()  {
        self.message.text = nil
        self.message.isHidden = false
        self.messageBackground.image = nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        self.message.textContainerInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        self.messageBackground.layer.cornerRadius = 15
        self.messageBackground.clipsToBounds = true
    }
}

class ReceiverCell: UITableViewCell {
    
    @IBOutlet weak var message: UITextView!
    @IBOutlet weak var messageBackground: UIImageView!
    
    func clearCellData()  {
        self.message.text = nil
        self.message.isHidden = false
        self.messageBackground.image = nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        self.message.textContainerInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        self.messageBackground.layer.cornerRadius = 15
        self.messageBackground.clipsToBounds = true
        
    }
}

class VoiceNoteCell: UITableViewCell {
    
    var bgV = UIView()
    var vnPlayBtn = VoiceNoteUIButton()
    var vnProgress = UISlider()
    var type = 0
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        let scrWidth = UIScreen.main.bounds.width
        
        contentView.frame = CGRect(x: 0, y: 0, width: scrWidth, height: 60)
        bgV.frame = CGRect(x: scrWidth * 0.3 + 15, y: 5, width: scrWidth * 0.7 - 30, height: 50)
        bgV.backgroundColor = UIColor(red: 204/255, green: 204/255, blue: 204/255, alpha: 1)
        bgV.layer.cornerRadius = 15
        
        vnPlayBtn.frame = CGRect(x: 10, y: 10, width: bgV.frame.height - 20, height: bgV.frame.height - 20)
        vnPlayBtn.setTitle("", for: .normal)
        vnPlayBtn.imageView?.contentMode = .scaleAspectFit
        vnPlayBtn.setImage(UIImage(named: "play_icn"), for: .normal)
        
        vnProgress.frame = CGRect(x: vnPlayBtn.frame.maxX + 10, y: bgV.frame.height / 2 - 2, width: bgV.frame.width - vnPlayBtn.frame.maxX - 20, height: 3)
        vnProgress.value = 0
        
        bgV.addSubview(vnPlayBtn)
        bgV.addSubview(vnProgress)
        
        contentView.addSubview(bgV)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ConversationsTBCell: UITableViewCell {
    
    @IBOutlet weak var profilePic: RoundedImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    func clearCellData()  {
        self.nameLabel.font = UIFont(name:"AvenirNext-Regular", size: 17.0)
        self.messageLabel.font = UIFont(name:"AvenirNext-Regular", size: 14.0)
        self.timeLabel.font = UIFont(name:"AvenirNext-Regular", size: 13.0)
        self.profilePic.layer.borderColor = GlobalVariables.blue.cgColor
        self.messageLabel.textColor = UIColor.rbg(r: 111, g: 113, b: 121)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.profilePic.layer.borderWidth = 2
        self.profilePic.layer.borderColor = GlobalVariables.blue.cgColor
    }
    
}

class ContactsCVCell: UICollectionViewCell {
    
    @IBOutlet weak var profilePic: RoundedImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}




