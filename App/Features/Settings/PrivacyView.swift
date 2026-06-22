import SwiftUI

/// Plain-language, in-app explanation of how the app handles data.
/// Mirrors the audited reality: everything stays on the device.
struct PrivacyView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Your data never leaves this device", systemImage: "lock.shield")
                        .font(.headline)
                    Text("Everything you log is stored only on your iPhone. There is no account, no sign-in, and the app makes no internet connections.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("What we do") {
                PrivacyRow(icon: "iphone", title: "Store on device",
                           detail: "Your logs live in a private database on this iPhone, inside the app's sandbox.")
                PrivacyRow(icon: "person.crop.circle.badge.xmark", title: "No account",
                           detail: "No email, no password, no profile. Nothing identifies you.")
                PrivacyRow(icon: "hand.raised", title: "You're in control",
                           detail: "You can edit or delete any entry at any time. Deleting the app removes all of its data.")
            }

            Section("What we never do") {
                PrivacyRow(icon: "wifi.slash", title: "No network requests",
                           detail: "The app sends nothing over the internet — there is no server to send it to.")
                PrivacyRow(icon: "icloud.slash", title: "No cloud or sync",
                           detail: "Your data is not uploaded, backed up to our servers, or synced anywhere.")
                PrivacyRow(icon: "chart.bar.xmark", title: "No analytics or tracking",
                           detail: "No usage analytics, no advertising, no third-party SDKs, no tracking of any kind.")
                PrivacyRow(icon: "shippingbox", title: "No third parties",
                           detail: "Nothing is shared with or sold to anyone. There are no outside services involved.")
            }

            Section {
                Text("This app is for personal logging only. It is not a medical device and does not provide medical advice, fertility, or contraception guidance.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PrivacyRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.callout.weight(.semibold))
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack { PrivacyView() }
}
