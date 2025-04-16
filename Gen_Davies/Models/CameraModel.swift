//
//  CameraModel.swift
//  Gen_Davies
//
//  Created by Peter Rogers on 15/04/2025.
//
import SwiftUI
import Combine

@MainActor
class CameraModel: ObservableObject {
	let manager = CameraManager()
	@Published var currentPixelBuffer: CVPixelBuffer?

	private var cancellables = Set<AnyCancellable>()

	init(contourModel: ContourModel) {
		manager.pixelBufferPublisher
			.receive(on: RunLoop.main)
			.sink { [weak contourModel] buffer in
				contourModel?.processNewFrame(buffer)
			}
			.store(in: &cancellables)
	}
	
	func start() {
		manager.startVideoProcessing()
	}
	
	func stop(){
		manager.stopVideoProcessing()
	}
}
