//
//  SliderView.swift
//  Gen_Davies
//
//  Created by Peter Rogers on 15/04/2025.
//
import SwiftUI

struct SliderControlView: View {
	let title: String
	@Binding var threshold: Double
	@Binding var pivot: Double

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text(title)
				.font(.headline)

			VStack(alignment: .leading, spacing: 0) {
				Text("threshold: \(String(format: "%.2f", threshold))")
					.font(.subheadline)
				Slider(value: $threshold, in: 0...2)
			}

			VStack(alignment: .leading, spacing: 0) {
				Text("pivot: \(String(format: "%.2f", pivot))")
					.font(.subheadline)
				Slider(value: $pivot, in: 0...1)
			}
		}
		.padding(10)
		.padding(.bottom, 20)
		.background(Color.gray.opacity(0.1))
	}
}

#Preview {
	SliderControlView(
		title: "Test Sliders",
		threshold: .constant(1.0),
		pivot: .constant(0.5)
	)
	.frame(width: 300)
	.padding()
}
