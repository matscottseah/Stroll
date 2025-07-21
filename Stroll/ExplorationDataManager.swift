//
//  ExplorationDataManager.swift
//  Stroll
//
//  Created by Matthew Seah on 7/20/25.
//

import Foundation
import CoreLocation

class ExplorationDataManager: ObservableObject {
    @Published var exploredRoutes: [ExploredRoute] = []
    @Published var roads: [Road] = []
    @Published var explorationStats = ExplorationStats(totalRoads: 0, exploredRoads: 0, totalDistance: 0, exploredDistance: 0)
    
    private let explorationThreshold: Double = 20.0 // meters
    
    init() {
        loadSampleData()
        calculateExplorationStats()
    }
    
    func addExploredRoute(_ route: ExploredRoute) {
        exploredRoutes.append(route)
        updateRoadExploration(for: route)
        calculateExplorationStats()
    }
    
    private func updateRoadExploration(for route: ExploredRoute) {
        for (index, road) in roads.enumerated() {
            let exploredSegments = calculateExploredSegments(road: road, route: route.coordinates)
            roads[index].exploredPercentage = max(roads[index].exploredPercentage, exploredSegments)
            roads[index].explorationStatus = getExplorationStatus(for: roads[index].exploredPercentage)
        }
    }
    
    private func calculateExploredSegments(road: Road, route: [CLLocationCoordinate2D]) -> Double {
        guard !road.coordinates.isEmpty && !route.isEmpty else { return 0 }
        
        var exploredCount = 0
        for roadPoint in road.coordinates {
            let roadLocation = CLLocation(latitude: roadPoint.latitude, longitude: roadPoint.longitude)
            for routePoint in route {
                let routeLocation = CLLocation(latitude: routePoint.latitude, longitude: routePoint.longitude)
                if roadLocation.distance(from: routeLocation) <= explorationThreshold {
                    exploredCount += 1
                    break
                }
            }
        }
        
        return Double(exploredCount) / Double(road.coordinates.count)
    }
    
    private func getExplorationStatus(for percentage: Double) -> ExplorationStatus {
        if percentage == 0 {
            return .unexplored
        } else if percentage < 0.8 {
            return .partiallyExplored
        } else {
            return .fullyExplored
        }
    }
    
    private func calculateExplorationStats() {
        let totalRoads = roads.count
        let exploredRoads = roads.filter { $0.explorationStatus != .unexplored }.count
        
        explorationStats = ExplorationStats(
            totalRoads: totalRoads,
            exploredRoads: exploredRoads,
            totalDistance: calculateTotalDistance(),
            exploredDistance: calculateExploredDistance()
        )
    }
    
    private func calculateTotalDistance() -> Double {
        return roads.reduce(0) { total, road in
            total + calculateRoadDistance(road.coordinates)
        }
    }
    
    private func calculateExploredDistance() -> Double {
        return roads.reduce(0) { total, road in
            let roadDistance = calculateRoadDistance(road.coordinates)
            return total + (roadDistance * road.exploredPercentage)
        }
    }
    
    private func calculateRoadDistance(_ coordinates: [CLLocationCoordinate2D]) -> Double {
        guard coordinates.count > 1 else { return 0 }
        
        var totalDistance: Double = 0
        for i in 0..<coordinates.count - 1 {
            let location1 = CLLocation(latitude: coordinates[i].latitude, longitude: coordinates[i].longitude)
            let location2 = CLLocation(latitude: coordinates[i + 1].latitude, longitude: coordinates[i + 1].longitude)
            totalDistance += location1.distance(from: location2)
        }
        return totalDistance
    }
    
    // Sample data for testing
    private func loadSampleData() {
        // Sample roads in Baltimore area
        roads = [
            Road(name: "Main Street",
                 coordinates: generateSampleRoadCoordinates(start: CLLocationCoordinate2D(latitude: 39.2904, longitude: -76.6122),
                                                           end: CLLocationCoordinate2D(latitude: 39.2954, longitude: -76.6172)),
                 explorationStatus: .unexplored,
                 exploredPercentage: 0.0),
            
            Road(name: "Baltimore Street",
                 coordinates: generateSampleRoadCoordinates(start: CLLocationCoordinate2D(latitude: 39.2854, longitude: -76.6122),
                                                           end: CLLocationCoordinate2D(latitude: 39.2854, longitude: -76.6222)),
                 explorationStatus: .fullyExplored,
                 exploredPercentage: 1.0),
            
            Road(name: "Charles Street",
                 coordinates: generateSampleRoadCoordinates(start: CLLocationCoordinate2D(latitude: 39.2904, longitude: -76.6122),
                                                           end: CLLocationCoordinate2D(latitude: 39.2904, longitude: -76.6022)),
                 explorationStatus: .partiallyExplored,
                 exploredPercentage: 0.6),
        ]
        
        // Sample explored route
        exploredRoutes = [
            ExploredRoute(coordinates: generateSampleRoadCoordinates(
                start: CLLocationCoordinate2D(latitude: 39.2854, longitude: -76.6122),
                end: CLLocationCoordinate2D(latitude: 39.2854, longitude: -76.6222)
            ), activityType: .run, timestamp: Date().addingTimeInterval(-3600), name: "Morning Run")
        ]
    }
    
    private func generateSampleRoadCoordinates(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        let steps = 10
        
        for i in 0...steps {
            let progress = Double(i) / Double(steps)
            let lat = start.latitude + (end.latitude - start.latitude) * progress
            let lon = start.longitude + (end.longitude - start.longitude) * progress
            coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
        
        return coordinates
    }
}
