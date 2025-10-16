//
//  SettingsView.swift
//  DailyRoutineApp
//
//  Created by GitHub Copilot on 16/10/2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appCoordinator: AppCoordinator
    @State private var notificationsEnabled = true
    @State private var analyticsEnabled = true
    @State private var hapticFeedbackEnabled = true
    
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section {
                    ProfileRow()
                }
                
                // Preferences
                Section("Preferences") {
                    SettingsRow(icon: "bell.fill", title: "Notifications", color: .orange) {
                        Toggle("", isOn: $notificationsEnabled)
                    }
                    
                    SettingsRow(icon: "chart.bar.fill", title: "Analytics", color: .blue) {
                        Toggle("", isOn: $analyticsEnabled)
                    }
                    
                    SettingsRow(icon: "iphone.radiowaves.left.and.right", title: "Haptic Feedback", color: .purple) {
                        Toggle("", isOn: $hapticFeedbackEnabled)
                    }
                }
                
                // Data & Privacy
                Section("Data & Privacy") {
                    SettingsRow(icon: "square.and.arrow.up", title: "Export Data", color: .green) {
                        Button("Export") {
                            appCoordinator.navigate(to: .exportData)
                        }
                    }
                    
                    SettingsRow(icon: "trash", title: "Clear All Data", color: .red) {
                        Button("Clear") {
                            // Show confirmation alert
                        }
                        .foregroundColor(.red)
                    }
                }
                
                // Support
                Section("Support") {
                    SettingsRow(icon: "questionmark.circle", title: "Help & FAQ", color: .blue) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    
                    SettingsRow(icon: "envelope", title: "Contact Support", color: .blue) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    
                    SettingsRow(icon: "star", title: "Rate App", color: .yellow) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
                
                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    SettingsRow(icon: "doc.text", title: "Privacy Policy", color: .gray) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    
                    SettingsRow(icon: "doc.text", title: "Terms of Service", color: .gray) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .onAppear {
            AnalyticsManager.shared.track(.screenViewed("settings"))
        }
    }
}

struct ProfileRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 50, height: 50)
                .overlay(
                    Text("U")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("User Name")
                    .font(.headline)
                Text("Daily Routine Enthusiast")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    let color: Color
    let content: () -> Content
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(color)
                .cornerRadius(6)
            
            Text(title)
            
            Spacer()
            
            content()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppCoordinator())
}