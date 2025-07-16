//
//  TicketScanTests.swift
//  TicketScanTests
//
//  Created by Yoshioka Keito on 2025/05/11.
//

import Testing
import CoreData
@testable import TicketScan

// Helper class to manage the in-memory Core Data stack
class TestCoreDataStack {
    let persistentContainer: NSPersistentContainer
    var managedObjectContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    init(modelName: String = "TicketScan") {
        guard let modelURL = Bundle(for: type(of: self)).url(forResource: modelName, withExtension: "momd"),
              let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Unable to load model \(modelName).momd from test bundle")
        }

        persistentContainer = NSPersistentContainer(name: modelName, managedObjectModel: managedObjectModel)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false // Make it synchronous for testing

        persistentContainer.persistentStoreDescriptions = [description]

        persistentContainer.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            // Optional: print store URL for debugging
            // print("In-memory store loaded: \(storeDescription.url?.absoluteString ?? "No URL")")
        }
        // Ensure the viewContext is set up correctly
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}

struct TicketScanTests {
    var testCoreDataStack: TestCoreDataStack
    var viewModel: TicketViewModel

    init() {
        testCoreDataStack = TestCoreDataStack()
        viewModel = TicketViewModel(context: testCoreDataStack.managedObjectContext)
    }

    @Test func testViewModelInitialization() throws {
        #expect(viewModel.context === testCoreDataStack.managedObjectContext, "ViewModel should be initialized with the test context")
    }

    @Test func testAddTicket_AddsTicketToStoreAndUpdatesViewModel() throws {
        let testDate = Date()
        let testImageData = "test_image_data".data(using: .utf8)!
        let newTicket = Ticket(
            id: UUID(), // Explicitly create UUID for later comparison
            title: "Tech Conference 2024",
            location: "Online",
            description: "Annual tech conference with various speakers.",
            imageData: testImageData,
            createdAt: testDate,
            isFavorite: true,
            eventDate: testDate.addingTimeInterval(86400 * 7) // Event is one week from creation
        )
        
        viewModel.addTicket(newTicket)

        // 1. Verify viewModel.tickets
        #expect(viewModel.tickets.count == 1, "ViewModel should have one ticket after adding.")
        
        guard let ticketFromViewModel = viewModel.tickets.first else {
            Issue.record("ViewModel's tickets array was empty after adding a ticket.")
            return
        }

        // 2. Assert properties of the ticket in viewModel.tickets
        #expect(ticketFromViewModel.id == newTicket.id, "ID should match")
        #expect(ticketFromViewModel.title == newTicket.title, "Title should match")
        #expect(ticketFromViewModel.location == newTicket.location, "Location should match")
        #expect(ticketFromViewModel.description == newTicket.description, "Description should match")
        #expect(ticketFromViewModel.imageData == newTicket.imageData, "ImageData should match")
        // Comparing dates can be tricky due to precision. Comparing timeIntervalSince1970 is safer.
        #expect(abs(ticketFromViewModel.createdAt.timeIntervalSince1970 - newTicket.createdAt.timeIntervalSince1970) < 0.001, "CreatedAt should match")
        #expect(ticketFromViewModel.isFavorite == newTicket.isFavorite, "IsFavorite should match")
        #expect(abs(ticketFromViewModel.eventDate.timeIntervalSince1970 - newTicket.eventDate.timeIntervalSince1970) < 0.001, "EventDate should match")

        // 3. Fetch directly from the context to confirm persistence
        let fetchRequest: NSFetchRequest<TicketEntity> = TicketEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", newTicket.id as CVarArg)
        
        let context = testCoreDataStack.managedObjectContext
        let results = try context.fetch(fetchRequest)
        
        #expect(results.count == 1, "Should find one ticket entity in the store with the new ID.")
        
        guard let ticketEntityFromStore = results.first else {
            Issue.record("Ticket entity not found in the store.")
            return
        }

        // 4. Assert properties of the entity fetched from the store
        #expect(ticketEntityFromStore.id == newTicket.id, "Entity ID should match")
        #expect(ticketEntityFromStore.title == newTicket.title, "Entity title should match")
        #expect(ticketEntityFromStore.location == newTicket.location, "Entity location should match")
        #expect(ticketEntityFromStore.desc == newTicket.description, "Entity description should match")
        #expect(ticketEntityFromStore.imageData == newTicket.imageData, "Entity imageData should match")
        #expect(abs(ticketEntityFromStore.createdAt!.timeIntervalSince1970 - newTicket.createdAt.timeIntervalSince1970) < 0.001, "Entity createdAt should match")
        #expect(ticketEntityFromStore.isFavorite == newTicket.isFavorite, "Entity isFavorite should match")
        #expect(abs(ticketEntityFromStore.eventDate!.timeIntervalSince1970 - newTicket.eventDate.timeIntervalSince1970) < 0.001, "Entity eventDate should match")
    }

