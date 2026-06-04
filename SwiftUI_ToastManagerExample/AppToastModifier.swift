//
//  AppToastModifier.swift
//  SwiftUI_ToastManagerExample
//
//  Created by cano on 2026/06/04.
//

import SwiftUI

// ==========================================
// 6. 共通Modifierとしてカプセル化
// ==========================================
/// アプリの基本View階層の最前面に対して、トースト管理コンポーネントをOverlay（重ね合わせ）する修飾子
struct AppToastOverlayModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            content // 各画面のメインUI
            
            // 常に最前面をキープするトーストコンポーネントの配置
            ToastContainerView()
        }
    }
}

extension View {
    /// 画面に対してトースト通知レイヤーシステムを一括組み込みする共通関数
    public func applyToastSystem() -> some View {
        self.modifier(AppToastOverlayModifier())
    }
}

// ==========================================
// 7. 社内研修・動作確認用のテストView
// ==========================================
struct ToastTestView: View {
    // パターン①の個別タップアクションからトリガーされる「別画面（ハーフシート）」の開閉管理フラグ
    @State private var openDetailSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 25) {
                Text("研修用：引数カスタム検証")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                // 検証A：【画面下部】×【背景グレーあり】×【タップ時に別画面（シート）を展開】
                Button("検証A：下部 / グレーあり / タップで別画面起動") {
                    AppToastManager.shared.showBasic(
                        style: .success,
                        title: "タスクを保存しました",
                        description: "ここをタップすると、別画面シートが起動します。",
                        position: .bottom,
                        showOverlayBackground: true,
                        onTapAction: {
                            // トースト本体がタップされた時に実行する動作をここに直接記述
                            openDetailSheet = true
                        }
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                
                // 検証B：【画面上部】×【背景グレーなし（重ねて表示するだけ）】×【タップ動作なし】
                Button("検証B：上部 / グレーなし / タップ動作なし") {
                    AppToastManager.shared.showMultiple(
                        style: .error,
                        title: "同期エラーが3件発生",
                        details: [
                            "ユーザー名の入力形式が不正です。",
                            "サーバーへのアクセス制限を検出しました。"
                        ],
                        position: .top,
                        showOverlayBackground: false, // グレー背景を敷かないため、裏のボタンを続けて触れます
                        onTapAction: nil
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                
                // 検証C：【画面上部】×【背景グレーあり】×【デフォルトの詳細履歴展開】
                Button("検証C：上部 / グレーあり / 通常の詳細展開") {
                    AppToastManager.shared.showBasic(
                        style: .info,
                        title: "システムメンテナンス通知",
                        description: "タップすると、自動消去が一時停止し全ログが並びます。",
                        position: .top,
                        showOverlayBackground: true,
                        onTapAction: nil // nilにすることで、デフォルトの openDetail() が走りグレー背景が機能します
                    )
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .navigationTitle("トーストコントロール")
            // 検証Aのタップで呼び出される別画面コンポーネント
            .sheet(isPresented: $openDetailSheet) {
                NavigationStack {
                    VStack {
                        Text("トーストのタップアクションによって\n安全に起動された別画面です。")
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .navigationTitle("詳細ログ画面")
                }
                .presentationDetents([.medium])
            }
        }
        // アプリの大元にこれ1行を繋ぐだけで、引数に応じたすべての挙動がViewを汚さずに有効化されます
        .applyToastSystem()
    }
}
