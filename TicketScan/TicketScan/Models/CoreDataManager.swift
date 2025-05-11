import CoreData
import SwiftUI

class CoreDataManager {
    static let shared = CoreDataManager()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "Ticket")
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("CoreDataの読み込みに失敗しました: \(error.localizedDescription)")
            }
        }
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("CoreDataの保存に失敗しました: \(error.localizedDescription)")
            }
        }
    }
} 