//
//  AnalyticsView.swift
//  DailyRoutineApp
//
//  Created by GitHub Copilot on 16/10/2025.
//

import SwiftUI

struct AnalyticsView: View {
    @State private var selectedPeriod: AnalyticsPeriod = .week
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Period selector
                    PeriodSelector(selectedPeriod: $selectedPeriod)
                    
                    // Overview cards
                    OverviewCardsSection()
                    
                    // Charts section
                    ChartsSection()
                    
                    // Insights section
                    InsightsSection()
                }
                .padding()
            }
            .navigationTitle("Analytics")
        }
        .onAppear {
            AnalyticsManager.shared.track(.screenViewed("analytics"))
        }
    }
}

struct PeriodSelector: View {
    @Binding var selectedPeriod: AnalyticsPeriod
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                    Button(period.displayName) {
                        selectedPeriod = period
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(selectedPeriod == period ? Color.accentColor : Color.secondary.opacity(0.1))
                    .foregroundColor(selectedPeriod == period ? .white : .primary)
                    .cornerRadius(20)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct OverviewCardsSection: View {
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            OverviewCard(title: "Routines", value: "85%", subtitle: "Completion Rate", color: .blue)
            OverviewCard(title: "Habits", value: "23", subtitle: "Day Streak", color: .green)
            OverviewCard(title: "Meditation", value: "45 min", subtitle: "This Week", color: .purple)
            OverviewCard(title: "Focus Time", value: "3.2 hrs", subtitle: "Daily Average", color: .orange)
        }
    }
}

struct OverviewCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ChartsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress Charts")
                .font(.headline)
            
            // Placeholder for charts
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
                .frame(height: 200)
                .overlay(
                    Text("Routine Completion Chart")
                        .foregroundColor(.secondary)
                )
            
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
                .frame(height: 200)
                .overlay(
                    Text("Meditation Progress Chart")
                        .foregroundColor(.secondary)
                )
        }
    }
}

struct InsightsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.headline)
            
            VStack(spacing: 12) {
                InsightCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Great Progress!",
                    description: "Your routine completion rate improved by 15% this week.",
                    color: .green
                )
                
                InsightCard(
                    icon: "clock",
                    title: "Peak Performance",
                    description: "You're most consistent with morning routines.",
                    color: .blue
                )
                
                InsightCard(
                    icon: "target",
                    title: "Goal Suggestion",
                    description: "Try adding 5 more minutes to your meditation sessions.",
                    color: .orange
                )
            }
        }
    }
}

struct InsightCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
}

#Preview {
    AnalyticsView()
}