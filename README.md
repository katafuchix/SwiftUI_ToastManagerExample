# SwiftUI_ToastManagerExample

- 利用例
```
AppToastManager.shared.showBasic(
    style: .info,
    title: "システムメンテナンス通知",
    description: "タップすると、自動消去が一時停止し全ログが並びます。",
    position: .top,
    showOverlayBackground: true,
    onTapAction: nil 
)
```
