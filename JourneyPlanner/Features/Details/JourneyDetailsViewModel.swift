//
//  JourneyDetailsViewModel.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 30.03.2026.
//

import Foundation

@MainActor
final class JourneyDetailsViewModel {
    let journey: Journey

    init(journey: Journey) { self.journey = journey }

    var headerTitle: String {
        "\(Formatters.time.string(from: journey.departure)) – \(Formatters.time.string(from: journey.arrival))"
    }

    var headerSubtitle: String {
        let transfers = journey.transferCount == 0 ? "Direct" : "\(journey.transferCount) transfer\(journey.transferCount == 1 ? "" : "s")"
        return "\(Formatters.duration(journey.duration)) · \(transfers)"
    }

    var legs: [Leg] { journey.legs }
}
