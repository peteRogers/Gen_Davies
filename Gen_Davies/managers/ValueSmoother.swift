//
//  ValueSmoother.swift
//  Gen_Davies
//
//  Created by Peter Rogers on 29/04/2025.
//

import Foundation
import AudioKit

class ValueSmoother {
	private(set) var value: AUValue
	private var target: AUValue
	private let smoothingFactor: AUValue

	init(initialValue: AUValue, smoothingFactor: AUValue = 0.05) {
		self.value = initialValue
		self.target = initialValue
		self.smoothingFactor = smoothingFactor
	}

	func setTarget(_ newTarget: AUValue) {
		self.target = newTarget
	}

	func update() {
		value += (target - value) * smoothingFactor
	}
}
