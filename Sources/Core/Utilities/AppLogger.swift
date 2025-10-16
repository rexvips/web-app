//
//  AppLogger.swift
//  DailyRoutineApp
//
//  Created by GitHub Copilot on 16/10/2025.
//

import Foundation
import os.log

/// Centralized logging system with structured logging support
final class AppLogger {
    static let shared = AppLogger()
    
    private let logger: Logger
    private let subsystem = Bundle.main.bundleIdentifier ?? "DailyRoutineApp"
    
    private init() {
        self.logger = Logger(subsystem: subsystem, category: "App")
    }
    
    enum LogLevel: String, CaseIterable {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        case critical = "CRITICAL"
        
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            case .critical: return .fault
            }
        }
    }
    
    /// Log a message with the specified level
    func log(_ message: String, level: LogLevel = .info, category: String = "General") {
        let categoryLogger = Logger(subsystem: subsystem, category: category)
        
        switch level {
        case .debug:
            categoryLogger.debug("\(message)")
        case .info:
            categoryLogger.info("\(message)")
        case .warning:
            categoryLogger.warning("\(message)")
        case .error:
            categoryLogger.error("\(message)")
        case .critical:
            categoryLogger.critical("\(message)")
        }
        
        #if DEBUG
        print("[\(level.rawValue)] [\(category)] \(message)")
        #endif
    }
    
    /// Log an error with additional context
    func logError(_ error: Error, context: String = "", category: String = "Error") {
        let message = context.isEmpty ? error.localizedDescription : "\(context): \(error.localizedDescription)"
        log(message, level: .error, category: category)
        
        // Send to crash reporting service in production
        #if !DEBUG
        // Crashlytics.crashlytics().record(error: error)
        #endif
    }
    
    /// Log performance metrics
    func logPerformance(_ operation: String, duration: TimeInterval, category: String = "Performance") {
        log("Operation '\(operation)' completed in \(String(format: "%.3f", duration))s", level: .info, category: category)
    }
    
    /// Log user actions for analytics
    func logUserAction(_ action: String, parameters: [String: Any] = [:], category: String = "UserAction") {
        var message = "User action: \(action)"
        if !parameters.isEmpty {
            let paramString = parameters.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            message += " | Parameters: \(paramString)"
        }
        log(message, level: .info, category: category)
    }
}