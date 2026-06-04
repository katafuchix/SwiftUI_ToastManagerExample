//
//  MenuButton.swift
//  SwiftUI_ToastManagerExample
//
//  Created by cano on 2026/06/04.
//

import SwiftUI

struct MenuButton: View {
    let title: String
    let tint: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .menuButtonLabel()
        }
        .buttonStyle(.borderedProminent)
        .tint(tint)
    }
}

extension Text {
    func menuButtonLabel() -> some View {
        self
            .lineLimit(2)
            .font(.subheadline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
    }
}
