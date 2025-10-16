//
//  MeditationSettingsView.swift
//  DailyRoutineApp
//
//  Created by GitHub Copilot on 16/10/2025.
//

import SwiftUI

struct MeditationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var settings = MeditationSettings()
    
    var body: some View {
        NavigationView {
            Form {
                // Breathing Pattern Section
                BreathingPatternSection(breathingPattern: $settings.breathingPattern)
                
                // Sound Settings Section
                SoundSettingsSection(soundSettings: $settings.soundSettings)
                
                // Visual Settings Section
                VisualSettingsSection(visualSettings: $settings.visualSettings)
                
                // Haptic Settings Section
                HapticSettingsSection(hapticSettings: $settings.hapticSettings)
            }
            .navigationTitle("Meditation Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveSettings() {
        // Save settings to UserDefaults or repository
        AppLogger.shared.log("Meditation settings saved", level: .info, category: "Settings")
        AnalyticsManager.shared.track(.settingChanged("meditation_settings", value: "updated"))
    }
}

struct BreathingPatternSection: View {
    @Binding var breathingPattern: BreathingPattern
    
    var body: some View {
        Section("Breathing Pattern") {
            // Pattern type picker would go here
            VStack(alignment: .leading, spacing: 8) {
                Text("Box Breathing (4-4-4-4)")
                    .font(.subheadline)
                Text("Inhale 4s, Hold 4s, Exhale 4s, Pause 4s")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}

struct SoundSettingsSection: View {
    @Binding var soundSettings: SoundSettings
    
    var body: some View {
        Section("Sound Settings") {
            Toggle("Enable Sounds", isOn: $soundSettings.isEnabled)
            
            if soundSettings.isEnabled {
                Picker("Ambient Sound", selection: Binding(
                    get: { soundSettings.ambientSound ?? .none },
                    set: { soundSettings.ambientSound = $0 == .none ? nil : $0 }
                )) {
                    ForEach(AmbientSound.allCases, id: \.self) { sound in
                        Text(sound.displayName).tag(sound)
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Volume")
                    Slider(value: $soundSettings.volume, in: 0...1, step: 0.1)
                    Text("\(Int(soundSettings.volume * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Toggle("Breathing Cues", isOn: $soundSettings.breathingCues.isEnabled)
            }
        }
    }
}

struct VisualSettingsSection: View {
    @Binding var visualSettings: VisualSettings
    
    var body: some View {
        Section("Visual Settings") {
            Picker("Breathing Guide", selection: $visualSettings.breathingGuide) {
                ForEach(BreathingGuideType.allCases, id: \.self) { guide in
                    Text(guide.displayName).tag(guide)
                }
            }
            
            Picker("Color Theme", selection: $visualSettings.colorTheme) {
                ForEach(ColorTheme.allCases, id: \.self) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }
            
            Toggle("Show Timer", isOn: $visualSettings.showTimer)
            Toggle("Show Progress", isOn: $visualSettings.showProgress)
        }
    }
}

struct HapticSettingsSection: View {
    @Binding var hapticSettings: HapticSettings
    
    var body: some View {
        Section("Haptic Feedback") {
            Toggle("Enable Haptics", isOn: $hapticSettings.isEnabled)
            
            if hapticSettings.isEnabled {
                Picker("Intensity", selection: $hapticSettings.intensity) {
                    ForEach(HapticIntensity.allCases, id: \.self) { intensity in
                        Text(intensity.displayName).tag(intensity)
                    }
                }
                
                Picker("Pattern", selection: $hapticSettings.patternType) {
                    ForEach(HapticPatternType.allCases, id: \.self) { pattern in
                        Text(pattern.displayName).tag(pattern)
                    }
                }
            }
        }
    }
}

#Preview {
    MeditationSettingsView()
}