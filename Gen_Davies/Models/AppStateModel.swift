//
//  AppStateModel.swift
//  Gen_Davies
//
//  Created by Peter Rogers on 05/04/2025.
//

import Foundation
import Combine
import CoreVideo
import CoreGraphics
import CoreImage
import AudioKit

@MainActor
class AppStateModel: ObservableObject {
	
	enum SourceType {
		case camera
		case video
		case none
	}
	
	@Published var currentSource: SourceType = .none
	@Published var currentPixelBuffer: CVPixelBuffer?
	@Published var cameraModel: CameraModel!
	@Published var videoManager = VideoManager()
	@Published var videoModel: VideoModel!
	@Published var contourModel = ContourModel()
	@Published var audioModel:AudioModel!
	private var cancellables = Set<AnyCancellable>()

	init() {
		print("initialised app state model")
		audioModel = AudioModel()
		cameraModel = CameraModel(contourModel: contourModel)
		videoModel = VideoModel(provider: videoManager)
		bindToVideoManager(videoManager)

		if let fileURL = Bundle.main.url(forResource: "tester", withExtension: "wav") {
			audioModel.addPlayer(with: fileURL)
			audioModel.addPlayer(with: fileURL)
			
		}
		
		contourModel.$lightContourAreaRatio
			.sink { [weak self] ratio in
				guard let self = self else { return }
				print("Light contour area ratio: \(ratio) (\(ratio * 100)% of image)")
				guard !self.audioModel.players.isEmpty else { return }
				// Apply exponential scaling to boost small contour area ratios for better audio response.
				// Map full volume (1.0) to 10% of the image area: sqrt(0.10 * 100) = 1
				let boosted = pow(ratio * 10000000, 0.5) // sqrt boost scaled for 10% = full volume
				let scaledValue = AUValue(min(max(boosted, 0), 1))
				print("Sending amplitude to audio model: \(scaledValue)")
				self.audioModel.players[0].setAmplitude(scaledValue)
			}
			.store(in: &cancellables)
		
		contourModel.$lightShapeInfo
			.compactMap { $0 }
			.sink { [weak self] shape in
				guard let self = self else { return }
				let boosted = pow(shape.areaRatio * 1000000, 0.5)
				let scaledValue = AUValue(min(max(boosted, 0), 1))
				print("From ShapeInfo - Area Ratio: \(shape.areaRatio), Centroid: \(shape.centroid)")
				print("Amplitude from ShapeInfo: \(scaledValue)")
				if self.audioModel.players.indices.contains(0) {
					self.audioModel.players[0].setAmplitude(scaledValue)
				}
			}
			.store(in: &cancellables)
	}
	
	func switchSource(to source: SourceType) {
		// Always stop both sources to ensure previous sessions are halted
		cameraModel.stop()
		videoModel.stop()

		// Update current source
		currentSource = source

		// Start the newly selected source
		switch source {
		case .camera:
			cameraModel.start()
			audioModel.start()
		case .video:
			videoModel.start()
			audioModel.start()
		case .none:
			break
		}
	
	}

	func bindToVideoManager(_ manager: VideoManager) {
		manager.pixelBufferPublisher
			.receive(on: RunLoop.main)
			.sink { [weak self] buffer in
				self?.currentPixelBuffer = buffer
				self?.contourModel.processNewFrame(buffer)
			}
			.store(in: &cancellables)
	}
}
