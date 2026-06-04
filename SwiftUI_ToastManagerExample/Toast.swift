//
//  Toast.swift
//  SwiftUI_ToastManagerExample
//
//  Created by cano on 2026/06/04.
//

import SwiftUI

// ==========================================
// 1. 表示位置を制御するEnum（新規追加）
// ==========================================
/// トーストを画面の上部・下部のどちらに配置するかを指定するEnum
public enum ToastPosition {
    case top
    case bottom
}

// ==========================================
// 2. トーストのスタイル・バリエーションの定義
// ==========================================
/// トーストの重要度やアイコン・色を一元管理するEnum
public enum ToastStyle: Sendable {
    case success
    case error
    case info
    
    /// スタイルに応じたシステムアイコン名を返す
    public var iconName: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error:   return "xmark.circle.fill"
        case .info:    return "info.circle.fill"
        }
    }
    
    /// スタイルに応じたシンボルカラーを返す
    public var iconColor: Color {
        switch self {
        case .success: return .green
        case .error:   return .red
        case .info:    return .blue
        }
    }
    
    /// 各トーストが自動で消えるまでのデフォルト時間（秒）
    public var displayDuration: TimeInterval {
        switch self {
        case .success: return 3.0
        case .error:   return 4.0
        case .info:    return 3.0
        }
    }
}

// ==========================================
// 3. トーストデータの抽象化（プロトコル）
// ==========================================
/// 全てのトーストデータ構造体が準拠すべき基本プロトコル
public protocol ToastProtocol: Identifiable, Equatable {
    var id: UUID { get }
    var style: ToastStyle { get }
    var title: String { get }
    
    // 【拡張】トースト本体がタップされた時の個別アクションを保持（nilの場合は詳細モード展開）
    var onTapAction: (() -> Void)? { get }
}

/// パターンA：タイトルと短い説明文を持つ基本形のトースト
public struct BasicToastInfo: ToastProtocol {
    public let id: UUID = .init()
    public let style: ToastStyle
    public let title: String
    public let description: String?
    
    // 【拡張】個別のアクションを保持できるプロパティを追加
    public let onTapAction: (() -> Void)?
    
    // Equatable準拠のための比較定義（クロージャは比較不可のためIDのみで判定）
    public static func == (lhs: BasicToastInfo, rhs: BasicToastInfo) -> Bool {
        lhs.id == rhs.id
    }
}

/// パターンB：複数の詳細メッセージを内包できるリスト型のトースト
public struct MultipleToastInfo: ToastProtocol {
    public let id: UUID = .init()
    public let style: ToastStyle
    public let title: String
    public let detailMessages: [String]
    
    // 【拡張】個別のアクションを保持できるプロパティを追加
    public let onTapAction: (() -> Void)?
    
    // Equatable準拠のための比較定義
    public static func == (lhs: MultipleToastInfo, rhs: MultipleToastInfo) -> Bool {
        lhs.id == rhs.id
    }
}
