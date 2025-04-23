//
//  AudioControlsView.swift
//  Gen_Davies
//
//  Created by Peter Rogers on 23/04/2025.
//

//
//  VideoPreview.swift
//  Gen_Davies
//
//  Created by Peter Rogers on 05/04/2025.
//

import SwiftUI
import Combine
import AudioKit

struct AudioControlsView: View {
	let index: Int
	let volume: Binding<AUValue>
	let pan: Binding<AUValue>
	let reverbFedbcak: Binding<AUValue>
	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Audio \(index)")
				.font(.headline)
			VStack(alignment: .leading, spacing: 0) {
				Text("volume")
					.font(.subheadline)
				Slider(value: volume, in: 0...1)
				
			}
			VStack(alignment: .leading, spacing: 0) {
				Text("pan")
					.font(.subheadline)
				Slider(value: pan, in: -1...1)
			}
			VStack(alignment: .leading, spacing: 0) {
				Text("reverb feedback")
					.font(.subheadline)
				Slider(value: reverbFedbcak, in: 0...0.9)
			}
		}
		.padding(10)
		.padding(.bottom, 20)
		.background(Color.gray.opacity(0.1))
	}
}

#Preview {
	AudioControlsView(
		index: 0,
		volume: .constant(0.5),
		pan: .constant(0.0),
		reverbFedbcak: .constant(0.3)
	)
	.frame(width: 300)
	.padding()
}
