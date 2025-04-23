//
//  ContourModel.swift
//  Gen_Davies
//
//  Created by Peter Rogers on 15/04/2025.
//


import Foundation
import CoreGraphics
import CoreImage
//import CoreVideo

@MainActor
class ContourModel: ObservableObject {
	private let contourExtractor = ContourExtractor()

	@Published var lightThreshold: Double = 0.5
	@Published var darkThreshold: Double = 0.5
	@Published var lightPivot: Double = 0.5
	@Published var darkPivot: Double = 0.5

	@Published var light_contourCGImage: CGImage?
	@Published var dark_contourCGImage: CGImage?

	private var isProcessingFrame = false

	func processNewFrame(_ buffer: CVPixelBuffer) {
		guard !isProcessingFrame else {
			//print("Skipped frame: already processing.")
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
					light_contourCGImage = renderedImage
				} else {
					//print("No light contours to draw.")
				}
			} catch {
				print("Light contour detection error: \(error.localizedDescription)")
			}

			do {
				if let darkpath = try await contourExtractor.detectContours(
					cgImage: cgImage,
					detectDarkOnLight: true,
					contrastAdjustment: Float(darkThreshold),
					contrastPivot: Float(darkPivot)
				),
				let renderedImage = contourExtractor.drawContoursOnImage(originalImage: cgImage, contourPath: darkpath) {
					dark_contourCGImage = renderedImage
				} else {
					//print("No dark contours to draw.")
				}
			} catch {
				print("Dark contour detection error: \(error.localizedDescription)")
			}
		}
	}
}
