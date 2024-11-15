//
//  AudioManager.swift
//  TheSpyder iOS
//
//  Created by yang chen on 11/12/24.
//
import AVFoundation

class AudioManager {
    static let shared = AudioManager()
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    
    private init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func loadAudio(filename: String, fileExtension: String) {
        if let path = Bundle.main.path(forResource: filename, ofType: fileExtension) {
            let url = URL(fileURLWithPath: path)
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                audioPlayers[filename] = player
            } catch {
                print("Failed to load audio file \(filename): \(error)")
            }
        }
    }
    
    func playSound(_ soundName: String) {
        audioPlayers[soundName]?.play()
    }
}

