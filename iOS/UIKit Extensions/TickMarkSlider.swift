//
//  TickMarkSlider.swift
//  NetNewsWire-iOS
//
//  Created by Maurice Parker on 11/8/19.
//  Copyright © 2019 Ranchero Software. All rights reserved.
//

import UIKit
import SwiftUI

struct TickMarkSliderView: UIViewRepresentable {
	
	var minValue: Int
	var maxValue: Int
	@Binding var currentValue: Float
	
	func makeUIView(context: Context) -> TickMarkSlider {
		let slider = TickMarkSlider()
		slider.minimumValue = Float(minValue)
		slider.maximumValue = Float(maxValue)
		slider.value = currentValue
		slider.addTickMarks()
		return slider
	}
	
	func updateUIView(_ uiView: TickMarkSlider, context: Context) {
		uiView.addTarget(
			context.coordinator,
			action: #selector(Coordinator.valueChanged(_:)),
			for: .valueChanged
		)
	}
	
	func makeCoordinator() -> Coordinator {
		Coordinator(value: $currentValue)
	}
	
	class Coordinator: NSObject {
		var value: Binding<Float>
		
		init(value: Binding<Float>) {
			self.value = value
		}
		
		// Create a valueChanged(_:) action
		@objc func valueChanged(_ sender: Any) {
			if let slider = sender as? UISlider {
				self.value.wrappedValue = Float(slider.value.rounded())
			}
		}
		
	}
	
	typealias UIViewType = TickMarkSlider
}

class TickMarkSlider: UISlider {

	private var enableFeedback = false
	private let feedbackGenerator = UISelectionFeedbackGenerator()
	
	private var roundedValue: Float?
	override var value: Float {
		didSet {
			let testValue = value.rounded()
			if testValue != roundedValue && enableFeedback && value.truncatingRemainder(dividingBy: 1) == 0 {
				roundedValue = testValue
				feedbackGenerator.selectionChanged()
			}
		}
	}
	
	func addTickMarks() {

		enableFeedback = true
		
		let numberOfGaps = Int(maximumValue) - Int(minimumValue)
		
		var gapLayoutGuides = [UILayoutGuide]()
		
		for i in 0...numberOfGaps {
			
			let tick = UIView()
			tick.translatesAutoresizingMaskIntoConstraints = false
			tick.backgroundColor = AppAssets.tickMarkColor
			insertSubview(tick, at: 0)

			tick.widthAnchor.constraint(equalToConstant: 3).isActive = true
			tick.heightAnchor.constraint(equalToConstant: 10).isActive = true
			tick.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true

			if i == 0 {
				tick.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
			}
			
			if let lastGapLayoutGuild = gapLayoutGuides.last {
				lastGapLayoutGuild.trailingAnchor.constraint(equalTo: tick.leadingAnchor).isActive = true
			}
			
			if i != numberOfGaps {
				let gapLayoutGuild = UILayoutGuide()
				gapLayoutGuides.append(gapLayoutGuild)
				addLayoutGuide(gapLayoutGuild)
				tick.trailingAnchor.constraint(equalTo: gapLayoutGuild.leadingAnchor).isActive = true
			} else {
				tick.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
			}
			
		}
		
		if let firstGapLayoutGuild = gapLayoutGuides.first {
			for i in 1..<gapLayoutGuides.count {
				gapLayoutGuides[i].widthAnchor.constraint(equalTo: firstGapLayoutGuild.widthAnchor).isActive = true
			}
		}
				
	}
	
	override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
		let result = super.continueTracking(touch, with: event)
		value = value.rounded()
		return result
	}

	override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
		value = value.rounded()
	}
	
}
