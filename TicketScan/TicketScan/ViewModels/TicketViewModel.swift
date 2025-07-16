import Foundation
import SwiftUI
import CoreData

class TicketViewModel: ObservableObject {
    @Published var tickets: [Ticket] = []
    @Published var searchText = ""
    @Published var selectedFilter: TicketFilter = .all
    
    private let viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchTickets()
    }
    
    enum TicketFilter {
        case all
        case recent
        case favorite
    }
    
    var filteredTickets: [Ticket] {
        tickets.filter { ticket in
            let matchesSearch = searchText.isEmpty || 
                ticket.title.localizedCaseInsensitiveContains(searchText) ||
                ticket.location.localizedCaseInsensitiveContains(searchText)
            
            switch selectedFilter {
            case .all:
                return matchesSearch
            case .recent:
                return matchesSearch && Calendar.current.isDateInToday(ticket.createdAt)
            case .favorite:
                return matchesSearch && ticket.isFavorite
            }
        }
    }
    
    func addTicket(_ ticket: Ticket) {
        _ = ticket.toEntity(context: viewContext)
        save()
        fetchTickets()
    }
    
    func deleteTicket(_ ticket: Ticket) {
        let fetchRequest: NSFetchRequest<TicketEntity> = TicketEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", ticket.id as CVarArg)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            if let entity = results.first {
                viewContext.delete(entity)
                save()
                fetchTickets()
            }
        } catch {
            print("チケットの削除に失敗しました: \(error.localizedDescription)")
        }
    }
    
    func toggleFavorite(_ ticket: Ticket) {
        let fetchRequest: NSFetchRequest<TicketEntity> = TicketEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", ticket.id as CVarArg)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            if let entity = results.first {
                entity.isFavorite.toggle()
                save()
                fetchTickets()
            }
        } catch {
            print("お気に入りの更新に失敗しました: \(error.localizedDescription)")
        }
    }
    
    func updateTicket(_ ticket: Ticket, title: String, location: String, description: String, eventDate: Date, rating: Int, category: TicketCategory) {
        let fetchRequest: NSFetchRequest<TicketEntity> = TicketEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", ticket.id as CVarArg)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            if let entity = results.first {
                entity.title = title
                entity.location = location
                entity.desc = description
                entity.eventDate = eventDate
                entity.rating = Int16(rating)
                entity.category = category.rawValue
                save()
                fetchTickets()
            }
        } catch {
            print("チケットの更新に失敗しました: \(error.localizedDescription)")
        }
    }
    
    private func save() {
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate.
            // You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    private func fetchTickets() {
        let fetchRequest: NSFetchRequest<TicketEntity> = TicketEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TicketEntity.createdAt, ascending: false)]
        
        do {
            let entities = try viewContext.fetch(fetchRequest)
            tickets = entities.map { Ticket(from: $0) }
        } catch {
            print("チケットの読み込みに失敗しました: \(error.localizedDescription)")
        }
    }
} 
