# Privacy Policy — Joiner

*Last updated: March 2026*

## Overview

Joiner is a macOS menu bar application that reads your calendar events from the macOS Calendar app to display upcoming meetings and provide quick-join links for video conferences.

## Data We Access

Joiner requests read-only access to your macOS Calendar (`NSCalendarsFullAccessUsageDescription`) to:

- List your upcoming calendar events for the current day
- Read event details (title, time, location, description, URL) to detect video conference links
- Identify meeting links for Google Meet, Zoom, Microsoft Teams, and Slack Huddle

Calendar data is read locally via Apple's **EventKit** framework. Joiner does not connect to Google, Zoom, or any other external API on its own.

## Data Storage

**All data stays on your device.**

- Calendar event data is read directly from the system Calendar store and held only in memory while the app is running
- No event data or personal information is sent to any external server
- No analytics or telemetry are collected

## Data Sharing

Joiner does not share any data with third parties. The app has no network communication of its own — it only reads local calendar data via EventKit.

When you click a meeting link, your default browser opens and connects directly to the meeting provider (Google, Zoom, Microsoft, etc.) under their own privacy policies.

## Permissions

| Permission | Purpose |
|------------|---------|
| Calendar access (`NSCalendarsFullAccessUsageDescription`) | Read calendar events from the macOS Calendar store to display your meetings |

## Revoking Access

You can revoke Joiner's calendar access at any time:

1. Open **System Settings → Privacy & Security → Calendars**
2. Toggle off **Joiner**

You can also toggle individual calendars on/off within the app via **Preferences → Calendars**.

## Contact

For questions or concerns about this privacy policy, open an issue on the project repository.
