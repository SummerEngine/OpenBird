# OpenBird

A desktop aquarium where your git repositories come to life as virtual fish. Every commit feeds your creatures -- keep coding to watch them grow, or neglect them and watch them fade.

Built with SwiftUI and SpriteKit for macOS.

## Download

Download the latest `.dmg` from [Releases](https://github.com/SummerEngine/OpenBird/releases). Open it, drag OpenBird to Applications, done.

## How It Works

1. **Add a git repository** -- OpenBird watches it for new commits using macOS file system events
2. **A fish appears** -- each repo gets its own creature with a name and color you choose
3. **Commits = food** -- every time you commit, your fish gets fed and grows
4. **Neglect has consequences** -- hunger increases over time, happiness drops, fish shrink and desaturate. After 30 days without a commit, they die

### Creature Lifecycle

Fish progress through stages based on total commits:

| Stage | Commits |
|-------|---------|
| Seedling | 0 |
| Sprout | 5 |
| Buddy | 25 |
| Companion | 100 |
| Sage | 500 |

### Quests

Track your coding habits with built-in achievements:

- **Hello World** -- Make your first commit
- **Growing Up** -- Reach 10 commits on a single repo
- **Busy Day** -- 10 commits in one day
- **Good Habit** -- 3-day commit streak
- **On a Roll** -- 7-day streak
- **Old Friends** -- 100 commits on one repo
- **The More The Merrier** -- Track 5 repositories
- **Daily Ritual** -- 30-day streak

## Build from Source

### Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15+

### Steps

```bash
git clone https://github.com/SummerEngine/OpenBird.git
cd OpenBird
open OpenBird.xcodeproj
```

In Xcode, select your signing team under **Signing & Capabilities**, then hit **Cmd+R** to build and run.

To create a release build:

```bash
xcodebuild -project OpenBird.xcodeproj -scheme OpenBird -configuration Release build
```

### Project Structure

```
OpenBird/
├── Assets/              # Animations, backgrounds, fish sprites
├── Core/
│   ├── Models/          # Creature, Repository, CommitRecord, AppSettings
│   ├── Services/        # GitMonitor, CreatureLifecycle, Persistence, Hotkey
│   ├── Protocols/       # GameMode base classes
│   └── Quests/          # Quest definitions and tracking
├── GameModes/
│   └── Fish/            # Aquarium scene, fish rendering, animations
├── Views/               # Settings, repo management, activity log
└── Utilities/           # Git helpers, color parsing
```

## Usage

OpenBird lives in your menu bar. Click the bird icon to:

- **Show/Hide** the aquarium window (or use the global hotkey, default `Cmd+Shift+T`)
- **Add repositories** to start tracking
- **Open settings** to customize behavior

### Settings

- Show/hide creature names
- Adjust movement speed (0.3x - 2.5x)
- Toggle commit sounds
- Follow across macOS Spaces
- Customize the global hotkey

### Interacting with Fish

- **Click** a fish to select it
- **Right-click** for options: rename, view commit history

## Data Storage

All data is stored locally in `~/Library/Application Support/OpenBird/`:

- `repositories.json` -- tracked repos
- `creatures.json` -- creature state (hunger, happiness, size, stage)
- `quests.json` -- quest progress
- `commits/*.json` -- per-repo commit history (last 500 per repo)

No accounts, no cloud, no telemetry.

## Tech Stack

- **SwiftUI** -- settings and management UI
- **SpriteKit** -- aquarium rendering and animation
- **FSEvents** -- native macOS file system watching for git changes
- **Carbon** -- global keyboard shortcut registration
- Zero external dependencies

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for setup instructions and guidelines.

## License

[MIT](LICENSE) -- Copyright (c) 2026 Summer Engine - The AI Game Engine
