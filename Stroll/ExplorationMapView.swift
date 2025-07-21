import SwiftUI
import MapKit

struct ExplorationMapView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var dataManager = ExplorationDataManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.2904, longitude: -76.6122), // Baltimore
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var showingActivityView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main Map
                Map {
                    // Map content will be handled by overlays
                }
                .mapStyle(.standard)
                .overlay(
                    RoadOverlayView(roads: dataManager.roads, exploredRoutes: dataManager.exploredRoutes)
                )
                .onAppear {
                    locationManager.requestLocationPermission()
                }
                .onChange(of: locationManager.location) { oldValue, newValue in
                    if let location = newValue {
                        region.center = location.coordinate
                    }
                }
                
                // Stats overlay
                VStack {
                    HStack {
                        Spacer()
                        ExplorationStatsCard(stats: dataManager.explorationStats)
                            .padding(.trailing)
                    }
                    Spacer()
                }
                .padding(.top, 10)
                
                // Start Activity Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingActivityView = true
                        }) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                                .background(Circle().fill(Color.white))
                                .shadow(radius: 10)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Exploration")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingActivityView) {
                StartActivityView(locationManager: locationManager, dataManager: dataManager)
            }
        }
    }
}

// MARK: - Road Overlay View
struct RoadOverlayView: View {
    let roads: [Road]
    let exploredRoutes: [ExploredRoute]
    
    var body: some View {
        ZStack {
            // Draw roads
            ForEach(roads) { road in
                RoadPathView(coordinates: road.coordinates, color: road.explorationStatus.color, lineWidth: 4)
            }
            
            // Draw explored routes
            ForEach(exploredRoutes) { route in
                RoadPathView(coordinates: route.coordinates, color: .blue.opacity(0.7), lineWidth: 3)
            }
        }
    }
}

// MARK: - Road Path View
struct RoadPathView: View {
    let coordinates: [CLLocationCoordinate2D]
    let color: Color
    let lineWidth: CGFloat
    
    var body: some View {
        // Note: This is a simplified representation
        // In a real implementation, you'd use MapKit overlays or a custom map renderer
        Rectangle()
            .fill(color)
            .frame(width: lineWidth, height: 100)
            .opacity(0) // Placeholder - actual road rendering would be more complex
    }
}

