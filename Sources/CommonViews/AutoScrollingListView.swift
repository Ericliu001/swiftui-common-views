//
//  SwiftUIView.swift
//  Common
//
//  Created by Eric Liu on 2/28/25.
//

import SwiftUI

public struct AutoScrollingListView: View {
    @State private var items: [String] = [""]
    private let stream: AsyncStream<String>
    
    public init(stream: AsyncStream<String>) {
        self.stream = stream
    }

    public var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(items.indices, id: \.self) { index in
                    Text(items[index])
                        .frame(maxWidth: .infinity, alignment: .center)
                        .id(index)
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(PlainListStyle())
            .onChange(of: items.count) { _, _ in
                if let lastIndex = items.indices.last {
                    withAnimation(.smooth) {
                        proxy.scrollTo(lastIndex, anchor: .bottom)
                    }
                }
            }
        }
        .mask(gradientMask)
        .task {
            for await item in stream {
                self.items.append(item)
            }
            
            items.removeAll()
        }
    }
    
    private var gradientMask: some View {
        LinearGradient(
            gradient: Gradient(
                colors: [
                    Color.white.opacity(0),
                    Color.white.opacity(0.6),
                    Color.white.opacity(0)
                ]
            ),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview {
    {
        let stream = AsyncStream<String> { continuation in
            Task {
                for i in 0..<100 {
                    try? await Task
                        .sleep(nanoseconds: 100_000_000) // 0.5 seconds
                    continuation.yield("Item \(i)")
                }
                continuation.finish()
            }
        }
        
        return AutoScrollingListView(stream: stream).frame(height: 150)
    }()
}
