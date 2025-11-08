//
//  PlusButtonWithShadow.swift
//  
//
//  Created by Eric Liu on 10/17/25.
//
import SwiftUI

public struct PlusButtonWithShadow: View {
    private let color: Color
    
    public init(color: Color = Color.blue) {
        self.color = color
    }
    
    public var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 50, height: 50)
                .opacity(0.75)
                .glassEffect()
                .shadow(radius: 2, x: 1, y: 1)
            Image(systemName: "plus")
                .font(.title.weight(.bold))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    PlusButtonWithShadow()
        .padding()
        .previewLayout(.sizeThatFits)
}
