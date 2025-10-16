//
//  DashboardView.swift
//  DailyRoutineApp
//
//  Created by GitHub Copilot on 16/10/2025.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var appDependencies: AppDependencies
    @EnvironmentObject private var appCoordinator: AppCoordinator
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Today's Summary Card
                    TodaySummaryCard()
                    
                    // Active Routines
                    ActiveRoutinesSection()
                    
                    // Habits Progress
                    HabitsProgressSection()
                    
                    // Quick Actions
                    QuickActionsSection()
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .refreshable {
                // Refresh data
            }
        }
        .onAppear {
            AnalyticsManager.shared.track(.screenViewed("dashboard"))
        }
    }
}

struct TodaySummaryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Progress")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Routines")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("3/5 Complete")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Meditation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("15 min")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ActiveRoutinesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Routines")
                .font(.headline)
            
            // Placeholder routine cards
            ForEach(0..<3, id: \.self) { _ in
                RoutineCard()
            }
        }
    }
}

struct HabitsProgressSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Habits")
                .font(.headline)
            
            // Placeholder habit progress
            HStack {
                ForEach(0..<7, id: \.self) { _ in
                    Circle()
                        .fill(Color.green)
                        .frame(width: 30, height: 30)
                }
            }
        }
    }
}

struct QuickActionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionButton(title: "Start Meditation", icon: "leaf.fill")
                QuickActionButton(title: "Add Routine", icon: "plus.circle.fill")
                QuickActionButton(title: "Log Habit", icon: "checkmark.circle.fill")
                QuickActionButton(title: "View Analytics", icon: "chart.bar.fill")
            }
        }
    }
}

struct RoutineCard: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Morning Routine")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("30 min • 5 activities")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Start") {
                // Start routine
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    
    var body: some View {
        Button {
            // Handle action
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(12)
        }
        .foregroundColor(.accentColor)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppDependencies())
        .environmentObject(AppCoordinator())
}