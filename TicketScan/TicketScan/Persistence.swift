//
//  Persistence.swift
//  TicketScan
//
//  Created by Yoshioka Keito on 2025/05/11.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
        }
        do {
            try viewContext.save()
        } catch {
            print("プレビューデータの保存に失敗しました: \(error.localizedDescription)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "TicketScan")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("Core Data初期化エラー: \(error.localizedDescription)")
                print("エラー詳細: \(error.userInfo)")
                
                // 初期化エラーの場合は、アプリケーションを続行できないため、
                // 適切なエラーハンドリング機構を通じてユーザーに通知すべき
                // 本番環境では、適切なエラー報告機能を実装してください
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
