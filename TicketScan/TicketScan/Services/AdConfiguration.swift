import Foundation
import GoogleMobileAds
import AppTrackingTransparency
import AdSupport

class AdConfiguration {
    static let shared = AdConfiguration()
    
    private init() {}
    
    func configureAds() {
        // iOS 14以降のプライバシー対応
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    GADMobileAds.sharedInstance().start(completionHandler: nil)
                }
            }
        } else {
            GADMobileAds.sharedInstance().start(completionHandler: nil)
        }
        
        // テスト用デバイスIDを設定（開発時のみ）
        #if DEBUG
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [GADSimulatorID]
        #endif
    }
    
    func configureTargeting() {
        // 広告のターゲティング設定
        let extras = GADExtras()
        extras.additionalParameters = [
            "category": "entertainment",
            "keywords": "ticket,event,concert,sports"
        ]
        
        let request = GADRequest()
        request.register(extras)
    }
}

// 広告表示の頻度制御
class AdFrequencyManager {
    static let shared = AdFrequencyManager()
    
    private let interstitialKey = "lastInterstitialTime"
    private let minInterstitialInterval: TimeInterval = 120 // 2分間隔
    
    private init() {}
    
    func canShowInterstitial() -> Bool {
        let lastTime = UserDefaults.standard.double(forKey: interstitialKey)
        let currentTime = Date().timeIntervalSince1970
        return currentTime - lastTime > minInterstitialInterval
    }
    
    func recordInterstitialShown() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: interstitialKey)
    }
}

// 広告のパフォーマンス追跡
class AdAnalytics {
    static let shared = AdAnalytics()
    
    private init() {}
    
    func trackBannerImpression() {
        // Firebase Analytics などに送信
        print("バナー広告が表示されました")
    }
    
    func trackInterstitialImpression() {
        // Firebase Analytics などに送信
        print("インタースティシャル広告が表示されました")
    }
    
    func trackRewardedVideoComplete() {
        // Firebase Analytics などに送信
        print("リワード動画が完了しました")
    }
    
    func trackAdRevenue(value: Double, currency: String = "USD") {
        // 広告収益の追跡
        print("広告収益: \(value) \(currency)")
    }
}