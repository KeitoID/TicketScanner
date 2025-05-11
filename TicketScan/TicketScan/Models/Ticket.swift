import Foundation
import CoreData

struct Ticket: Identifiable {
    var id: UUID
    var title: String
    var location: String
    var description: String
    var imageData: Data
    var createdAt: Date
    var isFavorite: Bool
    var eventDate: Date
    
    init(id: UUID = UUID(), title: String, location: String, description: String, imageData: Data, createdAt: Date = Date(), isFavorite: Bool = false, eventDate: Date = Date()) {
        self.id = id
        self.title = title
        self.location = location
        self.description = description
        self.imageData = imageData
        self.createdAt = createdAt
        self.isFavorite = isFavorite
        self.eventDate = eventDate
    }
    
    init(from entity: TicketEntity) {
        self.id = entity.id ?? UUID()
        self.title = entity.title ?? ""
        self.location = entity.location ?? ""
        self.description = entity.desc ?? ""
        self.imageData = entity.imageData ?? Data()
        self.createdAt = entity.createdAt ?? Date()
        self.isFavorite = entity.isFavorite
        self.eventDate = entity.eventDate ?? Date()
    }
    
    func toEntity(context: NSManagedObjectContext) -> TicketEntity {
        let entity = TicketEntity(context: context)
        entity.id = id
        entity.title = title
        entity.location = location
        entity.desc = description
        entity.imageData = imageData
        entity.createdAt = createdAt
        entity.isFavorite = isFavorite
        entity.eventDate = eventDate
        return entity
    }
} 
