import SwiftUI

extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

public extension View {
    func onFirstAppear(perform action: @escaping () -> Void) -> some View {
        modifier(ViewFirstAppearModifier(perform: action))
    }
}

struct ViewFirstAppearModifier: ViewModifier {
    @State private var didAppearBefore = false
    private let action: () -> Void

    init(perform action: @escaping () -> Void) {
        self.action = action
    }

    func body(content: Content) -> some View {
        content.onAppear {
            guard !didAppearBefore else { return }
            didAppearBefore = true
            action()
        }
    }
}

public extension View {
    /// Makes Return in a multi-line text field end editing instead of adding a
    /// line. A `TextField(axis: .vertical)` puts Return's newline into the
    /// text, so it is taken out here. Task descriptions and the command line
    /// are single lines in Taskwarrior. Newlines in pasted text become spaces.
    func returnEndsEditing(_ text: Binding<String>, perform action: @escaping () -> Void) -> some View {
        submitLabel(.done)
            .onChange(of: text.wrappedValue) { _, newValue in
                guard newValue.contains(where: \.isNewline) else {
                    return
                }
                text.wrappedValue = newValue.split(whereSeparator: \.isNewline).joined(separator: " ")
                action()
            }
    }
}
