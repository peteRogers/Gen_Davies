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
		print("Stopping engine...")
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
	
	private let feedbackSmoother = ValueSmoother(initialValue: 0.5)
	private let volumeSmoother = ValueSmoother(initialValue: 0.5)
	private let panSmoother = ValueSmoother(initialValue: 0.5)
	private var smoothingTimer: Timer?

	init(mixer: Mixer) {
		reverb = CostelloReverb(player)
		volumeMixer.addInput(reverb)
		reverb.balance = 0.5
		mixer.addInput(volumeMixer)

		// Start smoothing timer
		smoothingTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] _ in
			self?.updateSmoothers()
		}
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
		//print("volume", value)
		volumeSmoother.setTarget(value)
	}
	
	func setPan(_ value: AUValue) {
		panSmoother.setTarget(value)
		//volumeMixer.pan = value
	}
	
	func setReverbFeedback(_ value: AUValue) {
		//print(value)
		feedbackSmoother.setTarget(value)
		//reverb.feedback = value
	}
	
	func updateSmoothers() {
		feedbackSmoother.update()
		reverb.feedback = feedbackSmoother.value

		volumeSmoother.update()
		volumeMixer.volume = volumeSmoother.value

		panSmoother.update()
		volumeMixer.pan = panSmoother.value
	}

	func stop() {
		let backgroundQueue = DispatchQueue(label: "background_queue",
													qos: .background)
				
		backgroundQueue.async {[weak self] in
			// Call the class you need here and it will be done on a background QOS
			self?.player.stop()
		}
		smoothingTimer?.invalidate()
		smoothingTimer = nil
	}
}
