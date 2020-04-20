//
//  TwitterHashtag.swift
//  Account
//
//  Created by Maurice Parker on 4/18/20.
//  Copyright © 2020 Ranchero Software, LLC. All rights reserved.
//

import Foundation

struct TwitterHashtag: Codable, TwitterEntity {
	
	let text: String?
	let indices: [Int]?

	enum CodingKeys: String, CodingKey {
		case text = "text"
		case indices = "indices"
	}
	
	var startIndex: Int {
		if let indices = indices, indices.count > 0 {
			return indices[0] - 1
		}
		return 0
	}
	
	func renderAsHTML() -> String {
		return ""
	}
}
