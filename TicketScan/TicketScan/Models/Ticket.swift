import Foundation
import CoreData

enum TicketCategory: String, CaseIterable {
    case concert = "concert"
    case movie = "movie"
    case sports = "sports"
    case theater = "theater"
    case festival = "festival"
    case exhibition = "exhibition"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .concert: return "コンサート"
        case .movie: return "映画"
        case .sports: return "スポーツ"
        case .theater: return "演劇"
        case .festival: return "フェスティバル"
        case .exhibition: return "展示会"
        case .other: return "その他"
        }
    }
    
    var icon: String {
        switch self {
        case .concert: return "music.note"
        case .movie: return "film"
        case .sports: return "sportscourt"
        case .theater: return "theatermasks"
        case .festival: return "party.popper"
        case .exhibition: return "photo.on.rectangle"
        case .other: return "ticket"
        }
    }
}

struct Ticket: Identifiable {
    var id: UUID
    var title: String
    var location: String
    var description: String
    var imageData: Data
    var createdAt: Date
    var isFavorite: Bool
    var eventDate: Date
    var rating: Int // 1-5 stars
    var category: TicketCategory
    
    init(id: UUID = UUID(), title: String, location: String, description: String, imageData: Data, createdAt: Date = Date(), isFavorite: Bool = false, eventDate: Date = Date(), rating: Int = 0, category: TicketCategory = .other) {
        self.id = id
        self.title = title
        self.location = location
        self.description = description
        self.imageData = imageData
        self.createdAt = createdAt
        self.isFavorite = isFavorite
        self.eventDate = eventDate
        self.rating = rating
        self.category = category
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
        self.rating = Int(entity.rating)
        self.category = TicketCategory(rawValue: entity.category ?? "other") ?? .other
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
        entity.rating = Int16(rating)
        entity.category = category.rawValue
        return entity
    }
} 
