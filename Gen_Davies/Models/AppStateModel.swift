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
	@Published var cameraManager: CameraManager?
	@Published var videoManager: VideoManager?
	private var cancellables = Set<AnyCancellable>()
	private let contourExtractor = ContourExtractor()
	
	init() {
		print("initialised model")
	}
	
	func bindToCameraManager(_ manager: CameraManager) {
		manager.pixelBufferPublisher
			.receive(on: RunLoop.main)
			.sink { [weak self] buffer in
				self?.currentPixelBuffer = buffer
				self?.processNewFrame(buffer)
			}
			.store(in: &cancellables)
	}
	
	func bindToVideoManager(_ manager: VideoManager) {
		manager.pixelBufferPublisher
			.receive(on: RunLoop.main)
			.sink { [weak self] buffer in
				self?.currentPixelBuffer = buffer
				self?.processNewFrame(buffer)
			}
			.store(in: &cancellables)
	}

	private func processNewFrame(_ buffer: CVPixelBuffer) {
		print("Received new pixel buffer for processing.")

		guard let cgImage = contourExtractor.convertPixelBufferToCGImage(buffer) else {
			print("Failed to convert pixel buffer to CGImage")
			return
		}

		Task {
			do {
				if let path = try await contourExtractor.detectContours(
					cgImage: cgImage,
					detectDarkOnLight: true,
					contrastAdjustment: 1.0,
					contrastPivot: 0.5
				), let renderedImage = contourExtractor.drawContoursOnImage(originalImage: cgImage, contourPath: path) {
					print("Contours rendered into CGImage.")
					let ciImage = CIImage(cgImage: renderedImage)
					// Use ciImage as needed
				} else {
					print("No contours to draw.")
				}
			} catch {
				print("Contour detection error: \(error)")
			}
		}
	}
}
