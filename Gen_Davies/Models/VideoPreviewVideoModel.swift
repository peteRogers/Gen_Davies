//
//  VideoPreviewModel.swift
//  Gen_Davies
//
//  Created by Peter Rogers on 15/04/2025.
//

import SwiftUI
import Combine

class VideoPreviewViewModel: ObservableObject {
	@Published var currentFrame: CGImage?
	private var provider: any VideoFrameProvider
	private var cancellable: AnyCancellable?

	init(provider: some VideoFrameProvider) {
		self.provider = provider
		self.cancellable = provider
			.objectWillChange
			.receive(on: RunLoop.main)
			.sink { [weak self] _ in
				self?.currentFrame = provider.currentFrame
			}
	}

	func start() {
		provider.startVideoProcessing()
	}

	func stop() {
		
		provider.stopVideoProcessing()
	}

	func setProvider(_ newProvider: some VideoFrameProvider) {
		self.provider = newProvider
		self.cancellable = newProvider
			.objectWillChange
			.receive(on: RunLoop.main)
			.sink { [weak self] _ in
				self?.currentFrame = newProvider.currentFrame
			}
	}
}

protocol VideoFrameProvider: ObservableObject {
	var currentFrame: CGImage? { get }
	func startVideoProcessing()
	func stopVideoProcessing()
}


