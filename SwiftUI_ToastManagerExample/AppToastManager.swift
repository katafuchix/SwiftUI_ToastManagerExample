//
//  AppToastManager.swift
//  SwiftUI_ToastManagerExample
//
//  Created by cano on 2026/06/04.
//

import SwiftUI

// ==========================================
// 4. 状態管理（State）とタイマー制御
// ==========================================
/// アプリ全体のトースト通知の状態（配列・開閉・位置・背景・タップ挙動）を一元管理するクラス
@MainActor
@Observable
public class AppToastManager {
    /// どこからでも同じ状態にアクセスできるようにするためのシングルトンインスタンス
    public static let shared: AppToastManager = .init()
    
    /// 現在画面に出力されているアクティブなトーストの配列（外部からは変更不可）
    public private(set) var currentToasts: [any ToastProtocol] = []
    
    /// トースト全体が詳細モード（履歴展開状態）として開いているか、
    /// 或者はタップ後に画面上にホールドされているかどうかの管理フラグ
    public var isOpening: Bool = false
    
    // ==========================================
    // カスタマイズ指定用プロパティ（研修項目）
    // ==========================================
    /// トーストを表示する位置（上部: .top / 下部: .bottom）を一元管理するプロパティ
    public private(set) var position: ToastPosition = .bottom
    
    /// 詳細展開時、または通常表示時に背景をグレー（黒透過マスク）にするかどうかのプロパティ
    public private(set) var showOverlayBackground: Bool = true
    
    // 背景をタップした際にトーストを一括消去するかどうかの制御プロパティ
    // これにより、showOverlayBackground（見た目）とは完全に独立して「閉じる・閉じない」の挙動を制御します
    public private(set) var closeOnBackgroundTap: Bool = true
    
    /// 自動消去用の非同期タスク（Task）をトーストのIDごとに追跡・管理する辞書型コンテナ
    private var dismissTasks: [UUID: Task<Void, Never>] = [:]
    
    /// シングルトン設計のため、外部からの初期化を禁止
    private init() {}
    
    // ==========================================
    // トースト発行用パブリック関数群
    // ==========================================
    
    /// 【基本形トーストの発行】位置、背景の有無、背景タップで閉じるか、個別アクションを指定してトーストを生成
    public func showBasic(
        style: ToastStyle,
        title: String,
        description: String? = nil,
        position: ToastPosition = .bottom,
        showOverlayBackground: Bool = true,
        closeOnBackgroundTap: Bool = true, // 背景タップで閉じるかどうかの指定（デフォルトはtrue）
        onTapAction: (() -> Void)? = nil
    ) {
        // 全表示オプション（配置位置、背景グレーのON/OFF、背景タップ挙動）をマネージャー側の状態に同期
        configure(
            position: position,
            showOverlayBackground: showOverlayBackground,
            closeOnBackgroundTap: closeOnBackgroundTap
        )
        
        let toast = BasicToastInfo(style: style, title: title, description: description, onTapAction: onTapAction)
        addToast(toast)
    }
    
    /// 【リスト形トーストの発行】位置、背景の有無、背景タップで閉じるか、個別アクションを指定してトーストを生成
    public func showMultiple(
        style: ToastStyle,
        title: String,
        details: [String],
        position: ToastPosition = .bottom,
        showOverlayBackground: Bool = true,
        closeOnBackgroundTap: Bool = true, // 背景タップで閉じるかどうかの指定（デフォルトはtrue）
        onTapAction: (() -> Void)? = nil
    ) {
        // 全表示オプション（配置位置、背景グレーのON/OFF、背景タップ挙動）をマネージャー側の状態に同期
        configure(
            position: position,
            showOverlayBackground: showOverlayBackground,
            closeOnBackgroundTap: closeOnBackgroundTap
        )
        
        let toast = MultipleToastInfo(style: style, title: title, detailMessages: details, onTapAction: onTapAction)
        addToast(toast)
    }
    
    // ==========================================
    // 内部制御プライベートロジック
    // ==========================================
    
    /// 共通のレイアウトオプション・挙動オプションを状態クラスに同期セットする内部関数
    private func configure(position: ToastPosition, showOverlayBackground: Bool, closeOnBackgroundTap: Bool) {
        self.position = position
        self.showOverlayBackground = showOverlayBackground
        self.closeOnBackgroundTap = closeOnBackgroundTap // 背景タップ消去のフラグを状態に保持
    }
    
    /// トーストを配列の先頭に挿入し、指定時間後に自動消去するタイマーを起動する内部共通ロジック
    private func addToast(_ toast: some ToastProtocol) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            // 新しく発生したトーストを配列の先頭に挿入
            currentToasts.insert(toast, at: 0)
        }
        
        let duration = toast.style.displayDuration
        let id = toast.id
        
        // 自動消去タイマーの開始
        dismissTasks[id] = Task {
            try? await Task.sleep(for: .seconds(duration))
            
            // 【ホールド制御】詳細履歴モードが開いている間、または背景をホールドしている間は自動で消さない
            while isOpening {
                try? await Task.sleep(for: .seconds(0.5))
            }
            dismiss(id: id)
        }
    }
    
    /// 指定された特定のIDを持つトーストを、タイマーを安全にキャンセルした上で配列から削除する
    public func dismiss(id: UUID) {
        // 該当トーストの自動消去タスクをキャンセル
        dismissTasks[id]?.cancel()
        dismissTasks.removeValue(forKey: id)
        
        withAnimation(.easeInOut(duration: 0.2)) {
            currentToasts.removeAll(where: { $0.id == id })
            // トーストが画面からすべて消滅した場合は、状態フラグも自動で安全にリセットする
            if currentToasts.isEmpty {
                isOpening = false
            }
        }
    }
    
    // ==========================================
    // 背景タップ連動・一括クリア関数
    // ==========================================
    /// 背景（グレーマスクまたは透明領域）をタップした時に、トーストシステム全体を一括で閉じる関数
    public func closeDetail() {
        withAnimation(.easeInOut(duration: 0.2)) {
            // 1. 詳細・ホールド状態のフラグを解除
            isOpening = false
            
            // 2. 【最重要】現在画面に出力されているアクティブなトーストを「全削除」
            // これにより View 側の if !manager.currentToasts.isEmpty 条件が外れ、
            // 背面タップ領域（シールド）とトースト本体が同時にふわっと画面から消滅します
            currentToasts.removeAll()
        }
        
        // 3. バックグラウンドで待機中だったすべての自動消去タイマータスクを一括キャンセル（メモリ解放）
        dismissTasks.values.forEach { $0.cancel() }
        dismissTasks.removeAll()
    }
}
