//
//  ContentView.swift
//  Gen_Davies
//
//  Created by Peter Rogers on 05/04/2025.
//

import SwiftUI

struct ContentView: View {
	@StateObject private var appState = AppStateModel()
	
	var body: some View {
		VStack {
			previewView
			Spacer()
			HStack {
				Spacer()
				BlueButton(title: "Use Camera") {
					appState.switchSource(to: .camera)
				}

				BlueButton(title: "Use Video") {
					appState.switchSource(to: .video)
				}
				Spacer()
			}
			
			
		}
		.padding()
		.environmentObject(appState)
	}
	
	@ViewBuilder
	private var previewView: some View {
		switch appState.currentSource {
		case .camera:
			VideoPreviewView(viewModel: VideoModel(provider: appState.cameraModel.manager))
		case .video:
			VideoPreviewView(viewModel: appState.videoModel)
		}
	}
}

#Preview {
	ContentView()
}