    @Test func testAddMultipleTickets_UpdatesViewModelAndStoreCorrectly() throws {
        let ticket1Date = Date()
        let ticket1 = Ticket(
            title: "Concert Alpha",
            location: "Venue A",
            description: "Live music performance.",
            imageData: Data(),
            createdAt: ticket1Date,
            isFavorite: false,
            eventDate: ticket1Date.addingTimeInterval(86400 * 10)
        )
        
        let ticket2Date = Date().addingTimeInterval(3600) // An hour later
        let ticket2 = Ticket(
            title: "Workshop Beta",
            location: "Studio B",
            description: "Interactive learning session.",
            imageData: "img2".data(using: .utf8)!,
            createdAt: ticket2Date,
            isFavorite: true,
            eventDate: ticket2Date.addingTimeInterval(86400 * 5)
        )

        // Add tickets
        viewModel.addTicket(ticket1)
        viewModel.addTicket(ticket2)

        // 1. Verify viewModel.tickets count
        #expect(viewModel.tickets.count == 2, "ViewModel should have two tickets after adding.")

        // 2. Verify persistence in context by count
        let fetchRequest: NSFetchRequest<TicketEntity> = TicketEntity.fetchRequest()
        let context = testCoreDataStack.managedObjectContext
        let results = try context.fetch(fetchRequest)
        #expect(results.count == 2, "Store should contain two ticket entities.")

        // 3. Optionally, verify properties of one or both tickets from viewModel.tickets
        // Check based on title, assuming titles are unique for this test
        let vmTicket1 = viewModel.tickets.first { $0.title == "Concert Alpha" }
        let vmTicket2 = viewModel.tickets.first { $0.title == "Workshop Beta" }

        #expect(vmTicket1 != nil, "Ticket 1 should be in viewModel.tickets")
        #expect(vmTicket2 != nil, "Ticket 2 should be in viewModel.tickets")

        #expect(vmTicket1?.location == "Venue A", "Ticket 1 location mismatch in ViewModel")
        #expect(vmTicket2?.isFavorite == true, "Ticket 2 favorite status mismatch in ViewModel")
        
        // 4. Optionally, verify properties from store entities
        let entityTicket1 = results.first { $0.title == "Concert Alpha" }
        let entityTicket2 = results.first { $0.title == "Workshop Beta" }

        #expect(entityTicket1 != nil, "Ticket 1 entity should be in store")
        #expect(entityTicket2 != nil, "Ticket 2 entity should be in store")
        
        #expect(entityTicket1?.location == "Venue A", "Ticket 1 entity location mismatch in store")
        #expect(entityTicket2?.isFavorite == true, "Ticket 2 entity favorite status mismatch in store")
    }

    // MARK: - Delete Ticket Tests

    @Test func testDeleteTicket_RemovesTicketFromStoreAndUpdatesViewModel() throws {
        // 1. Add a sample ticket
        let ticketToDelete = Ticket(
            id: UUID(),
            title: "Event To Delete",
            location: "Some Location",
            description: "Details about event to delete.",
            imageData: Data(),
            eventDate: Date()
        )
        viewModel.addTicket(ticketToDelete)

        // 2. Verify it was added
        #expect(viewModel.tickets.count == 1, "ViewModel should have one ticket before deletion.")
        #expect(viewModel.tickets.first?.id == ticketToDelete.id, "The ticket to delete should be in the ViewModel.")

        // Verify in store
        let context = testCoreDataStack.managedObjectContext
        var fetchRequest: NSFetchRequest<TicketEntity> = TicketEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", ticketToDelete.id as CVarArg)
        var results = try context.fetch(fetchRequest)
        #expect(results.count == 1, "Ticket should exist in the store before deletion.")

        // 3. Delete the ticket
        viewModel.deleteTicket(ticketToDelete)

        // 4. Verify viewModel.tickets is now empty
        #expect(viewModel.tickets.isEmpty, "ViewModel tickets array should be empty after deletion.")

        // 5. Verify the ticket was removed from the Core Data store
        results = try context.fetch(fetchRequest) // Re-fetch with the same predicate
        #expect(results.isEmpty, "Ticket should be removed from the store after deletion.")
    }

