# CommonViews

A collection of reusable SwiftUI view components for iOS and macOS applications.

## Features

This package includes the following SwiftUI components:

- **AutoScrollingListView** - A list view that automatically scrolls to new items as they arrive from an AsyncStream, with gradient fade effects
- **CircularProgressButton** - A customizable button with circular progress indicator activated by long press
- **LoadingBubbleView** - An animated loading indicator with a spinning circular design
- **PlusButtonWithShadow** - A styled plus button with shadow effects
- **ShimmeringView** - A shimmering placeholder view for loading states (DEBUG only)

## Requirements

- iOS 18.0+ / macOS 14.0+
- Swift 6.2+
- Xcode 16.0+

## Installation

### Swift Package Manager

Add CommonViews to your project using Swift Package Manager:

1. In Xcode, select **File > Add Package Dependencies...**
2. Enter the repository URL:
   ```
   https://github.com/Ericliu001/ios-monorepo
   ```
3. Select the version or branch you want to use
4. Add the package to your target

Alternatively, add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Ericliu001/ios-monorepo", from: "1.0.0")
]
```

## Usage

### AutoScrollingListView

A list that automatically scrolls to display new items from an AsyncStream:

```swift
import CommonViews

let stream = AsyncStream<String> { continuation in
    Task {
        for i in 0..<100 {
            try? await Task.sleep(nanoseconds: 500_000_000)
            continuation.yield("Item \(i)")
        }
        continuation.finish()
    }
}

AutoScrollingListView(stream: stream)
    .frame(height: 150)
```

### CircularProgressButton

A button with a circular progress ring that fills during a long press:

```swift
import CommonViews

@State private var resetToggle = false

CircularProgressButton(
    resetToggle: $resetToggle,
    duration: .seconds(2),
    strokeWidth: 4,
    progressColor: .blue,
    completeColor: .green,
    onCompletion: {
        print("Action completed!")
    }
) { isCompleted in
    if isCompleted {
        Image(systemName: "checkmark")
    } else {
        Image(systemName: "hand.tap")
    }
}
.frame(width: 100, height: 100)
```

### LoadingBubbleView

An animated loading indicator:

```swift
import CommonViews

LoadingBubbleView(
    color: .blue,
    strokeLineWidth: 4
)
.frame(width: 60, height: 60)
```

### PlusButtonWithShadow

A styled plus button with drop shadow:

```swift
import CommonViews

Button {
    // Action
} label: {
    PlusButtonWithShadow(color: .blue)
}
```

### ShimmeringView

A shimmering placeholder for loading states (available in DEBUG builds only):

```swift
import CommonViews

ShimmeringView(color: .gray)
    .frame(height: 20)
```

## License

See [LICENSE](LICENSE) for details.

## Repository

This package is part of the [ios-monorepo](https://github.com/Ericliu001/ios-monorepo) project.
