//
//  LocationService.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 20.03.2026.
//

import Foundation

protocol LocationService: Sendable {
    func search(query: String) async throws -> [Location]
}

nonisolated struct LocationsResponse: Codable, Sendable {
    let locations: [Location]
}

final class DefaultLocationService: LocationService {
    private let network: NetworkService

    init(network: NetworkService) { self.network = network }

    func search(query: String) async throws -> [Location] {
        let endpoint = Endpoint(path: "/locations", query: ["q": query])
        let response: LocationsResponse = try await network.request(endpoint, as: LocationsResponse.self)
        return response.locations
    }
}
