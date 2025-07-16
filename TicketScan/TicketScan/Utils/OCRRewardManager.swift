import Foundation
import SwiftUI

class OCRRewardManager: ObservableObject {
    static let shared = OCRRewardManager()
    
    @Published var isOCRUnlocked = false
    @Published var currentSessionTicketId: String? = nil
    
    private init() {}
    
    func unlockOCR(for ticketId: String? = nil) {
        isOCRUnlocked = true
        currentSessionTicketId = ticketId
    }
    
    func checkOCRAvailability(for ticketId: String? = nil) -> Bool {
        // 新規チケット作成の場合（ticketIdがnil）は常に広告視聴が必要
        if ticketId == nil {
            return isOCRUnlocked && currentSessionTicketId == nil
        }
        
        // 既存チケット編集の場合、同じチケットIDでのみ利用可能
        return isOCRUnlocked && currentSessionTicketId == ticketId
    }
    
    func resetOCRAccess() {
        isOCRUnlocked = false
        currentSessionTicketId = nil
    }
    
    func switchToNewTicket() {
        resetOCRAccess()
    }
}