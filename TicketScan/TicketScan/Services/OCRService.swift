import Vision
import UIKit

extension String {
    func substring(with nsRange: NSRange) -> String? {
        guard let range = Range(nsRange, in: self) else { return nil }
        return String(self[range])
    }
}

class OCRService {
    static let shared = OCRService()
    
    private init() {}
    
    func recognizeText(from image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(OCRError.invalidImage))
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                completion(.failure(OCRError.visionRequestFailed(error)))
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.failure(OCRError.noTextFound))
                return
            }
            
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            if recognizedText.isEmpty {
                completion(.failure(OCRError.noTextFound))
            } else {
                completion(.success(recognizedText))
            }
        }
        
        request.recognitionLanguages = ["ja-JP", "en-US"]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                completion(.failure(OCRError.imageProcessingFailed(error)))
            }
        }
    }
    
    func extractTicketInfo(from text: String) -> TicketInfo {
        var ticketInfo = TicketInfo()
        ticketInfo.rawText = text
        
        // 日付抽出
        extractDate(from: text, into: &ticketInfo)
        
        // 会場抽出
        extractVenue(from: text, into: &ticketInfo)
        
        // タイトル抽出（最初の行を基本的にタイトルとする）
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        if let firstLine = lines.first {
            ticketInfo.title = firstLine.trimmingCharacters(in: .whitespaces)
        }
        
        return ticketInfo
    }
    
    private func extractDate(from text: String, into ticketInfo: inout TicketInfo) {
        let datePattern = "(\\d{4})[年/-](\\d{1,2})[月/-](\\d{1,2})[日]?"
        
        do {
            let regex = try NSRegularExpression(pattern: datePattern, options: [])
            let range = NSRange(location: 0, length: text.utf16.count)
            
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                let yearRange = match.range(at: 1)
                let monthRange = match.range(at: 2)
                let dayRange = match.range(at: 3)
                
                if let yearString = text.substring(with: yearRange),
                   let monthString = text.substring(with: monthRange),
                   let dayString = text.substring(with: dayRange),
                   let year = Int(yearString),
                   let month = Int(monthString),
                   let day = Int(dayString) {
                    
                    var dateComponents = DateComponents()
                    dateComponents.year = year
                    dateComponents.month = month
                    dateComponents.day = day
                    
                    ticketInfo.eventDate = Calendar.current.date(from: dateComponents)
                }
            }
        } catch {
            print("日付抽出エラー: \(error)")
        }
    }
    
    private func extractVenue(from text: String, into ticketInfo: inout TicketInfo) {
        let venuePatterns = [
            "(\\w+ドーム|\\w+スタジアム|\\w+アリーナ|\\w+ホール|\\w+劇場|\\w+会館)",
            "(東京ドーム|大阪ドーム|ナゴヤドーム|横浜スタジアム|甲子園|東京スカイツリー)"
        ]
        
        for pattern in venuePatterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                let range = NSRange(location: 0, length: text.utf16.count)
                
                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    let venueRange = match.range(at: 1)
                    if let venue = text.substring(with: venueRange) {
                        ticketInfo.venue = venue
                        break
                    }
                }
            } catch {
                print("会場抽出エラー: \(error)")
            }
        }
    }
}

struct TicketInfo {
    var title: String = ""
    var venue: String = ""
    var eventDate: Date?
    var rawText: String = ""
}

enum OCRError: Error, LocalizedError {
    case invalidImage
    case noTextFound
    case processingFailed
    case visionRequestFailed(Error)
    case imageProcessingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "画像が無効です"
        case .noTextFound:
            return "テキストが見つかりませんでした"
        case .processingFailed:
            return "処理に失敗しました"
        case .visionRequestFailed(let error):
            return "Vision処理エラー: \(error.localizedDescription)"
        case .imageProcessingFailed(let error):
            return "画像処理エラー: \(error.localizedDescription)"
        }
    }
}