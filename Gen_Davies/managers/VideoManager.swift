//
//  VideoManager.swift
//  FeatureExtractor
//
//  Created by student on 04/04/2025.
//

import Foundation
import AVFoundation
import SwiftUI
import CoreImage
import Combine

class VideoManager: ObservableObject, VideoFrameProvider {
	let pixelBufferPublisher = PassthroughSubject<CVPixelBuffer, Never>()

	func startVideoProcessing() {
		processVideo(from: "above motion test", withExtension: "mov") {
			print("Video processing complete")
		}
	}
	
	private var asset: AVAsset?
	private var reader: AVAssetReader?
	private var videoTrack: AVAssetTrack?
	private var videoOutput: AVAssetReaderTrackOutput?

	@Published var currentFrame: CGImage?
	private var isRunning = false

	private let frameSkipInterval = 1
	
	func stopVideoProcessing() {
		isRunning = false
	}

	func processVideo(from filename: String, withExtension fileExtension: String, completion: @escaping () -> Void) {
		
		guard let videoURL = Bundle.main.url(forResource: filename, withExtension: fileExtension) else {
			print("❌ Video file not found")
			return
		}

		asset = AVURLAsset(url: videoURL)

		guard let asset = asset,
			  let track = asset.tracks(withMediaType: .video).first else {
			print("❌ Failed to load video track")
			return
		}

		self.videoTrack = track

		do {
			reader = try AVAssetReader(asset: asset)
			videoOutput = AVAssetReaderTrackOutput(track: track, outputSettings: [
				kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
			])

			if let reader = reader, let videoOutput = videoOutput {
				reader.add(videoOutput)
				reader.startReading()

				DispatchQueue.global(qos: .userInitiated).async {
					self.isRunning = true
					var frameIndex = 0
					while self.isRunning, let sampleBuffer = videoOutput.copyNextSampleBuffer() {
						if frameIndex % self.frameSkipInterval == 0,
						   let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
						   let image = VideoManager.convert(pixelBuffer: pixelBuffer) {
							DispatchQueue.main.async {
								self.currentFrame = image
								self.pixelBufferPublisher.send(pixelBuffer)
							}
						}
						frameIndex += 1
					}
					DispatchQueue.main.async {
						completion()
					}
				}
			}
		} catch {
			print("❌ Error setting up video reader: \(error)")
		}
	}
}

extension VideoManager {
	static func convert(pixelBuffer: CVPixelBuffer) -> CGImage? {
		let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
		let context = CIContext()
		return context.createCGImage(ciImage, from: ciImage.extent)
	}
}
