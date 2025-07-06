//
//  PressAnimationModifier.swift
//  FillarGym
//
//  Created by 浜崎大輔 on 2025/07/06.
//

import SwiftUI

// MARK: - Press Animation Modifier
struct PressAnimationModifier: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .pressEvents(
                onPress: { isPressed = true },
                onRelease: { isPressed = false }
            )
            .animation(DesignSystem.Animation.quick, value: isPressed)
    }
}

extension View {
    func pressAnimation() -> some View {
        modifier(PressAnimationModifier())
    }
}