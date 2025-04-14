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
					appState.currentSource = .camera
					if appState.cameraManager == nil {
						appState.cameraManager = CameraManager()
					}
					if let cameraManager = appState.cameraManager {
						appState.bindToCameraManager(cameraManager)
					}
				}

				BlueButton(title: "Use Video") {
					appState.currentSource = .video
					let videoManager = VideoManager()
					appState.videoManager = videoManager
					appState.bindToVideoManager(videoManager)
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
			if let cameraManager = appState.cameraManager {
				VideoPreviewView(provider: cameraManager)
			}
		case .video:
			if let videoManager = appState.videoManager {
				VideoPreviewView(provider: videoManager)
			}
		}
	}
}

#Preview {
	ContentView()
}
