//
//  ContentView.swift
//  Stroll
//
//  Created by Matthew Seah on 7/19/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ExplorationMapView()
                .tabItem {
                    Image(systemName: "map")
                    Text("Explore")
                }
            
            StatsView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Stats")
                }
            
            ActivityView()
                .tabItem {
                    Image(systemName: "figure.walk")
                    Text("Activity")
                }
            
            LeaderboardView()
                .tabItem {
                    Image(systemName: "list.number")
                    Text("Leaderboard")
                }
        }
        .accentColor(.green)
    }
}

#Preview {
    ContentView()
}
