import SwiftUI
import GoogleMobileAds

struct AdBannerView: UIViewRepresentable {
    let adSize: GADAdSize
    
    init(adSize: GADAdSize = GADAdSizeBanner) {
        self.adSize = adSize
    }
    
    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView(adSize: adSize)
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716" // テスト用ID
        bannerView.rootViewController = UIApplication.shared.windows.first?.rootViewController
        bannerView.load(GADRequest())
        return bannerView
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {
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