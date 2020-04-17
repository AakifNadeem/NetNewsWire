//
//  Tweet.swift
//  Account
//
//  Created by Maurice Parker on 4/16/20.
//  Copyright © 2020 Ranchero Software, LLC. All rights reserved.
//

import Foundation

final class TwitterStatus: Codable {

	let createdAt: Date?
	let idStr: String?
	let fullText: String?
	let displayTextRange: [Int]?
	let user: TwitterUser
	let truncated: Bool
	let retweeted: Bool
	let retweetedStatus: TwitterStatus?
	let quotedStatus: TwitterStatus?

	enum CodingKeys: String, CodingKey {
		case createdAt = "created_at"
		case idStr = "id_str"
		case fullText = "full_text"
		case displayTextRange = "display_text_range"
		case user = "user"
		case truncated = "truncated"
		case retweeted = "retweeted"
		case retweetedStatus = "retweeted_status"
		case quotedStatus = "quoted_status"
	}
	
}
