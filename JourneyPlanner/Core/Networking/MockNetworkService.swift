//
//  MockNetworkService.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 19.03.2026.
//

import Foundation

// Mock backend. Returns canned JSON with a small artificial latency so the UI
// loading / empty / error states are exercised end to end.
final class MockNetworkService: NetworkService {

    func request<T>(_ endpoint: Endpoint, as type: T.Type) async throws -> T where T: Decodable & Sendable {
        try await Task.sleep(for: .milliseconds(650))

        let json: String
        switch endpoint.path {
        case "/locations":
            json = Self.locationsJSON(query: endpoint.query["q"] ?? "")
        case "/journeys":
            let from = endpoint.query["from"] ?? ""
            let to = endpoint.query["to"] ?? ""
            if from == to && !from.isEmpty {
                json = #"{"journeys":[]}"#
            } else if from.lowercased().contains("error") {
                throw NetworkError.transport(URLError(.notConnectedToInternet))
            } else {
                json = Self.journeysJSON(from: from, to: to)
            }
        default:
            throw NetworkError.invalidResponse
        }

        guard let data = json.data(using: .utf8) else { throw NetworkError.decodingFailed }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed
        }
    }

    // MARK: - Fixtures

    private static func locationsJSON(query: String) -> String {
        let all: [(String, String, String)] = [
            ("ber-hbf", "Berlin Hauptbahnhof", "Main station · Berlin"),
            ("ber-alex", "Alexanderplatz", "S+U · Berlin Mitte"),
            ("ber-fhain", "Frankfurter Allee", "S+U · Friedrichshain"),
            ("ber-tegel", "Berlin Tegel", "Bus terminal · Reinickendorf"),
            ("ham-hbf", "Hamburg Hauptbahnhof", "Main station · Hamburg"),
            ("ham-altona", "Hamburg-Altona", "Train station · Altona"),
            ("muc-hbf", "München Hauptbahnhof", "Main station · Munich"),
            ("muc-marienpl", "Marienplatz", "S+U · Munich Altstadt"),
            ("fra-hbf", "Frankfurt (Main) Hbf", "Main station · Frankfurt"),
            ("col-hbf", "Köln Hauptbahnhof", "Main station · Cologne"),
            ("lpz-hbf", "Leipzig Hauptbahnhof", "Main station · Leipzig"),
            ("dre-hbf", "Dresden Hauptbahnhof", "Main station · Dresden")
        ]
        let filtered = query.isEmpty ? all : all.filter {
            $0.1.localizedCaseInsensitiveContains(query) || $0.2.localizedCaseInsensitiveContains(query)
        }
        let items = filtered.prefix(8).map { #"{"id":"\#($0.0)","name":"\#($0.1)","subtitle":"\#($0.2)"}"# }.joined(separator: ",")
        return "{\"locations\":[\(items)]}"
    }

    private static func journeysJSON(from: String, to: String) -> String {
        let formatter = ISO8601DateFormatter()
        let now = Date()
        func iso(_ offset: TimeInterval) -> String { formatter.string(from: now.addingTimeInterval(offset)) }

        return """
        {"journeys":[
          {"id":"j1","departure":"\(iso(60*5))","arrival":"\(iso(60*42))","legs":[
            {"id":"l1","transport":"walk","line":"Walk","platform":null,"from":"\(from)","to":"S Hauptbahnhof","departure":"\(iso(60*5))","arrival":"\(iso(60*9))","delayMinutes":0},
            {"id":"l2","transport":"train","line":"ICE 1602","platform":"5","from":"S Hauptbahnhof","to":"Central Station","departure":"\(iso(60*12))","arrival":"\(iso(60*38))","delayMinutes":3},
            {"id":"l3","transport":"walk","line":"Walk","platform":null,"from":"Central Station","to":"\(to)","departure":"\(iso(60*38))","arrival":"\(iso(60*42))","delayMinutes":0}
          ]},
          {"id":"j2","departure":"\(iso(60*15))","arrival":"\(iso(60*64))","legs":[
            {"id":"l4","transport":"metro","line":"U2","platform":"B","from":"\(from)","to":"Alexanderplatz","departure":"\(iso(60*15))","arrival":"\(iso(60*24))","delayMinutes":0},
            {"id":"l5","transport":"bus","line":"Bus 100","platform":"3","from":"Alexanderplatz","to":"Zoologischer Garten","departure":"\(iso(60*28))","arrival":"\(iso(60*48))","delayMinutes":7},
            {"id":"l6","transport":"tram","line":"M10","platform":"A","from":"Zoologischer Garten","to":"\(to)","departure":"\(iso(60*52))","arrival":"\(iso(60*64))","delayMinutes":0}
          ]},
          {"id":"j3","departure":"\(iso(60*22))","arrival":"\(iso(60*55))","legs":[
            {"id":"l7","transport":"train","line":"RE 5","platform":"12","from":"\(from)","to":"\(to)","departure":"\(iso(60*22))","arrival":"\(iso(60*55))","delayMinutes":0}
          ]},
          {"id":"j4","departure":"\(iso(60*40))","arrival":"\(iso(60*88))","legs":[
            {"id":"l8","transport":"bus","line":"Bus N1","platform":"A","from":"\(from)","to":"Ostkreuz","departure":"\(iso(60*40))","arrival":"\(iso(60*61))","delayMinutes":0},
            {"id":"l9","transport":"train","line":"S5","platform":"2","from":"Ostkreuz","to":"\(to)","departure":"\(iso(60*65))","arrival":"\(iso(60*88))","delayMinutes":2}
          ]}
        ]}
        """
    }
}
