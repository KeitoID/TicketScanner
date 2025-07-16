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
                    VStack(spacing: 20) {
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "ticket")
                                .font(.system(size: 48, weight: .light))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        VStack(spacing: 8) {
                            Text("チケットがありません")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("カメラボタンをタップして\nチケットをスキャンしてください")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.filteredTickets) { ticket in
                                NavigationLink(destination: TicketDetailView(ticket: ticket, viewModel: viewModel)) {
                                    ModernTicketCard(ticket: ticket, viewModel: viewModel)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationTitle("チケット一覧")
            .adBanner(placement: .bottom)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: TicketGalleryView(viewModel: viewModel)) {
                        Image(systemName: "square.grid.2x2")
                    }
                }
                
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

struct ModernTicketCard: View {
    let ticket: Ticket
    @ObservedObject var viewModel: TicketViewModel
    @State private var isPressed = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color(.systemBackground), Color(.systemBackground).opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(
                    color: .black.opacity(isPressed ? 0.15 : 0.08),
                    radius: isPressed ? 20 : 15,
                    x: 0,
                    y: isPressed ? 8 : 5
                )
                .scaleEffect(isPressed ? 0.98 : 1.0)
            
            HStack(spacing: 16) {
                // 画像セクション
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    if let uiImage = UIImage(data: ticket.imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 76, height: 76)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    } else {
                        Image(systemName: "ticket")
                            .font(.system(size: 32, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
                
                // 情報セクション
                VStack(alignment: .leading, spacing: 6) {
                    Text(ticket.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "location")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.blue)
                        Text(ticket.location)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                        Text(ticket.eventDate.formatted(date: .numeric, time: .shortened))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // お気に入りボタン
                VStack {
                    Button(action: { 
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            viewModel.toggleFavorite(ticket)
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(ticket.isFavorite ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.1))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: ticket.isFavorite ? "star.fill" : "star")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(ticket.isFavorite ? .yellow : .gray)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
            }
            .padding(20)
        }
        .onPressGesture(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}

extension View {
    func onPressGesture(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
} 