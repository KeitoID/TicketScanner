import SwiftUI

struct OCRFeedbackView: View {
    let success: Bool
    let extractedText: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // 結果アイコン
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: success ? 
                                [Color.green.opacity(0.2), Color.green.opacity(0.1)] :
                                [Color.orange.opacity(0.2), Color.orange.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(success ? .green : .orange)
            }
            
            VStack(spacing: 12) {
                Text(success ? "テキスト検出成功！" : "テキストが検出されませんでした")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                if success {
                    Text("読み取ったテキストを各フィールドに自動入力しました")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    VStack(spacing: 8) {
                        Text("画像から文字を読み取れませんでした")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text("以下の点をご確認ください：")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(.orange)
                                Text("画像が鮮明で文字がはっきり見える")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(.orange)
                                Text("文字が適切な大きさで写っている")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(.orange)
                                Text("照明が十分で影がない")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(.orange)
                                Text("チケットに日本語や英語の文字がある")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                }
            }
            
            Button(action: onDismiss) {
                Text(success ? "確認" : "再試行する")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: success ? 
                                [Color.green, Color.green.opacity(0.8)] :
                                [Color.orange, Color.orange.opacity(0.8)],
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
        .padding(.horizontal, 40)
    }
}