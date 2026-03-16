import SwiftUI

struct SettingsAccountTab: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                accountCard(
                    title: "Accounts are for web sync and sharing later",
                    subtitle: "This area is reserved for hosted features like saving your tank or sharing your setup on the website."
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        featureRow(
                            icon: "icloud",
                            title: "Save your tank to the web",
                            detail: "Use the same tank and layout across devices once hosted sync is ready."
                        )
                        featureRow(
                            icon: "square.and.arrow.up",
                            title: "Share your window setup",
                            detail: "Publish or share your tank state from the hosted website when that ships."
                        )
                        featureRow(
                            icon: "waveform",
                            title: "Jam is not gated here",
                            detail: "Jam Mode is now a local feature and is configured from the Jam tab."
                        )

                        Text("This section is intentionally lightweight right now so it does not conflict with future backend-auth work.")
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

            Text("Accounts are for future hosted features, not for turning on local Jam Mode.")
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
