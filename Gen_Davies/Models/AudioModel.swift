//
//  AudioPlayer.swift
//  Gen_Davies
//
//  Created by Peter Rogers on 15/04/2025.
//

import AudioKit
import AVFoundation
import Foundation

class AudioModel: ObservableObject {
	let engine = AudioEngine()
	private let mixer = Mixer()
	private var players: [AudioFilePlayer] = []

	init() {
		engine.output = mixer
	}

	func addPlayer() -> AudioFilePlayer {
		let player = AudioFilePlayer(mixer: mixer)
		players.append(player)
		return player
	}

	func start() {
		do {
			try engine.start()
		} catch {
			print("Failed to start engine: \(error)")
		}
	}

	func stop() {
		players.forEach { $0.stop() }
		engine.stop()
	}
}


class AudioFilePlayer {
	private let player = AudioPlayer()

	init(mixer: Mixer) {
		mixer.addInput(player)
	}

	func loadAndPlay(fileURL: URL) throws {
		let audioFile = try AVAudioFile(forReading: fileURL)
		player.file = audioFile
		player.play()
	}

	func stop() {
		player.stop()
	}
}
