import SwiftUI

/// Small capsule marking the dev build, so it can't be confused with the App Store app.
/// Renders nothing unless the `TASKCHAMP_DEV` compilation condition is set.
struct DevBadge: View {
    var body: some View {
        #if TASKCHAMP_DEV
        Text("DEV")
            .font(.caption2)
            .bold()
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(.orange))
        #endif
    }
}
