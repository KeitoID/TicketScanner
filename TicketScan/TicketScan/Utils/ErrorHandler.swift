import Foundation
import SwiftUI

enum AppError: Error, LocalizedError {
    case coreDataSaveError(NSError)
    case coreDataLoadError(NSError)
    case coreDataInitializationError(NSError)
    case ocrProcessingError(Error)
    case invalidInput(String)
    case networkError(Error)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .coreDataSaveError(let error):
            return "データの保存に失敗しました: \(error.localizedDescription)"
        case .coreDataLoadError(let error):
            return "データの読み込みに失敗しました: \(error.localizedDescription)"
        case .coreDataInitializationError(let error):
            return "データベースの初期化に失敗しました: \(error.localizedDescription)"
        case .ocrProcessingError(let error):
            return "テキスト認識に失敗しました: \(error.localizedDescription)"
        case .invalidInput(let message):
            return "入力エラー: \(message)"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case .unknown(let error):
            return "予期しないエラーが発生しました: \(error.localizedDescription)"
        }
    }
}

class ErrorHandler: ObservableObject {
    @Published var currentError: AppError?
    @Published var showingError = false
    
    func handle(_ error: Error) {
        DispatchQueue.main.async {
            if let appError = error as? AppError {
                self.currentError = appError
            } else {
                self.currentError = AppError.unknown(error)
            }
            self.showingError = true
        }
    }
    
    func clearError() {
        currentError = nil
        showingError = false
    }
}

extension View {
    func errorAlert(_ errorHandler: ErrorHandler) -> some View {
        self.alert("エラー", isPresented: Binding(
            get: { errorHandler.showingError },
            set: { _ in errorHandler.clearError() }
        )) {
            Button("OK") {
                errorHandler.clearError()
            }
        } message: {
            Text(errorHandler.currentError?.errorDescription ?? "不明なエラーが発生しました")
        }
    }
}
