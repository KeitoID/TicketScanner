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
    
    init(ticket: Ticket, viewModel: TicketViewModel) {
        self.ticket = ticket
        self.viewModel = viewModel
        _editedTitle = State(initialValue: ticket.title)
        _editedLocation = State(initialValue: ticket.location)
        _editedDescription = State(initialValue: ticket.description)
        _editedEventDate = State(initialValue: ticket.eventDate)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 画像セクション
                Group {
                    if let uiImage = UIImage(data: ticket.imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .shadow(radius: 2)
                    } else {
                        VStack {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                            Text("画像を読み込み中...")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                // 情報セクション
                VStack(alignment: .leading, spacing: 16) {
                    // タイトルとお気に入り
                    HStack {
                        if isEditing {
                            TextField("タイトル", text: $editedTitle)
                                .font(.title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        } else {
                            Text(ticket.title)
                                .font(.title)
                                .bold()
                        }
                        
                        Spacer()
                        
                        Button(action: { viewModel.toggleFavorite(ticket) }) {
                            Image(systemName: ticket.isFavorite ? "star.fill" : "star")
                                .font(.title2)
                                .foregroundColor(ticket.isFavorite ? .yellow : .gray)
                        }
                    }
                    
                    // 開催日時
                    VStack(alignment: .leading, spacing: 4) {
                        Text("開催日時")
                            .font(.caption)
                            .foregroundColor(.gray)
                        if isEditing {
                            DatePicker("", selection: $editedEventDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                        } else {
                            Text(ticket.eventDate.formatted(date: .long, time: .shortened))
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 場所
                    VStack(alignment: .leading, spacing: 4) {
                        Text("場所")
                            .font(.caption)
                            .foregroundColor(.gray)
                        if isEditing {
                            TextField("場所", text: $editedLocation)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        } else {
                            Text(ticket.location)
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 説明
                    VStack(alignment: .leading, spacing: 4) {
                        Text("説明")
                            .font(.caption)
                            .foregroundColor(.gray)
                        if isEditing {
                            TextEditor(text: $editedDescription)
                                .frame(minHeight: 100)
                                .padding(4)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        } else {
                            Text(ticket.description)
                                .font(.body)
                        }
                    }
                    
                    // 作成日
                    VStack(alignment: .leading, spacing: 4) {
                        Text("作成日")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(ticket.createdAt.formatted(date: .long, time: .shortened))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: { showingShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    
                    Button(isEditing ? "保存" : "編集") {
                        if isEditing {
                            viewModel.updateTicket(
                                ticket,
                                title: editedTitle,
                                location: editedLocation,
                                description: editedDescription,
                                eventDate: editedEventDate
                            )
                        }
                        isEditing.toggle()
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            TicketShareView(ticket: ticket)
        }
    }
} 