import SwiftUI

struct SettingsAccountTab: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                accountCard(
                    title: "Accounts may unlock optional sync and sharing later",
                    subtitle: "OpenBird works fully without an account today. This area is reserved for optional web features if they ship."
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        featureRow(
                            icon: "icloud",
                            title: "Sync your setup",
                            detail: "Use the same tank and layout across devices if optional sync ships in the future."
                        )
                        featureRow(
                            icon: "square.and.arrow.up",
                            title: "Share your setup",
                            detail: "Publish or share your tank state if OpenBird gets optional web features later on."
                        )
                        featureRow(
                            icon: "waveform",
                            title: "Jam is not gated here",
                            detail: "Jam Mode is now a local feature and is configured from the Jam tab."
                        )

                        Text("This section stays lightweight for now while these ideas remain future-facing.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(20)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Account", systemImage: "person.crop.circle")
                .font(.title2.weight(.semibold))

            Text("Accounts are optional future-facing features, not a requirement for local OpenBird features like Jam Mode.")
                .font(.callout)
                .foregroundColor(.secondary)
        }
    }

    private func accountCard<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.callout)
                .foregroundColor(.secondary)
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.secondary.opacity(0.08))
        )
    }

    private func featureRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.medium)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
