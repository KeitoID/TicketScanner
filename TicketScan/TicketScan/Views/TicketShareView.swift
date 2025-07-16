import SwiftUI

struct TicketShareView: View {
    let ticket: Ticket
    @Environment(\.dismiss) private var dismiss
    @State private var shareImage: UIImage?
    @State private var customMessage: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            HStack {
                Button("戻る") {
                    dismiss()
                }
                Spacer()
                Text("チケット共有🎫")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            
            // 共有用カード
            ScrollView {
                VStack(spacing: 20) {
                    // チケット画像
                    if let uiImage = UIImage(data: ticket.imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(16)
                            .shadow(radius: 5)
                    }
                    
                    // チケット情報
                    VStack(alignment: .leading, spacing: 16) {
                        // タイトル
                        Text(ticket.title)
                            .font(.title)
                            .bold()
                            .foregroundColor(.primary)
                        
                        // 開催日時
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            Text(ticket.eventDate.formatted(date: .numeric, time: .shortened))
                                .font(.headline)
                        }
                        
                        // 場所
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                            Text(ticket.location)
                                .font(.headline)
                        }
                        
                        // 説明
                        if !ticket.description.isEmpty {
                            Text(ticket.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        // アプリ情報
                        HStack {
                            Image("AppIcon")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .cornerRadius(4)
                            Text("TicketScan")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(radius: 3)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
        .onAppear {
            prepareShareImage()
        }
    }
    
    private func prepareShareImage() {
        let renderer = ImageRenderer(content: 
            VStack(spacing: 20) {
                if let uiImage = UIImage(data: ticket.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(16)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text(ticket.title)
                        .font(.title)
                        .bold()
                    
                    HStack {
                        Image(systemName: "calendar")
                        Text(ticket.eventDate.formatted(date: .numeric, time: .shortened))
                            .font(.headline)
                    }
                    
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                        Text(ticket.location)
                            .font(.headline)
                    }
                    
                    if !ticket.description.isEmpty {
                        Text(ticket.description)
                            .font(.body)
                    }
                    
                    HStack {
                        Image("AppIcon")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .cornerRadius(4)
                        Text("TicketScan")
                            .font(.caption)
                    }
                }
                .padding()
            }
            .padding()
            .background(Color(.systemBackground))
        )
        
        renderer.scale = UIScreen.main.scale
        shareImage = renderer.uiImage
    }
}