//
//  CustomButtonView.swift
//  Gen_Davies
//
//  Created by Peter Rogers on 06/04/2025.
//
import SwiftUI

struct BlueButton: View {
	var title: String
	var action: () -> Void

	var body: some View {
		Button(action: action) {
			Text(title)
				.font(.headline)
				.foregroundColor(.white)
				.padding()
				.frame(maxWidth: .infinity)
				.background(Color.blue)
				.cornerRadius(10)
		}
		.padding(.horizontal)
	}
}
