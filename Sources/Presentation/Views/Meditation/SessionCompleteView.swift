//
//  SessionCompleteView.swift
//  DailyRoutineApp
//
//  Created by GitHub Copilot on 16/10/2025.
//

import SwiftUI

struct SessionCompleteView: View {
    let meditationType: MeditationType
    let actualDuration: TimeInterval
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appCoordinator: AppCoordinator
    @State private var showingShareSheet = false
    @State private var sessionNotes = ""
    @State private var moodRating: Int = 3
    
    private var formattedDuration: String {
        let minutes = Int(actualDuration) / 60
        let seconds = Int(actualDuration) % 60
        return "\(minutes)m \(seconds)s"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Success animation and title
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                            .scaleEffect(1.0)
                            .onAppear {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    // Animation would be handled here
                                }
                            }
                        
                        Text("Well Done!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("You completed a \(meditationType.displayName.lowercased()) session")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Session stats
                    SessionStatsView(duration: formattedDuration, type: meditationType)
                    
                    // Mood rating
                    MoodRatingView(rating: $moodRating)
                    
                    // Session notes
                    SessionNotesView(notes: $sessionNotes)
                    
                    // Action buttons
                    ActionButtonsView(
                        onShare: { showingShareSheet = true },
                        onAnotherSession: { startAnotherSession() },
                        onDone: { dismiss() }
                    )
                }
                .padding()
            }
            .navigationTitle("Session Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [createShareText()])
        }
        .onAppear {
            AnalyticsManager.shared.track(.screenViewed("session_complete"))
        }
    }
    
    private func startAnotherSession() {
        dismiss()
        appCoordinator.navigate(to: .meditationSession(type: meditationType))
    }
    
    private func createShareText() -> String {
        return "Just completed a \(formattedDuration) \(meditationType.displayName.lowercased()) session with Daily Routine App! 🧘‍♀️✨"
    }
}

struct SessionStatsView: View {
    let duration: String
    let type: MeditationType
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Session Summary")
                .font(.headline)
            
            HStack(spacing: 40) {
                StatItem(title: "Duration", value: duration, icon: "clock")
                StatItem(title: "Type", value: type.displayName, icon: type.icon)
                StatItem(title: "Status", value: "Complete", icon: "checkmark.circle")
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

struct MoodRatingView: View {
    @Binding var rating: Int
    
    private let moods = ["😔", "😕", "😐", "🙂", "😊"]
    
    var body: some View {
        VStack(spacing: 12) {
            Text("How do you feel?")
                .font(.headline)
            
            HStack(spacing: 16) {
                ForEach(1...5, id: \.self) { index in
                    Button {
                        rating = index
                    } label: {
                        Text(moods[index - 1])
                            .font(.title)
                            .scaleEffect(rating == index ? 1.2 : 1.0)
                            .opacity(rating == index ? 1.0 : 0.6)
                    }
                    .animation(.easeInOut(duration: 0.2), value: rating)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
}

struct SessionNotesView: View {
    @Binding var notes: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes (Optional)")
                .font(.headline)
            
            TextField("How was your session? Any insights?", text: $notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
    }
}

struct ActionButtonsView: View {
    let onShare: () -> Void
    let onAnotherSession: () -> Void
    let onDone: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Button("Start Another Session") {
                onAnotherSession()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            HStack(spacing: 16) {
                Button("Share") {
                    onShare()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                Button("Done") {
                    onDone()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SessionCompleteView(
        meditationType: .boxBreathing,
        actualDuration: 300
    )
    .environmentObject(AppCoordinator())
}