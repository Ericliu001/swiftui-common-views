//
//  ToastView.swift
//
//  Created by Codex on 11/18/24.
//

import SwiftUI

/// Describes the presentation and styling of a toast.
public struct ToastConfiguration {
    public enum Placement {
        case top
        case center
        case bottom
    }

    public var message: String
    public var systemImageName: String?
    public var duration: TimeInterval
    public var backgroundColor: Color
    public var foregroundColor: Color
    public var placement: Placement
    public var padding: EdgeInsets?

    public init(
        message: String,
        systemImageName: String? = nil,
        duration: TimeInterval = 2.0,
        backgroundColor: Color = .black.opacity(0.8),
        foregroundColor: Color = .white,
        placement: Placement = .top,
        padding: EdgeInsets? = nil
    ) {
        self.message = message
        self.systemImageName = systemImageName
        self.duration = duration
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.placement = placement
        self.padding = padding
    }
}

/// Renders the toast content.
public struct ToastView: View {
    private let configuration: ToastConfiguration

    public init(configuration: ToastConfiguration) {
        self.configuration = configuration
    }

    public var body: some View {
        HStack(spacing: 8) {
            if let systemImageName = configuration.systemImageName {
                Image(systemName: systemImageName)
                    .imageScale(.medium)
            }

            Text(configuration.message)
                .font(.callout)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .foregroundColor(configuration.foregroundColor)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(configuration.backgroundColor)
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
    }
}

/// Presents a toast using a boolean trigger. Flip the trigger value to display the toast.
public struct ToastModifier: ViewModifier {
    private let toggle: Bool
    private let configuration: ToastConfiguration
    private let onDismiss: (() -> Void)?

    @State private var isPresented: Bool = false
    @State private var dismissTask: Task<Void, Never>?

    public init(
        toggle: Bool,
        configuration: ToastConfiguration,
        onDismiss: (() -> Void)? = nil
    ) {
        self.toggle = toggle
        self.configuration = configuration
        self.onDismiss = onDismiss
    }

    public func body(content: Content) -> some View {
        content
            .onChange(of: toggle) { _, newValue in
                presentToast()
            }
            .overlay(alignment: toastAlignment) {
                Group {
                    if isPresented {
                        ToastView(configuration: configuration)
                            .padding(toastPadding)
                            .transition(toastTransition)
                            .onDisappear(perform: cancelDismiss)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isPresented)
    }

    private var toastAlignment: Alignment {
        switch configuration.placement {
        case .top:
            return .top
        case .center:
            return .center
        case .bottom:
            return .bottom
        }
    }

    private var toastPadding: EdgeInsets {
        switch configuration.placement {
        case .top:
            if let padding = configuration.padding {
                return padding
            }
            return EdgeInsets(top: 32, leading: 16, bottom: 0, trailing: 16)
        case .center:
            if let padding = configuration.padding {
                return padding
            }
            return EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        case .bottom:
            if let padding = configuration.padding {
                return padding
            }
            return EdgeInsets(top: 0, leading: 16, bottom: 32, trailing: 16)
        }
    }

    private var toastTransition: AnyTransition {
        switch configuration.placement {
        case .top:
            return AnyTransition.move(edge: .top).combined(with: .opacity)
        case .center:
            return AnyTransition.opacity
        case .bottom:
            return AnyTransition.move(edge: .bottom).combined(with: .opacity)
        }
    }

    private func presentToast() {

        withAnimation {
            isPresented = true
        }

        scheduleDismiss()
    }

    private func scheduleDismiss() {
        cancelDismiss()
        
        guard configuration.duration > 0 else { return }

        let duration = configuration.duration

        dismissTask = Task {
            do {
                try await Task.sleep(for: .seconds(duration))
            } catch {
                return
            }

            guard !Task.isCancelled else { return }

            await MainActor.run {
                completeDismiss()
            }
        }
    }

    private func cancelDismiss() {
        dismissTask?.cancel()
        dismissTask = nil
    }

    @MainActor
    private func completeDismiss() {
        guard isPresented else {
            dismissTask = nil
            return
        }

        withAnimation {
            isPresented = false
        }
        dismissTask = nil

        onDismiss?()
    }
}

public extension View {
    /// Presents a toast controlled by a boolean trigger. Change the trigger's value to display the toast.
    func toast(
        toggle: Bool,
        configuration: ToastConfiguration,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        modifier(
            ToastModifier(
                toggle: toggle,
                configuration: configuration,
                onDismiss: onDismiss
            )
        )
    }

    /// Convenience overload for constructing a toast configuration inline.
    func toast(
        toggle: Bool,
        message: String,
        systemImageName: String? = nil,
        duration: TimeInterval = 2.0,
        backgroundColor: Color = .black.opacity(0.8),
        foregroundColor: Color = .white,
        placement: ToastConfiguration.Placement = .top,
        padding: EdgeInsets? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        let configuration = ToastConfiguration(
            message: message,
            systemImageName: systemImageName,
            duration: duration,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            placement: placement,
            padding: padding
        )

        return toast(
            toggle: toggle,
            configuration: configuration,
            onDismiss: onDismiss
        )
    }
}
