import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif

// MARK: - Confetti Piece Model
struct ConfettiPiece: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var rotation: Double
    var rotation3D: Double
    var scale: CGFloat
    var opacity: Double
    var color: Color
    var shape: ConfettiShape
    var velocityX: CGFloat
    var velocityY: CGFloat
    var angularVelocity: Double
    var angularVelocity3D: Double
    var axisX: CGFloat
    var axisY: CGFloat
    var axisZ: CGFloat
}

enum ConfettiShape {
    case ellipse
    case square
    case triangle
    case rectangle
    case star

    @ViewBuilder
    func view(color: Color, size: CGFloat) -> some View {
        switch self {
        case .ellipse:
            Ellipse()
                .fill(color)
                .frame(width: size, height: size)
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
        case .star:
            Star()
                .fill(color)
                .frame(width: size, height: size)
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

struct Star: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.4
        let numberOfPoints = 5

        for i in 0..<numberOfPoints * 2 {
            let angle = CGFloat(i) * .pi / CGFloat(numberOfPoints) - .pi / 2
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

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
    let enableHaptics: Bool
    let enableSound: Bool

    init(
        toggle: Binding<Bool>,
        intensity: Int = 50,
        colors: [Color] = [
            .red, .orange, .yellow, .green, .blue, .purple, .pink
        ],
        enableHaptics: Bool = true,
        enableSound: Bool = true
    ) {
        self._toggle = toggle
        self.intensity = intensity
        self.colors = colors
        self.enableHaptics = enableHaptics
        self.enableSound = enableSound
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(pieces) { piece in
                    piece.shape.view(color: piece.color, size: 10 * piece.scale)
                        .rotation3DEffect(
                            .degrees(piece.rotation3D),
                            axis: (x: piece.axisX, y: piece.axisY, z: piece.axisZ)
                        )
                        .rotationEffect(Angle.degrees(piece.rotation))
                        .opacity(piece.opacity)
                        .position(x: piece.x, y: piece.y)
                }
            }
            .onChange(of: toggle) { _, _ in
                startConfetti(in: geometry.size)
            }
            .onDisappear {
                stopConfetti()
            }
        }
        .allowsHitTesting(false)
    }

    private func startConfetti(in size: CGSize) {
        stopConfetti()
        triggerLaunchFeedback()
        // Generate initial confetti pieces
        pieces = (0..<intensity).map { _ in
            createConfettiPiece(in: size)
        }

        // Animate confetti
        animationTimer = Timer
            .scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
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
            stopConfetti()
        }
    }

    private func stopConfetti() {
        animationTimer?.invalidate()
        animationTimer = nil
        pieces.removeAll()
    }

    private func triggerLaunchFeedback() {
        triggerHaptic()
        playLaunchSound()
    }

#if canImport(UIKit)
    private func triggerHaptic() {
        guard enableHaptics else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
#else
    private func triggerHaptic() {}
#endif

    private func playLaunchSound() {
        guard enableSound else { return }
#if canImport(AudioToolbox)
        AudioServicesPlaySystemSound(1030) // 1030 | Sherwood_Forest.caf   
#endif
    }

    private func createConfettiPiece(in size: CGSize) -> ConfettiPiece {
        let startX = CGFloat.random(
            in: -(size.width * 0.1)...(size.width * 1.1)
        )
        let startY = CGFloat.random(in: -(size.height * 0.25)...0)
        let axis = randomAxis()

        return ConfettiPiece(
            x: startX,
            y: startY,
            rotation: Double.random(in: 0...360),
            rotation3D: Double.random(in: 0...360),
            scale: CGFloat.random(in: 0.5...1.5),
            opacity: 1.0,
            color: colors.randomElement() ?? .blue,
            shape: [.ellipse, .square, .triangle, .rectangle, .star]
                .randomElement() ?? .triangle,
            velocityX: CGFloat.random(in: -1...1),
            velocityY: CGFloat.random(in: 0.25...3),
            angularVelocity: Double.random(in: -10...10),
            angularVelocity3D: Double.random(in: -20...20),
            axisX: axis.x,
            axisY: axis.y,
            axisZ: axis.z
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
            newPiece.rotation3D += piece.angularVelocity3D

            // Apply gravity
            newPiece.velocityY += 0.1

            // Fade out as it falls
            if newPiece.y > size.height * 0.7 {
                newPiece.opacity -= 0.02
            }

            return newPiece
        }
    }

    private func randomAxis() -> (x: CGFloat, y: CGFloat, z: CGFloat) {
        var axis: (x: CGFloat, y: CGFloat, z: CGFloat)
        repeat {
            axis = (
                x: CGFloat.random(in: -1...1),
                y: CGFloat.random(in: -1...1),
                z: CGFloat.random(in: -1...1)
            )
        } while axis.x == 0 && axis.y == 0 && axis.z == 0

        let magnitude = max(
            (axis.x * axis.x + axis.y * axis.y + axis.z * axis.z).squareRoot(),
            0.001
        )

        return (
            x: axis.x / magnitude,
            y: axis.y / magnitude,
            z: axis.z / magnitude
        )
    }
}

// MARK: - Confetti Modifier
struct ConfettiModifier: ViewModifier {
    let toggle: Binding<Bool>
    let intensity: Int
    let colors: [Color]
    let enableHaptics: Bool
    let enableSound: Bool

    func body(content: Content) -> some View {
        content
            .overlay(
                ConfettiView(
                    toggle: toggle,
                    intensity: intensity,
                    colors: colors,
                    enableHaptics: enableHaptics,
                    enableSound: enableSound
                )
            )
    }
}

public extension View {
    /// Displays confetti effect over the view
    /// - Parameters:
    ///   - toggle: Binding that triggers the confetti when set to `true`
    ///   - intensity: Number of confetti pieces (default: 100)
    ///   - colors: Array of colors to use (default: rainbow colors)
    ///   - enableHaptics: Whether to play a success haptic when confetti starts
    ///   - enableSound: Whether to play a celebration sound when confetti starts
    func confetti(
        toggle: Binding<Bool>,
        intensity: Int = 100,
        colors: [Color] = [
            .red,
            .orange,
            .yellow,
            .green,
            .blue,
            .purple,
            .pink
        ],
        enableHaptics: Bool = true,
        enableSound: Bool = true
    ) -> some View {
        modifier(
            ConfettiModifier(
                toggle: toggle,
                intensity: intensity,
                colors: colors,
                enableHaptics: enableHaptics,
                enableSound: enableSound
            )
        )
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
        .confetti(toggle: $showConfetti, intensity: 250)
    }

}

// MARK: - Custom Colors Example
struct CustomColorConfettiExample: View {
    @State private var showConfetti = false

    var body: some View {
        VStack {
            Spacer()
            Text("Custom Colors")
                .font(.title)

            Button("Show Green & Gold Confetti") {
                showConfetti.toggle()
            }
            .buttonStyle(.borderedProminent)
        }
        .confetti(
            toggle: $showConfetti,
            intensity: 175,
            colors: [.green, .yellow, .mint, .teal]
        )
    }

}

// MARK: - Task Completion Example
struct TaskCompletionExample: View {
    @State private var isCompleted = false
    @State private var showConfetti = false

    var body: some View {
        VStack {
            Spacer()
            Text("Complete Task")
                .font(.title2)

            Button {
                isCompleted.toggle()
                if isCompleted {
                    showConfetti.toggle()
                }
            } label: {
                HStack {
                    Image(
                        systemName: isCompleted ? "checkmark.circle.fill" : "circle"
                    )
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
