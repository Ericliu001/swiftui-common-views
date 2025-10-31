import SwiftUI

// MARK: - Confetti Piece Model
struct ConfettiPiece: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var rotation: Double
    var scale: CGFloat
    var opacity: Double
    var color: Color
    var shape: ConfettiShape
    var velocityX: CGFloat
    var velocityY: CGFloat
    var angularVelocity: Double
}

enum ConfettiShape {
    case circle
    case square
    case triangle
    case rectangle

    @ViewBuilder
    func view(color: Color, size: CGFloat) -> some View {
        switch self {
        case .circle:
            Ellipse()
                .fill(color)
                .frame(width: size * 0.5, height: size)
        case .square:
            Rectangle()
                .fill(color)
                .frame(width: size, height: size)
        case .triangle:
            Triangle()
                .fill(color)
                .frame(width: size, height: size)
        case .rectangle:
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: size, height: size * 0.6)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var pieces: [ConfettiPiece] = []
    @State private var animationTimer: Timer?
    @Binding private var toggle: Bool

    let intensity: Int
    let colors: [Color]

    init(toggle: Binding<Bool>, intensity: Int = 50, colors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink
    ]) {
        self._toggle = toggle
        self.intensity = intensity
        self.colors = colors
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(pieces) { piece in
                    piece.shape.view(color: piece.color, size: 10 * piece.scale)
                        .rotationEffect(Angle.degrees(piece.rotation))
                        .opacity(piece.opacity)
                        .position(x: piece.x, y: piece.y)
                }
            }
            .onChange(of: toggle) { _, _ in
                startConfetti(in: geometry.size)
            }
            .onDisappear {
                animationTimer?.invalidate()
            }
        }
        .allowsHitTesting(false)
    }

    private func startConfetti(in size: CGSize) {
        animationTimer?.invalidate()
        // Generate initial confetti pieces
        pieces = (0..<intensity).map { _ in
            createConfettiPiece(in: size)
        }

        // Animate confetti
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            Task { @MainActor in
                updateConfetti(in: size)
                checkIfAllPiecesOffScreen(in: size)
            }
        }
    }

    private func checkIfAllPiecesOffScreen(in size: CGSize) {
        // Check if all pieces are off screen (below the bottom or faded out)
        let allOffScreen = pieces.allSatisfy { piece in
            piece.y > size.height || piece.opacity <= 0
        }

        if allOffScreen {
            animationTimer?.invalidate()
            pieces.removeAll()
        }
    }

    private func createConfettiPiece(in size: CGSize) -> ConfettiPiece {
        let startX = CGFloat.random(in: 0...size.width)
        let startY = CGFloat.random(in: -50...0)

        return ConfettiPiece(
            x: startX,
            y: startY,
            rotation: Double.random(in: 0...360),
            scale: CGFloat.random(in: 0.5...1.5),
            opacity: 1.0,
            color: colors.randomElement() ?? .blue,
            shape: [ConfettiShape.circle, .square, .triangle, .rectangle].randomElement() ?? .triangle,
            velocityX: CGFloat.random(in: -2...2),
            velocityY: CGFloat.random(in: 1...5),
            angularVelocity: Double.random(in: -10...10)
        )
    }

    private func updateConfetti(in size: CGSize) {
        pieces = pieces.map { piece in
            var newPiece = piece

            // Update position
            newPiece.x += piece.velocityX
            newPiece.y += piece.velocityY

            // Update rotation
            newPiece.rotation += piece.angularVelocity

            // Apply gravity
            newPiece.velocityY += 0.2

            // Fade out as it falls
            if newPiece.y > size.height * 0.7 {
                newPiece.opacity -= 0.02
            }

            return newPiece
        }
    }
}

// MARK: - Confetti Modifier
struct ConfettiModifier: ViewModifier {
    let toggle: Binding<Bool>
    let intensity: Int
    let colors: [Color]

    func body(content: Content) -> some View {
        content
            .overlay(
                ConfettiView(toggle: toggle, intensity: intensity, colors: colors)
            )
    }
}

extension View {
    /// Displays confetti effect over the view
    /// - Parameters:
    ///   - isActive: Whether to show the confetti
    ///   - intensity: Number of confetti pieces (default: 50)
    ///   - colors: Array of colors to use (default: rainbow colors)
    func confetti(
        toggle: Binding<Bool>,
        intensity: Int = 100,
        colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    ) -> some View {
        modifier(ConfettiModifier(toggle: toggle, intensity: intensity, colors: colors))
    }
}


#if DEBUG
import SwiftUI

/// Example usage of the Confetti effect in different scenarios
struct ConfettiExamples: View {
    @State private var showConfetti = false

    var body: some View {
        VStack(spacing: 30) {
            Text("Confetti Examples")
                .font(.largeTitle)
                .bold()

            // Example 1: Basic button trigger
            Button("Celebrate!") {
                showConfetti.toggle()
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
        .confetti(toggle: $showConfetti)
    }

}

// MARK: - Custom Colors Example
struct CustomColorConfettiExample: View {
    @State private var showConfetti = false

    var body: some View {
        VStack {
            Text("Custom Colors")
                .font(.title)

            Button("Show Green & Gold Confetti") {
                showConfetti.toggle()
            }
            .buttonStyle(.borderedProminent)
        }
        .confetti(
            toggle: $showConfetti,
            intensity: 75,
            colors: [.green, .yellow, .mint, .teal]
        )
    }

}

// MARK: - Task Completion Example
struct TaskCompletionExample: View {
    @State private var isCompleted = false
    @State private var showConfetti = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Complete Task")
                .font(.title2)

            Button {
                isCompleted.toggle()
                if isCompleted {
                    showConfetti.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    Text(isCompleted ? "Task Completed!" : "Complete Task")
                }
                .foregroundColor(isCompleted ? .green : .primary)
            }
            .buttonStyle(.bordered)
        }
        .confetti(toggle: $showConfetti)
    }

}

// MARK: - Preview
#Preview("Basic") {
    ConfettiExamples()
}

#Preview("Custom Colors") {
    CustomColorConfettiExample()
}

#Preview("Task Completion") {
    TaskCompletionExample()
}


#endif