    @Test func testDeleteTicket_WhenTicketDoesNotExist_ShouldNotCrashAndStateRemainsConsistent() throws {
        // 1. Add an initial ticket to ensure the ViewModel is not empty
        let initialTicket = Ticket(title: "Initial Event", location: "Initial Location", description: "", imageData: Data(), eventDate: Date())
        viewModel.addTicket(initialTicket)
        let initialTicketCount = viewModel.tickets.count
        
        let context = testCoreDataStack.managedObjectContext
        var fetchRequest: NSFetchRequest<TicketEntity> = TicketEntity.fetchRequest()
        let initialStoreCount = try context.count(for: fetchRequest)


        // 2. Create a ticket that is NOT added to the store or ViewModel
        let nonExistentTicket = Ticket(
            id: UUID(), // Unique ID, guaranteed not to be in the store
            title: "Non Existent Event",
            location: "Nowhere",
            description: "This ticket was never added.",
            imageData: Data(),
            eventDate: Date()
        )

        // 3. Attempt to delete the non-existent ticket
        viewModel.deleteTicket(nonExistentTicket) // This should not crash

        // 4. Verify ViewModel state is unchanged
        #expect(viewModel.tickets.count == initialTicketCount, "ViewModel ticket count should remain unchanged.")
        #expect(viewModel.tickets.first?.id == initialTicket.id, "The initial ticket should still be in the ViewModel.")


        // 5. Verify store state is unchanged
        let currentStoreCount = try context.count(for: fetchRequest)
        #expect(currentStoreCount == initialStoreCount, "Store ticket count should remain unchanged.")
    }

    @Test func testDeleteTicket_WithMultipleTickets_DeletesCorrectTicketAndKeepsOthers() throws {
        // 1. Add multiple tickets
        let ticket1 = Ticket(id: UUID(), title: "Event One", location: "Venue 1", description: "", imageData: Data(), eventDate: Date())
        let ticketToKeep = Ticket(id: UUID(), title: "Event To Keep", location: "Venue 2", description: "", imageData: Data(), eventDate: Date())
        let ticketToDelete = Ticket(id: UUID(), title: "Event To Delete", location: "Venue 3", description: "", imageData: Data(), eventDate: Date())

        viewModel.addTicket(ticket1)
        viewModel.addTicket(ticketToKeep)
        viewModel.addTicket(ticketToDelete)
        
        #expect(viewModel.tickets.count == 3, "ViewModel should have three tickets before deletion.")

        // 2. Delete one specific ticket
        viewModel.deleteTicket(ticketToDelete)

        // 3. Verify ViewModel state
        #expect(viewModel.tickets.count == 2, "ViewModel should have two tickets after deletion.")
        #expect(viewModel.tickets.contains(where: { $0.id == ticketToDelete.id }) == false, "Deleted ticket should not be in ViewModel.")
        #expect(viewModel.tickets.contains(where: { $0.id == ticketToKeep.id }) == true, "Ticket to keep should still be in ViewModel.")
        #expect(viewModel.tickets.contains(where: { $0.id == ticket1.id }) == true, "Ticket 1 should still be in ViewModel.")

        // 4. Verify store state
        let context = testCoreDataStack.managedObjectContext
        
        // Check deleted ticket is gone from store
        var fetchRequestDeleted: NSFetchRequest<TicketEntity> = TicketEntity.fetchRequest()
        fetchRequestDeleted.predicate = NSPredicate(format: "id == %@", ticketToDelete.id as CVarArg)
        let deletedResults = try context.fetch(fetchRequestDeleted)
        #expect(deletedResults.isEmpty, "Deleted ticket should be removed from the store.")

        // Check other tickets are still in store
        var fetchRequestKept: NSFetchRequest<TicketEntity> = TicketEntity.fetchRequest()
        fetchRequestKept.predicate = NSPredicate(format: "id == %@", ticketToKeep.id as CVarArg)
        let keptResults = try context.fetch(fetchRequestKept)
        #expect(keptResults.count == 1, "Ticket to keep should still be in the store.")
        
        var fetchRequest1: NSFetchRequest<TicketEntity> = TicketEntity.fetchRequest()
        fetchRequest1.predicate = NSPredicate(format: "id == %@", ticket1.id as CVarArg)
        let results1 = try context.fetch(fetchRequest1)
        #expect(results1.count == 1, "Ticket 1 should still be in the store.")
        
        let totalCountRequest: NSFetchRequest<TicketEntity> = TicketEntity.fetchRequest()
        let totalCount = try context.count(for: totalCountRequest)
        #expect(totalCount == 2, "Total count in store should be 2 after deletion.")
    }

    // MARK: - Toggle Favorite Tests

