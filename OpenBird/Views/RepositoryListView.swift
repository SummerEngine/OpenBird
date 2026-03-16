import SwiftUI

struct RepositoryListView: View {
    @ObservedObject var gitMonitor = GitMonitorService.shared
    @ObservedObject var lifecycle = CreatureLifecycleService.shared

    var body: some View {
        List {
            if gitMonitor.repositories.isEmpty {
                Text("No repositories added yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(gitMonitor.repositories) { repo in
                    repositoryRow(repo)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let repo = gitMonitor.repositories[index]
                        gitMonitor.removeRepository(repo.id)
                    }
                }
            }
        }
    }

    private func repositoryRow(_ repo: Repository) -> some View {
        let creature = lifecycle.creatures[repo.id]
        return NavigationLink(destination: ActivityLogView(repo: repo)) {
            HStack(spacing: 12) {
                // Status indicator
                Circle()
                    .fill(statusColor(creature))
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(repo.creatureName)
                        .fontWeight(.medium)
                    Text(repo.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let creature = creature {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(creature.totalCommitsFed) commits")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let lastFed = creature.lastFedDate {
                            Text(lastFed, style: .relative)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func statusColor(_ creature: Creature?) -> Color {
        guard let creature = creature, creature.isAlive else { return .gray }
        if creature.hunger > 0.7 { return .red }
        if creature.hunger > 0.4 { return .yellow }
        return .green
    }
}
