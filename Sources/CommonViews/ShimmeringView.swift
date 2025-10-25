//
//  SwiftUIView.swift
//  Common
//
//  Created by Eric Liu on 2/25/25.
//
#if DEBUG

import SwiftUI

public struct ShimmeringView: View {
    @State private var isAnimating = false
    private let color: Color
    
    public init() {
        self.color = .gray
    }
    
    public init(color: Color) {
        self.color = color
    }
    
    public var body: some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.2))
                .overlay(
                    LinearGradient(
                        gradient: Gradient(
                            colors: [
                                color.opacity(0),
                                color.opacity(0.6),
                                color.opacity(0)
                            ]
                        ),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.5)
                    .offset(x: isAnimating ? -geo.size.width * 0.25 : geo.size.width * 0.25)
                )
                .onAppear {
                    withAnimation(
                        Animation
                            .easeInOut(duration: 1)
                            .repeatForever(autoreverses: true)
                    ) {
                        isAnimating.toggle()
                    }
                }
        }
        .frame(height: 20)
    }
}

#Preview {
    ShimmeringView()
}

#endif
