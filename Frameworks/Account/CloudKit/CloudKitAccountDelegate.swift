//
//  CloudKitAppDelegate.swift
//  Account
//
//  Created by Maurice Parker on 3/18/20.
//  Copyright © 2020 Ranchero Software, LLC. All rights reserved.
//

import Foundation
import CloudKit
import os.log
import SyncDatabase
import RSCore
import RSParser
import Articles
import RSWeb

public enum CloudKitAccountDelegateError: String, Error {
	case invalidParameter = "An invalid parameter was used."
}

final class CloudKitAccountDelegate: AccountDelegate {

	private var log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "CloudKit")

	private let database: SyncDatabase
	
	private let container: CKContainer = {
		let orgID = Bundle.main.object(forInfoDictionaryKey: "OrganizationIdentifier") as! String
		return CKContainer(identifier: "iCloud.\(orgID).NetNewsWire")
	}()
	
	private lazy var zones = [accountZone]
	private let accountZone: CloudKitAccountZone
	
	private let refresher = LocalAccountRefresher()

	let behaviors: AccountBehaviors = []
	let isOPMLImportInProgress = false
	
	let server: String? = nil
	var credentials: Credentials?
	var accountMetadata: AccountMetadata?

	var refreshProgress: DownloadProgress {
		return refresher.progress
	}
	
	init(dataFolder: String) {
		accountZone = CloudKitAccountZone(container: container)
		let databaseFilePath = (dataFolder as NSString).appendingPathComponent("Sync.sqlite3")
		database = SyncDatabase(databaseFilePath: databaseFilePath)
		accountZone.refreshProgress = refreshProgress
	}
	
	func receiveRemoteNotification(for account: Account, userInfo: [AnyHashable : Any], completion: @escaping () -> Void) {
		let group = DispatchGroup()
		
		zones.forEach { zone in
			group.enter()
			zone.receiveRemoteNotification(userInfo: userInfo) {
				group.leave()
			}
		}
		
		group.notify(queue: DispatchQueue.main) {
			completion()
		}
	}
	
	func refreshAll(for account: Account, completion: @escaping (Result<Void, Error>) -> Void) {
		accountZone.fetchChangesInZone() { result in
			switch result {
			case .success:
				self.refresher.refreshFeeds(account.flattenedWebFeeds()) {
					account.metadata.lastArticleFetchEndTime = Date()
					completion(.success(()))
				}
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}

	func sendArticleStatus(for account: Account, completion: @escaping ((Result<Void, Error>) -> Void)) {
		completion(.success(()))
	}
	
	func refreshArticleStatus(for account: Account, completion: @escaping ((Result<Void, Error>) -> Void)) {
		completion(.success(()))
	}
	
	func importOPML(for account:Account, opmlFile: URL, completion: @escaping (Result<Void, Error>) -> Void) {
		var fileData: Data?
		
		do {
			fileData = try Data(contentsOf: opmlFile)
		} catch {
			completion(.failure(error))
			return
		}
		
		guard let opmlData = fileData else {
			completion(.success(()))
			return
		}
		
		let parserData = ParserData(url: opmlFile.absoluteString, data: opmlData)
		var opmlDocument: RSOPMLDocument?
		
		do {
			opmlDocument = try RSOPMLParser.parseOPML(with: parserData)
		} catch {
			completion(.failure(error))
			return
		}
		
		guard let loadDocument = opmlDocument else {
			completion(.success(()))
			return
		}

		guard let children = loadDocument.children else {
			return
		}

		BatchUpdate.shared.perform {
			account.loadOPMLItems(children, parentFolder: nil)
		}
		
		completion(.success(()))

	}
	
	func createWebFeed(for account: Account, url urlString: String, name: String?, container: Container, completion: @escaping (Result<WebFeed, Error>) -> Void) {
		guard let url = URL(string: urlString) else {
			completion(.failure(LocalAccountDelegateError.invalidParameter))
			return
		}
		
		refreshProgress.addToNumberOfTasksAndRemaining(1)
		FeedFinder.find(url: url) { result in
			
			switch result {
			case .success(let feedSpecifiers):
				guard let bestFeedSpecifier = FeedSpecifier.bestFeed(in: feedSpecifiers), let url = URL(string: bestFeedSpecifier.urlString) else {
					self.refreshProgress.completeTask()
					completion(.failure(AccountError.createErrorNotFound))
					return
				}
				
				if account.hasWebFeed(withURL: bestFeedSpecifier.urlString) {
					self.refreshProgress.completeTask()
					completion(.failure(AccountError.createErrorAlreadySubscribed))
					return
				}
				
				self.accountZone.createWebFeed(url: bestFeedSpecifier.urlString, editedName: name, container: container) { result in
					switch result {
					case .success(let containerWebFeed):
						
						let feed = account.createWebFeed(with: nil, url: url.absoluteString, webFeedID: url.absoluteString, homePageURL: nil)
						
						InitialFeedDownloader.download(url) { parsedFeed in
							self.refreshProgress.completeTask()

							if let parsedFeed = parsedFeed {
								account.update(feed, with: parsedFeed, {_ in
									
									feed.editedName = name
									feed.externalID = containerWebFeed.webFeedExternalID
									feed.folderRelationship?[containerWebFeed.containerWebFeedExternalID] = containerWebFeed.containerExternalID
									
									container.addWebFeed(feed)
									completion(.success(feed))
									
								})
							}
							
						}

					case .failure(let error):
						self.refreshProgress.completeTask()
						completion(.failure(error))  // TODO: need to handle userDeletedZone
					}
				}
								
			case .failure:
				self.refreshProgress.completeTask()
				completion(.failure(AccountError.createErrorNotFound))
			}
			
		}

	}

	func renameWebFeed(for account: Account, with feed: WebFeed, to name: String, completion: @escaping (Result<Void, Error>) -> Void) {
		let editedName = name.isEmpty ? nil : name
		accountZone.renameWebFeed(feed, editedName: editedName) { result in
			switch result {
			case .success:
				feed.editedName = name
				completion(.success(()))
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}

	func removeWebFeed(for account: Account, with feed: WebFeed, from container: Container, completion: @escaping (Result<Void, Error>) -> Void) {
		accountZone.removeWebFeed(feed) { result in
			switch result {
			case .success:
				container.removeWebFeed(feed)
				completion(.success(()))
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
	
	func moveWebFeed(for account: Account, with feed: WebFeed, from: Container, to: Container, completion: @escaping (Result<Void, Error>) -> Void) {
		from.removeWebFeed(feed)
		to.addWebFeed(feed)
		completion(.success(()))
	}
	
	func addWebFeed(for account: Account, with feed: WebFeed, to container: Container, completion: @escaping (Result<Void, Error>) -> Void) {
		container.addWebFeed(feed)
		completion(.success(()))
	}
	
	func restoreWebFeed(for account: Account, feed: WebFeed, container: Container, completion: @escaping (Result<Void, Error>) -> Void) {
		container.addWebFeed(feed)
		completion(.success(()))
	}
	
	func createFolder(for account: Account, name: String, completion: @escaping (Result<Folder, Error>) -> Void) {
		accountZone.createFolder(name: name) { result in
			switch result {
			case .success(let externalID):
				if let folder = account.ensureFolder(with: name) {
					folder.externalID = externalID
					completion(.success(folder))
				} else {
					completion(.failure(FeedbinAccountDelegateError.invalidParameter))
				}
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
	
	func renameFolder(for account: Account, with folder: Folder, to name: String, completion: @escaping (Result<Void, Error>) -> Void) {
		accountZone.renameFolder(folder, to: name) { result in
			switch result {
			case .success:
				folder.name = name
				completion(.success(()))
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
	
	func removeFolder(for account: Account, with folder: Folder, completion: @escaping (Result<Void, Error>) -> Void) {
		accountZone.removeFolder(folder) { result in
			switch result {
			case .success:
				account.removeFolder(folder)
				completion(.success(()))
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
	
	func restoreFolder(for account: Account, folder: Folder, completion: @escaping (Result<Void, Error>) -> Void) {
		guard let name = folder.name else {
			completion(.failure(LocalAccountDelegateError.invalidParameter))
			return
		}
		
		accountZone.createFolder(name: name) { result in
			switch result {
			case .success(let externalID):
				folder.externalID = externalID
				account.addFolder(folder)
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}

	func markArticles(for account: Account, articles: Set<Article>, statusKey: ArticleStatus.Key, flag: Bool) -> Set<Article>? {
		return try? account.update(articles, statusKey: statusKey, flag: flag)
	}

	func accountDidInitialize(_ account: Account) {
		accountZone.delegate = CloudKitAcountZoneDelegate(account: account, refreshProgress: refreshProgress)
		
		if account.externalID == nil {
			accountZone.findOrCreateAccount() { result in
				switch result {
				case .success(let externalID):
					account.externalID = externalID
				case .failure(let error):
					os_log(.error, log: self.log, "Error adding account container: %@", error.localizedDescription)
				}
			}
		}
		
		zones.forEach { zone in
			zone.resumeLongLivedOperationIfPossible()
			zone.subscribe()
		}
	}
	
	func accountWillBeDeleted(_ account: Account) {
		zones.forEach { zone in
			zone.resetChangeToken()
		}
	}

	static func validateCredentials(transport: Transport, credentials: Credentials, endpoint: URL? = nil, completion: (Result<Credentials?, Error>) -> Void) {
		return completion(.success(nil))
	}

	// MARK: Suspend and Resume (for iOS)

	func suspendNetwork() {
		refresher.suspend()
	}

	func suspendDatabase() {
		// Nothing to do
	}
	
	func resume() {
		refresher.resume()
	}
}
