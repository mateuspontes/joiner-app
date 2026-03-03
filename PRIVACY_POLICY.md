# Privacy Policy — Joiner

*Last updated: March 2026*

## Overview

Joiner is a macOS menu bar application that connects to your Google Calendar to display upcoming meetings and provide quick-join links for video conferences.

## Data We Access

Joiner requests read-only access to your Google Calendar (`calendar.readonly` scope) to:

- List your upcoming calendar events for the current day
- Read event details (title, time, location, description) to detect video conference links
- Identify meeting links for Google Meet, Zoom, Microsoft Teams, and Slack Huddle

## Data Storage

**All data stays on your device.**

- Calendar event data is fetched directly from Google's API and held only in memory while the app is running
- OAuth authentication tokens are stored exclusively in your Mac's **Keychain** — the system-level secure credential store
- No event data, personal information, or tokens are sent to any server other than Google's official APIs
- No analytics or telemetry are collected

## Data Sharing

Joiner does not share any data with third parties. The only external communication is:

- **Google Calendar API** (`googleapis.com`) — to fetch your events
- **Google Sign-In** (`accounts.google.com`) — for authentication

## Permissions

| Permission | Purpose |
|------------|---------|
| `calendar.readonly` | Read calendar events to display your meetings |
| Network access | Communicate with Google Calendar API |
| Keychain access | Securely store your authentication tokens |

## Revoking Access

You can revoke Joiner's access to your Google account at any time:

1. Visit [Google Account Permissions](https://myaccount.google.com/permissions)
2. Find "Joiner" and click "Remove Access"

You can also remove your account from within the app via **Preferences → Accounts → Remove**.

## Contact

For questions or concerns about this privacy policy, open an issue on the project repository.
