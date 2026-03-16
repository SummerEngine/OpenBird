import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var gitMonitor = GitMonitorService.shared
    @ObservedObject var lifecycle = CreatureLifecycleService.shared
    @ObservedObject var quests = QuestService.shared
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

            preferencesTab
                .tabItem { Label("Preferences", systemImage: "gearshape") }
                .tag(2)

            roadmapTab
                .tabItem { Label("Roadmap", systemImage: "lightbulb") }
                .tag(3)
        }
        .frame(minWidth: 500, minHeight: 380)
        .sheet(isPresented: $showingAddRepo) {
            AddRepositoryView { repo in
                gitMonitor.addRepository(repo)
            }
        }
    }

    // MARK: - Repositories Tab

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
        if commits < 1000 { return ("Sage", 1000) }
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

    // MARK: - Quests Tab

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
            evolutionStageRow("Sage", "1000+ commits", "A wise old friend")
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

    // MARK: - Preferences Tab

    private var preferencesTab: some View {
        Form {
            Section("General") {
                Toggle("Show window on launch", isOn: $settings.showOnLaunch)
                Toggle("Play sounds on commit", isOn: $settings.enableSounds)
                Toggle("Show friend names", isOn: $settings.showCreatureNames)
                Toggle("Show on all Spaces", isOn: $settings.followAcrossSpaces)
                    .help("Keep the tank visible when switching between macOS Spaces")
            }

            Section("Friends") {
                HStack {
                    Text("Movement speed")
                    Slider(value: $settings.movementSpeed, in: 0.3...2.5, step: 0.1)
                    Text(String(format: "%.1fx", settings.movementSpeed))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 35)
                }
                Text("Commits grow your friends over time. Manual feeding only gives them a small happiness boost.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("World") {
                Picker("Mode", selection: $settings.currentGameMode) {
                    ForEach(GameModeID.allCases) { mode in
                        Label(mode.displayName, systemImage: mode.iconName)
                            .tag(mode.rawValue)
                    }
                }
                Text(modeDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Toggle("Show window border", isOn: $settings.showWindowBorder)
                Toggle("Ambient effects", isOn: $settings.showAmbientEffects)
                    .help("Bubbles in Aquarium, breeze lines in Aviary")
                Picker("Backdrop", selection: $settings.sceneBackgroundStyle) {
                    Text("Themed").tag("themed")
                    Text("Night").tag("night")
                    Text("Clear").tag("clear")
                }
                Text("Backdrop and effects adapt to the selected world.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Keyboard Shortcut") {
                Text("Cmd+Shift+T to toggle window")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }

            Section("About") {
                HStack {
                    Text("OpenBird")
                        .fontWeight(.medium)
                    Text("v1.0")
                        .foregroundColor(.secondary)
                }
                Text("Your repos, alive.")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Roadmap Tab

    private var roadmapTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Roadmap")
                    .font(.headline)
                    .padding(.bottom, 4)

                ideaRow("bird", "More Worlds", "Expand beyond aquarium and aviary into new habitats with their own art, behaviors, and commit reactions.")
                ideaRow("cursorarrow.click.2", "Click Actions", "Bind what happens when you click a friend. Open a URL, launch your editor to the latest commit, open Claude Code.")
                ideaRow("message", "Talk to Your Friends", "Send messages to friends via MCP. They relay prompts to Cursor, Claude Code, or any connected agent.")
                ideaRow("network", "Orchestrator Mode", "Your friends become workers. Assign tasks, watch them build. Like Warcraft peons for your codebase.")
                ideaRow("cube", "3D Rendering", "Switch from 2D SpriteKit to SceneKit or Metal for a 3D terrarium/vivarium experience.")
                ideaRow("paintpalette", "Customization", "Custom colors, species based on primary language, name plates, accessories.")
                ideaRow("speaker.wave.2", "Sound Packs", "Different sound effects per game mode. Aquarium bubbles, bird chirps, orc grunts.")
                ideaRow("globe", "Leaderboard", "Compare your feeding streaks with friends. Longest-living friend wins.")
                ideaRow("arrow.triangle.branch", "Branch Awareness", "Friends react differently to main vs feature branches. Merge = celebration.")
                ideaRow("person.2", "Multi-user", "See teammates' friends in a shared pond. Social coding visualization.")
                ideaRow("arrow.up.circle", "Evolution", "Friends evolve through stages based on commit milestones. Visual transformations at each tier.")
                ideaRow("tshirt", "Wearables", "Earn cosmetic items for your friends by completing quests. Hats, accessories, effects.")
            }
            .padding(20)
        }
    }

    private func ideaRow(_ icon: String, _ title: String, _ description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private var modeDescription: String {
        switch GameModeID(rawValue: settings.currentGameMode) ?? .fish {
        case .fish:
            return "Aquarium keeps the friends in water, with calmer swim paths and optional bubbles."
        case .bird:
            return "Aviary gives each repo a bird that perches, hops, and takes a flight loop when a commit lands."
        }
    }

}
