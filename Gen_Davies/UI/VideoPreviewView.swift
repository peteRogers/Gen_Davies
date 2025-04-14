//
//  VideoPreview.swift
//  Gen_Davies
//
//  Created by Peter Rogers on 05/04/2025.
//

import SwiftUI
import Combine

protocol VideoFrameProvider: ObservableObject {
	var currentFrame: CGImage? { get }
	func startVideoProcessing()
	func stopVideoProcessing()
}

struct VideoPreviewView: View {
	@StateObject private var viewModel: VideoPreviewViewModel
	@EnvironmentObject var appState: AppStateModel

	init(provider: some VideoFrameProvider) {
		_viewModel = StateObject(wrappedValue: VideoPreviewViewModel(provider: provider))
	}

	var body: some View {
		VStack {
			if let cgImage = viewModel.currentFrame {
				Image(decorative: cgImage, scale: 1.0)
					.resizable()
					.scaledToFit()
					.frame(width: 300, height: 300)
					.border(Color.gray)
			} else {
				Text("Waiting for frames...")
					.foregroundColor(.gray)
			}
		}
		.onAppear {
			viewModel.start()
		}
	}
}

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
