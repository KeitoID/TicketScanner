import SwiftUI

struct OCRResultsView: View {
    let ocrText: String
    @Binding var title: String
    @Binding var location: String
    @Binding var description: String
    @Binding var eventDate: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("認識されたテキスト")) {
                    ScrollView {
                        Text(ocrText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .frame(height: 150)
                }
                
                Section(header: Text("抽出された情報")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("タイトル")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("タイトル", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("場所")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("場所", text: $location)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("説明")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("説明", text: $description)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("開催日時")
                            .font(.caption)
                            .foregroundColor(.gray)
                        DatePicker("開催日時", selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(CompactDatePickerStyle())
                    }
                    .padding(.vertical, 4)
                }
                
                Section {
                    Button(action: { extractManually() }) {
                        HStack {
                            Image(systemName: "wand.and.rays")
                            Text("再度自動抽出")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }
            .navigationTitle("OCR結果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func extractManually() {
        let ticketInfo = OCRService.shared.extractTicketInfo(from: ocrText)
        
        if !ticketInfo.title.isEmpty {
            title = ticketInfo.title
        }
        if !ticketInfo.venue.isEmpty {
            location = ticketInfo.venue
        }
        if let extractedDate = ticketInfo.eventDate {
            eventDate = extractedDate
        }
    }
}