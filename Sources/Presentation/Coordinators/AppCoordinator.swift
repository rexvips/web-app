//
//  AppCoordinator.swift
//  DailyRoutineApp
//
//  Created by GitHub Copilot on 16/10/2025.
//

import SwiftUI
import Combine

/// App routes for navigation
enum AppRoute: Hashable {
    case dashboard
    case routineBuilder(routine: Routine? = nil)
    case meditationStudio
    case meditationSession(type: MeditationType)
    case analytics
    case settings
    case habitDetail(habit: Habit)
    case exportData
    
    var identifier: String {
        switch self {
        case .dashboard: return "dashboard"
        case .routineBuilder: return "routineBuilder"
        case .meditationStudio: return "meditationStudio"
        case .meditationSession: return "meditationSession"
        case .analytics: return "analytics"
        case .settings: return "settings"
        case .habitDetail: return "habitDetail"
        case .exportData: return "exportData"
        }
    }
}

/// Central navigation coordinator following the Coordinator pattern
final class AppCoordinator: ObservableObject {
    @Published var navigationPath = NavigationPath()
    @Published var selectedTab: MainTab = .dashboard
    @Published var presentedSheet: AppRoute?
    @Published var presentedFullScreenCover: AppRoute?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAnalytics()
    }
    
    // MARK: - Navigation Methods
    func navigate(to route: AppRoute) {
        navigationPath.append(route)
        trackNavigation(to: route)
    }
    
    func navigateBack() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }
    
    func navigateToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }
    
    func presentSheet(_ route: AppRoute) {
        presentedSheet = route
        trackNavigation(to: route)
    }
    
    func presentFullScreenCover(_ route: AppRoute) {
        presentedFullScreenCover = route
        trackNavigation(to: route)
    }
    
    func dismissSheet() {
        presentedSheet = nil
    }
    
    func dismissFullScreenCover() {
        presentedFullScreenCover = nil
    }
    
    func selectTab(_ tab: MainTab) {
        selectedTab = tab
        // Clear navigation path when switching tabs
        navigationPath.removeLast(navigationPath.count)
    }
    
    // MARK: - View Factory
    @ViewBuilder
    func view(for route: AppRoute) -> some View {
        switch route {
        case .dashboard:
            DashboardView()
        case .routineBuilder(let routine):
            RoutineBuilderView(routine: routine)
        case .meditationStudio:
            MeditationStudioView()
        case .meditationSession(let type):
            MeditationSessionView(meditationType: type)
        case .analytics:
            AnalyticsView()
        case .settings:
            SettingsView()
        case .habitDetail(let habit):
            HabitDetailView(habit: habit)
        case .exportData:
            ExportDataView()
        }
    }
    
    // MARK: - Deep Linking
    func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host else { return }
        
        switch host {
        case "meditation":
            if let type = components.queryItems?.first(where: { $0.name == "type" })?.value,
               let meditationType = MeditationType(rawValue: type) {
                navigate(to: .meditationSession(type: meditationType))
            } else {
                navigate(to: .meditationStudio)
            }
        case "routine":
            navigate(to: .routineBuilder())
        case "analytics":
            selectTab(.analytics)
        default:
            break
        }
    }
    
    // MARK: - Private Methods
    private func setupAnalytics() {
        // Track tab selections
        $selectedTab
            .dropFirst()
            .sink { tab in
                AnalyticsManager.shared.track(.tabSelected(tab.rawValue))
            }
            .store(in: &cancellables)
    }
    
    private func trackNavigation(to route: AppRoute) {
        AnalyticsManager.shared.track(.screenViewed(route.identifier))
    }
}

// MARK: - Main Tabs
enum MainTab: String, CaseIterable {
    case dashboard = "Dashboard"
    case routines = "Routines"
    case meditation = "Meditation"
    case analytics = "Analytics"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .routines: return "list.clipboard.fill"
        case .meditation: return "leaf.fill"
        case .analytics: return "chart.bar.fill"
        case .settings: return "gear"
        }
    }
    
    var selectedIcon: String {
        return icon
    }
}