// MARK: - Exploration Stats Card
struct ExplorationStatsCard: View {
    let stats: ExplorationStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "map")
                    .foregroundColor(.green)
                Text("Exploration Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Text("\(String(format: "%.1f", stats.explorationPercentage))%")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.green)
            
            Text("\(stats.exploredRoads) of \(stats.totalRoads) roads")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ProgressView(value: stats.explorationPercentage / 100)
                .tint(.green)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

// MARK: - Start Activity View
struct StartActivityView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var dataManager: ExplorationDataManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedActivityType: ActivityType = .walk
    @State private var activityName = ""
    @State private var isTracking = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Start New Activity")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Activity type picker
                VStack(alignment: .leading, spacing: 15) {
                    Text("Activity Type")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        ForEach(ActivityType.allCases, id: \.self) { type in
                            ActivityTypeButton(
                                type: type,
                                isSelected: selectedActivityType == type
                            ) {
                                selectedActivityType = type
                            }
                        }
                    }
                }
                
                // Activity name input
                VStack(alignment: .leading, spacing: 10) {
                    Text("Activity Name (Optional)")
                        .font(.headline)
                    
                    TextField("Enter activity name", text: $activityName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Spacer()
                
                // Start/Stop button
                Button(action: {
                    if isTracking {
                        stopActivity()
                    } else {
                        startActivity()
                    }
                }) {
                    HStack {
                        Image(systemName: isTracking ? "stop.circle.fill" : "play.circle.fill")
                        Text(isTracking ? "Stop Activity" : "Start Activity")
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isTracking ? Color.red : Color.green)
                    .cornerRadius(12)
                }
                
                if isTracking {
                    VStack {
                        Text("Activity in Progress")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        Text("New roads discovered: \(locationManager.currentRoute.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func startActivity() {
        locationManager.startTracking()
        isTracking = true
    }
    
    private func stopActivity() {
        locationManager.stopTracking()
        
        if !locationManager.currentRoute.isEmpty {
            let newRoute = ExploredRoute(
                coordinates: locationManager.currentRoute,
                activityType: selectedActivityType,
                timestamp: Date(),
                name: activityName.isEmpty ? nil : activityName
            )
            dataManager.addExploredRoute(newRoute)
        }
        
        isTracking = false
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Activity Type Button
struct ActivityTypeButton: View {
    let type: ActivityType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: type.icon)
                    .font(.title2)
                Text(type.rawValue)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding()
            .background(isSelected ? Color.green : Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - Placeholder Views
struct StatsView: View {
    @StateObject private var dataManager = ExplorationDataManager()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Overall Progress Card
                    OverallProgressCard(stats: dataManager.explorationStats)
                    
                    // Activity Breakdown
                    ActivityBreakdownCard(exploredRoutes: dataManager.exploredRoutes)
                    
                    // Exploration Timeline
                    ExplorationTimelineCard(exploredRoutes: dataManager.exploredRoutes)
                    
                    // Achievement Cards
                    AchievementsCard(stats: dataManager.explorationStats, routeCount: dataManager.exploredRoutes.count)
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Overall Progress Card
struct OverallProgressCard: View {
    let stats: ExplorationStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "map.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("Overall Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // Main percentage
            HStack {
                VStack(alignment: .leading) {
                    Text("\(String(format: "%.1f", stats.explorationPercentage))%")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    Text("of city explored")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Circular progress
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: stats.explorationPercentage / 100)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 80, height: 80)
                        .animation(.easeInOut(duration: 1.0), value: stats.explorationPercentage)
                }
            }
            
            Divider()
            
            // Detailed stats
            HStack {
                StatItem(title: "Roads Explored", value: "\(stats.exploredRoads)", subtitle: "of \(stats.totalRoads)")
                
                Spacer()
                
                StatItem(title: "Distance", value: String(format: "%.1f", stats.exploredDistance / 1000), subtitle: "km explored")
                
                Spacer()
                
                StatItem(title: "Completion", value: "\(stats.exploredRoads)", subtitle: "roads done")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Activity Breakdown Card
struct ActivityBreakdownCard: View {
    let exploredRoutes: [ExploredRoute]
    
    private var activityStats: [ActivityType: (count: Int, distance: Double)] {
        var stats: [ActivityType: (count: Int, distance: Double)] = [:]
        
        for route in exploredRoutes {
            let distance = calculateRouteDistance(route.coordinates)
            let current = stats[route.activityType] ?? (count: 0, distance: 0.0)
            stats[route.activityType] = (count: current.count + 1, distance: current.distance + distance)
        }
        
        return stats
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "figure.walk.motion")
                    .foregroundColor(.green)
                    .font(.title2)
                Text("Activity Breakdown")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if exploredRoutes.isEmpty {
                VStack {
                    Image(systemName: "figure.walk.diamond")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("No activities yet")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("Start your first exploration!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                VStack(spacing: 12) {
                    ForEach(ActivityType.allCases, id: \.self) { activityType in
                        if let stat = activityStats[activityType] {
                            ActivityStatRow(
                                activityType: activityType,
                                count: stat.count,
                                distance: stat.distance
                            )
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func calculateRouteDistance(_ coordinates: [CLLocationCoordinate2D]) -> Double {
        guard coordinates.count > 1 else { return 0 }
        
        var totalDistance: Double = 0
        for i in 0..<coordinates.count - 1 {
            let location1 = CLLocation(latitude: coordinates[i].latitude, longitude: coordinates[i].longitude)
            let location2 = CLLocation(latitude: coordinates[i + 1].latitude, longitude: coordinates[i + 1].longitude)
            totalDistance += location1.distance(from: location2)
        }
        return totalDistance
    }
}

// MARK: - Activity Stat Row
struct ActivityStatRow: View {
    let activityType: ActivityType
    let count: Int
    let distance: Double
    
    var body: some View {
        HStack {
            Image(systemName: activityType.icon)
                .foregroundColor(activityColor)
                .font(.title3)
                .frame(width: 30)
            
            Text(activityType.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(count) activities")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(String(format: "%.1f km", distance / 1000))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var activityColor: Color {
        switch activityType {
        case .walk: return .blue
        case .run: return .orange
        case .bike: return .purple
        }
    }
}

// MARK: - Exploration Timeline Card
struct ExplorationTimelineCard: View {
    let exploredRoutes: [ExploredRoute]
    
    private var recentActivities: [ExploredRoute] {
        Array(exploredRoutes.sorted { $0.timestamp > $1.timestamp }.prefix(5))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.purple)
                    .font(.title2)
                Text("Recent Exploration")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if recentActivities.isEmpty {
                VStack {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                    Text("No recent activities")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 10) {
                    ForEach(recentActivities) { route in
                        RecentActivityRow(route: route)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Recent Activity Row
struct RecentActivityRow: View {
    let route: ExploredRoute
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: route.activityType.icon)
                .foregroundColor(activityColor)
                .font(.title3)
                .frame(width: 25)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(route.name ?? "\(route.activityType.rawValue) Activity")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(formatDate(route.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(String(format: "%.1f km", calculateDistance() / 1000))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
    }
    
    private var activityColor: Color {
        switch route.activityType {
        case .walk: return .blue
        case .run: return .orange
        case .bike: return .purple
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDate(date, inSameDayAs: Date()) {
            formatter.dateFormat = "'Today at' HH:mm"
        } else if calendar.isDate(date, inSameDayAs: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()) {
            formatter.dateFormat = "'Yesterday at' HH:mm"
        } else {
            formatter.dateFormat = "MMM d, HH:mm"
        }
        
        return formatter.string(from: date)
    }
    
    private func calculateDistance() -> Double {
        guard route.coordinates.count > 1 else { return 0 }
        
        var totalDistance: Double = 0
        for i in 0..<route.coordinates.count - 1 {
            let location1 = CLLocation(latitude: route.coordinates[i].latitude, longitude: route.coordinates[i].longitude)
            let location2 = CLLocation(latitude: route.coordinates[i + 1].latitude, longitude: route.coordinates[i + 1].longitude)
            totalDistance += location1.distance(from: location2)
        }
        return totalDistance
    }
}

// MARK: - Achievements Card
struct AchievementsCard: View {
    let stats: ExplorationStats
    let routeCount: Int
    
    private var achievements: [Achievement] {
        var earned: [Achievement] = []
        
        // Exploration percentage achievements
        if stats.explorationPercentage >= 10 {
            earned.append(Achievement(title: "Explorer", description: "Explored 10% of the city", icon: "map", isUnlocked: true))
        }
        if stats.explorationPercentage >= 25 {
            earned.append(Achievement(title: "Pathfinder", description: "Explored 25% of the city", icon: "location.north.line", isUnlocked: true))
        }
        if stats.explorationPercentage >= 50 {
            earned.append(Achievement(title: "Navigator", description: "Explored 50% of the city", icon: "safari", isUnlocked: true))
        }
        
        // Activity count achievements
        if routeCount >= 5 {
            earned.append(Achievement(title: "Getting Started", description: "Completed 5 activities", icon: "figure.walk", isUnlocked: true))
        }
        if routeCount >= 25 {
            earned.append(Achievement(title: "Regular Explorer", description: "Completed 25 activities", icon: "flame", isUnlocked: true))
        }
        
        // Road count achievements
        if stats.exploredRoads >= 10 {
            earned.append(Achievement(title: "Road Warrior", description: "Explored 10 different roads", icon: "road.lanes", isUnlocked: true))
        }
        
        return earned
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                    .font(.title2)
                Text("Achievements")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(achievements.count)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
            }
            
            if achievements.isEmpty {
                VStack {
                    Image(systemName: "trophy")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                    Text("No achievements yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Start exploring to unlock achievements!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(achievements, id: \.title) { achievement in
                        AchievementBadge(achievement: achievement)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Achievement Model
struct Achievement {
    let title: String
    let description: String
    let icon: String
    let isUnlocked: Bool
}

// MARK: - Achievement Badge
struct AchievementBadge: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: achievement.icon)
                .font(.title2)
                .foregroundColor(achievement.isUnlocked ? .yellow : .gray)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(achievement.isUnlocked ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.1))
                )
            
            VStack(spacing: 2) {
                Text(achievement.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(achievement.description)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct ActivityView: View {
    var body: some View {
        NavigationView {
            Text("Activity History - Coming Soon")
                .navigationTitle("Activities")
        }
    }
}

struct LeaderboardView: View {
    var body: some View {
        NavigationView {
            Text("Leaderboard - Coming Soon")
                .navigationTitle("Leaderboard")
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
