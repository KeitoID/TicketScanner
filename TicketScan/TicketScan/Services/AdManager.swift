import SwiftUI
import GoogleMobileAds

class AdManager: NSObject, ObservableObject {
    static let shared = AdManager()
    
    // テスト用広告ID（本番時は実際のIDに変更）
    private let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    private let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    private let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"
    
    @Published var showingInterstitial = false
    @Published var showingRewarded = false
    
    private var interstitialAd: GADInterstitialAd?
    private var rewardedAd: GADRewardedAd?
    
    override init() {
        super.init()
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        loadInterstitialAd()
        loadRewardedAd()
    }
    
    // MARK: - バナー広告
    func createBannerView() -> GADBannerView {
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
        bannerView.adUnitID = bannerAdUnitID
        bannerView.rootViewController = UIApplication.shared.windows.first?.rootViewController
        bannerView.load(GADRequest())
        return bannerView
    }
    
    // MARK: - インタースティシャル広告
    func loadInterstitialAd() {
        let request = GADRequest()
        GADInterstitialAd.load(withAdUnitID: interstitialAdUnitID, request: request) { [weak self] ad, error in
            if let error = error {
                print("インタースティシャル広告の読み込みに失敗: \(error.localizedDescription)")
                return
            }
            self?.interstitialAd = ad
            self?.interstitialAd?.fullScreenContentDelegate = self
        }
    }
    
    func showInterstitialAd() {
        // 頻度制御チェック
        guard AdFrequencyManager.shared.canShowInterstitial() else {
            print("インタースティシャル広告の表示間隔が短すぎます")
            return
        }
        
        guard let interstitialAd = interstitialAd else {
            print("インタースティシャル広告が準備できていません")
            loadInterstitialAd() // 次回のために再読み込み
            return
        }
        
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            return
        }
        
        interstitialAd.present(fromRootViewController: rootViewController)
        
        // 表示記録
        AdFrequencyManager.shared.recordInterstitialShown()
        AdAnalytics.shared.trackInterstitialImpression()
    }
    
    // MARK: - リワード動画広告
    func loadRewardedAd() {
        let request = GADRequest()
        GADRewardedAd.load(withAdUnitID: rewardedAdUnitID, request: request) { [weak self] ad, error in
            if let error = error {
                print("リワード動画広告の読み込みに失敗: \(error.localizedDescription)")
                return
            }
            self?.rewardedAd = ad
            self?.rewardedAd?.fullScreenContentDelegate = self
        }
    }
    
    func showRewardedAd(completion: @escaping (Bool) -> Void) {
        guard let rewardedAd = rewardedAd else {
            print("リワード動画広告が準備できていません")
            loadRewardedAd()
            completion(false)
            return
        }
        
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            completion(false)
            return
        }
        
        rewardedAd.present(fromRootViewController: rootViewController) {
            let reward = rewardedAd.adReward
            print("ユーザーが報酬を獲得: \(reward.amount) \(reward.type)")
            completion(true)
        }
    }
}

// MARK: - GADFullScreenContentDelegate
extension AdManager: GADFullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        if ad is GADInterstitialAd {
            loadInterstitialAd() // 次回のために再読み込み
        } else if ad is GADRewardedAd {
            loadRewardedAd() // 次回のために再読み込み
        }
    }
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("広告の表示に失敗: \(error.localizedDescription)")
        if ad is GADInterstitialAd {
            loadInterstitialAd()
        } else if ad is GADRewardedAd {
            loadRewardedAd()
        }
    }
}