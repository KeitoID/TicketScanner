import Testing
import CoreData
@testable import TicketScan

struct TicketViewModelTests {
    
    private func createInMemoryContext() -> NSManagedObjectContext {
        let container = NSPersistentContainer(name: "Ticket")
        container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load store: \(error)")
            }
        }
        return container.viewContext
    }
    
    @Test func testInitialState() async throws {
        let context = createInMemoryContext()
        let viewModel = TicketViewModel(context: context)
        
        #expect(viewModel.tickets.isEmpty)
        #expect(viewModel.searchText.isEmpty)
        #expect(viewModel.selectedFilter == .all)
        #expect(viewModel.filteredTickets.isEmpty)
    }
    
    @Test func testAddTicket() async throws {
        let context = createInMemoryContext()
        let viewModel = TicketViewModel(context: context)
        
        let ticket = Ticket(
            id: UUID(),
            title: "テストイベント",
            location: "東京ドーム",
            description: "テスト用のチケット",
            imageData: Data(),
            createdAt: Date(),
            isFavorite: false,
            eventDate: Date()
        )
        
        viewModel.addTicket(ticket)
        
        // Wait for Core Data operations to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        #expect(viewModel.tickets.count == 1)
        #expect(viewModel.tickets.first?.title == "テストイベント")
        #expect(viewModel.tickets.first?.location == "東京ドーム")
    }
    
    @Test func testDeleteTicket() async throws {
        let context = createInMemoryContext()
        let viewModel = TicketViewModel(context: context)
        
        let ticket = Ticket(
            id: UUID(),
            title: "削除テスト",
            location: "会場名",
            description: "削除テスト用",
            imageData: Data(),
            createdAt: Date(),
            isFavorite: false,
            eventDate: Date()
        )
        
        viewModel.addTicket(ticket)
        
        // Wait for Core Data operations to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        #expect(viewModel.tickets.count == 1)
        
        viewModel.deleteTicket(ticket)
        
        // Wait for Core Data operations to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        #expect(viewModel.tickets.isEmpty)
    }
    
    @Test func testToggleFavorite() async throws {
        let context = createInMemoryContext()
        let viewModel = TicketViewModel(context: context)
        
        let ticket = Ticket(
            id: UUID(),
            title: "お気に入りテスト",
            location: "会場名",
            description: "お気に入りテスト用",
            imageData: Data(),
            createdAt: Date(),
            isFavorite: false,
            eventDate: Date()
        )
        
        viewModel.addTicket(ticket)
        
        // Wait for Core Data operations to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        let addedTicket = viewModel.tickets.first!
        
        #expect(addedTicket.isFavorite == false)
        
        viewModel.toggleFavorite(addedTicket)
        
        // Wait for Core Data operations to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        let updatedTicket = viewModel.tickets.first!
        #expect(updatedTicket.isFavorite == true)
    }
    
    @Test func testSearchFilter() async throws {
        let context = createInMemoryContext()
        let viewModel = TicketViewModel(context: context)
        
        let ticket1 = Ticket(
            id: UUID(),
            title: "コンサート",
            location: "東京ドーム",
            description: "音楽イベント",
            imageData: Data(),
            createdAt: Date(),
            isFavorite: false,
            eventDate: Date()
        )
        
        let ticket2 = Ticket(
            id: UUID(),
            title: "野球",
            location: "甲子園",
            description: "スポーツイベント",
            imageData: Data(),
            createdAt: Date(),
            isFavorite: false,
            eventDate: Date()
        )
        
        viewModel.addTicket(ticket1)
        viewModel.addTicket(ticket2)
        
        // Wait for Core Data operations to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        #expect(viewModel.filteredTickets.count == 2)
        
        viewModel.searchText = "コンサート"
        #expect(viewModel.filteredTickets.count == 1)
        #expect(viewModel.filteredTickets.first?.title == "コンサート")
        
        viewModel.searchText = "東京"
        #expect(viewModel.filteredTickets.count == 1)
        #expect(viewModel.filteredTickets.first?.location == "東京ドーム")
    }
    
    @Test func testFavoriteFilter() async throws {
        let context = createInMemoryContext()
        let viewModel = TicketViewModel(context: context)
        
        let ticket1 = Ticket(
            id: UUID(),
            title: "お気に入り",
            location: "会場1",
            description: "説明1",
            imageData: Data(),
            createdAt: Date(),
            isFavorite: true,
            eventDate: Date()
        )
        
        let ticket2 = Ticket(
            id: UUID(),
            title: "普通",
            location: "会場2",
            description: "説明2",
            imageData: Data(),
            createdAt: Date(),
            isFavorite: false,
            eventDate: Date()
        )
        
        viewModel.addTicket(ticket1)
        viewModel.addTicket(ticket2)
        
        // Wait for Core Data operations to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        viewModel.selectedFilter = .favorite
        #expect(viewModel.filteredTickets.count == 1)
        #expect(viewModel.filteredTickets.first?.title == "お気に入り")
    }
}