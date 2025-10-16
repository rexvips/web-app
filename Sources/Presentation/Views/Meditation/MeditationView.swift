//
//  MeditationView.swift
//  DailyRoutineApp
//
//  Created by GitHub Copilot on 16/10/2025.
//

import SwiftUI

struct MeditationView: View {
    @EnvironmentObject private var appCoordinator: AppCoordinator
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Today's meditation summary
                    MeditationSummaryCard()
                    
                    // Meditation types
                    MeditationTypesSection()
                    
                    // Recent sessions
                    RecentSessionsSection()
                }
                .padding()
            }
            .navigationTitle("Meditation")
        }
        .onAppear {
            AnalyticsManager.shared.track(.screenViewed("meditation"))
        }
    }
}

struct MeditationSummaryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Meditation")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("15 min")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Sessions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("2")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("7 days")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
}

struct MeditationTypesSection: View {
    @EnvironmentObject private var appCoordinator: AppCoordinator
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meditation Types")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(MeditationType.allCases, id: \.self) { type in
                    MeditationTypeCard(type: type) {
                        appCoordinator.navigate(to: .meditationSession(type: type))
                    }
                }
            }
        }
    }
}

struct MeditationTypeCard: View {
    let type: MeditationType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.title)
                    .foregroundColor(.accentColor)
                
                VStack(spacing: 4) {
                    Text(type.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                    
                    Text("\(Int(type.defaultDuration / 60)) min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(12)
        }
        .foregroundColor(.primary)
    }
}

struct RecentSessionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(.headline)
            
            ForEach(0..<3, id: \.self) { _ in
                SessionRowView()
            }
        }
    }
}

struct SessionRowView: View {
    var body: some View {
        HStack {
            Image(systemName: "leaf.fill")
                .foregroundColor(.green)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Box Breathing")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("10 minutes • Completed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("2 hours ago")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    MeditationView()
        .environmentObject(AppCoordinator())
}