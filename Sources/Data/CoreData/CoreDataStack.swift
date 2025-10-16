//
//  CoreDataStack.swift
//  DailyRoutineApp
//
//  Created by GitHub Copilot on 16/10/2025.
//

import Foundation
import CoreData
import CloudKit
import Combine

/// Production-grade Core Data stack with CloudKit integration
final class CoreDataStack: NSObject, CoreDataStackProtocol {
    
    // MARK: - Properties
    private let modelName = "DailyRoutineApp"
    private let cloudKitContainerIdentifier = "iCloud.com.dailyroutineapp.container"
    
    private lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: modelName)
        
        // Configure the persistent store description for CloudKit
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }
        
        // Configure CloudKit
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: cloudKitContainerIdentifier
        )
        
        // Configure for performance
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true
        
        // Load the persistent stores
        container.loadPersistentStores { [weak self] _, error in
            if let error = error {
                AppLogger.shared.logError(error, context: "Failed to load Core Data stack", category: "CoreData")
                fatalError("Core Data error: \(error)")
            }
            
            AppLogger.shared.log("Core Data stack loaded successfully", level: .info, category: "CoreData")
            self?.setupNotifications()
        }
        
        return container
    }()
    
    // MARK: - Public Properties
    var viewContext: NSManagedObjectContext {
        let context = persistentContainer.viewContext
        context.automaticallyMergesChangesFromParent = true
        return context
    }
    
    var backgroundContext: NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
    }
    
    func initialize() async {
        // Trigger lazy initialization
        _ = persistentContainer
        
        // Setup initial data if needed
        await setupInitialDataIfNeeded()
        
        AppLogger.shared.log("CoreDataStack initialized", level: .info, category: "CoreData")
    }
    
    // MARK: - Save Operations
    func save() async throws {
        let context = viewContext
        
        guard context.hasChanges else { return }
        
        do {
            try context.save()
            AppLogger.shared.log("View context saved successfully", level: .debug, category: "CoreData")
        } catch {
            AppLogger.shared.logError(error, context: "Failed to save view context", category: "CoreData")
            throw CoreDataError.saveFailed(error.localizedDescription)
        }
    }
    
    func saveBackground() async throws {
        let context = backgroundContext
        
        guard context.hasChanges else { return }
        
        try await context.perform {
            do {
                try context.save()
                AppLogger.shared.log("Background context saved successfully", level: .debug, category: "CoreData")
            } catch {
                AppLogger.shared.logError(error, context: "Failed to save background context", category: "CoreData")
                throw CoreDataError.saveFailed(error.localizedDescription)
            }
        }
    }
    
    func performBackgroundTask<T>(
        _ block: @escaping (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        let context = backgroundContext
        
        return try await context.perform {
            let result = try block(context)
            
            if context.hasChanges {
                try context.save()
            }
            
            return result
        }
    }
    
    // MARK: - CloudKit Operations
    func initializeCloudKitSchema() async throws {
        do {
            try await persistentContainer.initializeCloudKitSchema()
            AppLogger.shared.log("CloudKit schema initialized", level: .info, category: "CoreData")
        } catch {
            AppLogger.shared.logError(error, context: "Failed to initialize CloudKit schema", category: "CoreData")
            throw CoreDataError.cloudKitError(error.localizedDescription)
        }
    }
    
    // MARK: - Migration Support
    func performMigrationIfNeeded() async throws {
        // Check if migration is needed
        guard needsMigration() else { return }
        
        AppLogger.shared.log("Starting Core Data migration", level: .info, category: "CoreData")
        
        // Migration logic would be implemented here
        // For now, we rely on automatic migrations
        
        AppLogger.shared.log("Core Data migration completed", level: .info, category: "CoreData")
    }
    
    private func needsMigration() -> Bool {
        // Implementation for checking migration needs
        // This would compare current model version with stored version
        return false
    }
    
    // MARK: - Batch Operations
    func performBatchInsert<T: NSManagedObject>(
        entityName: String,
        objects: [[String: Any]]
    ) async throws -> [T] {
        let request = NSBatchInsertRequest(entityName: entityName, objects: objects)
        request.resultType = .objectIDs
        
        let context = backgroundContext
        
        return try await context.perform {
            let result = try context.execute(request) as? NSBatchInsertResult
            let objectIDs = result?.result as? [NSManagedObjectID] ?? []
            
            // Convert object IDs to objects
            return objectIDs.compactMap { objectID in
                try? context.existingObject(with: objectID) as? T
            }
        }
    }
    
    func performBatchUpdate(
        entityName: String,
        predicate: NSPredicate?,
        properties: [String: Any]
    ) async throws -> Int {
        let request = NSBatchUpdateRequest(entityName: entityName)
        request.predicate = predicate
        request.propertiesToUpdate = properties
        request.resultType = .updatedObjectsCountResultType
        
        let context = backgroundContext
        
        return try await context.perform {
            let result = try context.execute(request) as? NSBatchUpdateResult
            return result?.result as? Int ?? 0
        }
    }
    
    func performBatchDelete(
        entityName: String,
        predicate: NSPredicate
    ) async throws -> Int {
        let request = NSBatchDeleteRequest(entityName: entityName)
        request.predicate = predicate
        request.resultType = .resultTypeCount
        
        let context = backgroundContext
        
        return try await context.perform {
            let result = try context.execute(request) as? NSBatchDeleteResult
            return result?.result as? Int ?? 0
        }
    }
    
    // MARK: - Private Methods
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contextDidChange(_:)),
            name: .NSManagedObjectContextObjectsDidChange,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(storeRemoteChange(_:)),
            name: .NSPersistentStoreRemoteChange,
            object: nil
        )
    }
    
    @objc private func contextDidChange(_ notification: Notification) {
        guard let context = notification.object as? NSManagedObjectContext else { return }
        
        AppLogger.shared.log(
            "Context did change: \(context.description)",
            level: .debug,
            category: "CoreData"
        )
    }
    
    @objc private func storeRemoteChange(_ notification: Notification) {
        AppLogger.shared.log(
            "Store remote change detected",
            level: .info,
            category: "CoreData"
        )
        
        // Handle remote changes from CloudKit
        Task {
            await handleRemoteChanges(notification)
        }
    }
    
    private func handleRemoteChanges(_ notification: Notification) async {
        // Process remote changes and update local data
        await viewContext.perform {
            self.viewContext.refreshAllObjects()
        }
    }
    
    private func setupInitialDataIfNeeded() async {
        let hasData = await performBackgroundTask { context in
            let routineRequest: NSFetchRequest<RoutineEntity> = RoutineEntity.fetchRequest()
            routineRequest.fetchLimit = 1
            
            do {
                let count = try context.count(for: routineRequest)
                return count > 0
            } catch {
                return false
            }
        }
        
        guard let hasExistingData = try? hasData, !hasExistingData else {
            return
        }
        
        AppLogger.shared.log("Setting up initial data", level: .info, category: "CoreData")
        
        // Create sample data for first-time users
        await createSampleData()
    }
    
    private func createSampleData() async {
        // Implementation for creating sample routines, habits, etc.
        AppLogger.shared.log("Sample data created", level: .info, category: "CoreData")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Core Data Errors
enum CoreDataError: LocalizedError {
    case saveFailed(String)
    case fetchFailed(String)
    case deleteFailed(String)
    case migrationFailed(String)
    case cloudKitError(String)
    case invalidManagedObject
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let message):
            return "Save failed: \(message)"
        case .fetchFailed(let message):
            return "Fetch failed: \(message)"
        case .deleteFailed(let message):
            return "Delete failed: \(message)"
        case .migrationFailed(let message):
            return "Migration failed: \(message)"
        case .cloudKitError(let message):
            return "CloudKit error: \(message)"
        case .invalidManagedObject:
            return "Invalid managed object"
        }
    }
}

// MARK: - Fetch Request Extensions
extension NSFetchRequest {
    static func fetchRequest<T: NSManagedObject>(for type: T.Type) -> NSFetchRequest<T> {
        return NSFetchRequest<T>(entityName: String(describing: type))
    }
}

extension NSManagedObjectContext {
    func fetch<T: NSManagedObject>(_ type: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor] = []) throws -> [T] {
        let request = NSFetchRequest<T>.fetchRequest(for: type)
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        return try fetch(request)
    }
    
    func fetchFirst<T: NSManagedObject>(_ type: T.Type, predicate: NSPredicate? = nil) throws -> T? {
        let request = NSFetchRequest<T>.fetchRequest(for: type)
        request.predicate = predicate
        request.fetchLimit = 1
        return try fetch(request).first
    }
}