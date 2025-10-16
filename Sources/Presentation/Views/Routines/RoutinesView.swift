//
//  RoutinesView.swift
//  DailyRoutineApp
//
//  Created by GitHub Copilot on 16/10/2025.
//

import SwiftUI

struct RoutinesView: View {
    @EnvironmentObject private var appCoordinator: AppCoordinator
    @State private var searchText = ""
    @State private var selectedCategory: RoutineCategory = .general
    
    var body: some View {
        NavigationView {
            VStack {
                // Category picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(RoutineCategory.allCases, id: \.self) { category in
                            CategoryChip(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Routines list
                List {
                    ForEach(0..<5, id: \.self) { _ in
                        RoutineRowView()
                    }
                }
                .searchable(text: $searchText, prompt: "Search routines")
            }
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        appCoordinator.navigate(to: .routineBuilder())
                    }
                }
            }
        }
        .onAppear {
            AnalyticsManager.shared.track(.screenViewed("routines"))
        }
    }
}

struct CategoryChip: View {
    let category: RoutineCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
    }
}

struct RoutineRowView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Sample Routine")
                    .font(.headline)
                Text("Morning routine with 5 activities")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Label("30 min", systemImage: "clock")
                    Label("Streak: 5", systemImage: "flame")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack {
                Button("Start") {
                    // Start routine
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    RoutinesView()
        .environmentObject(AppCoordinator())
}