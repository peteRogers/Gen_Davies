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
		VStack(alignment: .leading, spacing: 20) {
			Text(title)
				.font(.headline)

			VStack(alignment: .leading) {
				Text("threshold: \(String(format: "%.2f", threshold))")
				Slider(value: $threshold, in: 0...2)
			}

			VStack(alignment: .leading) {
				Text("pivot: \(String(format: "%.2f", pivot))")
				Slider(value: $pivot, in: 0...1)
			}
		}
		.padding()
	}
}
