import SwiftUI
import UIKit

struct AdBannerView: UIViewRepresentable {
    let height: CGFloat
    
    init(height: CGFloat = 50) {
        self.height = height
    }
    
    func makeUIView(context: Context) -> UIView {
        let bannerView = UIView()
        bannerView.backgroundColor = UIColor.systemGray5
        
        let label = UILabel()
        label.text = "広告エリア（プレースホルダー）"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        
        bannerView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: bannerView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: bannerView.centerYAnchor)
        ])
        
        return bannerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // 必要に応じて更新処理
    }
}

struct AdBannerModifier: ViewModifier {
    let placement: AdPlacement
    
    enum AdPlacement {
        case top
        case bottom
    }
    
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            if placement == .top {
                AdBannerView()
                    .frame(height: 50)
                    .background(Color(.systemGray6))
            }
            
            content
            
            if placement == .bottom {
                AdBannerView()
                    .frame(height: 50)
                    .background(Color(.systemGray6))
            }
        }
    }
}

extension View {
    func adBanner(placement: AdBannerModifier.AdPlacement = .bottom) -> some View {
        modifier(AdBannerModifier(placement: placement))
    }
}