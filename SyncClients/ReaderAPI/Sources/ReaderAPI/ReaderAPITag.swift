//
//  ReaderAPICompatibleTag.swift
//  Account
//
//  Created by Jeremy Beker on 5/28/19.
//  Copyright © 2019 Ranchero Software, LLC. All rights reserved.
//

import Foundation

struct ReaderAPITagContainer: Codable {
	let tags: [ReaderAPITag]
	
	enum CodingKeys: String, CodingKey {
		case tags = "tags"
	}
}

public struct ReaderAPITag: Codable {
	
	public let tagID: String
	public let type: String?
	
	enum CodingKeys: String, CodingKey {
		case tagID = "id"
		case type = "type"
	}
	
	public var folderName: String? {
		guard let range = tagID.range(of: "/label/") else {
			return nil
		}
		return String(tagID.suffix(from: range.upperBound))
	}
	
}
