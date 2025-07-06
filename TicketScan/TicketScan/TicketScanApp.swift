//
//  TicketScanApp.swift
//  TicketScan
//
//  Created by Yoshioka Keito on 2025/05/11.
//

import SwiftUI

@main
struct TicketScanApp: App {
    
    init() {
        // 広告初期化
        AdConfiguration.shared.configureAds()
    }
    
    var body: some Scene {
        WindowGroup {
            TicketListView()
                .onAppear {
                    // アプリ起動時の処理
                    AdConfiguration.shared.configureTargeting()
                }
        }
    }
}