    @Test func testToggleFavorite_UpdatesFavoriteStatusInStoreAndViewModel() throws {
        // 1. Add a sample ticket with isFavorite = false
        let ticketID = UUID()
        let initialTicket = Ticket(
            id: ticketID,
            title: "Favorite Event",
            location: "Venue Fav",
            description: "Event to test favorite toggle.",
            imageData: Data(),
            isFavorite: false, // Start as not favorite
            eventDate: Date()
        )
        viewModel.addTicket(initialTicket)

        // 2. Verify initial state
        guard let ticketInViewModel = viewModel.tickets.first(where: { $0.id == ticketID }) else {
            Issue.record("Ticket not found in ViewModel after adding.")
            return
        }
        #expect(ticketInViewModel.isFavorite == false, "Ticket should initially be not favorite in ViewModel.")

        let context = testCoreDataStack.managedObjectContext
        var fetchRequest: NSFetchRequest<TicketEntity> = TicketEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", ticketID as CVarArg)
        
        guard let entityInStore = try context.fetch(fetchRequest).first else {
            Issue.record("Ticket entity not found in store after adding.")
            return
        }
        #expect(entityInStore.isFavorite == false, "Ticket should initially be not favorite in store.")

        // 3. Toggle favorite to true
        viewModel.toggleFavorite(ticketInViewModel) // Pass the ViewModel's version of the ticket

        // 4. Verify isFavorite is true in ViewModel
        guard let favoritedTicketInViewModel = viewModel.tickets.first(where: { $0.id == ticketID }) else {
            Issue.record("Ticket not found in ViewModel after first toggle.")
            return
        }
        #expect(favoritedTicketInViewModel.isFavorite == true, "Ticket should be favorite in ViewModel after first toggle.")

        // 5. Verify isFavorite is true in store
        guard let favoritedEntityInStore = try context.fetch(fetchRequest).first else {
            Issue.record("Ticket entity not found in store after first toggle.")
            return
        }
        #expect(favoritedEntityInStore.isFavorite == true, "Ticket should be favorite in store after first toggle.")

        // 6. Toggle favorite back to false
        viewModel.toggleFavorite(favoritedTicketInViewModel)

        // 7. Verify isFavorite is false in ViewModel
        guard let unfavoritedTicketInViewModel = viewModel.tickets.first(where: { $0.id == ticketID }) else {
            Issue.record("Ticket not found in ViewModel after second toggle.")
            return
        }
        #expect(unfavoritedTicketInViewModel.isFavorite == false, "Ticket should be not favorite in ViewModel after second toggle.")
        
        // 8. Verify isFavorite is false in store
        guard let unfavoritedEntityInStore = try context.fetch(fetchRequest).first else {
            Issue.record("Ticket entity not found in store after second toggle.")
            return
        }
        #expect(unfavoritedEntityInStore.isFavorite == false, "Ticket should be not favorite in store after second toggle.")
    }

    @Test func testToggleFavorite_WhenTicketDoesNotExist_ShouldNotCrashAndStateRemainsConsistent() throws {
        // 1. Add an initial ticket to ensure the ViewModel is not empty and has a known state.
        let initialTicket = Ticket(
            id: UUID(),
            title: "Existing Event",
            location: "Some Venue",
            description: "An event that exists.",
            imageData: Data(),
            isFavorite: false,
            eventDate: Date()
        )
        viewModel.addTicket(initialTicket)
        
        let initialTicketCountInViewModel = viewModel.tickets.count
        let initialFavoriteStatusInViewModel = viewModel.tickets.first!.isFavorite

        let context = testCoreDataStack.managedObjectContext
        let initialFetchRequest: NSFetchRequest<TicketEntity> = TicketEntity.fetchRequest()
        initialFetchRequest.predicate = NSPredicate(format: "id == %@", initialTicket.id as CVarArg)
        let initialEntityInStore = try context.fetch(initialFetchRequest).first
        let initialFavoriteStatusInStore = initialEntityInStore?.isFavorite

        // 2. Create a ticket that is NOT added to the store or ViewModel
        let nonExistentTicket = Ticket(
            id: UUID(), // Different UUID, guaranteed not to be in the store
            title: "Ghost Event",
            location: "Limbo",
            description: "This ticket does not exist.",
            imageData: Data(),
            isFavorite: false,
            eventDate: Date()
        )

        // 3. Attempt to toggle favorite on the non-existent ticket
        viewModel.toggleFavorite(nonExistentTicket) // This should not crash

        // 4. Verify ViewModel state is unchanged for the existing ticket
        #expect(viewModel.tickets.count == initialTicketCountInViewModel, "ViewModel ticket count should remain unchanged.")
        guard let existingTicketInViewModel = viewModel.tickets.first(where: { $0.id == initialTicket.id }) else {
            Issue.record("Initial ticket not found in ViewModel after toggle attempt on non-existent ticket.")
            return
        }
        #expect(existingTicketInViewModel.isFavorite == initialFavoriteStatusInViewModel, "Favorite status of existing ticket in ViewModel should remain unchanged.")

        // 5. Verify store state is unchanged for the existing ticket
        guard let existingEntityInStore = try context.fetch(initialFetchRequest).first else {
            Issue.record("Initial ticket entity not found in store after toggle attempt on non-existent ticket.")
            return
        }
        #expect(existingEntityInStore.isFavorite == initialFavoriteStatusInStore, "Favorite status of existing ticket in store should remain unchanged.")
        
        // 6. Verify non-existent ticket was not added to the store
        let nonExistentFetchRequest: NSFetchRequest<TicketEntity> = TicketEntity.fetchRequest()
        nonExistentFetchRequest.predicate = NSPredicate(format: "id == %@", nonExistentTicket.id as CVarArg)
        let nonExistentResults = try context.fetch(nonExistentFetchRequest)
        #expect(nonExistentResults.isEmpty, "Non-existent ticket should not have been added to the store.")
    }

