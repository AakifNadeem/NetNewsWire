//
//  TwitterFeedProvider+Extensions.swift
//  NetNewsWire
//
//  Created by Maurice Parker on 4/7/20.
//  Copyright © 2020 Ranchero Software. All rights reserved.
//

import Foundation
import FeedProvider
import RSCore
import OAuthSwift
import Secrets

extension TwitterFeedProvider: ExtensionPoint {
	
	static var isSinglton = false
	static var title = NSLocalizedString("Twitter", comment: "Twitter")
	static var templateImage = AppAssets.extensionPointTwitter
	static var description: NSAttributedString = {
		let attrString = TwitterFeedProvider.makeAttrString("This extension enables you to subscribe to Twitter URL's as if they were RSS feeds.")
		let range = NSRange(location: 43, length: 7)
		attrString.beginEditing()
		attrString.addAttribute(NSAttributedString.Key.link, value: "https://twitter.com", range: range)
		attrString.addAttribute(NSAttributedString.Key.foregroundColor, value: NSColor.systemBlue, range: range)
		attrString.endEditing()
		return attrString
	}()

	var extensionPointID: ExtensionPointIdentifer {
		return ExtensionPointIdentifer.twitter(userID, screenName)
	}

	var title: String {
		return "@\(screenName)"
	}

}
