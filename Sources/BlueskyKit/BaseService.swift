//
//  File.swift
//  
//
//  Created by Charlie Peters on 9/8/24.
//

import Foundation

class BaseService {
	private var baseURL: URL
	private var authSession: AuthSession?
	
	init(instanceURL: String = "https://bsky.app/xrpc", authSession: AuthSession? = nil) {
		guard let url = URL(string: instanceURL) else {
			fatalError("Invalid base URL")
		}
		self.baseURL = url
		self.authSession = authSession
	}
	
	// Function to set or update the authSession
	func setAuthSession(_ session: AuthSession) {
		self.authSession = session
	}
	
	// Function to perform authenticated GET request
	func authenticatedGet<T: Decodable>(endpoint: String, queryParams: [String: String]? = nil, completion: @escaping (Result<T, Error>) -> Void) {
		guard let authSession = authSession, authSession.isAuthenticated else {
			completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Unauthorized: No valid session"])))
			return
		}
		
		authSession.authenticatedGet(endpoint: endpoint, queryParams: queryParams, completion: completion)
	}
	
	// Function to perform unauthenticated GET request
	func get<T: Decodable>(endpoint: String, queryParams: [String: String]? = nil, completion: @escaping (Result<T, Error>) -> Void) {
		var urlComponents = URLComponents(url: baseURL.appendingPathComponent(endpoint), resolvingAgainstBaseURL: true)!
		if let params = queryParams {
			urlComponents.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
		}
		
		guard let url = urlComponents.url else {
			completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
			return
		}
		
		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		
		let task = URLSession.shared.dataTask(with: request) { data, response, error in
			if let error = error {
				completion(.failure(error))
				return
			}
			
			guard let data = data else {
				completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
				return
			}
			
			do {
				let decodedData = try JSONDecoder().decode(T.self, from: data)
				completion(.success(decodedData))
			} catch {
				completion(.failure(error))
			}
		}
		task.resume()
	}
	
	// Function to update the instance URL
	func updateInstanceURL(_ url: String) {
		guard let newURL = URL(string: url) else {
			print("Invalid URL provided")
			return
		}
		self.baseURL = newURL
	}
}
