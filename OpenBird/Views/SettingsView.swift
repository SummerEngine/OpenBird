import SwiftUI

struct SettingsView: View {
    @ObservedObject private var gitMonitor = GitMonitorService.shared
    @ObservedObject private var lifecycle = CreatureLifecycleService.shared
    @ObservedObject private var quests = QuestService.shared

    @State private var showingAddRepo = false
    @State private var selectedTab = 0
    @State private var expandedRepoID: UUID?

    var body: some View {
        TabView(selection: $selectedTab) {
            repositoriesTab
                .tabItem { Label("Repositories", systemImage: "folder") }
                .tag(0)

            questsTab
                .tabItem { Label("Quests", systemImage: "star") }
                .tag(1)

            SettingsPreferencesTab()
                .tabItem { Label("Preferences", systemImage: "gearshape") }
                .tag(2)

            SettingsJamTab()
                .tabItem { Label("Jam", systemImage: "waveform") }
                .tag(3)

            SettingsAccountTab()
                .tabItem { Label("Account", systemImage: "person.crop.circle") }
                .tag(4)

            SettingsRoadmapTab()
                .tabItem { Label("Roadmap", systemImage: "lightbulb") }
                .tag(5)
        }
        .frame(minWidth: 500, minHeight: 380)
        .sheet(isPresented: $showingAddRepo) {
            AddRepositoryView { repo in
                gitMonitor.addRepository(repo)
            }
        }
    }

