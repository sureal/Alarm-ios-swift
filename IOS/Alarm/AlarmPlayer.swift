//
// Created by Matthias Neubert on 2019-02-28.
// Copyright (c) 2019 LongGames. All rights reserved.
//

import Foundation
import AudioToolbox
import AVFoundation

class AlarmPlayer: NSObject, AVAudioPlayerDelegate {

    private var audioPlayer: AVAudioPlayer?

    override init() {
        super.init()
        self.setupAudioSession()
    }

    func setupAudioSession() {

        var error: NSError?
        do {
            try AVAudioSession.sharedInstance().setCategory(
                    AVAudioSession.Category.playback,
                    mode: AVAudioSession.Mode.default,
                    options: AVAudioSession.CategoryOptions.duckOthers)

            //.setCategory(convertFromAVAudioSessionCategory(AVAudioSession.Category.playback))
        } catch let error1 as NSError {
            error = error1
            print("could not set session. err:\(error!.localizedDescription)")
        }
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error1 as NSError {
            error = error1
            print("could not active session. err:\(error!.localizedDescription)")
        }
    }

    func stopSound() {

        self.audioPlayer?.stop()
        AudioServicesRemoveSystemSoundCompletion(kSystemSoundID_Vibrate)
    }

    func playSound(_ soundName: String) {

        //vibrate phone first
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        //set vibrate callback
        let vibrateSoundID = SystemSoundID(kSystemSoundID_Vibrate)
        AudioServicesAddSystemSoundCompletion(
                vibrateSoundID, nil, nil, { (_: SystemSoundID, _: UnsafeMutableRawPointer?) -> Void in
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        }, nil)

        let url = URL(fileURLWithPath: Bundle.main.path(forResource: soundName, ofType: "mp3")!)

        var error: NSError?

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
        } catch let error1 as NSError {
            error = error1
            audioPlayer = nil
        }

        if let err = error {
            print("audioPlayer error \(err.localizedDescription)")
            return
        } else {
            audioPlayer!.delegate = self
            audioPlayer!.prepareToPlay()
        }

        //negative number means loop infinity
        audioPlayer!.numberOfLoops = -1
        audioPlayer!.play()
    }

    //AVAudioPlayerDelegate protocol
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {

    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {

    }

}
