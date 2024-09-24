import XCTest
import Alamofire
@testable import BlueskyKit

final class BlueskyKitTests: XCTestCase {
	var kit: BlueskyKit!
	var mockBaseURL: URL!
	
	override func setUp() {
		super.setUp()
		mockBaseURL = URL(string: "https://mock.bsky.social")!
		
		let configuration = URLSessionConfiguration.default
		configuration.protocolClasses = [MockURLProtocol.self]
		let session = Session(configuration: configuration)
		
		kit = BlueskyKit(baseURL: mockBaseURL)
		kit.client = ATProtoClient(baseURL: mockBaseURL, session: session)
	}
	
	func testInitialization() {
		XCTAssertNotNil(kit)
		XCTAssertNotNil(kit.client)
	}
	
	func testLogin() {
		let expectation = self.expectation(description: "Login")
		
		// Use placeholder values for testing
		let testIdentifier = "fairweather.blue"
		let testPassword = "FDtxK3xDKCrJ6Au"
		
		// Mock the network request
		MockURLProtocol.requestHandler = { request in
			let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
			let data = """
			{
				"accessJwt": "mockAccessToken",
				"refreshJwt": "mockRefreshToken",
				"handle": "test.bsky.social",
				"did": "did:plc:testuser123"
			}
			""".data(using: .utf8)!
			return (response, data)
		}
		
		kit.client.login(identifier: testIdentifier, password: testPassword) { result in
			switch result {
			case .success(let session):
				XCTAssertEqual(session.handle, "fairweather.blue")
				XCTAssertEqual(session.did, "did:plc:rfudfcqwxkz2ouapeguova7f")
				XCTAssertEqual(session.accessJwt, "mockAccessToken")
				XCTAssertEqual(session.refreshJwt, "mockRefreshToken")
			case .failure(let error):
				XCTFail("Login failed with error: \(error)")
			}
			expectation.fulfill()
		}
		
		waitForExpectations(timeout: 5, handler: nil)
	}
	
	func testGetTimeline() {
		let expectation = self.expectation(description: "Get Timeline")
		
		// Mock the network request
		MockURLProtocol.requestHandler = { request in
			let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
			let data = """
			{
				"feed": [
					{
						"post": {
							"uri": "at://did:plc:testuser123/app.bsky.feed.post/1234",
							"cid": "bafyreia...",
							"author": {
								"did": "did:plc:testuser123",
								"handle": "test.bsky.social"
							},
							"record": {
								"text": "Hello, Bluesky!",
								"createdAt": "2023-06-01T12:00:00Z"
							},
							"indexedAt": "2023-06-01T12:00:01Z"
						}
					}
				],
				"cursor": "nextCursor123"
			}
			""".data(using: .utf8)!
			return (response, data)
		}
		
		kit.client.getTimeline { result in
			switch result {
			case .success(let feedResponse):
				XCTAssertEqual(feedResponse.feed.count, 1)
				XCTAssertEqual(feedResponse.feed[0].post.record.text, "Hello, Bluesky!")
				XCTAssertEqual(feedResponse.cursor, "nextCursor123")
			case .failure(let error):
				XCTFail("Get timeline failed with error: \(error)")
			}
			expectation.fulfill()
		}
		
		waitForExpectations(timeout: 5, handler: nil)
	}
	
	func testCreatePost() {
		let expectation = self.expectation(description: "Create Post")
		
		// Mock the network request
		MockURLProtocol.requestHandler = { request in
			let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
			let data = """
			{
				"uri": "at://did:plc:testuser123/app.bsky.feed.post/1234",
				"cid": "bafyreia..."
			}
			""".data(using: .utf8)!
			return (response, data)
		}
		
		kit.client.createPost(text: "Hello, Bluesky!") { result in
			switch result {
			case .success(let postReference):
				XCTAssertEqual(postReference.uri, "at://did:plc:testuser123/app.bsky.feed.post/1234")
				XCTAssertEqual(postReference.cid, "bafyreia...")
			case .failure(let error):
				XCTFail("Create post failed with error: \(error)")
			}
			expectation.fulfill()
		}
		
		waitForExpectations(timeout: 5, handler: nil)
	}
	
	func testGetProfile() {
		let expectation = self.expectation(description: "Get Profile")
		
		// Mock the network request
		MockURLProtocol.requestHandler = { request in
			let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
			let data = """
			{
				"did": "did:plc:testuser123",
				"handle": "test.bsky.social",
				"displayName": "Test User",
				"description": "This is a test profile",
				"followersCount": 100,
				"followsCount": 50,
				"postsCount": 25
			}
			""".data(using: .utf8)!
			return (response, data)
		}
		
		kit.client.getProfile(actor: "test.bsky.social") { result in
			switch result {
			case .success(let profile):
				XCTAssertEqual(profile.did, "did:plc:testuser123")
				XCTAssertEqual(profile.handle, "test.bsky.social")
				XCTAssertEqual(profile.displayName, "Test User")
				XCTAssertEqual(profile.description, "This is a test profile")
				XCTAssertEqual(profile.followersCount, 100)
				XCTAssertEqual(profile.followsCount, 50)
				XCTAssertEqual(profile.postsCount, 25)
			case .failure(let error):
				XCTFail("Get profile failed with error: \(error)")
			}
			expectation.fulfill()
		}
		
		waitForExpectations(timeout: 5, handler: nil)
	}
}

// Mock URLProtocol for simulating network responses
class MockURLProtocol: URLProtocol {
	static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
	
	override class func canInit(with request: URLRequest) -> Bool {
		return true
	}
	
	override class func canonicalRequest(for request: URLRequest) -> URLRequest {
		return request
	}
	
	override func startLoading() {
		guard let handler = MockURLProtocol.requestHandler else {
			fatalError("Handler is unavailable.")
		}
		
		do {
			let (response, data) = try handler(request)
			client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
			client?.urlProtocol(self, didLoad: data)
			client?.urlProtocolDidFinishLoading(self)
		} catch {
			client?.urlProtocol(self, didFailWithError: error)
		}
	}
	
	override func stopLoading() {}
}
