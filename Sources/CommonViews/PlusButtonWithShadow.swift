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
                .frame(width: 44, height: 44)
                .shadow(radius: 2, x: 2, y: 2)
            Image(systemName: "plus")
                .font(.title2.weight(.bold))
                .foregroundColor(.white)
        }
    }
}
