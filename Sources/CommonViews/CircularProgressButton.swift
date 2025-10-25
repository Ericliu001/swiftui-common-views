//
//  CircularProgressButton.swift
//  Common
//
//  Created by Eric Liu on 9/25/25.
//

import SwiftUI

private extension Duration {
    var asSeconds: Double {
        let comps = self.components
        return Double(comps.seconds) + Double(
            comps.attoseconds
        ) / 1_000_000_000_000_000_000
    }
}

public struct CircularProgressButton<Content: View>: View {
    @State private var progressValue: Double = 0.0
    @State private var isPressed: Bool = false
    @State private var isCompleted: Bool = false
    @State private var task: Task<Void, Never>?
    @Binding private var resetToggle: Bool
    
    private let onCompletion: () -> Void
    private let duration: Duration
    private let strokeWidth: CGFloat
    private let progressColor: Color
    private let completeColor: Color
    private let backgroundColor: Color
    private let content: (_ isCompleted: Bool) -> Content
    private let divideCount: Double = 180

    public init(
        resetToggle: Binding<Bool> = .constant(false),
        duration: Duration = .seconds(3),
        strokeWidth: CGFloat = 4,
        progressColor: Color = .accentColor,
        completeColor: Color  = .green,
        backgroundColor: Color = .white,
        onCompletion: @escaping () -> Void,
        @ViewBuilder content: @escaping (_ isCompleted: Bool) -> Content
    ) {
        self.onCompletion = onCompletion
        self.duration = duration
        self.strokeWidth = strokeWidth
        self.progressColor = progressColor
        self.completeColor = completeColor
        self.backgroundColor = backgroundColor
        self.content = content
        self._resetToggle = resetToggle
    }

    public var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                // Base circle
                Circle()
                    .fill(backgroundColor)
                    .background(.regularMaterial, in: Circle())
                
                // Progress ring background
                Circle()
                    .stroke(progressColor.opacity(0.2), lineWidth: strokeWidth)
                    .frame(
                        width: size - strokeWidth,
                        height: size - strokeWidth
                    )
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: isCompleted ? 1 :  progressValue)
                    .stroke(
                        isCompleted ? completeColor : progressColor,
                        style: StrokeStyle(
                            lineWidth: strokeWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90)) // Start from top
                    .frame(
                        width: size - strokeWidth,
                        height: size - strokeWidth
                    )
                    .animation(.linear(duration: 0.16), value: progressValue)
                
                Group {
                    if isCompleted {
                        content(true)
                    } else {
                        content(false)
                    }
                }
                .frame(width: size * 0.9, height: size * 0.9)
                .foregroundColor(
                    isCompleted ? completeColor : progressColor
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
                
            }
            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2) // Drop shadow.
            .scaleEffect(isPressed ? 0.95 : 1)
            .animation(
                .spring(response: 0.2, dampingFraction: 0.7),
                value: isPressed
            )
            .onChange(of: resetToggle) {_, _ in
                withAnimation{
                    isCompleted = false
                }
                print("Has been reset: \(resetToggle)")
            }
            .onLongPressGesture(
                minimumDuration: duration.asSeconds,
                maximumDistance: 50
            ) {
                isCompleted = true
                self.progressValue = 0
                self.onCompletion()
                print("Long pressed \(duration.asSeconds)")
                
            } onPressingChanged: { pressing in
                isPressed = pressing
                task?.cancel()
                
                if pressing && !isCompleted {
                    task = Task {
                        var localProgressValue: Double = 0.0
                        while !Task.isCancelled && localProgressValue < 1.0 {
                            try? await Task.sleep(for: duration/divideCount)
                            localProgressValue += 1.0 / divideCount
                            await MainActor.run {
                                self.progressValue = localProgressValue
                            }
                        }
                        
                        await MainActor.run {
                            // Reset progress value
                            self.progressValue = 0
                        }
                    }
                }
            }
        }
        .onDisappear {
            task?.cancel()
        }
    }
}

#if DEBUG
struct CircularProgressButtonPreviewHost: View {
    @State private var reset = false

    var body: some View {
        VStack(spacing: 40) {
            CircularProgressButton(
                resetToggle: $reset,
                duration: .seconds(1.5), onCompletion: {
                    print("Completed!")
                }) { isCompleted in
                    if isCompleted {
                        Button(action: {
                            reset.toggle()
                            print("Reset init!")
                        }) {
                            Text("Done")
                        }
                    } else {
                        Text("Tap me!")
                    }
                }

            CircularProgressButton(
                resetToggle: $reset,
                strokeWidth: 16,
                progressColor: .blue,
                onCompletion: {
                    print("Completed!")
                }) { isCompleted in
                    if isCompleted {
                        Button(action: {
                            reset.toggle()
                            print("Reset init!")
                        }) {
                            Image(systemName: "checkmark")
                        }
                    } else {
                        Image(systemName: "hand.tap")
                    }
                }
        }
        .padding(100)
        
        
    }
}

#Preview {
    CircularProgressButtonPreviewHost()
}
#endif


