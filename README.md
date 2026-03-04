# Joiner

macOS menu bar app that shows your upcoming meetings with one-click join links for Google Meet, Zoom, Microsoft Teams and Slack Huddle. Reads directly from the macOS Calendar app — no Google account or API keys required.

## Features

- Reads from macOS Calendar (supports iCloud, Google, Exchange, CalDAV and any calendar synced to Calendar.app)
- Automatic meeting link detection (Meet, Zoom, Teams, Slack)
- Toggle individual calendars on/off in Preferences
- Conflict grouping for overlapping events
- "Next Up" card for imminent meetings (< 15 min)
- Dynamic countdown in the menu bar (e.g. `12m`)
- Menu bar icon blinks red when a meeting starts
- Notification 5 min before (silent) + at meeting time (with sound)
- "Join Now" action directly from the notification

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 16+ (for development)
- Calendar access permission (prompted on first launch)

---

## Development Setup

### 1. Clone and install tools

```bash
brew install xcodegen   # already handled by `make setup`
```

### 2. Build and run

```bash
make run    # generates project, builds, and launches
make test   # runs unit tests
```

On first launch the app will request **Calendar access** via the standard macOS permission dialog. Grant access to see your events.

---

## Distribution

Joiner uses EventKit (macOS system framework) to read calendar data. No external API keys or OAuth credentials are needed.

To distribute the app outside the Mac App Store you need:

1. **Apple Developer account** — for code signing and notarization
2. **Privacy Policy** — host `PRIVACY_POLICY.md` at a public URL (e.g. GitHub Pages)
3. Run the full deployment pipeline:

```bash
export CODE_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
export APPLE_ID="your@apple.id"
export TEAM_ID="YOUR_TEAM_ID"
export APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"  # from appleid.apple.com

make deploy   # archive → sign → notarize → DMG
```

---

## Makefile Reference

| Command | Description |
|---------|-------------|
| `make setup` | Install xcodegen via Homebrew |
| `make generate` | Generate Xcode project from `project.yml` |
| `make build` | Debug build |
| `make run` | Build and launch the app |
| `make test` | Run unit tests |
| `make archive` | Release archive (requires signing identity) |
| `make sign` | Code sign with Developer ID |
| `make notarize` | Submit to Apple notary + staple |
| `make dmg` | Create distributable DMG |
| `make deploy` | Full pipeline: archive → sign → notarize → DMG |
| `make clean` | Remove build artifacts |

---

## Architecture

```
src/Joiner/
├── App/                    # Entry point, AppDelegate (NSStatusItem)
├── Models/                 # CalendarEvent, MeetingLink
├── Services/
│   ├── Calendar/           # EventKitService, CalendarSyncService, EventParser
│   ├── MeetingLinkDetector # Regex for Meet/Zoom/Teams/Slack
│   ├── NotificationService # UNUserNotificationCenter
│   └── SyncScheduler       # Push-based sync + 5-min polling fallback
├── ViewModels/             # MenuBarViewModel, StatusItemViewModel, etc.
├── Views/
│   ├── MenuBar/            # PopoverContentView, StatusItemView
│   ├── Popover/            # NextUpCard, EventRow, ConflictGroup, JoinButton
│   ├── Preferences/        # Calendars, Appearance tabs
│   └── Components/         # CountdownBadge, VibrancyBackground
└── Utilities/              # Constants, DateFormatters, DismissedEventsStore
```

**Key decisions:**
- `NSStatusItem` + `NSPopover` (not SwiftUI `MenuBarExtra`) for full control over dynamic icon
- `@Observable` + SwiftUI — macOS 14+ only
- **EventKit** reads from the system Calendar store — supports all calendar providers without extra credentials
- Push-based sync via `EKEventStoreChanged` notification + 5-min polling fallback
- `UNUserNotificationCenter` for native notifications
