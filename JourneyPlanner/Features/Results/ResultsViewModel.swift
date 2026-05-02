//
//  ResultsViewModel.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 26.03.2026.
//

import Foundation

@MainActor
final class ResultsViewModel {

    enum State {
        case loading
        case loaded([Journey])
        case empty
        case error(String)
    }

    enum Sort: Int, CaseIterable {
        case earliest, fastest, fewestTransfers

        var title: String {
            switch self {
            case .earliest: return "Earliest"
            case .fastest: return "Fastest"
            case .fewestTransfers: return "Transfers"
            }
        }
    }

    private let journeyService: JourneyService
    private let favorites: FavoritesRepository
    let origin: Location
    let destination: Location

    private var rawJourneys: [Journey] = []
    private(set) var state: State = .loading
    private(set) var sort: Sort = .earliest

    var onStateChange: ((State) -> Void)?

    init(journeyService: JourneyService, favorites: FavoritesRepository, origin: Location, destination: Location) {
        self.journeyService = journeyService
        self.favorites = favorites
        self.origin = origin
        self.destination = destination
    }

    func load(showLoading: Bool = true) {
        if showLoading { update(.loading) }
        Task { [weak self] in
            guard let self else { return }
            do {
                let journeys = try await self.journeyService.journeys(from: self.origin, to: self.destination)
                self.rawJourneys = journeys
                self.applySort()
            } catch NetworkError.empty {
                self.rawJourneys = []
                self.update(.empty)
            } catch {
                self.update(.error(error.localizedDescription))
            }
        }
    }

    func setSort(_ new: Sort) {
        guard sort != new else { return }
        sort = new
        applySort()
    }

    func isFavorite(_ journey: Journey) -> Bool {
        favorites.contains(FavoriteJourney.makeID(origin: origin, destination: destination, journey: journey))
    }

    @discardableResult
    func toggleFavorite(_ journey: Journey) -> Bool {
        favorites.toggle(journey: journey, origin: origin, destination: destination)
    }

    static func sort(_ journeys: [Journey], by sort: Sort) -> [Journey] {
        switch sort {
        case .earliest:
            return journeys.sorted { $0.departure < $1.departure }
        case .fastest:
            return journeys.sorted { $0.duration < $1.duration }
        case .fewestTransfers:
            return journeys.sorted {
                if $0.transferCount == $1.transferCount { return $0.duration < $1.duration }
                return $0.transferCount < $1.transferCount
            }
        }
    }

    private func applySort() {
        guard !rawJourneys.isEmpty else {
            update(.empty)
            return
        }
        update(.loaded(Self.sort(rawJourneys, by: sort)))
    }

    private func update(_ new: State) {
        state = new
        onStateChange?(new)
    }
}
