//
//  JourneyPlannerWidgetBundle.swift
//  JourneyPlannerWidget
//
//  Created by Vanine Ghazaryan on 27.04.2026.
//

import SwiftUI
import WidgetKit

// Bundle entry point. Widgets are isolated processes — this `@main` struct is
// the equivalent of an `@main App` for the extension target.
@main
struct JourneyPlannerWidgetBundle: WidgetBundle {
    var body: some Widget {
        NextDepartureWidget()
        QuickRouteWidget()
    }
}
