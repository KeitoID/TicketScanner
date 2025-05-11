import SwiftUI

struct TicketListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: TicketViewModel
    @State private var showingScanner = false
    @State private var showingFilterSheet = false
    
    init() {
        _viewModel = StateObject(wrappedValue: TicketViewModel(context: CoreDataManager.shared.container.viewContext))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // 検索バー
                SearchBar(text: $viewModel.searchText)
                    .padding(.horizontal)
                
                // フィルターボタン
                HStack {
                    Button(action: { showingFilterSheet = true }) {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text(viewModel.selectedFilter == .all ? "すべて" :
                                 viewModel.selectedFilter == .recent ? "今日" : "お気に入り")
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                
                if viewModel.filteredTickets.isEmpty {
                    ContentUnavailableView(
                        "チケットがありません",
                        systemImage: "ticket",
                        description: Text("カメラボタンをタップしてチケットをスキャンしてください")
                    )
                } else {
                    List {
                        ForEach(viewModel.filteredTickets) { ticket in
                            NavigationLink(destination: TicketDetailView(ticket: ticket, viewModel: viewModel)) {
                                TicketRowView(ticket: ticket, viewModel: viewModel)
                            }
                        }
                        .onDelete(perform: deleteTickets)
                    }
                }
            }
            .navigationTitle("チケット一覧")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingScanner = true }) {
                        Image(systemName: "camera")
                    }
                }
            }
            .sheet(isPresented: $showingScanner) {
                TicketScannerView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterView(selectedFilter: $viewModel.selectedFilter)
            }
        }
    }
    
    private func deleteTickets(at offsets: IndexSet) {
        offsets.forEach { index in
            let ticket = viewModel.filteredTickets[index]
            viewModel.deleteTicket(ticket)
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("検索", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

struct FilterView: View {
    @Binding var selectedFilter: TicketViewModel.TicketFilter
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Button(action: { selectedFilter = .all }) {
                    HStack {
                        Text("すべて")
                        Spacer()
                        if selectedFilter == .all {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Button(action: { selectedFilter = .recent }) {
                    HStack {
                        Text("今日")
                        Spacer()
                        if selectedFilter == .recent {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Button(action: { selectedFilter = .favorite }) {
                    HStack {
                        Text("お気に入り")
                        Spacer()
                        if selectedFilter == .favorite {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("フィルター")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TicketRowView: View {
    let ticket: Ticket
    @ObservedObject var viewModel: TicketViewModel
    
    var body: some View {
        HStack {
            if let uiImage = UIImage(data: ticket.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
            } else {
                Color.gray
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading) {
                Text(ticket.title)
                    .font(.headline)
                Text(ticket.location)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: { viewModel.toggleFavorite(ticket) }) {
                Image(systemName: ticket.isFavorite ? "star.fill" : "star")
                    .foregroundColor(ticket.isFavorite ? .yellow : .gray)
            }
        }
    }
} 