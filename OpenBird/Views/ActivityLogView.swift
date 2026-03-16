import SwiftUI

struct ActivityLogView: View {
    let repo: Repository
    @State private var commits: [CommitRecord] = []

    var body: some View {
        VStack(alignment: .leading) {
            Text(repo.creatureName)
                .font(.headline)

            Text(repo.path)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            Divider()

            if commits.isEmpty {
                Text("No commits recorded yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                List(commits) { commit in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(commit.message)
                            .font(.body)
                            .lineLimit(2)

                        HStack {
                            Text(commit.author)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(commit.date, style: .relative)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding()
        .frame(minWidth: 300, minHeight: 200)
        .onAppear {
            commits = PersistenceService.shared.loadCommits(for: repo.id)
        }
    }
}
