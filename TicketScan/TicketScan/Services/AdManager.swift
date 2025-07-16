import SwiftUI
import UIKit

class AdManager: NSObject, ObservableObject {
    static let shared = AdManager()
    
    // テスト用広告ID（本番時は実際のIDに変更）
    private let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    private let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    private let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"
    
    @Published var showingInterstitial = false
    @Published var showingRewarded = false
    
    private var interstitialAd: String?
    private var rewardedAd: String?
    
    override init() {
        super.init()
        print("広告SDK初期化")
        loadInterstitialAd()
        loadRewardedAd()
    }
    
    // MARK: - バナー広告
    func createBannerView() -> UIView {
        let bannerView = UIView()
        bannerView.backgroundColor = .lightGray
        print("バナー広告プレースホルダーを作成")
        return bannerView
    }
    
    // MARK: - インタースティシャル広告
    func loadInterstitialAd() {
        print("インタースティシャル広告を読み込み中...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.interstitialAd = "loaded"
            print("インタースティシャル広告読み込み完了")
        }
    }
    
    func showInterstitialAd() {
        // 頻度制御チェック
        guard AdFrequencyManager.shared.canShowInterstitial() else {
            print("インタースティシャル広告の表示間隔が短すぎます")
            return
        }
        
        guard interstitialAd != nil else {
            print("インタースティシャル広告が準備できていません")
            loadInterstitialAd() // 次回のために再読み込み
            return
        }
        
        print("インタースティシャル広告を表示")
        
        // 表示記録
        AdFrequencyManager.shared.recordInterstitialShown()
        AdAnalytics.shared.trackInterstitialImpression()
    }
    
    // MARK: - リワード動画広告
    func loadRewardedAd() {
        print("リワード動画広告を読み込み中...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.rewardedAd = "loaded"
            print("リワード動画広告読み込み完了")
        }
    }
    
    func showRewardedAd(completion: @escaping (Bool) -> Void) {
        guard rewardedAd != nil else {
            print("リワード動画広告が準備できていません")
            loadRewardedAd()
            completion(false)
            return
        }
        
        print("リワード動画広告を表示")
        
        // シミュレート報酬
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            print("ユーザーが報酬を獲得: 1 coin")
            completion(true)
        }
    }
}

// MARK: - 広告デリゲート（プレースホルダー）
extension AdManager {
    func adDidDismiss() {
        print("広告が閉じられました")
        loadInterstitialAd()
        loadRewardedAd()
    }
    
    func adDidFailToPresent() {
        print("広告の表示に失敗")
        loadInterstitialAd()
        loadRewardedAd()
    }
}