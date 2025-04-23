//
//  VideoPreview.swift
//  Gen_Davies
//
//  Created by Peter Rogers on 05/04/2025.
//

import SwiftUI
import Combine

struct VideoPreviewView: View {
	@ObservedObject var viewModel: VideoModel
	@EnvironmentObject var appState: AppStateModel
	
	init(viewModel: VideoModel) {
		self.viewModel = viewModel
	}

	var body: some View {
		VStack {
			HStack {
				Text("Audio Player Volumes")
					.font(.headline)
					.padding(.bottom, 4)

				ForEach(Array(appState.audioModel.players.enumerated()), id: \.offset) { index, player in
					VStack(alignment: .leading) {
						Text("Player \(index + 1)")
							.font(.subheadline)

						Slider(
							value: Binding(
								get: { player.volumeMixer.volume },
								set: { player.setAmplitude($0) }
							),
							in: 0...1
						)
					}
				}
			}
			.padding()
			HStack{
				SliderControlView(title: "Light Settings: ", threshold: $appState.contourModel.lightThreshold, pivot: $appState.contourModel.lightPivot)
					.frame(width: 300, height: 300)
				SliderControlView(title: "Dark Settings: ", threshold: $appState.contourModel.darkThreshold, pivot: $appState.contourModel.darkPivot)
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
				if let cgImage = appState.contourModel.light_contourCGImage{
					Image(decorative: cgImage, scale: 1.0)
						.resizable()
						.scaledToFit()
						.frame(width: 300, height: 300)
						.border(Color.gray)
				} else {
					Text("Waiting for frames...")
						.foregroundColor(.gray)
				}
				if let cgImage = appState.contourModel.dark_contourCGImage{
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
