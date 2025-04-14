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
	@Published var light_contourCGImage: CGImage?
	@Published var dark_contourCGImage: CGImage?
	private var isProcessingFrame = false
	
	@Published var lightThreshold: Double = 0.5
	@Published var darkThreshold: Double = 0.5
	@Published var lightPivot: Double = 0.5
	@Published var darkPivot: Double = 0.5
	
	init() {
		print("initialised app state model")
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
		guard !isProcessingFrame else {
			print("Skipped frame: already processing.")
			return
		}
		isProcessingFrame = true

		guard let cgImage = contourExtractor.convertPixelBufferToCGImage(buffer) else {
			print("Failed to convert pixel buffer to CGImage")
			isProcessingFrame = false
			return
		}

		Task { @MainActor in
			defer { isProcessingFrame = false }
			do {
				if let lightpath = try await contourExtractor.detectContours(
					cgImage: cgImage,
					detectDarkOnLight: false,
					contrastAdjustment: Float(lightThreshold),
					contrastPivot: Float(lightPivot)
				),
				let renderedImage = contourExtractor.drawContoursOnImage(originalImage: cgImage, contourPath: lightpath) {
					//print("Contours rendered into CGImage.")
					light_contourCGImage = renderedImage
				} else {
					print("No contours to draw.")
				}
			} catch {
				print("Contour detection error: \(error.localizedDescription)")
			}
			do {
				if let darkpath = try await contourExtractor.detectContours(
					cgImage: cgImage,
					detectDarkOnLight: true,
					contrastAdjustment: Float(darkThreshold),
					contrastPivot: Float(darkPivot)
				),
				let renderedImage = contourExtractor.drawContoursOnImage(originalImage: cgImage, contourPath: darkpath) {
					//print("Contours rendered into CGImage.")
					dark_contourCGImage = renderedImage
				} else {
					print("No contours to draw.")
				}
			} catch {
				print("Contour detection error: \(error.localizedDescription)")
			}
		}
	}
}
