//
//  Models.swift
//  Stroll
//
//  Created by Matthew Seah on 7/20/25.
//

import Foundation
import CoreLocation
import MapKit
import SwiftUICore

struct ExploredRoute: Identifiable {
    let id = UUID()
    let coordinates: [CLLocationCoordinate2D]
    let activityType: ActivityType
    let timestamp: Date
    let name: String?
}

struct Road: Identifiable {
    let id = UUID()
    let name: String
    let coordinates: [CLLocationCoordinate2D]
    var explorationStatus: ExplorationStatus
    var exploredPercentage: Double
}

enum ActivityType: String, CaseIterable {
    case walk = "Walk"
    case run = "Run"
    case bike = "Bike"
    
    var icon: String {
        switch self {
        case .walk: return "figure.walk"
        case .run: return "figure.run"
        case .bike: return "bicycle"
        }
    }
}

enum ExplorationStatus {
    case unexplored
    case partiallyExplored
    case fullyExplored
    
    var color: Color {
        switch self {
        case .unexplored: return .gray.opacity(0.6)
        case .partiallyExplored: return .yellow
        case .fullyExplored: return .green
        }
    }
}

struct ExplorationStats {
    let totalRoads: Int
    let exploredRoads: Int
    let totalDistance: Double
    let exploredDistance: Double
    
    var explorationPercentage: Double {
        guard totalRoads > 0 else { return 0 }
        return Double(exploredRoads) / Double(totalRoads) * 100
    }
}
