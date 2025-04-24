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
	@Published var lightContour: CGPath?
	@Published var darkContour: CGPath?

	@Published var lightContourAreaRatio: Double = 0.0
	@Published var darkContourAreaRatio: Double = 0.0
	
	@Published var lightShapeInfo: ShapeInfo?
	@Published var darkShapeInfo: ShapeInfo?

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
					lightContour = lightpath
					let boundingBox = lightpath.boundingBox
					let imageArea = Double(cgImage.width * cgImage.height)
					let contourArea = Double(boundingBox.width * boundingBox.height)
					lightContourAreaRatio = contourArea / imageArea
					let centroid = CGPoint(x: boundingBox.midX, y: boundingBox.midY)
					lightShapeInfo = ShapeInfo(areaRatio: lightContourAreaRatio, boundingBox: boundingBox, centroid: centroid)
				} else {
					//print("No light contours to draw.")
					lightContourAreaRatio = 0.0
					lightShapeInfo = nil
				}
			} catch {
				print("Light contour detection error: \(error.localizedDescription)")
				lightContourAreaRatio = 0.0
				lightShapeInfo = nil
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
					darkContour = darkpath
					let boundingBox = darkpath.boundingBox
					let imageArea = Double(cgImage.width * cgImage.height)
					let contourArea = Double(boundingBox.width * boundingBox.height)
					darkContourAreaRatio = contourArea / imageArea
					let centroid = CGPoint(x: boundingBox.midX, y: boundingBox.midY)
					darkShapeInfo = ShapeInfo(areaRatio: darkContourAreaRatio, boundingBox: boundingBox, centroid: centroid)
				} else {
					//print("No dark contours to draw.")
					darkContourAreaRatio = 0.0
					darkShapeInfo = nil
				}
			} catch {
				print("Dark contour detection error: \(error.localizedDescription)")
				darkContourAreaRatio = 0.0
				darkShapeInfo = nil
			}
		}
	}
}


struct ShapeInfo {
	let areaRatio: Double
	let boundingBox: CGRect
	let centroid: CGPoint
}
