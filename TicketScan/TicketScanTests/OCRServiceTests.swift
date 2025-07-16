import Testing
import UIKit
import Vision
@testable import TicketScan

struct OCRServiceTests {
    
    private func createTestImage(with text: String) -> UIImage {
        let size = CGSize(width: 200, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            UIColor.black.setFill()
            let font = UIFont.systemFont(ofSize: 16)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.black
            ]
            
            let rect = CGRect(x: 10, y: 10, width: size.width - 20, height: size.height - 20)
            text.draw(in: rect, withAttributes: attributes)
        }
    }
    
    @Test func testRecognizeTextSuccess() async throws {
        let ocrService = OCRService.shared
        let testImage = createTestImage(with: "Test Concert\n2024/12/25\n東京ドーム")
        
        let expectation = expectation(description: "OCR completion")
        var result: Result<String, Error>?
        
        ocrService.recognizeText(from: testImage) { ocrResult in
            result = ocrResult
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
        
        switch result {
        case .success(let text):
            #expect(!text.isEmpty)
            // OCR might not be 100% accurate, so we just check it's not empty
        case .failure(let error):
            #expect(Bool(false), "OCR should succeed: \(error)")
        case .none:
            #expect(Bool(false), "Result should not be nil")
        }
    }
    
    @Test func testRecognizeTextInvalidImage() async throws {
        let ocrService = OCRService.shared
        
        // Create an invalid image (empty)
        let size = CGSize(width: 0, height: 0)
        let renderer = UIGraphicsImageRenderer(size: size)
        let invalidImage = renderer.image { _ in }
        
        let expectation = expectation(description: "OCR completion")
        var result: Result<String, Error>?
        
        ocrService.recognizeText(from: invalidImage) { ocrResult in
            result = ocrResult
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
        
        switch result {
        case .success:
            #expect(Bool(false), "OCR should fail with invalid image")
        case .failure(let error):
            if let ocrError = error as? OCRError {
                #expect(ocrError == OCRError.invalidImage)
            } else {
                #expect(Bool(false), "Should return OCRError.invalidImage")
            }
        case .none:
            #expect(Bool(false), "Result should not be nil")
        }
    }
    
    @Test func testExtractTicketInfoWithFullInfo() async throws {
        let ocrService = OCRService.shared
        let testText = """
        春のコンサート 2024
        2024年4月15日
        東京ドーム
        開場 18:00 開演 19:00
        """
        
        let ticketInfo = ocrService.extractTicketInfo(from: testText)
        
        #expect(ticketInfo.title == "春のコンサート 2024")
        #expect(ticketInfo.venue == "東京ドーム")
        #expect(ticketInfo.rawText == testText)
        #expect(ticketInfo.eventDate != nil)
        
        // Check if the extracted date is correct
        if let eventDate = ticketInfo.eventDate {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day], from: eventDate)
            #expect(components.year == 2024)
            #expect(components.month == 4)
            #expect(components.day == 15)
        }
    }
    
    @Test func testExtractTicketInfoWithMinimalInfo() async throws {
        let ocrService = OCRService.shared
        let testText = "シンプルなイベント"
        
        let ticketInfo = ocrService.extractTicketInfo(from: testText)
        
        #expect(ticketInfo.title == "シンプルなイベント")
        #expect(ticketInfo.venue.isEmpty)
        #expect(ticketInfo.rawText == testText)
        #expect(ticketInfo.eventDate == nil)
    }
    
    @Test func testExtractTicketInfoWithDifferentDateFormats() async throws {
        let ocrService = OCRService.shared
        
        let testCases = [
            ("イベント1\n2024/12/25", 2024, 12, 25),
            ("イベント2\n2024-03-15", 2024, 3, 15),
            ("イベント3\n2024年1月5日", 2024, 1, 5)
        ]
        
        for (text, expectedYear, expectedMonth, expectedDay) in testCases {
            let ticketInfo = ocrService.extractTicketInfo(from: text)
            
            if let eventDate = ticketInfo.eventDate {
                let calendar = Calendar.current
                let components = calendar.dateComponents([.year, .month, .day], from: eventDate)
                #expect(components.year == expectedYear)
                #expect(components.month == expectedMonth)
                #expect(components.day == expectedDay)
            } else {
                #expect(Bool(false), "Should extract date from: \(text)")
            }
        }
    }
    
    @Test func testExtractTicketInfoWithDifferentVenues() async throws {
        let ocrService = OCRService.shared
        
        let testCases = [
            ("コンサート\n東京ドーム", "東京ドーム"),
            ("野球観戦\n甲子園", "甲子園"),
            ("イベント\n横浜アリーナ", "横浜アリーナ"),
            ("公演\n帝国劇場", "帝国劇場")
        ]
        
        for (text, expectedVenue) in testCases {
            let ticketInfo = ocrService.extractTicketInfo(from: text)
            #expect(ticketInfo.venue == expectedVenue)
        }
    }
    
    @Test func testExtractTicketInfoWithEmptyText() async throws {
        let ocrService = OCRService.shared
        let testText = ""
        
        let ticketInfo = ocrService.extractTicketInfo(from: testText)
        
        #expect(ticketInfo.title.isEmpty)
        #expect(ticketInfo.venue.isEmpty)
        #expect(ticketInfo.rawText.isEmpty)
        #expect(ticketInfo.eventDate == nil)
    }
    
    @Test func testExtractTicketInfoWithWhitespaceOnly() async throws {
        let ocrService = OCRService.shared
        let testText = "   \n  \n   "
        
        let ticketInfo = ocrService.extractTicketInfo(from: testText)
        
        #expect(ticketInfo.title.isEmpty)
        #expect(ticketInfo.venue.isEmpty)
        #expect(ticketInfo.rawText == testText)
        #expect(ticketInfo.eventDate == nil)
    }
}

extension OCRError: Equatable {
    public static func == (lhs: OCRError, rhs: OCRError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidImage, .invalidImage),
             (.noTextFound, .noTextFound),
             (.processingFailed, .processingFailed):
            return true
        case (.visionRequestFailed(let lhsError), .visionRequestFailed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.imageProcessingFailed(let lhsError), .imageProcessingFailed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

private func expectation(description: String) -> Expectation {
    return Expectation(description: description)
}

private class Expectation {
    let description: String
    private var fulfilled = false
    
    init(description: String) {
        self.description = description
    }
    
    func fulfill() {
        fulfilled = true
    }
    
    var isFulfilled: Bool {
        return fulfilled
    }
}

private func fulfillment(of expectations: [Expectation], timeout: TimeInterval) async {
    let startTime = Date()
    
    while Date().timeIntervalSince(startTime) < timeout {
        if expectations.allSatisfy({ $0.isFulfilled }) {
            return
        }
        
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }
}