//
//  File.swift
//  
//
//  Created by Charlie Peters on 9/8/24.
//

import Foundation

class AuthSession {
	private var baseURL: URL
	private var bearerToken: String?
	
	init(instanceURL: String = "https://bsky.app/xrpc") {
		guard let url = URL(string: instanceURL) else {
			fatalError("Invalid base URL")
		}
		self.baseURL = url
	}
	
	// Function to set bearer token
	func setBearerToken(_ token: String) {
		self.bearerToken = token
	}
	
	// Function to check if the session is authenticated
	var isAuthenticated: Bool {
		return bearerToken != nil
	}
	
	// Function to perform an authenticated GET request
	func authenticatedGet<T: Decodable>(endpoint: String, queryParams: [String: String]? = nil, completion: @escaping (Result<T, Error>) -> Void) {
		guard let token = bearerToken else {
			completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Unauthorized: Bearer token is missing"])))
			return
		}
		
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
		request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		
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
	
	// Example: Function to login and retrieve bearer token (if needed)
	func login(username: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
		// Create the login request (this depends on how Bluesky handles auth)
		let loginURL = baseURL.appendingPathComponent("loginEndpoint") // Replace with actual login endpoint
		
		var request = URLRequest(url: loginURL)
		request.httpMethod = "POST"
		let body: [String: Any] = ["username": username, "password": password]
		request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		
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
				let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
				if let token = json?["accessToken"] as? String {
					self.setBearerToken(token)
					completion(.success(token))
				} else {
					completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
				}
			} catch {
				completion(.failure(error))
			}
		}
		task.resume()
	}
	
	// Function to log out by clearing the token
	func logout() {
		self.bearerToken = nil
	}
}
