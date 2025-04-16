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

@MainActor
class AppStateModel: ObservableObject {
	
	enum SourceType {
		case camera
		case video
	}
	
	@Published var currentSource: SourceType = .video
	@Published var currentPixelBuffer: CVPixelBuffer?
	@Published var cameraModel: CameraModel!
	@Published var videoManager = VideoManager()
	@Published var videoModel: VideoModel!
	@Published var contourModel = ContourModel()
	private var cancellables = Set<AnyCancellable>()

	init() {
		print("initialised app state model")
		cameraModel = CameraModel(contourModel: contourModel)
		videoModel = VideoModel(provider: videoManager)
		bindToVideoManager(videoManager)
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
		case .video:
			videoModel.start()
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
