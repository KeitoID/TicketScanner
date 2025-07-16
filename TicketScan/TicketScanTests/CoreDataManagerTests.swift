import Testing
import CoreData
@testable import TicketScan

struct CoreDataManagerTests {
    
    private func createInMemoryContext() -> NSManagedObjectContext {
        let container = NSPersistentContainer(name: "Ticket")
        
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load store: \(error)")
            }
        }
        
        return container.viewContext
    }
    
    @Test func testInitialization() async throws {
        let manager = CoreDataManager.shared
        #expect(manager.isInitialized == true)
        #expect(manager.container.name == "Ticket")
    }
    
    @Test func testSaveWithoutChanges() async throws {
        let context = createInMemoryContext()
        
        // Test direct context save without changes
        do {
            try context.save()
            #expect(true) // Should succeed
        } catch {
            #expect(Bool(false), "Save should succeed when no changes: \(error)")
        }
    }
    
    @Test func testSaveWithChanges() async throws {
        let context = createInMemoryContext()
        
        // Create a new ticket entity using NSEntityDescription
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "TicketEntity", in: context) else {
            #expect(Bool(false), "Could not find TicketEntity in managed object model")
            return
        }
        
        let ticketEntity = TicketEntity(entity: entityDescription, insertInto: context)
        
        // Set all required properties
        ticketEntity.id = UUID()
        ticketEntity.title = "テストチケット"
        ticketEntity.location = "テスト会場" 
        ticketEntity.desc = "テスト説明"
        ticketEntity.eventDate = Date()
        ticketEntity.createdAt = Date()
        ticketEntity.isFavorite = false
        ticketEntity.imageData = Data()
        
        // Verify context has changes
        #expect(context.hasChanges == true)
        
        // Save and verify
        try context.save()
        #expect(context.hasChanges == false)
        
        // Verify entity exists
        let fetchRequest: NSFetchRequest<TicketEntity> = TicketEntity.fetchRequest()
        let results = try context.fetch(fetchRequest)
        #expect(results.count == 1)
        #expect(results.first?.title == "テストチケット")
    }
    
    @Test func testFetchTickets() async throws {
        let context = createInMemoryContext()
        
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "TicketEntity", in: context) else {
            #expect(Bool(false), "Could not find TicketEntity in managed object model")
            return
        }
        
        // Create test data
        let ticketEntity1 = TicketEntity(entity: entityDescription, insertInto: context)
        ticketEntity1.id = UUID()
        ticketEntity1.title = "チケット1"
        ticketEntity1.location = "会場1"
        ticketEntity1.desc = "説明1"
        ticketEntity1.eventDate = Date()
        ticketEntity1.createdAt = Date()
        ticketEntity1.isFavorite = false
        ticketEntity1.imageData = Data()
        
        let ticketEntity2 = TicketEntity(entity: entityDescription, insertInto: context)
        ticketEntity2.id = UUID()
        ticketEntity2.title = "チケット2"
        ticketEntity2.location = "会場2"
        ticketEntity2.desc = "説明2"
        ticketEntity2.eventDate = Date()
        ticketEntity2.createdAt = Date()
        ticketEntity2.isFavorite = true
        ticketEntity2.imageData = Data()
        
        try context.save()
        
        // Fetch tickets
        let fetchRequest: NSFetchRequest<TicketEntity> = TicketEntity.fetchRequest()
        let tickets = try context.fetch(fetchRequest)
        
        #expect(tickets.count == 2)
        #expect(tickets.contains { $0.title == "チケット1" })
        #expect(tickets.contains { $0.title == "チケット2" })
    }
    
    @Test func testDeleteTicket() async throws {
        let context = createInMemoryContext()
        
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "TicketEntity", in: context) else {
            #expect(Bool(false), "Could not find TicketEntity in managed object model")
            return
        }
        
        // Create test data
        let ticketEntity = TicketEntity(entity: entityDescription, insertInto: context)
        ticketEntity.id = UUID()
        ticketEntity.title = "削除テスト"
        ticketEntity.location = "会場"
        ticketEntity.desc = "削除テスト用"
        ticketEntity.eventDate = Date()
        ticketEntity.createdAt = Date()
        ticketEntity.isFavorite = false
        ticketEntity.imageData = Data()
        
        try context.save()
        
        // Delete the ticket
        context.delete(ticketEntity)
        try context.save()
        
        // Verify deletion
        let fetchRequest: NSFetchRequest<TicketEntity> = TicketEntity.fetchRequest()
        let tickets = try context.fetch(fetchRequest)
        
        #expect(tickets.isEmpty)
    }
    
    @Test func testFetchWithSortDescriptor() async throws {
        let context = createInMemoryContext()
        
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "TicketEntity", in: context) else {
            #expect(Bool(false), "Could not find TicketEntity in managed object model")
            return
        }
        
        let now = Date()
        let earlier = now.addingTimeInterval(-3600) // 1 hour earlier
        
        // Create test data with different creation times
        let ticketEntity1 = TicketEntity(entity: entityDescription, insertInto: context)
        ticketEntity1.id = UUID()
        ticketEntity1.title = "新しいチケット"
        ticketEntity1.location = "会場1"
        ticketEntity1.desc = "説明1"
        ticketEntity1.eventDate = Date()
        ticketEntity1.createdAt = now
        ticketEntity1.isFavorite = false
        ticketEntity1.imageData = Data()
        
        let ticketEntity2 = TicketEntity(entity: entityDescription, insertInto: context)
        ticketEntity2.id = UUID()
        ticketEntity2.title = "古いチケット"
        ticketEntity2.location = "会場2"
        ticketEntity2.desc = "説明2"
        ticketEntity2.eventDate = Date()
        ticketEntity2.createdAt = earlier
        ticketEntity2.isFavorite = false
        ticketEntity2.imageData = Data()
        
        try context.save()
        
        // Fetch with sort descriptor (newest first)
        let fetchRequest: NSFetchRequest<TicketEntity> = TicketEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TicketEntity.createdAt, ascending: false)]
        
        let tickets = try context.fetch(fetchRequest)
        
        #expect(tickets.count == 2)
        #expect(tickets.first?.title == "新しいチケット")
        #expect(tickets.last?.title == "古いチケット")
    }
}

extension Result {
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
}