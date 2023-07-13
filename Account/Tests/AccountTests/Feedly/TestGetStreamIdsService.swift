//
//  TestGetStreamIdsService.swift
//  AccountTests
//
//  Created by Kiel Gillard on 29/10/19.
//  Copyright © 2019 Ranchero Software, LLC. All rights reserved.
//

import XCTest
@testable import Account

final class TestGetStreamIdsService: FeedlyGetStreamIDsService {
	
	var mockResult: Result<FeedlyStreamIDs, Error>?
	var parameterTester: ((FeedlyResourceId, String?, Date?, Bool?) -> ())?
	var getStreamIdsExpectation: XCTestExpectation?
	
	func getStreamIds(for resource: FeedlyResourceId, continuation: String?, newerThan: Date?, unreadOnly: Bool?, completion: @escaping (Result<FeedlyStreamIDs, Error>) -> ()) {
		guard let result = mockResult else {
			XCTFail("Missing mock result. Test may time out because the completion will not be called.")
			return
		}
		parameterTester?(resource, continuation, newerThan, unreadOnly)
		DispatchQueue.main.async {
			completion(result)
			self.getStreamIdsExpectation?.fulfill()
		}
	}
}
