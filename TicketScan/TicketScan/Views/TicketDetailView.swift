import SwiftUI

struct TicketDetailView: View {
    let ticket: Ticket
    @ObservedObject var viewModel: TicketViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var showingShareSheet = false
    @State private var editedTitle: String
    @State private var editedLocation: String
    @State private var editedDescription: String
    @State private var editedEventDate: Date
    @State private var editedRating: Int
    @State private var editedCategory: TicketCategory
    @State private var showingOCRFeedback = false
    @State private var ocrSuccess = false
    @State private var ocrText = ""
    @StateObject private var ocrRewardManager = OCRRewardManager.shared
    
    init(ticket: Ticket, viewModel: TicketViewModel) {
        self.ticket = ticket
        self.viewModel = viewModel
        _editedTitle = State(initialValue: ticket.title)
        _editedLocation = State(initialValue: ticket.location)
        _editedDescription = State(initialValue: ticket.description)
        _editedEventDate = State(initialValue: ticket.eventDate)
        _editedRating = State(initialValue: ticket.rating)
        _editedCategory = State(initialValue: ticket.category)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 画像セクション
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
                    
                    if let uiImage = UIImage(data: ticket.imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(16)
                            .scaleEffect(isEditing ? 0.95 : 1.0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isEditing)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "photo")
                                .font(.system(size: 48, weight: .light))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Text("画像を読み込み中...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(40)
                    }
                }
                .padding(.horizontal, 20)
                
                // 情報セクション
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                        
                        VStack(alignment: .leading, spacing: 20) {
                            // タイトルとお気に入り
                            HStack {
                                if isEditing {
                                    TextField("タイトル", text: $editedTitle)
                                        .font(.system(size: 24, weight: .bold))
                                        .textFieldStyle(ModernDetailTextFieldStyle())
                                } else {
                                    Text(ticket.title)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.primary)
                                        .opacity(isEditing ? 0.6 : 1.0)
                                }
                                
                                Spacer()
                                
                                Button(action: { 
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        viewModel.toggleFavorite(ticket)
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(ticket.isFavorite ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.1))
                                            .frame(width: 44, height: 44)
                                        
                                        Image(systemName: ticket.isFavorite ? "star.fill" : "star")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(ticket.isFavorite ? .yellow : .gray)
                                    }
                                }
                                .scaleEffect(ticket.isFavorite ? 1.1 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: ticket.isFavorite)
                            }
                    
                            // 開催日時
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.red)
                                        .font(.system(size: 16, weight: .medium))
                                    Text("開催日時")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                
                                if isEditing {
                                    DatePicker("", selection: $editedEventDate, displayedComponents: [.date, .hourAndMinute])
                                        .datePickerStyle(.compact)
                                        .environment(\.locale, Locale(identifier: "ja_JP"))
                                } else {
                                    Text(ticket.eventDate.formatted(date: .numeric, time: .shortened))
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // 場所
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "location")
                                        .foregroundColor(.green)
                                        .font(.system(size: 16, weight: .medium))
                                    Text("場所")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                
                                if isEditing {
                                    TextField("場所", text: $editedLocation)
                                        .textFieldStyle(ModernDetailTextFieldStyle())
                                } else {
                                    Text(ticket.location)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // 説明
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "note.text")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 16, weight: .medium))
                                    Text("説明")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                
                                if isEditing {
                                    TextEditor(text: $editedDescription)
                                        .frame(minHeight: 100)
                                        .padding(12)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                        )
                                } else {
                                    Text(ticket.description)
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // 作成日
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundColor(.purple)
                                        .font(.system(size: 16, weight: .medium))
                                    Text("作成日")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                
                                Text(ticket.createdAt.formatted(date: .numeric, time: .shortened))
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            // 評価
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "star")
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 16, weight: .medium))
                                    Text("評価")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                
                                if isEditing {
                                    StarRatingView(rating: $editedRating, starSize: 24)
                                } else {
                                    if ticket.rating > 0 {
                                        StarRatingDisplayView(rating: ticket.rating, starSize: 20)
                                    } else {
                                        Text("未評価")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            // カテゴリ
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "tag")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 16, weight: .medium))
                                    Text("カテゴリ")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                
                                if isEditing {
                                    Menu {
                                        ForEach(TicketCategory.allCases, id: \.self) { category in
                                            Button(action: {
                                                editedCategory = category
                                            }) {
                                                HStack {
                                                    Image(systemName: category.icon)
                                                    Text(category.displayName)
                                                    if editedCategory == category {
                                                        Spacer()
                                                        Image(systemName: "checkmark")
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: editedCategory.icon)
                                                .foregroundColor(.blue)
                                            Text(editedCategory.displayName)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .foregroundColor(.blue)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                        )
                                    }
                                } else {
                                    HStack {
                                        Image(systemName: ticket.category.icon)
                                            .foregroundColor(.blue)
                                        Text(ticket.category.displayName)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            // OCR リワード広告（編集中のみ表示）
                            if isEditing {
                                OCRRewardAdView(ticketId: ticket.id.uuidString) {
                                    performOCR()
                                }
                            }
                        }
                        .padding(24)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    Button(action: { showingShareSheet = true }) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            if isEditing {
                                viewModel.updateTicket(
                                    ticket,
                                    title: editedTitle,
                                    location: editedLocation,
                                    description: editedDescription,
                                    eventDate: editedEventDate,
                                    rating: editedRating,
                                    category: editedCategory
                                )
                            }
                            isEditing.toggle()
                        }
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(isEditing ? Color.green : Color.blue)
                                .frame(width: 72, height: 36)
                            
                            Text(isEditing ? "保存" : "編集")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            TicketShareView(ticket: ticket)
        }
        .sheet(isPresented: $showingOCRFeedback) {
            OCRFeedbackView(
                success: ocrSuccess,
                extractedText: ocrText,
                onDismiss: {
                    showingOCRFeedback = false
                    if ocrSuccess && !ocrText.isEmpty {
                        // OCR成功時は編集フィールドに自動入力
                        DispatchQueue.main.async {
                            let ticketInfo = OCRService.shared.extractTicketInfo(from: ocrText)
                            
                            if !ticketInfo.title.isEmpty {
                                editedTitle = ticketInfo.title
                            }
                            if !ticketInfo.venue.isEmpty {
                                editedLocation = ticketInfo.venue
                            }
                            if let extractedDate = ticketInfo.eventDate {
                                editedEventDate = extractedDate
                            }
                        }
                    }
                }
            )
        }
        .onAppear {
            // 別のチケットの場合はOCR状態をリセット
            if ocrRewardManager.currentSessionTicketId != ticket.id.uuidString {
                ocrRewardManager.switchToNewTicket()
            }
        }
    }
    
    private func performOCR() {
        guard let image = UIImage(data: ticket.imageData) else { return }
        
        OCRService.shared.recognizeText(from: image) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let text):
                    ocrText = text
                    
                    // テキストが実際に検出されたかチェック
                    let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    ocrSuccess = !trimmedText.isEmpty
                    
                    showingOCRFeedback = true
                    
                case .failure(let error):
                    print("OCR Error: \(error.localizedDescription)")
                    ocrSuccess = false
                    ocrText = ""
                    showingOCRFeedback = true
                }
            }
        }
    }
}

struct ModernDetailTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
            )
            .font(.system(size: 18, weight: .medium))
    }
} 