    private var repositoriesTab: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Repositories")
                    .font(.headline)
                Spacer()
                Button(action: { showingAddRepo = true }) {
                    Image(systemName: "plus")
                }
                .help("Add a repository")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            if gitMonitor.repositories.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "bird")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No repositories yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Add a repository to meet your first friend")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Add Repository") { showingAddRepo = true }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 4)
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 1) {
                        ForEach(gitMonitor.repositories) { repo in
                            repoRow(repo)
                                .padding(.horizontal, 12)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private func repoRow(_ repo: Repository) -> some View {
        let creature = lifecycle.creatures[repo.id]
        let isExpanded = expandedRepoID == repo.id
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                // Color swatch
                Circle()
                    .fill(Color(nsColor: NSColor.fromHex(repo.color)))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(statusBorderColor(creature), lineWidth: 2)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(repo.creatureName)
                            .fontWeight(.medium)
                        if let creature = creature {
                            Text(creature.stage)
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.secondary.opacity(0.15))
                                .cornerRadius(3)
                        }
                    }
                    HStack(spacing: 4) {
                        Text(repo.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let creature = creature {
                            Text("--")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(creature.totalCommitsFed) commits")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if creature.currentStreak > 0 {
                                Image(systemName: "flame")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                                Text("\(creature.currentStreak)d")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }

                Spacer()

                if let creature = creature {
                    VStack(alignment: .trailing, spacing: 2) {
                        hungerBar(creature)
                        if let lastFed = creature.lastFedDate {
                            Text("Fed \(lastFed, style: .relative) ago")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Never fed")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Button(action: {
                    gitMonitor.removeRepository(repo.id)
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Remove repository")
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isExpanded ? Color.accentColor.opacity(0.08) : Color.clear)
            )
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedRepoID = isExpanded ? nil : repo.id
                }
            }

            // Expanded detail
            if isExpanded, let creature = creature {
                repoDetail(repo, creature: creature)
            }
        }
    }

    private func repoDetail(_ repo: Repository, creature: Creature) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()

            // Path
            HStack {
                Text("Path:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(repo.path)
                    .font(.caption)
                    .textSelection(.enabled)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            // Stats grid
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    statLabel("Total Commits", "\(creature.totalCommitsFed)")
                    statLabel("Happiness", String(format: "%.0f%%", creature.happiness * 100))
                    statLabel("Hunger", String(format: "%.0f%%", creature.hunger * 100))
                }
                VStack(alignment: .leading, spacing: 4) {
                    statLabel("Size", String(format: "%.2f", creature.size))
                    statLabel("Current Streak", "\(creature.currentStreak)d")
                    statLabel("Best Streak", "\(creature.longestStreak)d")
                }
            }

            // Evolution progress
            let (nextStage, threshold) = nextEvolutionStage(creature)
            if let nextStage = nextStage, let threshold = threshold {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(creature.stage) -> \(nextStage)")
                        .font(.caption)
                        .fontWeight(.medium)
                    HStack(spacing: 6) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.secondary.opacity(0.15))
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.accentColor.opacity(0.7))
                                    .frame(width: geo.size.width * evolutionFraction(creature, threshold: threshold))
                            }
                        }
                        .frame(height: 6)
                        Text("\(creature.totalCommitsFed)/\(threshold)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .trailing)
                    }
                }
            } else {
                Text("Max evolution reached")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }

            // Dates
            HStack(spacing: 16) {
                statLabel("Born", creature.birthDate.formatted(date: .abbreviated, time: .omitted))
                if let lastFed = creature.lastFedDate {
                    statLabel("Last Fed", lastFed.formatted(date: .abbreviated, time: .shortened))
                }
            }
        }
        .padding(.leading, 24)
        .padding(.vertical, 8)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func statLabel(_ label: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text(label + ":")
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption2)
                .fontWeight(.medium)
        }
    }

    private func nextEvolutionStage(_ creature: Creature) -> (String?, Int?) {
        let commits = creature.totalCommitsFed
        if commits < 10 { return ("Sprout", 10) }
        if commits < 50 { return ("Buddy", 50) }
        if commits < 200 { return ("Companion", 200) }
        if commits < 1000 { return ("Golden", 1000) }
        if commits < 10000 { return ("Legend", 10000) }
        return (nil, nil)
    }

    private func evolutionFraction(_ creature: Creature, threshold: Int) -> Double {
        let commits = creature.totalCommitsFed
        let prevThreshold: Int
        switch threshold {
        case 10: prevThreshold = 0
        case 50: prevThreshold = 10
        case 200: prevThreshold = 50
        case 1000: prevThreshold = 200
        case 10000: prevThreshold = 1000
        default: prevThreshold = 0
        }
        let progress = Double(commits - prevThreshold) / Double(threshold - prevThreshold)
        return min(1.0, max(0.0, progress))
    }

    private func hungerBar(_ creature: Creature) -> some View {
        let barColor: Color = creature.hunger > 0.7 ? .red : creature.hunger > 0.4 ? .yellow : .green
        return HStack(spacing: 4) {
            Text("Health")
                .font(.caption2)
                .foregroundColor(.secondary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.secondary.opacity(0.2))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor)
                        .frame(width: geo.size.width * (1.0 - creature.hunger))
                }
            }
            .frame(width: 60, height: 6)
        }
    }

    private func statusBorderColor(_ creature: Creature?) -> Color {
        guard let creature = creature, creature.isAlive else { return .gray }
        if creature.hunger > 0.7 { return .red }
        if creature.hunger > 0.4 { return .yellow }
        return .green
    }

    private var questsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !quests.activeQuests.isEmpty {
                    Text("Active Quests")
                        .font(.headline)
                        .padding(.bottom, 2)

                    ForEach(quests.activeQuests) { quest in
                        questRow(quest, completed: false)
                    }
                }

                if !quests.completedQuests.isEmpty {
                    Divider()
                        .padding(.vertical, 4)

                    Text("Completed")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    ForEach(quests.completedQuests) { quest in
                        questRow(quest, completed: true)
                    }
                }

                Divider()
                    .padding(.vertical, 8)

                evolutionGuide
            }
            .padding(20)
        }
    }

    private var evolutionGuide: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Evolution Guide")
                .font(.headline)
                .padding(.bottom, 2)

            evolutionStageRow("Seedling", "0-9 commits", "Your friend is just getting started")
            evolutionStageRow("Sprout", "10-49 commits", "Growing nicely")
            evolutionStageRow("Buddy", "50-199 commits", "A real companion")
            evolutionStageRow("Companion", "200-999 commits", "You've been through a lot together")
            evolutionStageRow("Golden", "1,000-9,999 commits", "An epic gold bird form")
            evolutionStageRow("Legend", "10,000+ commits", "A legendary companion")
        }
    }

    private func evolutionStageRow(_ stage: String, _ range: String, _ desc: String) -> some View {
        HStack(spacing: 8) {
            Text(stage)
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 80, alignment: .leading)
            Text(range)
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 90, alignment: .leading)
            Text(desc)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private func questRow(_ quest: Quest, completed: Bool) -> some View {
        let prog = quests.questProgress(
            quest,
            creatures: lifecycle.creatures,
            repoCount: gitMonitor.repositories.count
        )

        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                .foregroundColor(completed ? .green : .secondary)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(quest.title)
                    .fontWeight(.medium)
                    .strikethrough(completed)
                Text(quest.description)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if !completed {
                    // Progress bar
                    HStack(spacing: 6) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.secondary.opacity(0.15))
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.accentColor.opacity(0.7))
                                    .frame(width: geo.size.width * prog.fraction)
                            }
                        }
                        .frame(height: 6)

                        Text(prog.label)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .trailing)
                    }
                }

                Text(quest.rewardDescription)
                    .font(.caption2)
                    .foregroundColor(.accentColor)
                    .italic()
            }
        }
        .padding(.vertical, 2)
        .opacity(completed ? 0.6 : 1.0)
    }
}
