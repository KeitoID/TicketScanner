import SwiftUI

struct RewardAdView: View {
    @StateObject private var adManager = AdManager.shared
    @State private var hasReward = false
    @State private var rewardExpiry: Date?
    @State private var showingRewardModal = false
    
    var isRewardActive: Bool {
        guard let expiry = rewardExpiry else { return false }
        return Date() < expiry
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // プレミアム機能状態表示
            if isRewardActive {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("プレミアム機能が利用可能")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(timeRemaining)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.yellow.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                        )
                )
            } else {
                // リワード広告ボタン
                Button(action: {
                    showRewardAd()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 18, weight: .semibold))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("動画を見てプレミアム機能を解放")
                                .font(.system(size: 14, weight: .semibold))
                            Text("24時間すべての機能が使い放題")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
        }
        .sheet(isPresented: $showingRewardModal) {
            RewardSuccessView {
                showingRewardModal = false
            }
        }
    }
    
    private var timeRemaining: String {
        guard let expiry = rewardExpiry else { return "" }
        let remaining = expiry.timeIntervalSinceNow
        let hours = Int(remaining) / 3600
        let minutes = Int(remaining % 3600) / 60
        return "\(hours):\(String(format: "%02d", minutes))"
    }
    
    private func showRewardAd() {
        adManager.showRewardedAd { success in
            if success {
                hasReward = true
                rewardExpiry = Date().addingTimeInterval(24 * 60 * 60) // 24時間後
                showingRewardModal = true
                
                // UserDefaultsに保存
                UserDefaults.standard.set(rewardExpiry, forKey: "rewardExpiry")
            }
        }
    }
}

struct RewardSuccessView: View {
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // 成功アニメーション
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.2), Color.orange.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "star.fill")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.yellow)
            }
            
            VStack(spacing: 8) {
                Text("プレミアム機能が解放されました！")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("24時間、すべての機能をお楽しみください")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                FeatureRow(icon: "wand.and.rays", title: "高精度OCR", description: "より正確なテキスト認識")
                FeatureRow(icon: "icloud", title: "クラウド同期", description: "複数デバイスでデータ共有")
                FeatureRow(icon: "chart.bar", title: "詳細統計", description: "チケット履歴の分析")
                FeatureRow(icon: "square.and.arrow.up", title: "データエクスポート", description: "PDF・CSV形式で出力")
            }
            .padding(.vertical, 16)
            
            Button(action: onDismiss) {
                Text("始める")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 20)
        .padding(.horizontal, 40)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}