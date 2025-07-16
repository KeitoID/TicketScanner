import CoreData
import SwiftUI

class CoreDataManager {
    static let shared = CoreDataManager()
    
    let container: NSPersistentContainer
    private var initializationError: AppError?
    
    init() {
        container = NSPersistentContainer(name: "Ticket")
        
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                self.initializationError = AppError.coreDataInitializationError(error)
            }
        }
    }
    
    func save() -> Result<Void, AppError> {
        if let initError = initializationError {
            return .failure(initError)
        }
        
        let context = container.viewContext
        
        guard context.hasChanges else {
            return .success(())
        }
        
        do {
            try context.save()
            return .success(())
        } catch {
            let nsError = error as NSError
            return .failure(AppError.coreDataSaveError(nsError))
        }
    }
    
    func fetch<T: NSManagedObject>(_ fetchRequest: NSFetchRequest<T>) -> Result<[T], AppError> {
        if let initError = initializationError {
            return .failure(initError)
        }
        
        do {
            let results = try container.viewContext.fetch(fetchRequest)
            return .success(results)
        } catch {
            let nsError = error as NSError
            return .failure(AppError.coreDataLoadError(nsError))
        }
    }
    
    func delete<T: NSManagedObject>(_ object: T) -> Result<Void, AppError> {
        if let initError = initializationError {
            return .failure(initError)
        }
        
        container.viewContext.delete(object)
        return save()
    }
    
    var isInitialized: Bool {
        return initializationError == nil
    }
} 