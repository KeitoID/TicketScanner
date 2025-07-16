import SwiftUI

struct TicketGalleryView: View {
    @ObservedObject var viewModel: TicketViewModel
    @State private var selectedCategory: TicketCategory = .other
    @State private var showingCategoryFilter = false
    @State private var displayMode: DisplayMode = .grid
    
    enum DisplayMode {
        case grid, list
    }
    
    var filteredTickets: [Ticket] {
        if selectedCategory == .other {
            return viewModel.filteredTickets
        } else {
            return viewModel.filteredTickets.filter { $0.category == selectedCategory }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 統計表示
                if !viewModel.tickets.isEmpty {
                    StatisticsHeaderView(tickets: viewModel.tickets)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
                
                // フィルター・表示モード切替
                HStack {
                    Button(action: { showingCategoryFilter = true }) {
                        HStack {
                            Image(systemName: selectedCategory.icon)
                            Text(selectedCategory == .other ? "すべて" : selectedCategory.displayName)
                            Image(systemName: "chevron.down")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            displayMode = displayMode == .grid ? .list : .grid
                        }
                    }) {
                        Image(systemName: displayMode == .grid ? "list.bullet" : "square.grid.2x2")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // メインコンテンツ
                if filteredTickets.isEmpty {
                    EmptyGalleryView(category: selectedCategory)
                } else {
                    ScrollView {
                        if displayMode == .grid {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                                ForEach(filteredTickets) { ticket in
                                    NavigationLink(destination: TicketDetailView(ticket: ticket, viewModel: viewModel)) {
                                        TicketGalleryCard(ticket: ticket)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 12)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredTickets) { ticket in
                                    NavigationLink(destination: TicketDetailView(ticket: ticket, viewModel: viewModel)) {
                                        TicketGalleryListItem(ticket: ticket)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("ギャラリー")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingCategoryFilter) {
                CategoryFilterView(selectedCategory: $selectedCategory)
            }
        }
    }
}

struct TicketGalleryCard: View {
    let ticket: Ticket
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 画像（統一されたアスペクト比）
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(height: 120) // 統一された固定高さ
                
                if let uiImage = UIImage(data: ticket.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: 120) // 統一された固定高さ
                        .clipped()
                        .cornerRadius(12)
                } else {
                    VStack {
                        Image(systemName: ticket.category.icon)
                            .font(.system(size: 32))
                            .foregroundColor(.gray)
                        Text("No Image")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(height: 120) // 統一された固定高さ
                }
                
                // カテゴリバッジ
                VStack {
                    HStack {
                        Spacer()
                        Text(ticket.category.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    Spacer()
                }
                .padding(8)
            }
            
            // 情報
            VStack(alignment: .leading, spacing: 4) {
                Text(ticket.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(ticket.location)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    Text(ticket.eventDate.formatted(date: .numeric, time: .omitted))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if ticket.rating > 0 {
                        StarRatingDisplayView(rating: ticket.rating, starSize: 12)
                    }
                }
            }
            .padding(.horizontal, 12) // 情報部分にマージン追加
            
            Spacer(minLength: 0) // 下部のスペースを統一
        }
        .frame(height: 200) // カード全体の高さを統一
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct TicketGalleryListItem: View {
    let ticket: Ticket
    
    var body: some View {
        HStack(spacing: 12) {
            // 画像
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(width: 60, height: 60)
                
                if let uiImage = UIImage(data: ticket.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    Image(systemName: ticket.category.icon)
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                }
            }
            
            // 情報
            VStack(alignment: .leading, spacing: 4) {
                Text(ticket.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(ticket.location)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    Text(ticket.eventDate.formatted(date: .numeric, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if ticket.rating > 0 {
                        StarRatingDisplayView(rating: ticket.rating, starSize: 12)
                    }
                }
            }
            
            Spacer()
            
            // カテゴリアイコン
            Image(systemName: ticket.category.icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct EmptyGalleryView: View {
    let category: TicketCategory
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: category == .other ? "photo.on.rectangle" : category.icon)
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                Text(category == .other ? "チケットがありません" : "\(category.displayName)のチケットがありません")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("カメラボタンをタップして\nチケットをスキャンしてください")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct CategoryFilterView: View {
    @Binding var selectedCategory: TicketCategory
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Button(action: {
                    selectedCategory = .other
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "square.grid.2x2")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Text("すべて")
                        Spacer()
                        if selectedCategory == .other {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                ForEach(TicketCategory.allCases.filter { $0 != .other }, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text(category.displayName)
                            Spacer()
                            if selectedCategory == category {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("カテゴリ")
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

struct StatisticsHeaderView: View {
    let tickets: [Ticket]
    
    var statistics: (total: Int, thisYear: Int, categories: [TicketCategory: Int]) {
        let total = tickets.count
        let thisYear = tickets.filter { 
            Calendar.current.isDate($0.eventDate, equalTo: Date(), toGranularity: .year)
        }.count
        
        var categories: [TicketCategory: Int] = [:]
        for ticket in tickets {
            categories[ticket.category, default: 0] += 1
        }
        
        return (total: total, thisYear: thisYear, categories: categories)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                StatisticCard(title: "総チケット数", value: "\(statistics.total)", icon: "ticket")
                StatisticCard(title: "今年", value: "\(statistics.thisYear)", icon: "calendar")
                StatisticCard(title: "平均評価", value: averageRating, icon: "star")
            }
            
            if !statistics.categories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(statistics.categories.sorted(by: { $0.value > $1.value }), id: \.key) { category, count in
                            CategoryStatCard(category: category, count: count)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
    
    private var averageRating: String {
        let ratedTickets = tickets.filter { $0.rating > 0 }
        if ratedTickets.isEmpty {
            return "-"
        }
        let average = Double(ratedTickets.reduce(0) { $0 + $1.rating }) / Double(ratedTickets.count)
        return String(format: "%.1f", average)
    }
}

struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct CategoryStatCard: View {
    let category: TicketCategory
    let count: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: category.icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
            
            Text(category.displayName)
                .font(.caption)
                .foregroundColor(.primary)
            
            Text("\(count)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

#Preview {
    TicketGalleryView(viewModel: TicketViewModel(context: CoreDataManager.shared.container.viewContext))
}