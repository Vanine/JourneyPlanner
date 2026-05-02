//
//  JourneyPlannerTests.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 09.04.2026.
//

import Testing
import Foundation
@testable import JourneyPlanner

struct JourneyPlannerTests {

    private func makeJourney(id: String, departIn minutes: Int, durationMin: Int, transfers: Int) -> Journey {
        let dep = Date().addingTimeInterval(TimeInterval(minutes * 60))
        let arr = dep.addingTimeInterval(TimeInterval(durationMin * 60))
        var legs: [Leg] = []
        for i in 0...transfers {
            legs.append(Leg(
                id: "\(id)-\(i)",
                transport: .train,
                line: "L\(i)",
                platform: "1",
                from: "A",
                to: "B",
                departure: dep,
                arrival: arr,
                delayMinutes: 0
            ))
        }
        return Journey(id: id, departure: dep, arrival: arr, legs: legs)
    }

    @Test func sortByEarliestOrdersByDeparture() {
        let a = makeJourney(id: "a", departIn: 10, durationMin: 30, transfers: 1)
        let b = makeJourney(id: "b", departIn: 5,  durationMin: 60, transfers: 0)
        let c = makeJourney(id: "c", departIn: 15, durationMin: 20, transfers: 2)
        let result = ResultsViewModel.sort([a, b, c], by: .earliest)
        #expect(result.map(\.id) == ["b", "a", "c"])
    }

    @Test func sortByFastestOrdersByDuration() {
        let a = makeJourney(id: "a", departIn: 10, durationMin: 30, transfers: 1)
        let b = makeJourney(id: "b", departIn: 5,  durationMin: 60, transfers: 0)
        let c = makeJourney(id: "c", departIn: 15, durationMin: 20, transfers: 2)
        let result = ResultsViewModel.sort([a, b, c], by: .fastest)
        #expect(result.map(\.id) == ["c", "a", "b"])
    }

    @Test func sortByFewestTransfersOrdersByTransferCount() {
        let a = makeJourney(id: "a", departIn: 10, durationMin: 30, transfers: 1)
        let b = makeJourney(id: "b", departIn: 5,  durationMin: 60, transfers: 0)
        let c = makeJourney(id: "c", departIn: 15, durationMin: 20, transfers: 2)
        let result = ResultsViewModel.sort([a, b, c], by: .fewestTransfers)
        #expect(result.first?.id == "b")
        #expect(result.last?.id == "c")
    }
}
