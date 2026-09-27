import SwiftUI

/// Small tinted label used for project, priority, and tags in task rows (styled after vimango).
struct TagBadge: View {
    let text: String
    let color: Color
    /// Draw the text in the badge color instead of secondary (used for priority).
    var tintedText = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(tintedText ? AnyShapeStyle(color) : AnyShapeStyle(.secondary))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            // vimango's 0.12 is too faint on the dark gray list.
            .background(color.opacity(colorScheme == .dark ? 0.25 : 0.12))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