    // MARK: - Update Ticket Tests

    @Test func testUpdateTicket_UpdatesAllDetailsInStoreAndViewModel() throws {
        // 1. Add a sample ticket
        let originalTicketID = UUID()
        let originalDate = Date()
        let originalImageData = "original_image".data(using: .utf8)!
        let originalIsFavorite = false

        let originalTicket = Ticket(
            id: originalTicketID,
            title: "Original Title",
            location: "Original Location",
            description: "Original Description",
            imageData: originalImageData,
            createdAt: originalDate,
            isFavorite: originalIsFavorite,
            eventDate: originalDate.addingTimeInterval(1000)
        )
        viewModel.addTicket(originalTicket)

        // 2. Define new values
        let newTitle = "Updated Title"
        let newLocation = "Updated Location"
        let newDescription = "Updated Description"
        let newEventDate = originalDate.addingTimeInterval(2000) // Different from original eventDate

        // 3. Call updateTicket
        viewModel.updateTicket(originalTicket, title: newTitle, location: newLocation, description: newDescription, eventDate: newEventDate)

        // 4. Verify properties in viewModel.tickets
        guard let updatedTicketInViewModel = viewModel.tickets.first(where: { $0.id == originalTicketID }) else {
            Issue.record("Updated ticket not found in ViewModel.")
            return
        }
        #expect(updatedTicketInViewModel.title == newTitle, "ViewModel title should be updated.")
        #expect(updatedTicketInViewModel.location == newLocation, "ViewModel location should be updated.")
        #expect(updatedTicketInViewModel.description == newDescription, "ViewModel description should be updated.")
        #expect(abs(updatedTicketInViewModel.eventDate.timeIntervalSince1970 - newEventDate.timeIntervalSince1970) < 0.001, "ViewModel eventDate should be updated.")
        // Check unchanged properties
        #expect(updatedTicketInViewModel.id == originalTicketID, "ViewModel ID should remain unchanged.")
        #expect(abs(updatedTicketInViewModel.createdAt.timeIntervalSince1970 - originalDate.timeIntervalSince1970) < 0.001, "ViewModel createdAt should remain unchanged.")
        #expect(updatedTicketInViewModel.isFavorite == originalIsFavorite, "ViewModel isFavorite should remain unchanged.")
        #expect(updatedTicketInViewModel.imageData == originalImageData, "ViewModel imageData should remain unchanged.")


        // 5. Verify properties in Core Data store
        let context = testCoreDataStack.managedObjectContext
        let fetchRequest: NSFetchRequest<TicketEntity> = TicketEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", originalTicketID as CVarArg)
        
        guard let entityInStore = try context.fetch(fetchRequest).first else {
            Issue.record("Updated ticket entity not found in store.")
            return
        }
        #expect(entityInStore.title == newTitle, "Store title should be updated.")
        #expect(entityInStore.location == newLocation, "Store location should be updated.")
        #expect(entityInStore.desc == newDescription, "Store description should be updated.")
        #expect(abs(entityInStore.eventDate!.timeIntervalSince1970 - newEventDate.timeIntervalSince1970) < 0.001, "Store eventDate should be updated.")
        // Check unchanged properties in store
        #expect(entityInStore.id == originalTicketID, "Store ID should remain unchanged.")
        #expect(abs(entityInStore.createdAt!.timeIntervalSince1970 - originalDate.timeIntervalSince1970) < 0.001, "Store createdAt should remain unchanged.")
        #expect(entityInStore.isFavorite == originalIsFavorite, "Store isFavorite should remain unchanged.")
        #expect(entityInStore.imageData == originalImageData, "Store imageData should remain unchanged.")
    }

