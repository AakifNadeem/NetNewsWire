//
//  InjectedNavigationView.swift
//  NetNewsWire-iOS
//
//  Created by Stuart Breckenridge on 15/12/2022.
//  Copyright © 2022 Ranchero Software. All rights reserved.
//

import SwiftUI

struct InjectedNavigationView: View {
	
	@Environment(\.dismiss) var dismiss
	var injectedView: any View
	
	var body: some View {
		NavigationView {
			AnyView(injectedView)
				.toolbar {
					ToolbarItem(placement: .navigationBarLeading) {
						Button(role: .cancel) {
							dismiss()
						} label: {
							Text("DONE_BUTTON_TITLE", tableName: "Buttons")
						}
					}
				}				
		}.navigationViewStyle(.stack)
	}
}
