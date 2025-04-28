//
//  ContourModel.swift
//  Gen_Davies
//
//  Created by Peter Rogers on 15/04/2025.
//


import Foundation
import CoreGraphics
import CoreImage
import AudioKit
//import CoreVideo

@MainActor
class ContourModel: ObservableObject {
	private let contourExtractor = ContourExtractor()

	@Published var lightThreshold: Double = 1.8
	@Published var darkThreshold: Double = 0.9
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

//	// Analyze light shape and return a scaled amplitude value
//	func analyzeLightShape() -> AUValue {
//		guard let shape = lightShapeInfo else { return 0.0 }
//		let boosted = pow(shape.areaRatio * 1000000, 0.5)
//		let scaledValue = AUValue(min(max(boosted, 0), 1))
//		print("Analyzing Light Shape - Area Ratio: \(shape.areaRatio), Centroid: \(shape.centroid)")
//		print("Computed Amplitude: \(scaledValue)")
//		return scaledValue
//	}
//
//	// Analyze dark shape and return a scaled amplitude value
//	func analyzeDarkShape() -> AUValue {
//		guard let shape = darkShapeInfo else { return 0.0 }
//		let boosted = pow(shape.areaRatio * 1000000, 0.5)
//		let scaledValue = AUValue(min(max(boosted, 0), 1))
//		print("Analyzing Dark Shape - Area Ratio: \(shape.areaRatio), Centroid: \(shape.centroid)")
//		print("Computed Amplitude: \(scaledValue)")
//		return scaledValue
//	}

	// Optional: General shape analyzer
	func analyzeShape(_ shapeInfo: ShapeInfo?) -> AUValue {
		guard let shape = shapeInfo else { return 0.0 }
		let boosted = pow(shape.areaRatio * 1000000, 0.5)
		let scaledValue = AUValue(min(max(boosted, 0), 1))
		print("Analyzing Shape - Area Ratio: \(shape.areaRatio), Centroid: \(shape.centroid)")
		print("Computed Amplitude: \(scaledValue)")
		return scaledValue
	}
	
	
	func analyzeShapeLongestLength(_ shapeInfo: ShapeInfo?) -> AUValue {
	 guard let shape = shapeInfo else { return 0.0 }
	 let longestSide = max(shape.boundingBox.width, shape.boundingBox.height)
	 let normalizedLength = longestSide / 1 // Assume 1000 is the max size for normalization
	 let scaledValue = AUValue(min(max(normalizedLength, 0), 1))
	 print("Analyzing Shape - Longest Side: \(longestSide), Normalized: \(normalizedLength)")
	 print("Computed Amplitude from Length: \(scaledValue)")
	 return scaledValue
 }
	
	func panShape(_ shapeInfo: ShapeInfo?) -> AUValue {
		guard let shape = shapeInfo else { return 0.0 } // Default center if no shape
		let normalizedX = shape.centroid.x / 1 // Assuming 1000 width
		let clampedX = min(max(normalizedX, 0), 1)
		let panValue = (clampedX * 2.0) - 1.0 // Map [0,1] to [-1,1]
		print("Centroid X: \(shape.centroid.x), Normalized X: \(normalizedX), Pan Value: \(panValue)")
		return AUValue(panValue)
	}
	
	
	
}


struct ShapeInfo {
	let areaRatio: Double
	let boundingBox: CGRect
	let centroid: CGPoint
}
