import SwiftUI

struct OCRRewardAdView: View {
    @StateObject private var adManager = AdManager.shared
    @StateObject private var ocrRewardManager = OCRRewardManager.shared
    @State private var showingRewardModal = false
    let onRewardEarned: () -> Void
    let ticketId: String?
    
    init(ticketId: String? = nil, onRewardEarned: @escaping () -> Void) {
        self.ticketId = ticketId
        self.onRewardEarned = onRewardEarned
    }
    
    var body: some View {
        if ocrRewardManager.checkOCRAvailability(for: ticketId) {
            // OCR機能が利用可能な状態
            Button(action: {
                onRewardEarned()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 16, weight: .semibold))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("OCR機能を実行")
                            .font(.system(size: 13, weight: .semibold))
                        Text("チケットのテキストを自動認識 ※画像の状態により検出できない場合があります")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [Color.green, Color.green.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .green.opacity(0.3), radius: 4, x: 0, y: 2)
            }
        } else {
            // リワード広告視聴が必要な状態
            Button(action: {
                showRewardAd()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 16, weight: .semibold))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("動画を見てOCR機能を利用")
                            .font(.system(size: 13, weight: .semibold))
                        Text("チケットのテキストを自動認識 ※画像の状態により検出できない場合があります")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [Color.orange, Color.red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .orange.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .sheet(isPresented: $showingRewardModal) {
                OCRRewardSuccessView {
                    showingRewardModal = false
                }
            }
        }
    }
    
    private func showRewardAd() {
        adManager.showRewardedAd { success in
            if success {
                ocrRewardManager.unlockOCR(for: ticketId)
                showingRewardModal = true
            }
        }
    }
}

struct OCRRewardSuccessView: View {
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // 成功アニメーション
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.2), Color.red.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "text.viewfinder")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(.orange)
            }
            
            VStack(spacing: 8) {
                Text("OCR機能が利用可能になりました！")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("チケットの文字を自動的に読み取って入力できます")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onDismiss) {
                Text("OCR機能を使う")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 15)
        .padding(.horizontal, 50)
    }
}

