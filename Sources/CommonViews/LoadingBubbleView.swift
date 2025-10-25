//
//  LoadingBubbleView.swift
//  BuddyGo
//
//  Created by Eric Liu on 7/1/24.
//

import SwiftUI

public struct LoadingBubbleView: View {
    @State private var isAnimating = false
    private let color: Color
    var strokeLineWidth: CGFloat
    
    public init(color: Color = Color.gray, strokeLineWidth: CGFloat = 4) {
        self.color = color
        self.strokeLineWidth = strokeLineWidth
    }

    public var body: some View {
        HStack {
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(color, lineWidth: strokeLineWidth)
                .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
                .onAppear {
                    isAnimating = true
                }
                .padding()
                .background(color.opacity(0.2))
        }
        .cornerRadius(16)
    }
}

#Preview {
    LoadingBubbleView()
}
