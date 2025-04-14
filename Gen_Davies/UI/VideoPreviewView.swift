//
//  VideoPreview.swift
//  Gen_Davies
//
//  Created by Peter Rogers on 05/04/2025.
//

import SwiftUI
import Combine



struct VideoPreviewView: View {
	@StateObject private var viewModel: VideoPreviewViewModel
	@EnvironmentObject var appState: AppStateModel

	init(provider: some VideoFrameProvider) {
		_viewModel = StateObject(wrappedValue: VideoPreviewViewModel(provider: provider))
	}

	var body: some View {
		VStack {
			HStack{
				SliderControlView(threshold: $appState.lightThreshold, pivot: $appState.lightPivot)
					.frame(width: 300, height: 300)
				SliderControlView(threshold: $appState.darkThreshold, pivot: $appState.darkPivot)
					.frame(width: 300, height: 300)
			}
			HStack{
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
				if let cgImage = appState.light_contourCGImage{
					Image(decorative: cgImage, scale: 1.0)
						.resizable()
						.scaledToFit()
						.frame(width: 300, height: 300)
						.border(Color.gray)
				} else {
					Text("Waiting for frames...")
						.foregroundColor(.gray)
				}
				if let cgImage = appState.dark_contourCGImage{
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
			//SliderControlView(value1: .constant(0.5), value2: .constant(0.5)) // Example usage of SliderControlView
		}
		.onAppear {
			viewModel.start()
		}
	}
}