    @Test func testUpdateTicket_UpdatesPartialDetailsAndKeepsOthersUnchanged() throws {
        // 1. Add a sample ticket
        let ticketID = UUID()
        let originalTitle = "Original Title for Partial Update"
        let originalLocation = "Original Location for Partial Update"
        let originalDescription = "Original Description for Partial Update"
        let originalEventDate = Date()

        let ticket = Ticket(
            id: ticketID,
            title: originalTitle,
            location: originalLocation,
            description: originalDescription,
            imageData: Data(),
            eventDate: originalEventDate
        )
        viewModel.addTicket(ticket)

        // 2. Define new values for only some fields
        let newTitle = "Partially Updated Title"
        let newEventDate = originalEventDate.addingTimeInterval(5000)

        // 3. Call updateTicket, passing original values for fields not being updated
        viewModel.updateTicket(ticket, title: newTitle, location: originalLocation, description: originalDescription, eventDate: newEventDate)

        // 4. Verify properties in viewModel.tickets
        guard let updatedTicketInViewModel = viewModel.tickets.first(where: { $0.id == ticketID }) else {
            Issue.record("Partially updated ticket not found in ViewModel.")
            return
        }
        #expect(updatedTicketInViewModel.title == newTitle, "ViewModel title should be updated (partial).")
        #expect(abs(updatedTicketInViewModel.eventDate.timeIntervalSince1970 - newEventDate.timeIntervalSince1970) < 0.001, "ViewModel eventDate should be updated (partial).")
        #expect(updatedTicketInViewModel.location == originalLocation, "ViewModel location should remain unchanged (partial).")
        #expect(updatedTicketInViewModel.description == originalDescription, "ViewModel description should remain unchanged (partial).")

        // 5. Verify properties in Core Data store
        let context = testCoreDataStack.managedObjectContext
        let fetchRequest: NSFetchRequest<TicketEntity> = TicketEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", ticketID as CVarArg)
        
        guard let entityInStore = try context.fetch(fetchRequest).first else {
            Issue.record("Partially updated ticket entity not found in store.")
            return
        }
        #expect(entityInStore.title == newTitle, "Store title should be updated (partial).")
        #expect(abs(entityInStore.eventDate!.timeIntervalSince1970 - newEventDate.timeIntervalSince1970) < 0.001, "Store eventDate should be updated (partial).")
        #expect(entityInStore.location == originalLocation, "Store location should remain unchanged (partial).")
        #expect(entityInStore.desc == originalDescription, "Store description should remain unchanged (partial).")
    }

    @Test func testUpdateTicket_WhenTicketDoesNotExist_ShouldNotCrashOrAddTicket() throws {
        // 1. Add an initial ticket to ensure the ViewModel is not empty and has a known state.
        let initialTicket = Ticket(
            id: UUID(),
            title: "Existing Event Before Update Attempt",
            location: "Some Venue",
            description: "An event that exists.",
            imageData: Data(),
            isFavorite: false,
            eventDate: Date()
        )
        viewModel.addTicket(initialTicket)
        
        let initialViewModelTicketCount = viewModel.tickets.count
        let context = testCoreDataStack.managedObjectContext
        let initialStoreTicketCount = try context.count(for: TicketEntity.fetchRequest())


        // 2. Create a ticket that is NOT added to the store or ViewModel
        let nonExistentTicket = Ticket(
            id: UUID(), // Different UUID, guaranteed not to be in the store
            title: "Non Existent Original Title",
            location: "Non Existent Original Location",
            description: "This ticket does not exist for update.",
            imageData: Data(),
            eventDate: Date()
        )

        // 3. Attempt to update the non-existent ticket
        viewModel.updateTicket(nonExistentTicket, title: "Attempted Update Title", location: "Attempted Update Location", description: "Attempted Update Desc", eventDate: Date().addingTimeInterval(12345)) // This should not crash

        // 4. Verify ViewModel state is unchanged
        #expect(viewModel.tickets.count == initialViewModelTicketCount, "ViewModel ticket count should remain unchanged after attempting to update non-existent ticket.")
        #expect(viewModel.tickets.contains(where: { $0.id == initialTicket.id }), "Initial ticket should still exist in ViewModel.")
        #expect(viewModel.tickets.contains(where: { $0.id == nonExistentTicket.id }) == false, "Non-existent ticket should not have been added to ViewModel.")


        // 5. Verify store state is unchanged
        let currentStoreTicketCount = try context.count(for: TicketEntity.fetchRequest())
        #expect(currentStoreTicketCount == initialStoreTicketCount, "Store ticket count should remain unchanged after attempting to update non-existent ticket.")
        
        let nonExistentFetchRequest: NSFetchRequest<TicketEntity> = TicketEntity.fetchRequest()
        nonExistentFetchRequest.predicate = NSPredicate(format: "id == %@", nonExistentTicket.id as CVarArg)
        let nonExistentResults = try context.fetch(nonExistentFetchRequest)
        #expect(nonExistentResults.isEmpty, "Non-existent ticket should not have been added to the store after update attempt.")
    }

    // MARK: - Filtering and Searching Tests

    // Helper function to create dates for testing "recent" filter
    private func date(daysAgo: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
    }

    @Test func testFilteredTickets_All_NoSearchText_ReturnsAllTickets() throws {
        // 1. Setup: Add diverse tickets
        let ticket1 = Ticket(title: "Event Alpha", location: "Venue 1", description: "", imageData: Data(), createdAt: date(daysAgo: 0), isFavorite: true, eventDate: Date())
        let ticket2 = Ticket(title: "Event Beta", location: "Venue 2", description: "", imageData: Data(), createdAt: date(daysAgo: 1), isFavorite: false, eventDate: Date())
        let ticket3 = Ticket(title: "Event Gamma", location: "Venue 3", description: "", imageData: Data(), createdAt: date(daysAgo: 2), isFavorite: true, eventDate: Date())
        
        viewModel.addTicket(ticket1)
        viewModel.addTicket(ticket2)
        viewModel.addTicket(ticket3)
        
        // 2. Set filter and search text
        viewModel.selectedFilter = .all
        viewModel.searchText = ""
        
        // 3. Verify
        #expect(viewModel.filteredTickets.count == 3, "Filtered tickets should return all 3 tickets with .all filter and no search text.")
    }

