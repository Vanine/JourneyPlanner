//
//  JourneyPlannerWidgetBundle.swift
//  JourneyPlannerWidget
//
//  Created by Vanine Ghazaryan on 27.04.2026.
//

import SwiftUI
import WidgetKit

@main
struct JourneyPlannerWidgetBundle: WidgetBundle {
    var body: some Widget {
        NextDepartureWidget()
        QuickRouteWidget()
    }
}
