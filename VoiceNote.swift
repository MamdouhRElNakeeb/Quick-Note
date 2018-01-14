//
//  VoiceNote.swift
//  QuickNote
//
//  Created by Mamdouh El Nakeeb on 12/23/17.
//  Copyright © 2017 Nakeeb.me All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class VoiceNoteUIButton: UIButton{
    var params: Dictionary<String, Any>
    override init(frame: CGRect) {
        self.params = [:]
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.params = [:]
        super.init(coder: aDecoder)
    }
}

protocol VoiceNote: AVAudioPlayerDelegate {
    
    var vnPlayBtn: UIButton! { get set }
    var vnPlayer: AVAudioPlayer? { get set }
    var vnIsPlaying: Bool { get set }
    var vnStartTime: Date? { get set }
}

extension VoiceNote {
    
    var vnPath: URL! {
        return vnStartTime.flatMap {
            URL(string: NSHomeDirectory() + "/Documents/\($0.timeIntervalSince1970).acc")
        }
    }
    
    func playAction() {
        vnIsPlaying ? stopPlaying() : startPlaying()
    }
    
    func stopPlaying() {
        if vnIsPlaying {
            vnIsPlaying = false
            vnPlayBtn?.setTitle("Play", for: .normal)
            vnPlayer?.stop()
        }
    }
    
    func startPlaying() {
        vnIsPlaying = true
        vnPlayBtn?.setTitle("Stop", for: .normal)
        vnPlayer = try? AVAudioPlayer(contentsOf: vnPath)
        vnPlayer?.play()
        vnPlayer?.delegate = self
    }
}

