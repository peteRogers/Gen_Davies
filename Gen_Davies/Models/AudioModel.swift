import AudioKit
import AVFoundation
import Foundation
import SoundpipeAudioKit

class AudioModel: ObservableObject {
	let engine = AudioEngine()
	private let mainMixer = Mixer()

	@Published private(set) var players: [AudioFilePlayer] = []

	init() {
		engine.output = mainMixer
	}

	/// Start the audio engine and play all loaded players
	func start() {
		do {
			try engine.start()
			print("Audio engine started.")
			for player in players {
				print(player.fileURL as Any)
				player.play()
			}
		} catch {
			print("Failed to start AudioKit engine: \(error)")
		}
	}

	/// Stop all players and the audio engine
	func stop() {
		DispatchQueue.global(qos: .userInitiated).async {
			self.players.forEach { $0.stop() }
			self.engine.stop()
		}
		
	}

	/// Add and load a new player with a given file
	func addPlayer(with fileURL: URL) {
		do {
			let player = AudioFilePlayer(mixer: mainMixer)
			try player.load(fileURL: fileURL)
			players.append(player)
		} catch {
			print("Failed to load audio file: \(error)")
		}
	}
}

class AudioFilePlayer {
	private let player = AudioPlayer()
	let volumeMixer = Mixer()
	let reverb: CostelloReverb!
	private(set) var fileURL: URL?
	private let audioQueue = DispatchQueue(label: "AudioPlaybackQueue")

	init(mixer: Mixer) {
		reverb = CostelloReverb(player)
		volumeMixer.addInput(reverb)
		reverb.balance = 0.5
		mixer.addInput(volumeMixer)
	}

	func load(fileURL: URL) throws {
		let audioFile = try AVAudioFile(forReading: fileURL)
		print("File loaded")
		player.file = audioFile
		self.fileURL = fileURL
	}

	func play() {
		guard !player.isPlaying else { return }

		player.completionHandler = { [weak self] in
			guard let self = self else { return }
			print("Playback completed — restarting...")

			self.audioQueue.async {
				do {
					if let url = self.fileURL {
						try self.load(fileURL: url)
						self.play()
					}
				} catch {
					print("Failed to reload audio file for looping: \(error)")
				}
			}
		}

		player.play(from: 0)
	}

	func setAmplitude(_ value: AUValue) {
		volumeMixer.volume = value
	}
	
	func setPan(_ value: AUValue) {
		volumeMixer.pan = value
	}
	
	func setReverbFeedback(_ value: AUValue) {
		reverb.feedback = value
	}

	func stop() {
		player.stop()
	}
}