    @Test func testFilteredTickets_Recent_NoSearchText_ReturnsOnlyRecentTickets() throws {
        // 1. Setup
        let todayTicket1 = Ticket(title: "Today Event 1", location: "Venue T1", description: "", imageData: Data(), createdAt: date(daysAgo: 0), isFavorite: true, eventDate: Date())
        let todayTicket2 = Ticket(title: "Today Event 2", location: "Venue T2", description: "", imageData: Data(), createdAt: date(daysAgo: 0), isFavorite: false, eventDate: Date())
        let yesterdayTicket = Ticket(title: "Yesterday Event", location: "Venue Y1", description: "", imageData: Data(), createdAt: date(daysAgo: 1), isFavorite: true, eventDate: Date())
        let olderTicket = Ticket(title: "Older Event", location: "Venue O1", description: "", imageData: Data(), createdAt: date(daysAgo: 5), isFavorite: false, eventDate: Date())

        viewModel.addTicket(todayTicket1)
        viewModel.addTicket(todayTicket2)
        viewModel.addTicket(yesterdayTicket)
        viewModel.addTicket(olderTicket)

        // 2. Set filter and search text
        viewModel.selectedFilter = .recent
        viewModel.searchText = ""

        // 3. Verify
        let filtered = viewModel.filteredTickets
        #expect(filtered.count == 2, "Filtered tickets should return 2 recent (today's) tickets.")
        #expect(filtered.contains(where: { $0.id == todayTicket1.id }), "Today Event 1 should be included in recent.")
        #expect(filtered.contains(where: { $0.id == todayTicket2.id }), "Today Event 2 should be included in recent.")
        #expect(filtered.contains(where: { $0.id == yesterdayTicket.id }) == false, "Yesterday Event should not be included in recent.")
    }

    @Test func testFilteredTickets_Favorite_NoSearchText_ReturnsOnlyFavoriteTickets() throws {
        // 1. Setup
        let favoriteTicket1 = Ticket(title: "Favorite Event 1", location: "Venue F1", description: "", imageData: Data(), createdAt: date(daysAgo: 0), isFavorite: true, eventDate: Date())
        let nonFavoriteTicket = Ticket(title: "Non-Favorite Event", location: "Venue NF1", description: "", imageData: Data(), createdAt: date(daysAgo: 1), isFavorite: false, eventDate: Date())
        let favoriteTicket2 = Ticket(title: "Favorite Event 2", location: "Venue F2", description: "", imageData: Data(), createdAt: date(daysAgo: 2), isFavorite: true, eventDate: Date())

        viewModel.addTicket(favoriteTicket1)
        viewModel.addTicket(nonFavoriteTicket)
        viewModel.addTicket(favoriteTicket2)

        // 2. Set filter and search text
        viewModel.selectedFilter = .favorite
        viewModel.searchText = ""

        // 3. Verify
        let filtered = viewModel.filteredTickets
        #expect(filtered.count == 2, "Filtered tickets should return 2 favorite tickets.")
        #expect(filtered.contains(where: { $0.id == favoriteTicket1.id }), "Favorite Event 1 should be included.")
        #expect(filtered.contains(where: { $0.id == favoriteTicket2.id }), "Favorite Event 2 should be included.")
        #expect(filtered.contains(where: { $0.id == nonFavoriteTicket.id }) == false, "Non-Favorite Event should not be included.")
    }

