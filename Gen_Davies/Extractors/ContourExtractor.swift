//
//  ContourExtractor.swift
//  Gen_Davies
//
//  Created by Peter Rogers on 06/04/2025.
//
import SwiftUI
import Vision
import AVFoundation


class ContourExtractor{
	private let context = CIContext()
	
	func convertPixelBufferToCGImage(_ pixelBuffer: CVPixelBuffer) -> CGImage? {
		let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
		return context.createCGImage(ciImage, from: ciImage.extent)
	}
	
	public func detectContours(cgImage: CGImage, detectDarkOnLight: Bool, contrastAdjustment: Float, contrastPivot: Float) async throws -> CGPath? {
		let image = CIImage(cgImage: cgImage)
		
		// Set up the detect contours request
		var request = DetectContoursRequest()
		request.contrastAdjustment = contrastAdjustment
		request.contrastPivot = contrastPivot
		request.detectsDarkOnLight = detectDarkOnLight
		
		// Perform the detect contours request
		let contoursObservations = try await request.perform(
			on: image,
			orientation: .downMirrored
		)
		
		// Filter contours that touch more than one edge
		let filteredContours = contoursObservations.topLevelContours.filter { contour in
			let box = contour.normalizedPath.boundingBox
			if box.minX <= 0.01 { return false }
			if box.maxX >= 0.99 { return false }
			if box.minY <= 0.01 { return false }
			if box.maxY >= 0.99 { return false }
			return true
		}

		// Sort contours by area and then by distance to the center
		let imageCenter = CGPoint(x: 0.5, y: 0.5)
		let sorted = filteredContours.sorted {
			let aArea = $0.normalizedPath.boundingBox.area
			let bArea = $1.normalizedPath.boundingBox.area

			if abs(aArea - bArea) < 0.01 {
				let aDist = distance($0.normalizedPath.boundingBox.center, imageCenter)
				let bDist = distance($1.normalizedPath.boundingBox.center, imageCenter)
				return aDist < bDist
			}
			return aArea > bArea
		}

		guard let bestContour = sorted.first else { return nil }
		let contours = bestContour.normalizedPath
		
		return contours
	}
	
	func drawContoursOnImage(
		originalImage: CGImage,
		contourPath: CGPath,
		strokeColor: CGColor = CGColor(gray: 1.0, alpha: 1.0),
		lineWidth: CGFloat = 2.0
	) -> CGImage? {
		let width = originalImage.width
		let height = originalImage.height
		let colorSpace = CGColorSpaceCreateDeviceRGB()
		let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

		guard let context = CGContext(
			data: nil,
			width: width,
			height: height,
			bitsPerComponent: 8,
			bytesPerRow: 0,
			space: colorSpace,
			bitmapInfo: bitmapInfo
		) else {
			return nil
		}

		context.draw(originalImage, in: CGRect(x: 0, y: 0, width: width, height: height))
		context.setStrokeColor(strokeColor)
		context.setLineWidth(lineWidth)
		context.addPath(contourPath)
		context.strokePath()

		return context.makeImage()
	}
	
	private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
		let dx = a.x - b.x
		let dy = a.y - b.y
		return sqrt(dx * dx + dy * dy)
	}
}

extension CGRect {
	var area: CGFloat {
		return self.width * self.height
	}
	
	var center: CGPoint {
		return CGPoint(x: midX, y: midY)
	}
}
