//
//  NetworkService.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 19.03.2026.
//

import Foundation

enum NetworkError: LocalizedError, Sendable {
    case invalidResponse
    case decodingFailed
    case transport(Error)
    case empty

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "The server returned an invalid response."
        case .decodingFailed: return "Could not read the data from the server."
        case .transport(let error): return error.localizedDescription
        case .empty: return "No results found for this route."
        }
    }
}

// Protocol-oriented networking. The app talks to NetworkService, never to a
// concrete HTTP client. Tests / previews swap in a mock implementation.
protocol NetworkService: Sendable {
    func request<T: Decodable & Sendable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T
}

struct Endpoint: Sendable {
    let path: String
    let query: [String: String]

    init(path: String, query: [String: String] = [:]) {
        self.path = path
        self.query = query
    }
}