    @Test func testFilteredTickets_Search_WithAllFilter() throws {
        // 1. Setup
        let ticketSearchTitle = Ticket(title: "Searchable Unique Title", location: "Someplace", description: "", imageData: Data(), createdAt: date(daysAgo: 0), isFavorite: false, eventDate: Date())
        let ticketSearchLocation = Ticket(title: "Another Event", location: "Searchable Unique Location", description: "", imageData: Data(), createdAt: date(daysAgo: 1), isFavorite: false, eventDate: Date())
        let ticketNoMatch = Ticket(title: "Generic Item", location: "Anywhere", description: "", imageData: Data(), createdAt: date(daysAgo: 0), isFavorite: true, eventDate: Date())

        viewModel.addTicket(ticketSearchTitle)
        viewModel.addTicket(ticketSearchLocation)
        viewModel.addTicket(ticketNoMatch)
        
        viewModel.selectedFilter = .all

        // Test 1: Search by title
        viewModel.searchText = "Unique Title"
        var filtered = viewModel.filteredTickets
        #expect(filtered.count == 1, "Search by title should return 1 ticket.")
        #expect(filtered.first?.id == ticketSearchTitle.id, "Search by title should return the correct ticket.")

        // Test 2: Search by location
        viewModel.searchText = "Unique Location"
        filtered = viewModel.filteredTickets
        #expect(filtered.count == 1, "Search by location should return 1 ticket.")
        #expect(filtered.first?.id == ticketSearchLocation.id, "Search by location should return the correct ticket.")
        
        // Test 3: Search with no match
        viewModel.searchText = "NonExistentSearchTerm"
        filtered = viewModel.filteredTickets
        #expect(filtered.isEmpty, "Search with no match should return an empty array.")

        // Test 4: Case-insensitive search (title)
        viewModel.searchText = "searchable unique title" // Lowercase
        filtered = viewModel.filteredTickets
        #expect(filtered.count == 1, "Case-insensitive title search should return 1 ticket.")
        #expect(filtered.first?.id == ticketSearchTitle.id, "Case-insensitive title search should return the correct ticket.")

        // Test 5: Case-insensitive search (location)
        viewModel.searchText = "searchable unique location" // Lowercase
        filtered = viewModel.filteredTickets
        #expect(filtered.count == 1, "Case-insensitive location search should return 1 ticket.")
        #expect(filtered.first?.id == ticketSearchLocation.id, "Case-insensitive location search should return the correct ticket.")
    }
    
    @Test func testFilteredTickets_SearchAndFilterCombination() throws {
        // 1. Setup: Diverse tickets
        let favRecentMatch = Ticket(title: "Concert Star Favorite", location: "Stadium Today", description: "", imageData: Data(), createdAt: date(daysAgo: 0), isFavorite: true, eventDate: Date())
        let favOldMatch = Ticket(title: "Concert Star Old", location: "Hall Yesterday", description: "", imageData: Data(), createdAt: date(daysAgo: 1), isFavorite: true, eventDate: Date())
        let recentNotFavMatch = Ticket(title: "Expo Star Today", location: "Center Today", description: "", imageData: Data(), createdAt: date(daysAgo: 0), isFavorite: false, eventDate: Date())
        let otherTicket = Ticket(title: "Generic Event", location: "Local Park", description: "", imageData: Data(), createdAt: date(daysAgo: 5), isFavorite: false, eventDate: Date())

        viewModel.addTicket(favRecentMatch)
        viewModel.addTicket(favOldMatch)
        viewModel.addTicket(recentNotFavMatch)
        viewModel.addTicket(otherTicket)

        // Test 1: Favorite + Search term matching a favorite ticket
        viewModel.selectedFilter = .favorite
        viewModel.searchText = "Concert Star"
        var filtered = viewModel.filteredTickets
        #expect(filtered.count == 2, "Search for 'Concert Star' with .favorite filter should return 2 tickets.")
        #expect(filtered.contains(where: {$0.id == favRecentMatch.id}), "favRecentMatch should be included.")
        #expect(filtered.contains(where: {$0.id == favOldMatch.id}), "favOldMatch should be included.")


        // Test 2: Recent + Search term matching a recent ticket
        viewModel.selectedFilter = .recent
        viewModel.searchText = "Star Today" // Matches favRecentMatch (title) and recentNotFavMatch (title)
        filtered = viewModel.filteredTickets
        #expect(filtered.count == 2, "Search for 'Star Today' with .recent filter should return 2 tickets.")
        #expect(filtered.contains(where: {$0.id == favRecentMatch.id}), "favRecentMatch should be included in recent search.")
        #expect(filtered.contains(where: {$0.id == recentNotFavMatch.id}), "recentNotFavMatch should be included in recent search.")
        

        // Test 3: Search term matches a favorite ticket, but filter is .recent (and ticket is not recent)
        viewModel.selectedFilter = .recent
        viewModel.searchText = "Concert Star Old" // This ticket is favorite, but old
        filtered = viewModel.filteredTickets
        #expect(filtered.isEmpty, "Search for an old favorite ticket with .recent filter should return empty.")
        
        // Test 4: Search term matches a recent ticket, but filter is .favorite (and ticket is not favorite)
        viewModel.selectedFilter = .favorite
        viewModel.searchText = "Expo Star Today" // This ticket is recent, but not favorite
        filtered = viewModel.filteredTickets
        #expect(filtered.isEmpty, "Search for a recent non-favorite ticket with .favorite filter should return empty.")
        
        // Test 5: Search term does not match any, with .favorite filter
        viewModel.selectedFilter = .favorite
        viewModel.searchText = "NoMatchForFavorite"
        filtered = viewModel.filteredTickets
        #expect(filtered.isEmpty, "Search for non-matching term with .favorite filter should return empty.")

        // Test 6: Search term does not match any, with .recent filter
        viewModel.selectedFilter = .recent
        viewModel.searchText = "NoMatchForRecent"
        filtered = viewModel.filteredTickets
        #expect(filtered.isEmpty, "Search for non-matching term with .recent filter should return empty.")
    }
}
