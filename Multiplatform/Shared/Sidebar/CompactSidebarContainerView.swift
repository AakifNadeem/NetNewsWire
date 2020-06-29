//
//  CompactNavigationView.swift
//  Multiplatform iOS
//
//  Created by Stuart Breckenridge on 29/6/20.
//  Copyright © 2020 Ranchero Software. All rights reserved.
//

import SwiftUI

struct CompactSidebarContainerView: View {
    
	@EnvironmentObject private var sceneModel: SceneModel
	@StateObject private var sidebarModel = SidebarModel()
	
	var body: some View {
		SidebarView()
			.environmentObject(sidebarModel)
			.navigationBarTitle(Text("Feeds"))
			.listStyle(PlainListStyle())
			.onAppear {
				sceneModel.sidebarModel = sidebarModel
				sidebarModel.delegate = sceneModel
				sidebarModel.rebuildSidebarItems()
			}

	}
	
	
}

struct CompactSidebarContainerView_Previews: PreviewProvider {
    static var previews: some View {
        CompactSidebarContainerView()
			.environmentObject(SceneModel())
    }
}
