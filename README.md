# Joiner

macOS menu bar app that shows your upcoming Google Calendar meetings with one-click join links for Google Meet, Zoom, Microsoft Teams and Slack Huddle.

## Features

- Multi-account Google Calendar support
- Automatic meeting link detection (Meet, Zoom, Teams, Slack)
- Conflict grouping for overlapping events
- "Next Up" card for imminent meetings (< 15 min)
- Dynamic countdown in the menu bar (e.g. `12m`)
- Menu bar icon blinks red when a meeting starts
- Notification 5 min before (silent) + at meeting time (with sound)
- "Join Now" action directly from the notification

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 16+ (for development)
- Google Cloud project with Calendar API enabled (see setup below)

---

## Development Setup

### 1. Clone and install tools

```bash
brew install xcodegen   # already handled by `make setup`
```

### 2. Google Cloud Setup

Before building, you need a Google Cloud OAuth Client ID.

**Step-by-step:**

1. Go to [Google Cloud Console](https://console.cloud.google.com) and create a new project named **Joiner**

2. Enable the **Google Calendar API**:
   - APIs & Services → Library → search "Google Calendar API" → Enable

3. Configure the **OAuth Consent Screen**:
   - APIs & Services → OAuth Consent Screen
   - User Type: **External**
   - App name: `Joiner`
   - User support email: your email
   - App logo: optional (helps with verification)
   - Authorized domains: leave empty for desktop apps
   - Developer contact email: your email
   - Scopes: click "Add or remove scopes" → add:
     - `https://www.googleapis.com/auth/calendar.readonly`
   - Test users (for Testing mode): add your Gmail addresses

4. Create **OAuth Client ID**:
   - APIs & Services → Credentials → Create Credentials → OAuth Client ID
   - Application type: **macOS** (or "Desktop app")
   - Name: `Joiner macOS`
   - Download the JSON — you'll need the **Client ID**

5. Configure the app:
   - Open `src/Joiner/Utilities/Constants.swift`
   - Replace `YOUR_CLIENT_ID` with your actual Client ID (the part before `.apps.googleusercontent.com`)
   - Open `src/Joiner/Resources/Info.plist`
   - Replace both occurrences of `YOUR_CLIENT_ID` with the same value

### 3. Build and run

```bash
make run    # generates project, builds, and launches
make test   # runs unit tests
```

---

## Distribution

### For personal use / small group (≤ 100 users)

Keep the OAuth app in **Testing** mode and add users via the Google Cloud Console:
- APIs & Services → OAuth Consent Screen → Test users → Add users

No Google review required. Works immediately.

### For public distribution (any Google account)

You need to publish the OAuth app. Google will review it.

**What to prepare:**

1. **Privacy Policy** — host the `PRIVACY_POLICY.md` at a public URL, e.g.:
   - GitHub Pages: `https://yourusername.github.io/joiner/privacy`
   - Or any static hosting

2. **Submit for verification** in Google Cloud Console:
   - OAuth Consent Screen → Publish App → Submit for Verification
   - Fill in:
     - Privacy Policy URL (required)
     - Justification for `calendar.readonly`: *"Joiner reads calendar events to display upcoming meetings and extract video conference links. No data is stored on external servers — all data remains on the user's device."*
     - Demo video (optional but speeds up review): 2-3 min screen recording showing the sign-in flow and calendar display

3. **Wait for review** — usually 3–7 business days for apps requesting only `calendar.readonly`

> **Note:** While in "Unverified" status (before passing review), users will see a warning screen but can still proceed by clicking "Advanced → Go to Joiner (unsafe)". For personal use this is fine. For wide distribution, complete verification first.

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

### Environment variables for `make deploy`

```bash
export CODE_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
export APPLE_ID="your@apple.id"
export TEAM_ID="YOUR_TEAM_ID"
export APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"  # from appleid.apple.com
```

---

## Architecture

```
src/Joiner/
├── App/                    # Entry point, AppDelegate (NSStatusItem)
├── Models/                 # CalendarEvent, CalendarAccount, MeetingLink
├── Services/
│   ├── Auth/               # GoogleAuthService, KeychainService, TokenManager
│   ├── Calendar/           # GoogleCalendarAPIClient, CalendarSyncService, EventParser
│   ├── MeetingLinkDetector # Regex for Meet/Zoom/Teams/Slack
│   ├── NotificationService # UNUserNotificationCenter
│   └── SyncScheduler       # Periodic 15-min background sync
├── ViewModels/             # MenuBarViewModel, StatusItemViewModel, etc.
├── Views/
│   ├── MenuBar/            # PopoverContentView, StatusItemView
│   ├── Popover/            # NextUpCard, EventRow, ConflictGroup, JoinButton
│   ├── Preferences/        # Accounts, Calendars, Appearance tabs
│   └── Components/         # AccountDot, CountdownBadge, VibrancyBackground
└── Utilities/              # Constants, DateFormatters
```

**Key decisions:**
- `NSStatusItem` + `NSPopover` (not SwiftUI `MenuBarExtra`) for full control over dynamic icon
- `@Observable` + SwiftUI — macOS 14+ only
- Google Calendar REST API via `URLSession` — no heavy SDK, just Bearer token
- `Security.framework` Keychain for token storage
- `UNUserNotificationCenter` for native notifications
