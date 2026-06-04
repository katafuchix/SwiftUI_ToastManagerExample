//
//  ToastViewComponents.swift
//  SwiftUI_ToastManagerExample
//
//  Created by cano on 2026/06/04.
//

import SwiftUI

// ==========================================
// 5. トースト本体のUIコンポーネント群
// ==========================================
/// トーストの最背面マスクレイヤーおよび上下の配置アライメントを統合制御する親View
public struct ToastContainerView: View {
    // 状態を監視するためのマネージャーインスタンス（シングルトン）
    @Bindable var manager = AppToastManager.shared
    
    public var body: some View {
        // マネージャーが保持する position（.top または .bottom）に追従して、ZStack内の配置アライメントを動的に切り替えます
        ZStack(alignment: manager.position == .top ? .top : .bottom) {
            
            // ==========================================
            // 【完全版】背景タップを一括でキャッチする最背面シールド
            // ==========================================
            // 画面にトーストが1件でも存在している場合、画面全体（セーフエリア外まで）にタップ反応レイヤーを構築します
            if !manager.currentToasts.isEmpty {
                Group {
                    if manager.showOverlayBackground {
                        // ------------------------------------------
                        // パターン①：グレーありの場合（半透明黒マスク）
                        // ------------------------------------------
                        Color.black.opacity(0.4)
                    } else {
                        // ------------------------------------------
                        // パターン②：グレーなしの場合（完全透明シールド）
                        // ------------------------------------------
                        // 【研修重要ポイント】
                        // SwiftUIの仕様上、Color.clearのままだと「何も存在しない空間」とみなされ、
                        // タップイベントをそのままスルーして裏のボタン等を押してしまいます。
                        // .contentShape(Rectangle())を組み合わせることで、「見た目は透明だが、
                        // 画面全面でタップイベントを確実にブロック・検知する膜」として機能させることができます。
                        Color.clear
                            .contentShape(Rectangle())
                    }
                }
                .ignoresSafeArea() // 画面全体に広げる
                .onTapGesture {
                    // 【背景タップ挙動の制御：研修チェックポイント】
                    // 呼び出し側（showBasic等）で closeOnBackgroundTap: true が指定されている場合のみ一括消去を実行。
                    // false が明示されている場合は、タップを検知してもマネージャーのクリア関数を呼ばず、閉じない挙動を維持します。
                    if manager.closeOnBackgroundTap {
                        manager.closeDetail()
                    }
                }
                .transition(.opacity) // 登場・退場時にふわっとフェードイン/アウトさせる
            }
            
            // ==========================================
            // トースト本体の描画スタック（コンテンツエリア）
            // ==========================================
            // レイアウトの罠対策として、VStack自身のサイズを「トーストコンテンツがある分だけのジャストサイズ」に収め、
            // トーストの周りの空きスペースをタップしたイベントが、確実に背面のシールドに届くようにレイアウトします。
            VStack(spacing: 12) {
                if manager.isOpening {
                    // 【詳細展開時】すべてのトーストをその場から綺麗に並べて全件表示
                    VStack(spacing: 12) {
                        ForEach(manager.currentToasts, id: \.id) { toast in
                            resolveToastView(toast: toast)
                        }
                    }
                    .padding(.horizontal, 20)
                } else {
                    // 【未展開（通常時）】配列の先頭にある最新の1件のみを抽出し、指定位置にコンパクトに表示
                    if let topToast = manager.currentToasts.first {
                        resolveToastView(toast: topToast)
                            .padding(.horizontal, 20)
                        // 上部・下部それぞれの位置に最適化された登場・退場アニメーション
                            .transition(manager.position == .top ? .move(edge: .top).combined(with: .opacity) : .move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            // VStackが横幅いっぱいに勝手に引き伸ばされて透明な壁になるのを防ぐため、
            // コンテンツを中央寄せにしつつ、余計な空間のタップは背面へスルーできるように制限します
            .frame(maxWidth: .infinity)
            // 配置位置に応じて、セーフエリア（ステータスバーやホームインジケーター）との適切な余白を動的に確保
            .padding(.top, manager.position == .top ? 10 : 0)
            .padding(.bottom, manager.position == .bottom ? 30 : 0)
        }
        // コンポーネント内の開閉・増減アニメーションを一括適用
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: manager.isOpening)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: manager.currentToasts.count)
    }
    
    /// プロトコルで抽象化されたデータを実体のViewに安全にキャストして出し分けるビュービルダー
    @ViewBuilder
    private func resolveToastView(toast: any ToastProtocol) -> some View {
        Group {
            if let basicToast = toast as? BasicToastInfo {
                BasicToastView(info: basicToast)
            } else if let multipleToast = toast as? MultipleToastInfo {
                MultipleToastView(info: multipleToast)
            }
        }
    }
}

// ------------------------------------------
// パターンA：基本形のトーストUIモジュール
// ------------------------------------------
struct BasicToastView: View {
    let info: BasicToastInfo
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 左側：アイコンエリア
            Image(systemName: info.style.iconName)
                .foregroundColor(info.style.iconColor)
                .font(.title3)
            
            // 中央：テキストエリア（タイトル ＋ 任意の説明文）
            VStack(alignment: .leading, spacing: 4) {
                Text(info.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if let desc = info.description {
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            Spacer()
            
            // 右側：単体消去用バツボタン
            Button(action: { AppToastManager.shared.dismiss(id: info.id) }) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(16)
        .background(Color(.darkGray))
        .cornerRadius(12)
        .shadow(radius: 8)
        .onTapGesture {
            // 1. 個別アクション（別画面起動など）が指定されている場合は、最優先で実行します
            if let customAction = info.onTapAction {
                customAction()
                
                // 2. 自動消去タイマーをストップさせ、画面上にホールドさせるために一律で開閉状態をONにします
                // これにより、カード本体を叩いた時は背面のシールドまでタップイベントを貫通させず、閉じない挙動を作ります
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    AppToastManager.shared.isOpening = true
                }
            }
        }
    }
}

// ------------------------------------------
// パターンB：複数リスト形のトーストUIモジュール
// ------------------------------------------
struct MultipleToastView: View {
    let info: MultipleToastInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 上段：メインタイトル構成（アイコン・バツボタン含む）
            HStack {
                Image(systemName: info.style.iconName)
                    .foregroundColor(info.style.iconColor)
                    .font(.title3)
                
                Text(info.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { AppToastManager.shared.dismiss(id: info.id) }) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // 下段：複数メッセージの箇条書きリスト構成
            VStack(alignment: .leading, spacing: 6) {
                ForEach(info.detailMessages, id: \.self) { msg in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(info.style.iconColor)
                            .frame(width: 5, height: 5)
                        Text(msg)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .padding(.leading, 6)
        }
        .padding(16)
        .background(Color(.darkGray))
        .cornerRadius(12)
        .shadow(radius: 8)
        .onTapGesture {
            // Basic形と完全に共通のタップイベント上書きロジック（個別アクション実行 ＆ ホールド）
            if let customAction = info.onTapAction {
                customAction()
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    AppToastManager.shared.isOpening = true
                }
            }
        }
    }
}
