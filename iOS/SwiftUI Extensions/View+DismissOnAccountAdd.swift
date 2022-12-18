//
//  View+DismissOnAccountAdd.swift
//  NetNewsWire-iOS
//
//  Created by Stuart Breckenridge on 18/12/2022.
//  Copyright © 2022 Ranchero Software. All rights reserved.
//

import SwiftUI

struct DismissOnAccountAdd: ViewModifier {
	
	@Environment(\.dismiss) private var dismiss
	
	func body(content: Content) -> some View {
		content
			.onReceive(NotificationCenter.default.publisher(for: .UserDidAddAccount)) { _ in
			dismiss()
		}
	}
	
}

extension View {
	func dismissOnAccountAdd() -> some View {
		modifier(DismissOnAccountAdd())
	}
}
