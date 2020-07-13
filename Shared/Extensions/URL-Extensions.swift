//
//  URL-Extensions.swift
//  NetNewsWire
//
//  Created by Stuart Breckenridge on 03/05/2020.
//  Copyright © 2020 Ranchero Software. All rights reserved.
//

import Foundation

extension URL {
	
	/// Extracts email address from a `URL` with a `mailto` scheme, otherwise `nil`.
	var emailAddress: String? {
		scheme == "mailto" ? URLComponents(url: self, resolvingAgainstBaseURL: false)?.path : nil
	}
	
	func valueFor(_ parameter: String) -> String? {
		guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
			  let queryItems = components.queryItems,
			  let value = queryItems.first(where: { $0.name == parameter })?.value else {
			return nil
		}
		return value
	}
	
}
